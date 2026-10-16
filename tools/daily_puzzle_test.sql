-- Disposable local database only. Fixtures are rolled back.
begin;
insert into auth.users(id,raw_user_meta_data) values
 ('00000000-0000-0000-0000-000000000001','{"username":"Alice"}'),
 ('00000000-0000-0000-0000-000000000002','{"username":"Bobby"}'),
 ('00000000-0000-0000-0000-000000000003','{"username":"Carol"}');
-- Synthetic isolated fixtures: a two-move puzzle and single-move puzzles.
insert into public.puzzles(fingerprint,fen,solution,positions,rating,expected_seconds,theme) values
 ('daily-a','start',array['a1a2','h8h7','b1b2'],array['after1','after2','finished'],1400,60,'test');
insert into public.puzzles(fingerprint,fen,solution,positions,rating,expected_seconds,theme)
 select 'daily-'||n,'start',array['a1a2'],array['finished'],900,45,'test' from generate_series(1,5) n;

-- The selection is deterministic, pinned and does not repeat while unused puzzles remain.
do $$ declare first public.daily_puzzles; again public.daily_puzzles; seen int; begin
 first:=public.daily_puzzle_for(date '2026-01-01');
 update public.puzzles set rating=3000 where id=first.puzzle_id;
 again:=public.daily_puzzle_for(date '2026-01-01');
 assert first.puzzle_id=again.puzzle_id and again.rating=first.rating,'day must stay pinned';
 for i in 2..6 loop perform public.daily_puzzle_for(date '2026-01-01'+(i-1)); end loop;
 select count(distinct puzzle_id) into seen from public.daily_puzzles;
 assert seen=6,'no repeats before the pool is exhausted';
 perform public.daily_puzzle_for(date '2026-01-07');
 assert (select puzzle_id from public.daily_puzzles where day='2026-01-07')=first.puzzle_id,
  'least recently used puzzle returns first';
 assert public.daily_puzzle_today()=(now() at time zone 'Europe/Istanbul')::date;
 delete from public.daily_puzzles;
end $$;

-- Everyone gets the same puzzle; the solution never reaches the client.
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);
do $$ declare s jsonb; a jsonb; b jsonb; me uuid:=auth.uid(); begin
 s:=public.daily_puzzle_status();
 assert s->>'status'='none' and (s->>'solved')::boolean=false and (s->>'current_streak')::int=0;
 a:=public.start_daily_puzzle(); b:=public.start_daily_puzzle();
 assert a->>'attempt_id'=b->>'attempt_id','resume same attempt';
 assert a->'solution'='null'::jsonb and not a ? 'reply','solution must remain private';
 assert not has_table_privilege('authenticated','public.daily_puzzles','select');
 assert not has_table_privilege('authenticated','public.daily_puzzle_attempts','select');
 assert not has_table_privilege('authenticated','public.daily_puzzle_streaks','update');
 assert not has_function_privilege('authenticated','public.daily_puzzle_for(date)','execute');
 -- Use the two-move fixture to exercise replies, hints and resync.
 update public.daily_puzzles set puzzle_id=(select id from public.puzzles where fingerprint='daily-a'),rating=1400;
 update public.daily_puzzle_attempts set puzzle_id=(select id from public.puzzles where fingerprint='daily-a')
  where user_id=me;
 b:=public.daily_puzzle_action((a->>'attempt_id')::uuid,'move','a1a3',0);
 assert b->>'correct'='false';
 b:=public.daily_puzzle_action((a->>'attempt_id')::uuid,'move','a1a2',0);
 assert b->>'reply'='h8h7' and b->>'fen'='after2' and (b->>'step')::int=2;
 b:=public.daily_puzzle_action((a->>'attempt_id')::uuid,'move','b1b2',0);
 assert (b->>'resynced')::boolean,'stale step must resync';
 b:=public.daily_puzzle_action((a->>'attempt_id')::uuid,'move','b1b2',2);
 assert b->>'status'='solved' and (b->>'awarded_points')::int>0;
 assert (b->>'current_streak')::int=1 and (b->>'best_streak')::int=1;
 -- Wrong try halves the reward of a fast solve.
 assert (b->>'awarded_points')::int<=((25+1400/20.0)*1.5/2)::int+1;
 a:=public.daily_puzzle_action((a->>'attempt_id')::uuid,'move','b1b2',2);
 assert a->>'points'=b->>'points' and (a->>'current_streak')::int=1,'duplicate finish must not award twice';
 a:=public.start_daily_puzzle();
 assert a->>'status'='solved' and (a->>'step')::int=3,'a solved day cannot be replayed';
 s:=public.daily_puzzle_status();
 assert (s->>'solved')::boolean and s->>'awarded_points'=b->>'awarded_points';
end $$;

-- Hints keep the streak but give no points; consecutive days extend it.
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000002',true);
do $$ declare a jsonb; b jsonb; me uuid:=auth.uid(); begin
 a:=public.start_daily_puzzle();
 assert (select puzzle_id from public.daily_puzzle_attempts where id=(a->>'attempt_id')::uuid)=
  (select puzzle_id from public.daily_puzzles where day=public.daily_puzzle_today()),'same puzzle for everyone';
 update public.daily_puzzle_streaks set current_streak=4,best_streak=4,last_solved_day=public.daily_puzzle_today()-1
  where user_id=me;
 b:=public.daily_puzzle_action((a->>'attempt_id')::uuid,'hint',null,0);
 assert b->>'hint'='a1';
 b:=public.daily_puzzle_action((a->>'attempt_id')::uuid,'move','a1a2',0);
 b:=public.daily_puzzle_action((a->>'attempt_id')::uuid,'move','b1b2',2);
 assert b->>'status'='solved' and (b->>'awarded_points')::int=0,'hint forfeits points';
 assert (b->>'current_streak')::int=5 and (b->>'best_streak')::int=5;
 -- A missed day resets the visible streak but keeps the best one.
 update public.daily_puzzle_streaks set last_solved_day=public.daily_puzzle_today()-2 where user_id=me;
 b:=public.daily_puzzle_status();
 assert (b->>'current_streak')::int=0 and (b->>'best_streak')::int=5;
 update public.daily_puzzle_attempts set status='active',step=0,day=day-1 where user_id=me;
 update public.daily_puzzle_streaks set current_streak=2,last_solved_day=public.daily_puzzle_today()-3 where user_id=me;
 insert into public.daily_puzzles(day,puzzle_id,rating)
  select day-1,puzzle_id,rating from public.daily_puzzles where day=public.daily_puzzle_today();
 b:=public.daily_puzzle_action((a->>'attempt_id')::uuid,'move','a1a2',0);
 assert b->>'status'='expired','yesterday cannot be finished today';
 assert (b->>'current_streak')::int=0;
 a:=public.start_daily_puzzle();
 b:=public.daily_puzzle_action((a->>'attempt_id')::uuid,'move','a1a2',0);
 b:=public.daily_puzzle_action((a->>'attempt_id')::uuid,'move','b1b2',2);
 assert (b->>'current_streak')::int=1 and (b->>'best_streak')::int=5,'missed day restarts at one';
end $$;

-- Revealing ends the day without points and breaks the streak.
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000003',true);
do $$ declare a jsonb; b jsonb; me uuid:=auth.uid(); begin
 a:=public.start_daily_puzzle();
 update public.daily_puzzle_streaks set current_streak=3,best_streak=3,last_solved_day=public.daily_puzzle_today()-1
  where user_id=me;
 b:=public.daily_puzzle_action((a->>'attempt_id')::uuid,'reveal',null,0);
 assert b->>'status'='revealed' and b->'solution'=to_jsonb(array['a1a2','h8h7','b1b2']);
 assert (b->>'awarded_points')::int=0 and (b->>'current_streak')::int=0 and (b->>'best_streak')::int=3;
 b:=public.daily_puzzle_action((a->>'attempt_id')::uuid,'move','a1a2',0);
 assert b->>'status'='revealed','finished attempt cannot be solved afterwards';
 -- Another user's attempt is not reachable.
 perform set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);
 begin perform public.daily_puzzle_action((a->>'attempt_id')::uuid,'reveal',null,0); raise exception 'foreign attempt allowed';
 exception when no_data_found then null; end;
 perform set_config('request.jwt.claim.sub','',true);
 begin perform public.daily_puzzle_status(); raise exception 'anonymous allowed';
 exception when raise_exception then assert sqlerrm='authentication required'; end;
end $$;
rollback;
