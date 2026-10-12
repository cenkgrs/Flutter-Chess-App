-- Solutions are private. Clients only receive the next accepted move/reply.
create table public.puzzles (
 id uuid primary key default gen_random_uuid(),
 fingerprint text unique not null,
 fen text not null,
 solution text[] not null check (cardinality(solution) > 0),
 positions text[] not null,
 rating integer not null check (rating between 100 and 3500),
 expected_seconds integer not null check (expected_seconds > 0),
 theme text not null,
 source text not null default 'engine-selfplay',
 attempts integer not null default 0,
 created_at timestamptz not null default now(),
 check (cardinality(positions) = cardinality(solution))
);
create table public.puzzle_ratings (
 user_id uuid primary key references auth.users on delete cascade,
 rating integer not null default 1200,
 points bigint not null default 0,
 played integer not null default 0
);
create table public.puzzle_attempts (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users on delete cascade,
 puzzle_id uuid not null references public.puzzles,
 started_at timestamptz not null default clock_timestamp(),
 finished_at timestamptz,
 step integer not null default 0,
 mistakes integer not null default 0,
 helped boolean not null default false,
 status text not null default 'active' check(status in ('active','solved','revealed','abandoned')),
 puzzle_rating integer not null,
 awarded_points integer not null default 0,
 rating_delta integer not null default 0,
 unique(user_id,puzzle_id)
);
create unique index one_active_puzzle on public.puzzle_attempts(user_id) where status='active';
alter table public.puzzles enable row level security;
alter table public.puzzle_ratings enable row level security;
alter table public.puzzle_attempts enable row level security;
revoke all on public.puzzles, public.puzzle_ratings, public.puzzle_attempts from anon, authenticated;
grant select on public.puzzle_ratings to authenticated;
create policy own_puzzle_rating on public.puzzle_ratings for select to authenticated using(user_id=auth.uid());

create function public.start_puzzle() returns jsonb
language plpgsql security definer set search_path='' as $$
declare me uuid:=auth.uid(); r public.puzzle_ratings; a public.puzzle_attempts; p public.puzzles;
begin
 if me is null then raise exception 'authentication required'; end if;
 insert into public.puzzle_ratings(user_id) values(me) on conflict do nothing;
 select * into r from public.puzzle_ratings where user_id=me for update;
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

create function public.puzzle_action(p_attempt_id uuid,p_action text,p_move text default null,p_step integer default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare me uuid:=auth.uid(); a public.puzzle_attempts; p public.puzzles; r public.puzzle_ratings;
 reply text; elapsed numeric; expected numeric; success numeric; delta integer; reward integer:=0; next_fen text;
begin
 if me is null then raise exception 'authentication required'; end if;
 -- Same lock order for every action, serializing duplicate requests and multi-device attempts.
 select * into strict r from public.puzzle_ratings where user_id=me for update;
 select * into strict a from public.puzzle_attempts where id=p_attempt_id and user_id=me for update;
 select * into strict p from public.puzzles where id=a.puzzle_id for update;
 if a.status<>'active' then
  return jsonb_build_object('status',a.status,'points',r.points,'rating',r.rating,'awarded_points',a.awarded_points,'rating_delta',a.rating_delta,
   'fen',case when a.step=0 then p.fen else p.positions[a.step] end,'step',a.step,
   'solution',case when a.status='revealed' then to_jsonb(p.solution) else null end,
   'initial_fen',case when a.status='revealed' then p.fen else null end);
 end if;
 if p_step is distinct from a.step then
  return jsonb_build_object('status','active','fen',case when a.step=0 then p.fen else p.positions[a.step] end,'step',a.step,'resynced',true);
 end if;
 if p_action='hint' then
  update public.puzzle_attempts set helped=true where id=a.id;
  return jsonb_build_object('status','active','hint',left(p.solution[a.step+1],2));
 elsif p_action='move' then
  if p_move is distinct from p.solution[a.step+1] then
   update public.puzzle_attempts set mistakes=mistakes+1 where id=a.id;
   return jsonb_build_object('status','active','correct',false);
  end if;
  a.step:=a.step+1;
  if a.step<cardinality(p.solution) then
   reply:=p.solution[a.step+1]; a.step:=a.step+1;
  end if;
  next_fen:=p.positions[a.step];
  update public.puzzle_attempts set step=a.step where id=a.id;
  if a.step<cardinality(p.solution) then
   return jsonb_build_object('status','active','correct',true,'reply',reply,'fen',next_fen,'step',a.step);
  end if;
  a.status:='solved';
 elsif p_action in ('reveal','skip') then
  a.status:=case when p_action='reveal' then 'revealed' else 'abandoned' end;
 else raise exception 'invalid action'; end if;
 elapsed:=greatest(1,extract(epoch from(clock_timestamp()-a.started_at)));
 success:=case when a.status='solved' and not a.helped and a.mistakes=0 then 1 else 0 end;
 expected:=1/(1+power(10::numeric,(a.puzzle_rating-r.rating)/400.0));
 delta:=round((case when r.played<20 then 40 else 20 end)*(success-expected));
 if a.status='solved' and not a.helped then
  -- Difficulty base, at most 50% speed bonus, bounded wrong-try penalty.
  reward:=greatest(1,round((25+a.puzzle_rating/20.0)*
   (1+0.5*greatest(0,1-elapsed/p.expected_seconds))/(1+a.mistakes)));
 end if;
 update public.puzzle_ratings set rating=greatest(100,r.rating+delta),points=points+reward,played=played+1
  where user_id=me returning * into r;
 update public.puzzles set rating=greatest(100,least(3500,rating+round(8*(expected-success))::integer)),attempts=attempts+1 where id=p.id;
 update public.puzzle_attempts set status=a.status,finished_at=clock_timestamp(),awarded_points=reward,rating_delta=delta where id=a.id;
 return jsonb_build_object('status',a.status,'correct',true,'reply',reply,'fen',next_fen,'step',a.step,
 'points',r.points,'rating',r.rating,'awarded_points',reward,'rating_delta',delta,
 'solution',case when p_action='reveal' then to_jsonb(p.solution) else null end,
 'initial_fen',case when p_action='reveal' then p.fen else null end);
end $$;
revoke all on function public.start_puzzle() from public,anon;
revoke all on function public.puzzle_action(uuid,text,text,integer) from public,anon;
grant execute on function public.start_puzzle() to authenticated;
grant execute on function public.puzzle_action(uuid,text,text,integer) to authenticated;
