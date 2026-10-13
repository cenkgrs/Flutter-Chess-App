create table public.game_invitations (
 id uuid primary key default gen_random_uuid(),
 sender_id uuid not null references public.profiles(id),
 recipient_id uuid not null references public.profiles(id),
 pool text not null check(pool in ('bullet','blitz','rapid','classical')),
 minutes integer not null check(minutes between 1 and 180),
 increment integer not null check(increment between 0 and 180),
 status text not null default 'pending' check(status in ('pending','accepted','declined','cancelled')),
 game_id uuid references public.games(id),
 expires_at timestamptz not null default now()+interval '5 minutes',
 check(sender_id<>recipient_id)
);
alter table public.game_invitations enable row level security;
revoke all on public.game_invitations from anon,authenticated;

create function public.send_game_invitation(p_user uuid,p_pool text,p_minutes integer,p_increment integer)
returns uuid language plpgsql security definer set search_path='' as $$
declare me uuid:=auth.uid(); result uuid;
begin
 if me is null then raise exception 'authentication required'; end if;
 perform pg_advisory_xact_lock(hashtext(me::text));
 if not exists(select 1 from public.friendships where status='accepted'
   and least(sender_id,recipient_id)=least(me,p_user) and greatest(sender_id,recipient_id)=greatest(me,p_user)) then
   raise exception 'not friends';
 end if;
 update public.game_invitations set status='cancelled' where sender_id=me and status='pending';
 insert into public.game_invitations(sender_id,recipient_id,pool,minutes,increment)
 values(me,p_user,p_pool,p_minutes,p_increment) returning id into result;
 return result;
end $$;

create function public.game_invitation_list() returns jsonb
language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'authentication required'; end if;
 return coalesce((select jsonb_agg(to_jsonb(t)) from (
 select i.*, p.username, i.recipient_id=auth.uid() as incoming
 from public.game_invitations i join public.profiles p on p.id=
 case when i.sender_id=auth.uid() then i.recipient_id else i.sender_id end
 left join public.games g on g.id=i.game_id
 where auth.uid() in(i.sender_id,i.recipient_id)
 and ((i.status='pending' and i.expires_at>now()) or (i.status='accepted' and g.status='active'))
 order by i.expires_at desc limit 20) t),'[]'::jsonb);
end $$;

create function public.respond_game_invitation(p_id uuid,p_accept boolean) returns uuid
language plpgsql security definer set search_path='' as $$
declare i public.game_invitations; gid uuid; w uuid; b uuid;
begin
 if auth.uid() is null then raise exception 'authentication required'; end if;
 select * into strict i from public.game_invitations where id=p_id for update;
 if i.recipient_id<>auth.uid() then raise exception 'not recipient'; end if;
 if i.status='accepted' then return i.game_id; end if;
 if i.status<>'pending' or i.expires_at<=now() then raise exception 'invite expired'; end if;
 if not p_accept then
   update public.game_invitations set status='declined' where id=p_id; return null;
 end if;
 -- Serialize accepts involving either player, in a consistent order.
 perform pg_advisory_xact_lock(hashtext(least(i.sender_id,i.recipient_id)::text));
 perform pg_advisory_xact_lock(hashtext(greatest(i.sender_id,i.recipient_id)::text));
 if exists(select 1 from public.games where status='active'
   and (white_id in(i.sender_id,i.recipient_id) or black_id in(i.sender_id,i.recipient_id))) then
   raise exception 'player already in game';
 end if;
 w:=case when random()<0.5 then i.sender_id else i.recipient_id end;
 b:=case when w=i.sender_id then i.recipient_id else i.sender_id end;
 insert into public.games(white_id,black_id,pool,initial_minutes,increment_seconds,white_ms,black_ms)
 values(w,b,i.pool,i.minutes,i.increment,i.minutes*60000,i.minutes*60000) returning id into gid;
 delete from public.matchmaking_queue where user_id in(w,b);
 update public.game_invitations set status='accepted',game_id=gid where id=p_id;
 return gid;
end $$;
revoke all on function public.send_game_invitation(uuid,text,integer,integer) from public,anon;
revoke all on function public.game_invitation_list() from public,anon;
revoke all on function public.respond_game_invitation(uuid,boolean) from public,anon;
grant execute on function public.send_game_invitation(uuid,text,integer,integer) to authenticated;
grant execute on function public.game_invitation_list() to authenticated;
grant execute on function public.respond_game_invitation(uuid,boolean) to authenticated;
