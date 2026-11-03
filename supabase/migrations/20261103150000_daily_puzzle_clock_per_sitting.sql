-- The daily attempt is created once a day and its clock ran from that moment,
-- so a player who opened the puzzle in the morning and came back in the
-- evening met a timer reading in the hundreds of minutes and a speed bonus
-- that was already gone — without being told either.
--
-- The clock now measures the sitting: opening the puzzle again restarts it
-- while the attempt is still unsolved. It stays one scored attempt per day,
-- mistakes still cost, and nothing can be farmed by leaving and returning —
-- there is only ever the one puzzle.

create or replace function public.start_daily_puzzle() returns jsonb
language plpgsql security definer set search_path='' as $$
declare me uuid:=auth.uid(); today date:=public.daily_puzzle_today(); d public.daily_puzzles;
 a public.daily_puzzle_attempts; p public.puzzles; s public.daily_puzzle_streaks; r public.puzzle_ratings;
begin
 if me is null then raise exception 'authentication required'; end if;
 insert into public.puzzle_ratings(user_id) values(me) on conflict do nothing;
 insert into public.daily_puzzle_streaks(user_id) values(me) on conflict do nothing;
 -- Same lock order as daily_puzzle_action.
 select * into strict r from public.puzzle_ratings where user_id=me for update;
 select * into strict s from public.daily_puzzle_streaks where user_id=me for update;
 d:=public.daily_puzzle_for(today);
 if d.day is null then
  return jsonb_build_object('empty',true,'day',today,'points',r.points) || public.daily_streak_json(s,today);
 end if;
 -- Ignore a stale active attempt from yesterday; it is expired on its next action.
 update public.daily_puzzle_attempts set status='expired',finished_at=clock_timestamp()
  where user_id=me and status='active' and day<today;
 insert into public.daily_puzzle_attempts(user_id,day,puzzle_id) values(me,today,d.puzzle_id)
  on conflict (user_id,day) do nothing;
 update public.daily_puzzle_attempts set started_at=clock_timestamp()
  where user_id=me and day=today and status='active';
 select * into strict a from public.daily_puzzle_attempts where user_id=me and day=today;
 select * into strict p from public.puzzles where id=a.puzzle_id;
 return jsonb_build_object('attempt_id',a.id,'day',a.day,
  'fen',case when a.step=0 then p.fen else p.positions[a.step] end,
  'difficulty',d.rating,'theme',p.theme,'started_at',a.started_at,'step',a.step,
  'mistakes',a.mistakes,'helped',a.helped,'status',a.status,'awarded_points',a.awarded_points,
  'points',r.points,
  'solution',case when a.status='revealed' then to_jsonb(p.solution) else null end,
  'initial_fen',case when a.status='revealed' then p.fen else null end) || public.daily_streak_json(s,today);
end $$;
