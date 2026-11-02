-- A puzzle left open is resumed with the clock it started with, so a player
-- who came back the next day saw a timer in the thousands of minutes and lost
-- the whole speed bonus without being told. An attempt nobody has touched for
-- an hour is treated as abandoned, and the player is given a fresh puzzle.
--
-- Abandoning awards nothing and moves no rating, exactly as walking away did;
-- the only change is that the next visit starts cleanly.

create or replace function public.start_puzzle() returns jsonb
language plpgsql security definer set search_path='' as $$
declare me uuid:=auth.uid(); r public.puzzle_ratings; a public.puzzle_attempts; p public.puzzles;
begin
 if me is null then raise exception 'authentication required'; end if;
 insert into public.puzzle_ratings(user_id) values(me) on conflict do nothing;
 select * into r from public.puzzle_ratings where user_id=me for update;
 update public.puzzle_attempts set status='abandoned', finished_at=clock_timestamp()
  where user_id=me and status='active'
    and started_at < clock_timestamp() - interval '1 hour';
 select * into a from public.puzzle_attempts where user_id=me and status='active';
 if a.id is null then
  select * into p from public.puzzles candidate where not exists
   (select 1 from public.puzzle_attempts previous where previous.user_id=me and previous.puzzle_id=candidate.id)
   order by abs(candidate.rating-r.rating), random() limit 1;
  if p.id is null then return jsonb_build_object('empty',true,'rating',r.rating,'points',r.points); end if;
  insert into public.puzzle_attempts(user_id,puzzle_id,puzzle_rating) values(me,p.id,p.rating) returning * into a;
 else select * into p from public.puzzles where id=a.puzzle_id;
 end if;
 return jsonb_build_object('attempt_id',a.id,'fen',case when a.step=0 then p.fen else p.positions[a.step] end,
 'rating',r.rating,'points',r.points,'difficulty',a.puzzle_rating,'theme',p.theme,'started_at',a.started_at,
 'step',a.step,'mistakes',a.mistakes,'helped',a.helped,'status',a.status);
end $$;
