create table public.private_rooms (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (code ~ '^[A-Z2-9]{6}$'),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  pool text not null check (pool in ('bullet', 'blitz', 'rapid', 'classical')),
  initial_minutes integer not null check (initial_minutes between 1 and 180),
  increment_seconds integer not null check (increment_seconds between 0 and 180),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '30 minutes'
);

alter table public.games add column invite_code text;

alter table public.private_rooms enable row level security;
create policy "owners can read private rooms" on public.private_rooms
for select to authenticated using (auth.uid() = owner_id);

create or replace function public.create_private_room(
  p_pool text, p_minutes integer, p_increment integer
)
returns text language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  alphabet text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  room_code text;
begin
  if me is null then raise exception 'authentication required'; end if;
  delete from public.private_rooms where owner_id = me or expires_at < now();
  loop
    room_code := '';
    for i in 1..6 loop
      room_code := room_code || substr(alphabet, 1 + floor(random() * length(alphabet))::integer, 1);
    end loop;
    begin
      insert into public.private_rooms(code, owner_id, pool, initial_minutes, increment_seconds)
      values(room_code, me, p_pool, p_minutes, p_increment);
      return room_code;
    exception when unique_violation then null;
    end;
  end loop;
end; $$;

create or replace function public.join_private_room(p_code text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  me uuid := auth.uid();
  room public.private_rooms;
  new_game uuid;
  white_player uuid;
  black_player uuid;
begin
  if me is null then raise exception 'authentication required'; end if;
  select * into strict room from public.private_rooms
  where code = upper(trim(p_code)) and expires_at > now() for update;
  if room.owner_id = me then raise exception 'cannot join own room'; end if;
  if random() < .5 then white_player := me; black_player := room.owner_id;
  else white_player := room.owner_id; black_player := me; end if;
  insert into public.games(white_id, black_id, pool, initial_minutes,
    increment_seconds, white_ms, black_ms, invite_code)
  values(white_player, black_player, room.pool, room.initial_minutes,
    room.increment_seconds, room.initial_minutes * 60000, room.initial_minutes * 60000, room.code)
  returning id into new_game;
  delete from public.private_rooms where id = room.id;
  return new_game;
end; $$;

create or replace function public.find_private_room_game(p_code text)
returns uuid language sql security definer set search_path = '' stable as $$
  select g.id from public.games g
  where auth.uid() in (g.white_id, g.black_id)
    and g.invite_code = upper(trim(p_code))
    and g.status = 'active' and g.created_at > now() - interval '35 minutes'
  order by g.created_at desc limit 1;
$$;

create or replace function public.trim_old_game_moves()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  delete from public.game_moves gm
  using public.games old_game
  where gm.game_id = old_game.id
    and old_game.status <> 'active'
    and old_game.id not in (
      select id from (
        select g.id from public.games g
        where g.white_id = old_game.white_id or g.black_id = old_game.white_id
        order by coalesce(g.finished_at, g.updated_at) desc limit 10
      ) white_recent
    )
    and old_game.id not in (
      select id from (
        select g.id from public.games g
        where g.white_id = old_game.black_id or g.black_id = old_game.black_id
        order by coalesce(g.finished_at, g.updated_at) desc limit 10
      ) black_recent
    );
  return new;
end; $$;

create trigger trim_game_history_after_finish
after update of status on public.games
for each row when (old.status = 'active' and new.status <> 'active')
execute function public.trim_old_game_moves();

revoke all on function public.create_private_room(text, integer, integer) from public, anon;
revoke all on function public.join_private_room(text) from public, anon;
revoke all on function public.find_private_room_game(text) from public, anon;
grant execute on function public.create_private_room(text, integer, integer) to authenticated;
grant execute on function public.join_private_room(text) to authenticated;
grant execute on function public.find_private_room_game(text) to authenticated;
