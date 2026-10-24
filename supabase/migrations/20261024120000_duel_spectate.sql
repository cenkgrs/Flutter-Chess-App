-- Lets the waiting player watch the turn instead of staring at a blank panel.
--
-- Safe to expose: a match holds 20 distinct puzzles and turn N is solved only
-- by the player whose turn it is, so the position the spectator sees is never
-- one they will be given later in the same match. Their own turns stay hidden
-- from the opponent by exactly the same rule.
--
-- Adds, for the player who is NOT solving: `opponent_fen` (the live position),
-- `opponent_steps` and `opponent_difficulty`. `steps` is the solver's own
-- total, so both sides can draw the same progress bar.

create or replace function public.duel_state(p_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare d public.puzzle_duels; p public.puzzles; me uuid:=auth.uid(); mine boolean; watching boolean;
begin
 if me is null then raise exception 'authentication required'; end if;
 select * into strict d from public.puzzle_duels where id=p_id for update;
 if me not in(d.a,d.b) then raise exception 'not participant'; end if;
 while d.status='active' and d.turn<=20 and clock_timestamp()>=d.started_at+interval '30 seconds' loop
   d.history:=d.history||jsonb_build_array(jsonb_build_object('turn',d.turn,'points',0,'reason','timeout','mistakes',d.mistakes,'seconds',30));
   d.turn:=d.turn+1; d.step:=0; d.mistakes:=0; d.started_at:=d.started_at+interval '30 seconds';
 end loop;
 update public.puzzle_duels set turn=d.turn,step=d.step,mistakes=d.mistakes,started_at=d.started_at,history=d.history where id=p_id;
 if d.turn>20 and d.status='active' then
   perform public.duel_finish(p_id); select * into d from public.puzzle_duels where id=p_id;
 end if;
 mine:=case when d.turn%2=1 then me=d.a else me=d.b end;
 watching:=d.status='active' and d.turn<=20 and not mine;
 if d.status='active' and d.turn<=20 then select * into p from public.puzzles where id=d.puzzles[d.turn]; end if;
 return jsonb_build_object('id',d.id,'status',d.status,'turn',d.turn,'step',d.step,'mistakes',d.mistakes,
 'my_turn',mine,'is_a',me=d.a,'opponent_rating',case when me=d.a then d.rating_b else d.rating_a end,'opponent_delta',case when me=d.a then d.delta_b else d.delta_a end,'score',case when me=d.a then d.score_a else d.score_b end,
 'opponent_score',case when me=d.a then d.score_b else d.score_a end,
 'opponent',(select username from public.profiles where id=case when me=d.a then d.b else d.a end),
 'rating',case when me=d.a then d.rating_a else d.rating_b end,
 'delta',case when me=d.a then d.delta_a else d.delta_b end,
 'seconds_left',greatest(0,ceil(extract(epoch from(d.started_at+interval '30 seconds'-clock_timestamp())))),
 'fen',case when mine then(case when d.step=0 then p.fen else p.positions[d.step] end) end,
 'steps',cardinality(p.solution),
 'opponent_fen',case when watching then(case when d.step=0 then p.fen else p.positions[d.step] end) end,
 'opponent_steps',case when watching then cardinality(p.solution) end,
 'opponent_difficulty',case when watching then p.rating end,
 'difficulty',case when mine then p.rating end,'history',d.history);
end $$;

revoke all on function public.duel_state(uuid) from public,anon;
grant execute on function public.duel_state(uuid) to authenticated;
