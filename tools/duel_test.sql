begin;
insert into auth.users(id,raw_user_meta_data) values
 ('00000000-0000-0000-0000-000000000001','{"username":"Alice"}'),
 ('00000000-0000-0000-0000-000000000002','{"username":"Bobby"}'),
 ('00000000-0000-0000-0000-000000000003','{"username":"Carol"}');
-- Synthetic isolated fixtures: never shipped as playable puzzles.
insert into public.puzzles(fingerprint,fen,solution,positions,rating,expected_seconds,theme)
 select 'test'||n,'fixture',array['a1a2'],array['finished'],900,45,'test' from generate_series(1,30) n;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);
select public.duel_matchmaking();
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000002',true);
select public.duel_matchmaking();
do $$ declare d public.puzzle_duels; s jsonb; previous integer; begin
 select * into strict d from public.puzzle_duels;
 perform set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000003',true);
 begin perform public.duel_state(d.id); raise exception 'outsider allowed';
 exception when raise_exception then assert sqlerrm='not participant'; end;
 for i in 1..20 loop
   perform set_config('request.jwt.claim.sub',case when i%2=1 then d.a::text else d.b::text end,true);
   s:=public.duel_state(d.id); assert s->>'fen'='fixture';
   if i=1 then
     s:=public.duel_action(d.id,i,0,'move','b1b2'); assert (s->>'mistakes')::int=1;
   end if;
   s:=public.duel_action(d.id,i,0,case when i%2=1 then 'move' else 'skip' end,'a1a2');
   previous:=(s->>'turn')::int;
   s:=public.duel_action(d.id,i,0,'move','a1a2');
   assert (s->>'turn')::int=previous,'duplicate advanced turn';
 end loop;
 assert s->>'status'='finished';
 assert (select count(*) from public.duel_ratings where played=1)=2;
 perform public.duel_state(d.id);
 assert (select count(*) from public.duel_ratings where played=1)=2,'rating duplicated';
assert (select score_a>score_b from public.puzzle_duels where id=d.id);
end $$;
-- Forfeit is idempotent and awards rating only once.
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);
select public.duel_matchmaking();
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000002',true);
select public.duel_matchmaking();
do $$ declare gid uuid; before_played integer; begin
 select id into gid from public.puzzle_duels where status='active' order by started_at desc limit 1;
 select sum(played) into before_played from public.duel_ratings;
 perform public.duel_forfeit(gid);
 perform public.duel_forfeit(gid);
 assert (select status='finished' from public.puzzle_duels where id=gid);
 assert (select sum(played) from public.duel_ratings)=before_played+2,'forfeit rating duplicated';
end $$;
-- A new match handles both disconnected players without getting stuck.
select public.duel_matchmaking();
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);
select public.duel_matchmaking();
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000002',true);
select public.duel_matchmaking();
update public.puzzle_duels set started_at=now()-interval '11 minutes' where status='active';
do $$ declare gid uuid; begin
 select id into gid from public.puzzle_duels where status='active';
 assert public.duel_state(gid)->>'status'='finished';
end $$;
rollback;
