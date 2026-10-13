create table public.friendships (
 sender_id uuid not null references public.profiles(id) on delete cascade,
 recipient_id uuid not null references public.profiles(id) on delete cascade,
 status text not null default 'pending' check(status in ('pending','accepted')),
 created_at timestamptz not null default now(),
 primary key(sender_id,recipient_id),
 check(sender_id<>recipient_id)
);
create unique index friendships_pair on public.friendships
 (least(sender_id,recipient_id),greatest(sender_id,recipient_id));
alter table public.friendships enable row level security;
revoke all on public.friendships from anon,authenticated;

create function public.friend_list() returns jsonb
language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'authentication required'; end if;
 return coalesce((select jsonb_agg(jsonb_build_object('id',p.id,'username',p.username,
   'status',f.status,'incoming',f.recipient_id=auth.uid()) order by p.username)
 from public.friendships f join public.profiles p on p.id=
 case when f.sender_id=auth.uid() then f.recipient_id else f.sender_id end
 where auth.uid() in(f.sender_id,f.recipient_id)), '[]'::jsonb);
end $$;

create function public.search_players(p_query text) returns jsonb
language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'authentication required'; end if;
 if length(trim(p_query))<3 or length(trim(p_query))>20 then return '[]'::jsonb; end if;
 return coalesce((select jsonb_agg(to_jsonb(p)) from (
 select id,username from public.profiles
 where id<>auth.uid() and starts_with(lower(username::text),lower(trim(p_query)))
 order by username limit 20) p),'[]'::jsonb);
end $$;

create function public.friend_action(p_user uuid,p_action text) returns void
language plpgsql security definer set search_path='' as $$
declare me uuid:=auth.uid(); f public.friendships;
begin
 if me is null then raise exception 'authentication required'; end if;
 if p_user is null or p_user=me then raise exception 'invalid player'; end if;
 perform pg_advisory_xact_lock(hashtext(least(me,p_user)::text||greatest(me,p_user)::text));
 select * into f from public.friendships where
 least(sender_id,recipient_id)=least(me,p_user) and greatest(sender_id,recipient_id)=greatest(me,p_user);
 if p_action='send' then
   if f.sender_id is not null then return; end if;
   if (select count(*) from public.friendships where sender_id=me and status='pending')>=50 then
     raise exception 'too many pending requests';
   end if;
   insert into public.friendships(sender_id,recipient_id) values(me,p_user);
 elsif p_action='accept' then
   if f.recipient_id is distinct from me or f.status<>'pending' then raise exception 'invalid request'; end if;
   update public.friendships set status='accepted' where sender_id=f.sender_id and recipient_id=me;
 elsif p_action='decline' then
   delete from public.friendships where sender_id=p_user and recipient_id=me and status='pending';
 elsif p_action='cancel' then
   delete from public.friendships where sender_id=me and recipient_id=p_user and status='pending';
 else raise exception 'invalid action';
 end if;
end $$;
revoke all on function public.friend_list() from public,anon;
revoke all on function public.search_players(text) from public,anon;
revoke all on function public.friend_action(uuid,text) from public,anon;
grant execute on function public.friend_list() to authenticated;
grant execute on function public.search_players(text) to authenticated;
grant execute on function public.friend_action(uuid,text) to authenticated;
