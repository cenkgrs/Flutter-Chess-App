\set ON_ERROR_STOP on
begin;
create schema auth;
create table auth.users(id uuid primary key);
create role anon;
create role authenticated;
create function auth.uid() returns uuid language sql as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
\i /migration.sql
insert into auth.users values ('00000000-0000-0000-0000-000000000001'),('00000000-0000-0000-0000-000000000002');
insert into public.puzzles(fingerprint,fen,solution,positions,rating,expected_seconds,theme)
values ('test','initial',array['a1a2'],array['finished'],1200,60,'mate_in_1'),
('test2','initial',array['a1a2'],array['finished'],1300,60,'mate_in_1');
set request.jwt.claim.sub='00000000-0000-0000-0000-000000000001';
do $$
declare a jsonb; b jsonb; c jsonb; total bigint;
begin
 a:=public.start_puzzle(); b:=public.start_puzzle();
 assert a->>'attempt_id'=b->>'attempt_id', 'resume same attempt';
 assert not a ? 'solution', 'solution must remain private';
 b:=public.puzzle_action((a->>'attempt_id')::uuid,'move','a1a2',0);
 assert b->>'status'='solved';
 assert (b->>'awarded_points')::int>0;
 c:=public.puzzle_action((a->>'attempt_id')::uuid,'move','a1a2',0);
 assert b->>'points'=c->>'points', 'duplicate finish must not award twice';
 total:=(b->>'points')::bigint;
 a:=public.start_puzzle();
 perform public.puzzle_action((a->>'attempt_id')::uuid,'hint',null,0);
 b:=public.puzzle_action((a->>'attempt_id')::uuid,'move','a1a2',0);
 assert (b->>'awarded_points')::int=0, 'hint must prevent points';
 assert (b->>'points')::bigint=total;
 a:=public.start_puzzle(); assert (a->>'empty')::boolean, 'no repeat farming';
 assert not has_table_privilege('authenticated','public.puzzles','select'), 'solutions inaccessible';
 assert not has_table_privilege('authenticated','public.puzzle_ratings','update'), 'ratings read only';
end $$;
set request.jwt.claim.sub='00000000-0000-0000-0000-000000000002';
do $$
declare a jsonb; b jsonb;
begin
 a:=public.start_puzzle();
 update public.puzzle_attempts set started_at=now()-interval '1 hour' where id=(a->>'attempt_id')::uuid;
 b:=public.puzzle_action((a->>'attempt_id')::uuid,'move','a1a3',0);
 assert b->>'correct'='false';
 b:=public.puzzle_action((a->>'attempt_id')::uuid,'move','a1a2',0);
 assert (b->>'awarded_points')::int<60, 'slow incorrect attempt reduces points';
 assert (b->>'rating_delta')::int<0;
 a:=public.start_puzzle(); b:=public.puzzle_action((a->>'attempt_id')::uuid,'reveal',null,0);
 assert b->>'status'='revealed'; assert b ? 'solution'; assert (b->>'awarded_points')::int=0;
end $$;
\i /seed.sql
do $$
declare puzzle public.puzzles; user_id uuid; attempt_id uuid; response jsonb; step integer;
begin
 for puzzle in select * from public.puzzles where fingerprint not in ('test','test2') loop
  user_id:=gen_random_uuid();
  insert into auth.users values(user_id);
  insert into public.puzzle_ratings(user_id) values(user_id);
  perform set_config('request.jwt.claim.sub',user_id::text,true);
  insert into public.puzzle_attempts(user_id,puzzle_id,puzzle_rating)
   values(user_id,puzzle.id,puzzle.rating) returning id into attempt_id;
  step:=0;
  while step<cardinality(puzzle.solution) loop
   response:=public.puzzle_action(attempt_id,'move',puzzle.solution[step+1],step);
   assert (response->>'correct')::boolean;
   step:=(response->>'step')::integer;
   assert response->>'fen'=puzzle.positions[step];
  end loop;
  assert response->>'status'='solved';
 end loop;
end $$;
rollback;
