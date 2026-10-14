-- Shorten competitive turns and normalize the speed bonus to the same 30 seconds.
create or replace function public.duel_state(p_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare d public.puzzle_duels; p public.puzzles; me uuid:=auth.uid(); mine boolean;
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
 if d.status='active' and mine then select * into p from public.puzzles where id=d.puzzles[d.turn]; end if;
 return jsonb_build_object('id',d.id,'status',d.status,'turn',d.turn,'step',d.step,'mistakes',d.mistakes,
 'my_turn',mine,'is_a',me=d.a,'opponent_rating',case when me=d.a then d.rating_b else d.rating_a end,'opponent_delta',case when me=d.a then d.delta_b else d.delta_a end,'score',case when me=d.a then d.score_a else d.score_b end,
 'opponent_score',case when me=d.a then d.score_b else d.score_a end,
 'opponent',(select username from public.profiles where id=case when me=d.a then d.b else d.a end),
 'rating',case when me=d.a then d.rating_a else d.rating_b end,
 'delta',case when me=d.a then d.delta_a else d.delta_b end,
 'seconds_left',greatest(0,ceil(extract(epoch from(d.started_at+interval '30 seconds'-clock_timestamp())))),
 'fen',case when d.step=0 then p.fen else p.positions[d.step] end,
 'difficulty',p.rating,'history',d.history);
end $$;

create or replace function public.duel_action(p_id uuid,p_turn integer,p_step integer,p_action text,p_move text default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare d public.puzzle_duels; p public.puzzles; result jsonb; reward integer:=0; elapsed numeric;
begin
 result:=public.duel_state(p_id);
 select * into strict d from public.puzzle_duels where id=p_id for update;
 if d.status<>'active' or d.turn is distinct from p_turn or d.step is distinct from p_step then return result; end if;
 if (d.turn%2=1 and auth.uid()<>d.a) or (d.turn%2=0 and auth.uid()<>d.b) then raise exception 'not your turn'; end if;
 select * into strict p from public.puzzles where id=d.puzzles[d.turn];
 elapsed:=greatest(0,extract(epoch from(clock_timestamp()-d.started_at)));
 if p_action='move' then
   if p_move is distinct from p.solution[d.step+1] then
     update public.puzzle_duels set mistakes=mistakes+1 where id=p_id;
     return public.duel_state(p_id)||jsonb_build_object('wrong',true);
   end if;
   d.step:=least(d.step+2,cardinality(p.solution));
   if d.step<cardinality(p.solution) then
     update public.puzzle_duels set step=d.step where id=p_id;
     return public.duel_state(p_id);
   end if;
   elapsed:=greatest(1,extract(epoch from(clock_timestamp()-d.started_at)));
   reward:=greatest(1,round(100*(1+0.5*greatest(0,1-elapsed/30))/(1+d.mistakes)));
 elsif p_action<>'skip' then raise exception 'invalid action'; end if;
 update public.puzzle_duels set
 score_a=score_a+case when d.turn%2=1 then reward else 0 end,
 score_b=score_b+case when d.turn%2=0 then reward else 0 end,
 history=history||jsonb_build_array(jsonb_build_object('turn',d.turn,'points',reward,'mistakes',d.mistakes,'reason',p_action,'seconds',round(elapsed,1))),
 turn=turn+1,step=0,mistakes=0,started_at=clock_timestamp() where id=p_id;
 return public.duel_state(p_id);
end $$;
