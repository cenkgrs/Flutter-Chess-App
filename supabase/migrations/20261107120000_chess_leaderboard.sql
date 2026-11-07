-- The ratings table has always held one Elo per pool; nothing ever showed
-- them to the player. This reads the top of each pool and says, for every
-- name on it, whether an invitation may be sent — the friendship rule is
-- unchanged, so a stranger can only be befriended, not challenged.
create function public.chess_leaderboard(p_pool text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare me uuid:=auth.uid(); result jsonb;
begin
 if me is null then raise exception 'authentication required'; end if;
 if p_pool not in ('bullet','blitz','rapid','classical') then
   raise exception 'unknown pool';
 end if;
 with ranked as (
   select r.user_id, p.username::text, r.rating, r.games_played,
     rank() over(order by r.rating desc) as place
   from public.ratings r join public.profiles p on p.id=r.user_id
   where r.pool=p_pool and r.games_played>0
 ), leaders as (
   select l.*, case
     when l.user_id=me then 'self'
     when exists(select 1 from public.friendships f where f.status='accepted'
       and least(f.sender_id,f.recipient_id)=least(me,l.user_id)
       and greatest(f.sender_id,f.recipient_id)=greatest(me,l.user_id)) then 'accepted'
     when exists(select 1 from public.friendships f where f.status='pending'
       and least(f.sender_id,f.recipient_id)=least(me,l.user_id)
       and greatest(f.sender_id,f.recipient_id)=greatest(me,l.user_id)) then 'pending'
     else 'none' end as friendship
   from ranked l order by l.rating desc, l.username, l.user_id limit 100
 )
 select jsonb_build_object(
   'pool', p_pool,
   'leaders', coalesce((select jsonb_agg(to_jsonb(l)
     order by l.rating desc, l.username, l.user_id) from leaders l),'[]'::jsonb),
   'me', (select to_jsonb(r) from ranked r where r.user_id=me)
 ) into result;
 return result;
end $$;

revoke all on function public.chess_leaderboard(text) from public,anon;
grant execute on function public.chess_leaderboard(text) to authenticated;
