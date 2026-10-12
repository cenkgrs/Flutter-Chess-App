-- Queue presence is a short lease, renewed by the waiting screen.
alter table public.matchmaking_queue add column last_seen_at timestamptz not null default now();

create or replace function public.join_matchmaking(p_pool text, p_minutes integer, p_increment integer)
returns jsonb language plpgsql security definer set search_path='' as $$
declare
 me uuid := auth.uid(); my_rating integer; opponent uuid; new_game uuid;
 white_player uuid; black_player uuid;
begin
 if me is null then raise exception 'authentication required'; end if;
 if p_pool is null or p_pool not in ('bullet','blitz','rapid','classical')
    or p_minutes is null or p_minutes not between 1 and 180
    or p_increment is null or p_increment not between 0 and 180 then
   raise exception 'invalid time control';
 end if;
 perform pg_advisory_xact_lock(hashtext(p_pool || ':' || p_minutes || ':' || p_increment));
 select r.rating into strict my_rating from public.ratings r where r.user_id=me and r.pool=p_pool;
 select q.user_id into opponent from public.matchmaking_queue q
 where q.user_id<>me and q.pool=p_pool and q.initial_minutes=p_minutes
   and q.increment_seconds=p_increment and q.last_seen_at > now()-interval '15 seconds'
   and abs(q.rating-my_rating)<=greatest(100,extract(epoch from (now()-q.queued_at))::integer*4)
 order by q.queued_at limit 1 for update skip locked;
 if opponent is null then
   insert into public.matchmaking_queue(user_id,pool,initial_minutes,increment_seconds,rating)
   values(me,p_pool,p_minutes,p_increment,my_rating)
   on conflict(user_id) do update set pool=excluded.pool,initial_minutes=excluded.initial_minutes,
     increment_seconds=excluded.increment_seconds,rating=excluded.rating,
     queued_at=excluded.queued_at,last_seen_at=now();
   return jsonb_build_object('status','waiting','game_id',null);
 end if;
 white_player := case when random()<0.5 then me else opponent end;
 black_player := case when white_player=me then opponent else me end;
 insert into public.games(white_id,black_id,pool,initial_minutes,increment_seconds,white_ms,black_ms)
 values(white_player,black_player,p_pool,p_minutes,p_increment,p_minutes*60000,p_minutes*60000)
 returning id into new_game;
 delete from public.matchmaking_queue where user_id in(me,opponent);
 return jsonb_build_object('status','matched','game_id',new_game);
end $$;

create function public.matchmaking_population() returns jsonb
language plpgsql security definer set search_path='' as $$
declare me uuid:=auth.uid(); mine public.matchmaking_queue; result jsonb;
begin
 if me is null then raise exception 'authentication required'; end if;
 update public.matchmaking_queue set last_seen_at=now() where user_id=me returning * into mine;
 select jsonb_build_object('total',count(*),'same_control',count(*) filter (
   where pool=mine.pool and initial_minutes=mine.initial_minutes and increment_seconds=mine.increment_seconds))
 into result from public.matchmaking_queue
 where user_id<>me and last_seen_at>now()-interval '15 seconds';
 return result;
end $$;

-- Expose only public leaderboard fields, never attempts or puzzle solutions.
create function public.puzzle_leaderboard() returns jsonb
language plpgsql security definer set search_path='' as $$
declare result jsonb;
begin
 if auth.uid() is null then raise exception 'authentication required'; end if;
 with ranked as (
   select r.user_id,p.username::text,r.rating,r.points,r.played,
     rank() over(order by r.points desc) as place
   from public.puzzle_ratings r join public.profiles p on p.id=r.user_id where r.played>0
 ), leaders as (select * from ranked order by points desc,username,user_id limit 100)
 select jsonb_build_object(
   'leaders',coalesce((select jsonb_agg(to_jsonb(l) order by l.points desc,l.username,l.user_id) from leaders l),'[]'::jsonb),
   'me',(select to_jsonb(r) from ranked r where r.user_id=auth.uid())
 ) into result;
 return result;
end $$;
revoke all on function public.matchmaking_population() from public,anon;
revoke all on function public.puzzle_leaderboard() from public,anon;
grant execute on function public.matchmaking_population() to authenticated;
grant execute on function public.puzzle_leaderboard() to authenticated;
