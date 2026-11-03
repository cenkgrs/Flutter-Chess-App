-- Disposable local database only. Fixtures are rolled back.
begin;
insert into auth.users(id,raw_user_meta_data) values
 ('00000000-0000-0000-0000-000000000001','{"username":"Alice"}');
insert into public.puzzles(fingerprint,fen,solution,positions,rating,expected_seconds,theme) values
 ('clock-a','start',array['a1a2'],array['finished'],900,45,'test');

select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);

-- Coming back to an unsolved puzzle restarts the clock it is scored on.
do $$ declare first jsonb; again jsonb; begin
 first:=public.start_daily_puzzle();
 update public.daily_puzzle_attempts set started_at=clock_timestamp()-interval '9 hours'
  where user_id='00000000-0000-0000-0000-000000000001';
 again:=public.start_daily_puzzle();
 assert first->>'attempt_id'=again->>'attempt_id','still the same attempt';
 assert (again->>'started_at')::timestamptz > clock_timestamp()-interval '1 minute',
  'the clock restarts for this sitting';
end $$;

-- A finished attempt keeps its record; the clock is not touched again.
do $$ declare finished timestamptz; after jsonb; begin
 update public.daily_puzzle_attempts set status='solved',finished_at=clock_timestamp(),
  started_at=clock_timestamp()-interval '3 hours'
  where user_id='00000000-0000-0000-0000-000000000001';
 select started_at into finished from public.daily_puzzle_attempts
  where user_id='00000000-0000-0000-0000-000000000001';
 after:=public.start_daily_puzzle();
 assert (select started_at from public.daily_puzzle_attempts
   where user_id='00000000-0000-0000-0000-000000000001')=finished,
  'a solved attempt keeps the time it was solved in';
end $$;

rollback;
