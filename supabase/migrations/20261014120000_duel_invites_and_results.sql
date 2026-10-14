create table public.duel_invitations(
 id uuid primary key default gen_random_uuid(), sender_id uuid not null references public.profiles,
 recipient_id uuid not null references public.profiles, previous_match uuid references public.puzzle_duels,
 match_id uuid references public.puzzle_duels, status text not null default 'pending'
 check(status in ('pending','accepted','declined')), expires_at timestamptz not null default now()+interval '5 minutes',
 check(sender_id<>recipient_id)
);
alter table public.duel_invitations enable row level security;
revoke all on public.duel_invitations from anon,authenticated;

create function public.send_duel_invitation(p_user uuid,p_match uuid default null) returns uuid
language plpgsql security definer set search_path='' as $$
declare me uuid:=auth.uid(); result uuid;
begin
 if me is null then raise exception 'authentication required'; end if;
 if p_user is null or p_user=me then raise exception 'invalid player'; end if;
 perform pg_advisory_xact_lock(hashtext('rok-puzzle-duel-queue'));
 if p_match is null then
   if not exists(select 1 from public.friendships where status='accepted'
     and least(sender_id,recipient_id)=least(me,p_user) and greatest(sender_id,recipient_id)=greatest(me,p_user)) then
     raise exception 'not friends'; end if;
 elsif not exists(select 1 from public.puzzle_duels where id=p_match and status='finished'
   and least(a,b)=least(me,p_user) and greatest(a,b)=greatest(me,p_user)) then
   raise exception 'invalid rematch';
 end if;
 select id into result from public.duel_invitations where sender_id=me and recipient_id=p_user
 and previous_match is not distinct from p_match and status='pending' and expires_at>now();
 if result is not null then return result; end if;
 if (select count(*) from public.duel_invitations where sender_id=me and status='pending' and expires_at>now())>=10 then
   raise exception 'too many invitations'; end if;
 insert into public.duel_invitations(sender_id,recipient_id,previous_match) values(me,p_user,p_match) returning id into result;
 return result;
end $$;

create function public.duel_invitation_list() returns jsonb
language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'authentication required'; end if;
 return coalesce((select jsonb_agg(to_jsonb(t)) from (
 select i.id,i.status,i.match_id as game_id,i.recipient_id=auth.uid() as incoming,p.username,'duel' as kind
 from public.duel_invitations i join public.profiles p on p.id=case when i.sender_id=auth.uid() then i.recipient_id else i.sender_id end
 left join public.puzzle_duels d on d.id=i.match_id
 where auth.uid() in(i.sender_id,i.recipient_id) and
 ((i.status='pending' and i.expires_at>now()) or (i.status='accepted' and d.status='active'))
 order by i.expires_at desc limit 20) t),'[]'::jsonb);
end $$;

create function public.respond_duel_invitation(p_id uuid,p_accept boolean) returns uuid
language plpgsql security definer set search_path='' as $$
declare i public.duel_invitations; selected uuid[]; ra integer; rb integer; gid uuid; first_player uuid; second_player uuid;
begin
 if auth.uid() is null then raise exception 'authentication required'; end if;
 perform pg_advisory_xact_lock(hashtext('rok-puzzle-duel-queue'));
 select * into strict i from public.duel_invitations where id=p_id for update;
 if i.recipient_id<>auth.uid() then raise exception 'not recipient'; end if;
 if i.status='accepted' then return i.match_id; end if;
 if i.status<>'pending' or i.expires_at<=now() then raise exception 'invite expired'; end if;
 if p_accept is not true then update public.duel_invitations set status='declined' where id=p_id; return null; end if;
 if exists(select 1 from public.puzzle_duels where status='active' and (a in(i.sender_id,i.recipient_id) or b in(i.sender_id,i.recipient_id))) then
   raise exception 'player already in duel'; end if;
 first_player:=case when random()<.5 then i.sender_id else i.recipient_id end;
 second_player:=case when first_player=i.sender_id then i.recipient_id else i.sender_id end;
 insert into public.duel_ratings(user_id) values(first_player),(second_player) on conflict do nothing;
 select rating into ra from public.duel_ratings where user_id=first_player;
 select rating into rb from public.duel_ratings where user_id=second_player;
 with candidates as (
 select id,rating,theme,row_number() over(partition by theme order by random()) as n from public.puzzles
 ), pairs as (
 select array_agg(id order by random()) as ids,avg(abs(rating-(ra+rb)/2)) as distance from candidates
 group by theme,(n-1)/2 having count(*)=2 order by distance,random() limit 10
 ), numbered as(select ids,row_number() over() as pair from pairs)
 select array_agg(u.id order by pair,u.ord) into selected from numbered,lateral unnest(ids) with ordinality u(id,ord);
 if coalesce(cardinality(selected),0)<20 then raise exception 'not enough puzzles'; end if;
 insert into public.puzzle_duels(a,b,puzzles,rating_a,rating_b) values(first_player,second_player,selected,ra,rb) returning id into gid;
 delete from public.duel_queue where user_id in(first_player,second_player);
 update public.duel_invitations set status='accepted',match_id=gid where id=p_id;
 return gid;
end $$;

create function public.duel_rematch_status(p_match uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare d public.puzzle_duels; i public.duel_invitations;
begin
 if auth.uid() is null then raise exception 'authentication required'; end if;
 select * into strict d from public.puzzle_duels where id=p_match;
 if auth.uid() not in(d.a,d.b) or d.status<>'finished' then raise exception 'invalid rematch'; end if;
 select * into i from public.duel_invitations where previous_match=p_match
 and (status='accepted' or (status='pending' and expires_at>now())) order by expires_at desc limit 1;
 return jsonb_build_object('status',coalesce(i.status,'none'),'incoming',i.recipient_id=auth.uid(),'game_id',i.match_id);
end $$;

create function public.duel_rematch(p_match uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare d public.puzzle_duels; i public.duel_invitations; gid uuid;
begin
 perform public.duel_rematch_status(p_match); -- Validate participant and completed match.
 perform pg_advisory_xact_lock(hashtext('rok-puzzle-duel-queue'));
 select * into d from public.puzzle_duels where id=p_match;
 select * into i from public.duel_invitations where previous_match=p_match
 and (status='accepted' or (status='pending' and expires_at>now())) order by expires_at desc limit 1;
 if i.id is null then
   perform public.send_duel_invitation(case when auth.uid()=d.a then d.b else d.a end,p_match);
 elsif i.status='pending' and i.recipient_id=auth.uid() then
   gid:=public.respond_duel_invitation(i.id,true);
 end if;
 return public.duel_rematch_status(p_match);
end $$;

revoke all on function public.send_duel_invitation(uuid,uuid) from public,anon;
revoke all on function public.duel_invitation_list() from public,anon;
revoke all on function public.respond_duel_invitation(uuid,boolean) from public,anon;
revoke all on function public.duel_rematch_status(uuid) from public,anon;
revoke all on function public.duel_rematch(uuid) from public,anon;
grant execute on function public.send_duel_invitation(uuid,uuid) to authenticated;
grant execute on function public.duel_invitation_list() to authenticated;
grant execute on function public.respond_duel_invitation(uuid,boolean) to authenticated;
grant execute on function public.duel_rematch_status(uuid) to authenticated;
grant execute on function public.duel_rematch(uuid) to authenticated;
