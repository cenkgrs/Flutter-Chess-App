-- Local disposable database only; run after all migrations. Everything rolls back.
begin;
insert into auth.users(id) values
 ('00000000-0000-0000-0000-000000000001'),
 ('10000000-0000-0000-0000-000000000002'),
 ('20000000-0000-0000-0000-000000000003');
insert into public.puzzle_ratings(user_id,points,played) select id,100,1 from auth.users;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);
do $$ declare r jsonb; begin
 r:=public.puzzle_leaderboard();
 assert jsonb_array_length(r->'leaders')=3;
 assert (r->'me'->>'place')::int=1;
 assert (r->'leaders'->2->>'place')::int=1;
 assert not (r->'me' ? 'solution');
 perform public.join_matchmaking('blitz',3,2);
end $$;
insert into public.matchmaking_queue(user_id,pool,initial_minutes,increment_seconds,rating,last_seen_at)
 values ('10000000-0000-0000-0000-000000000002','blitz',3,2,1500,now()),
 ('20000000-0000-0000-0000-000000000003','blitz',3,2,1500,now()-interval '1 minute');
do $$ declare r jsonb; begin
 r:=public.matchmaking_population();
 assert (r->>'total')::int=1;
 assert (r->>'same_control')::int=1;
end $$;
update public.matchmaking_queue set last_seen_at=now()-interval '1 minute'
 where user_id<>'00000000-0000-0000-0000-000000000001';
do $$ declare r jsonb; begin
 r:=public.join_matchmaking('blitz',3,2);
 assert r->>'status'='waiting', 'stale opponent matched';
end $$;
select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000002',true);
do $$ declare r jsonb; begin
 r:=public.join_matchmaking('blitz',3,2);
 assert r->>'status'='matched';
end $$;
select set_config('request.jwt.claim.sub','',true);
do $$ begin
 begin perform public.puzzle_leaderboard(); raise exception 'anonymous access allowed';
 exception when raise_exception then assert sqlerrm='authentication required'; end;
end $$;
rollback;
