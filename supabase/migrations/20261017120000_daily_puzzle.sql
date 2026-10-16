-- Daily puzzle: one shared puzzle per Europe/Istanbul calendar day.
-- ROK's audience is Turkish first, so the puzzle changes at local midnight
-- instead of 03:00 (UTC midnight). Solutions stay private as in puzzle mode:
-- the client only receives accepted moves, the opponent reply and positions.
create table public.daily_puzzles (
 day date primary key,
 puzzle_id uuid not null references public.puzzles,
 -- Frozen at selection so every player gets the same difficulty and points,
 -- even while normal puzzle mode keeps recalibrating the shared puzzle.
 rating integer not null,
 created_at timestamptz not null default now()
);
create table public.daily_puzzle_attempts (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users on delete cascade,
 day date not null,
 puzzle_id uuid not null references public.puzzles,
 started_at timestamptz not null default clock_timestamp(),
 finished_at timestamptz,
 step integer not null default 0,
 mistakes integer not null default 0,
 helped boolean not null default false,
 status text not null default 'active' check(status in ('active','solved','revealed','expired')),
 awarded_points integer not null default 0,
 unique(user_id,day)
);
create table public.daily_puzzle_streaks (
 user_id uuid primary key references auth.users on delete cascade,
 current_streak integer not null default 0,
 best_streak integer not null default 0,
 last_solved_day date
);
alter table public.daily_puzzles enable row level security;
alter table public.daily_puzzle_attempts enable row level security;
alter table public.daily_puzzle_streaks enable row level security;
revoke all on public.daily_puzzles, public.daily_puzzle_attempts, public.daily_puzzle_streaks from anon, authenticated;

create function public.daily_puzzle_today() returns date
language sql stable set search_path='' as $$ select (now() at time zone 'Europe/Istanbul')::date $$;

-- A streak survives until the end of the day after the last solve.
create function public.daily_streak_json(s public.daily_puzzle_streaks, today date) returns jsonb
language sql immutable set search_path='' as $$
 select jsonb_build_object(
  'current_streak',case when s.last_solved_day>=today-1 then coalesce(s.current_streak,0) else 0 end,
  'best_streak',coalesce(s.best_streak,0))
$$;

-- Deterministic for a given pool: puzzles never used as daily come first, then
-- the least recently used; ties are broken by a hash of the day and puzzle.
-- The choice is pinned on first use, so later seeds never change a past day.
create function public.daily_puzzle_for(p_day date) returns public.daily_puzzles
language plpgsql security definer set search_path='' as $$
declare d public.daily_puzzles;
begin
 select * into d from public.daily_puzzles where day=p_day;
 if d.day is not null then return d; end if;
 insert into public.daily_puzzles(day,puzzle_id,rating)
  select p_day,p.id,p.rating from public.puzzles p
  order by (select max(used.day) from public.daily_puzzles used where used.puzzle_id=p.id) nulls first,
   md5(p_day::text||p.fingerprint), p.id
  limit 1
 on conflict (day) do nothing;
 select * into d from public.daily_puzzles where day=p_day;
 return d;
end $$;

create function public.daily_puzzle_status() returns jsonb
language plpgsql security definer set search_path='' as $$
declare me uuid:=auth.uid(); today date:=public.daily_puzzle_today(); s public.daily_puzzle_streaks; a public.daily_puzzle_attempts;
begin
 if me is null then raise exception 'authentication required'; end if;
 select * into s from public.daily_puzzle_streaks where user_id=me;
 select * into a from public.daily_puzzle_attempts where user_id=me and day=today;
 return jsonb_build_object('day',today,'status',coalesce(a.status,'none'),'solved',coalesce(a.status='solved',false),
  'awarded_points',coalesce(a.awarded_points,0)) || public.daily_streak_json(s,today);
end $$;

create function public.start_daily_puzzle() returns jsonb
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

create function public.daily_puzzle_action(p_attempt_id uuid,p_action text,p_move text default null,p_step integer default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare me uuid:=auth.uid(); today date:=public.daily_puzzle_today(); a public.daily_puzzle_attempts;
 p public.puzzles; d public.daily_puzzles; s public.daily_puzzle_streaks; r public.puzzle_ratings;
 reply text; next_fen text; elapsed numeric; reward integer:=0;
begin
 if me is null then raise exception 'authentication required'; end if;
 -- Same lock order for every action, serializing duplicate requests and multi-device attempts.
 select * into strict r from public.puzzle_ratings where user_id=me for update;
 select * into strict s from public.daily_puzzle_streaks where user_id=me for update;
 select * into strict a from public.daily_puzzle_attempts where id=p_attempt_id and user_id=me for update;
 select * into strict p from public.puzzles where id=a.puzzle_id;
 select * into strict d from public.daily_puzzles where day=a.day;
 -- The day is over: the attempt can no longer earn points or extend a streak.
 if a.status='active' and a.day<>today then
  update public.daily_puzzle_attempts set status='expired',finished_at=clock_timestamp() where id=a.id returning * into a;
 end if;
 if a.status<>'active' then
  return jsonb_build_object('status',a.status,'points',r.points,'awarded_points',a.awarded_points,
   'fen',case when a.step=0 then p.fen else p.positions[a.step] end,'step',a.step,
   'solution',case when a.status='revealed' then to_jsonb(p.solution) else null end,
   'initial_fen',case when a.status='revealed' then p.fen else null end) || public.daily_streak_json(s,today);
 end if;
 if p_step is distinct from a.step then
  return jsonb_build_object('status','active','fen',case when a.step=0 then p.fen else p.positions[a.step] end,'step',a.step,'resynced',true);
 end if;
 if p_action='hint' then
  update public.daily_puzzle_attempts set helped=true where id=a.id;
  return jsonb_build_object('status','active','hint',left(p.solution[a.step+1],2));
 elsif p_action='move' then
  if p_move is distinct from p.solution[a.step+1] then
   update public.daily_puzzle_attempts set mistakes=mistakes+1 where id=a.id;
   return jsonb_build_object('status','active','correct',false);
  end if;
  a.step:=a.step+1;
  if a.step<cardinality(p.solution) then
   reply:=p.solution[a.step+1]; a.step:=a.step+1;
  end if;
  next_fen:=p.positions[a.step];
  update public.daily_puzzle_attempts set step=a.step where id=a.id;
  if a.step<cardinality(p.solution) then
   return jsonb_build_object('status','active','correct',true,'reply',reply,'fen',next_fen,'step',a.step);
  end if;
  a.status:='solved';
 elsif p_action='reveal' then
  a.status:='revealed';
 else raise exception 'invalid action'; end if;
 if a.status='solved' then
  -- A solve keeps the streak even with hints; hints only forfeit points.
  update public.daily_puzzle_streaks set
   current_streak=case when last_solved_day=a.day-1 then current_streak+1 else 1 end,
   best_streak=greatest(best_streak,case when last_solved_day=a.day-1 then current_streak+1 else 1 end),
   last_solved_day=a.day
  where user_id=me returning * into s;
  if not a.helped then
   -- Same reward curve as puzzle mode, using the difficulty frozen for the day.
   elapsed:=greatest(1,extract(epoch from(clock_timestamp()-a.started_at)));
   reward:=greatest(1,round((25+d.rating/20.0)*
    (1+0.5*greatest(0,1-elapsed/p.expected_seconds))/(1+a.mistakes)));
   update public.puzzle_ratings set points=points+reward where user_id=me returning * into r;
  end if;
 else
  -- Giving up ends today's chance, so the streak restarts tomorrow.
  update public.daily_puzzle_streaks set current_streak=0 where user_id=me returning * into s;
 end if;
 update public.daily_puzzle_attempts set status=a.status,finished_at=clock_timestamp(),awarded_points=reward where id=a.id;
 return jsonb_build_object('status',a.status,'correct',true,'reply',reply,'fen',next_fen,'step',a.step,
  'points',r.points,'awarded_points',reward,
  'solution',case when a.status='revealed' then to_jsonb(p.solution) else null end,
  'initial_fen',case when a.status='revealed' then p.fen else null end) || public.daily_streak_json(s,today);
end $$;

revoke all on function public.daily_puzzle_today() from public,anon,authenticated;
revoke all on function public.daily_streak_json(public.daily_puzzle_streaks,date) from public,anon,authenticated;
revoke all on function public.daily_puzzle_for(date) from public,anon,authenticated;
revoke all on function public.daily_puzzle_status() from public,anon;
revoke all on function public.start_daily_puzzle() from public,anon;
revoke all on function public.daily_puzzle_action(uuid,text,text,integer) from public,anon;
grant execute on function public.daily_puzzle_status() to authenticated;
grant execute on function public.start_daily_puzzle() to authenticated;
grant execute on function public.daily_puzzle_action(uuid,text,text,integer) to authenticated;
