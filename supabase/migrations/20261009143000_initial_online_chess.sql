create extension if not exists citext;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username citext not null unique check (username ~ '^[A-Za-z0-9_]{3,20}$'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.ratings (
  user_id uuid not null references public.profiles(id) on delete cascade,
  pool text not null check (pool in ('bullet', 'blitz', 'rapid', 'classical')),
  rating integer not null default 1500 check (rating between 100 and 4000),
  games_played integer not null default 0 check (games_played >= 0),
  updated_at timestamptz not null default now(),
  primary key (user_id, pool)
);

create table public.games (
  id uuid primary key default gen_random_uuid(),
  white_id uuid not null references public.profiles(id),
  black_id uuid not null references public.profiles(id),
  pool text not null check (pool in ('bullet', 'blitz', 'rapid', 'classical')),
  initial_minutes integer not null check (initial_minutes between 1 and 180),
  increment_seconds integer not null check (increment_seconds between 0 and 180),
  status text not null default 'active'
    check (status in ('active', 'white_won', 'black_won', 'draw', 'aborted')),
  fen text not null default 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
  ply integer not null default 0 check (ply >= 0),
  white_ms integer not null,
  black_ms integer not null,
  result_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  finished_at timestamptz,
  check (white_id <> black_id)
);

create index games_white_active_idx on public.games (white_id, status, created_at desc);
create index games_black_active_idx on public.games (black_id, status, created_at desc);

create table public.game_moves (
  game_id uuid not null references public.games(id) on delete cascade,
  ply integer not null check (ply > 0),
  player_id uuid not null references public.profiles(id),
  uci text not null check (uci ~ '^[a-h][1-8][a-h][1-8][qrbn]?$'),
  san text not null,
  fen_after text not null,
  white_ms integer not null check (white_ms >= 0),
  black_ms integer not null check (black_ms >= 0),
  created_at timestamptz not null default now(),
  primary key (game_id, ply)
);

create table public.matchmaking_queue (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  pool text not null check (pool in ('bullet', 'blitz', 'rapid', 'classical')),
  initial_minutes integer not null check (initial_minutes between 1 and 180),
  increment_seconds integer not null check (increment_seconds between 0 and 180),
  rating integer not null,
  queued_at timestamptz not null default now()
);

create index matchmaking_lookup_idx on public.matchmaking_queue
  (pool, initial_minutes, increment_seconds, queued_at);

alter table public.profiles enable row level security;
alter table public.ratings enable row level security;
alter table public.games enable row level security;
alter table public.game_moves enable row level security;
alter table public.matchmaking_queue enable row level security;

create policy "authenticated users can read profiles"
on public.profiles for select to authenticated using (true);

create policy "users can update own profile"
on public.profiles for update to authenticated
using (auth.uid() is not null and auth.uid() = id)
with check (auth.uid() is not null and auth.uid() = id);

create policy "authenticated users can read ratings"
on public.ratings for select to authenticated using (true);

create policy "participants can read games"
on public.games for select to authenticated
using (auth.uid() is not null and auth.uid() in (white_id, black_id));

create policy "participants can read game moves"
on public.game_moves for select to authenticated
using (
  exists (
    select 1 from public.games g
    where g.id = game_id and auth.uid() in (g.white_id, g.black_id)
  )
);

create policy "users can read own queue entry"
on public.matchmaking_queue for select to authenticated
using (auth.uid() is not null and auth.uid() = user_id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
  requested_username text;
begin
  requested_username := coalesce(new.raw_user_meta_data ->> 'username', 'oyuncu_' || left(new.id::text, 8));
  insert into public.profiles (id, username)
  values (new.id, requested_username);

  insert into public.ratings (user_id, pool)
  select new.id, pool
  from unnest(array['bullet', 'blitz', 'rapid', 'classical']) as pool;
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.join_matchmaking(
  p_pool text,
  p_minutes integer,
  p_increment integer
)
returns jsonb
language plpgsql
security definer set search_path = ''
as $$
declare
  me uuid := auth.uid();
  my_rating integer;
  opponent uuid;
  new_game uuid;
  white_player uuid;
  black_player uuid;
  initial_clock integer := p_minutes * 60000;
begin
  if me is null then raise exception 'authentication required'; end if;
  if p_pool not in ('bullet', 'blitz', 'rapid', 'classical') then
    raise exception 'invalid pool';
  end if;
  if p_minutes < 1 or p_minutes > 180 or p_increment < 0 or p_increment > 180 then
    raise exception 'invalid time control';
  end if;

  perform pg_advisory_xact_lock(hashtext(p_pool || ':' || p_minutes || ':' || p_increment));

  select r.rating into strict my_rating
  from public.ratings r where r.user_id = me and r.pool = p_pool;

  select q.user_id into opponent
  from public.matchmaking_queue q
  where q.user_id <> me
    and q.pool = p_pool
    and q.initial_minutes = p_minutes
    and q.increment_seconds = p_increment
    and abs(q.rating - my_rating) <= greatest(100, extract(epoch from (now() - q.queued_at))::integer * 4)
  order by q.queued_at
  limit 1
  for update skip locked;

  if opponent is null then
    insert into public.matchmaking_queue
      (user_id, pool, initial_minutes, increment_seconds, rating, queued_at)
    values (me, p_pool, p_minutes, p_increment, my_rating, now())
    on conflict (user_id) do update set
      pool = excluded.pool,
      initial_minutes = excluded.initial_minutes,
      increment_seconds = excluded.increment_seconds,
      rating = excluded.rating,
      queued_at = excluded.queued_at;
    return jsonb_build_object('status', 'waiting', 'game_id', null);
  end if;

  if random() < 0.5 then
    white_player := me;
    black_player := opponent;
  else
    white_player := opponent;
    black_player := me;
  end if;

  insert into public.games
    (white_id, black_id, pool, initial_minutes, increment_seconds, white_ms, black_ms)
  values
    (white_player, black_player, p_pool, p_minutes, p_increment, initial_clock, initial_clock)
  returning id into new_game;

  delete from public.matchmaking_queue where user_id in (me, opponent);
  return jsonb_build_object('status', 'matched', 'game_id', new_game);
end;
$$;

create or replace function public.find_active_game()
returns uuid
language sql
security definer set search_path = ''
stable
as $$
  select g.id
  from public.games g
  where auth.uid() is not null
    and auth.uid() in (g.white_id, g.black_id)
    and g.status = 'active'
    and g.created_at > now() - interval '24 hours'
  order by g.created_at desc
  limit 1;
$$;

create or replace function public.leave_matchmaking()
returns void
language sql
security definer set search_path = ''
as $$
  delete from public.matchmaking_queue where user_id = auth.uid();
$$;

create or replace function public.submit_move(
  p_game_id uuid,
  p_expected_ply integer,
  p_uci text,
  p_san text,
  p_fen_after text,
  p_white_ms integer,
  p_black_ms integer
)
returns public.games
language plpgsql
security definer set search_path = ''
as $$
declare
  me uuid := auth.uid();
  current_game public.games;
begin
  select * into strict current_game from public.games
  where id = p_game_id for update;
  if current_game.status <> 'active' then raise exception 'game is not active'; end if;
  if current_game.ply <> p_expected_ply then raise exception 'stale game state'; end if;
  if (current_game.ply % 2 = 0 and me <> current_game.white_id)
     or (current_game.ply % 2 = 1 and me <> current_game.black_id) then
    raise exception 'not your turn';
  end if;
  if p_uci !~ '^[a-h][1-8][a-h][1-8][qrbn]?$' then raise exception 'invalid move'; end if;

  insert into public.game_moves
    (game_id, ply, player_id, uci, san, fen_after, white_ms, black_ms)
  values
    (p_game_id, p_expected_ply + 1, me, p_uci, p_san, p_fen_after,
     greatest(0, p_white_ms), greatest(0, p_black_ms));

  update public.games set
    ply = ply + 1,
    fen = p_fen_after,
    white_ms = greatest(0, p_white_ms),
    black_ms = greatest(0, p_black_ms),
    updated_at = now()
  where id = p_game_id
  returning * into current_game;
  return current_game;
end;
$$;

create or replace function public.finish_game(
  p_game_id uuid,
  p_result text,
  p_reason text
)
returns void
language plpgsql
security definer set search_path = ''
as $$
declare
  me uuid := auth.uid();
  g public.games;
  wr integer;
  br integer;
  wg integer;
  bg integer;
  ws numeric;
  bs numeric;
  we numeric;
  be numeric;
begin
  select * into strict g from public.games where id = p_game_id for update;
  if g.status <> 'active' then return; end if;
  if me not in (g.white_id, g.black_id) then raise exception 'not a participant'; end if;
  if p_result not in ('white', 'black', 'draw') then raise exception 'invalid result'; end if;
  if p_reason = 'resignation'
     and ((me = g.white_id and p_result <> 'black')
       or (me = g.black_id and p_result <> 'white')) then
    raise exception 'invalid resignation result';
  end if;
  if p_reason = 'timeout' then
    if g.ply % 2 = 0 then
      if g.white_ms > extract(epoch from (now() - g.updated_at)) * 1000 then
        raise exception 'white clock has not expired';
      end if;
      if p_result <> 'black' then raise exception 'invalid timeout result'; end if;
    else
      if g.black_ms > extract(epoch from (now() - g.updated_at)) * 1000 then
        raise exception 'black clock has not expired';
      end if;
      if p_result <> 'white' then raise exception 'invalid timeout result'; end if;
    end if;
  end if;

  select rating, games_played into strict wr, wg
    from public.ratings where user_id = g.white_id and pool = g.pool for update;
  select rating, games_played into strict br, bg
    from public.ratings where user_id = g.black_id and pool = g.pool for update;

  ws := case p_result when 'white' then 1.0 when 'black' then 0.0 else 0.5 end;
  bs := 1.0 - ws;
  we := 1.0 / (1.0 + power(10.0, (br - wr) / 400.0));
  be := 1.0 - we;

  update public.ratings set
    rating = greatest(100, round(wr + (case when wg < 30 then 40 else 20 end) * (ws - we))::integer),
    games_played = games_played + 1,
    updated_at = now()
  where user_id = g.white_id and pool = g.pool;

  update public.ratings set
    rating = greatest(100, round(br + (case when bg < 30 then 40 else 20 end) * (bs - be))::integer),
    games_played = games_played + 1,
    updated_at = now()
  where user_id = g.black_id and pool = g.pool;

  update public.games set
    status = case p_result when 'white' then 'white_won' when 'black' then 'black_won' else 'draw' end,
    result_reason = left(p_reason, 40),
    finished_at = now(),
    updated_at = now()
  where id = p_game_id;
end;
$$;

revoke all on function public.join_matchmaking(text, integer, integer) from public, anon;
revoke all on function public.find_active_game() from public, anon;
revoke all on function public.leave_matchmaking() from public, anon;
revoke all on function public.submit_move(uuid, integer, text, text, text, integer, integer) from public, anon;
revoke all on function public.finish_game(uuid, text, text) from public, anon;

grant execute on function public.join_matchmaking(text, integer, integer) to authenticated;
grant execute on function public.find_active_game() to authenticated;
grant execute on function public.leave_matchmaking() to authenticated;
grant execute on function public.submit_move(uuid, integer, text, text, text, integer, integer) to authenticated;
grant execute on function public.finish_game(uuid, text, text) to authenticated;

do $$
begin
  alter publication supabase_realtime add table public.games;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.game_moves;
exception when duplicate_object then null;
end $$;
