-- Disposable local database only. Fixtures are rolled back.
begin;
insert into auth.users(id,raw_user_meta_data) values
 ('00000000-0000-0000-0000-000000000001','{"username":"Alice"}');
insert into public.puzzles(fingerprint,fen,solution,positions,rating,expected_seconds,theme)
 select 'stale-'||n,'start'||n,array['a1a2'],array['finished'],1500,45,'test'
 from generate_series(1,3) n;

select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);

-- A puzzle picked up again within the hour is the same one, same clock.
do $$ declare first jsonb; again jsonb; begin
 first:=public.start_puzzle();
 again:=public.start_puzzle();
 assert first->>'attempt_id'=again->>'attempt_id','a fresh attempt is resumed';
 assert first->>'started_at'=again->>'started_at','and keeps its clock';
end $$;

-- One left overnight is abandoned, and the next visit starts a new puzzle.
do $$ declare stale uuid; resumed jsonb; begin
 select id into stale from public.puzzle_attempts
  where user_id='00000000-0000-0000-0000-000000000001' and status='active';
 update public.puzzle_attempts set started_at=clock_timestamp()-interval '26 hours'
  where id=stale;

 resumed:=public.start_puzzle();
 assert (resumed->>'attempt_id')::uuid<>stale,'a stale attempt is not resumed';
 assert (select status from public.puzzle_attempts where id=stale)='abandoned',
  'the stale attempt is closed';
 assert (select awarded_points from public.puzzle_attempts where id=stale)=0,
  'abandoning awards nothing';
 assert (select rating_delta from public.puzzle_attempts where id=stale)=0,
  'and moves no rating';
 assert (resumed->>'started_at')::timestamptz > clock_timestamp()-interval '1 minute',
  'the new attempt starts its clock now';
end $$;

rollback;
