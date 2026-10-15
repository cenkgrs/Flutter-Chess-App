-- Resume-safe snapshots use the database clock so device clock skew cannot
-- add or remove time from a player.
create or replace function public.get_game_state(p_game_id uuid)
returns jsonb
language plpgsql
security definer set search_path = ''
stable
as $$
declare
  g public.games;
begin
  select * into strict g
  from public.games
  where id = p_game_id
    and auth.uid() is not null
    and auth.uid() in (white_id, black_id);

  return to_jsonb(g) || jsonb_build_object('_server_now', now());
end;
$$;

revoke all on function public.get_game_state(uuid) from public, anon;
grant execute on function public.get_game_state(uuid) to authenticated;

-- The database, not either player's device, owns the clocks. Keep the old
-- signature for deployed clients, but deliberately ignore their clock values.
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
  elapsed_ms integer;
  next_white_ms integer;
  next_black_ms integer;
begin
  select * into strict current_game
  from public.games
  where id = p_game_id
  for update;

  if current_game.status <> 'active' then raise exception 'game is not active'; end if;
  if current_game.ply <> p_expected_ply then raise exception 'stale game state'; end if;
  if (current_game.ply % 2 = 0 and me <> current_game.white_id)
     or (current_game.ply % 2 = 1 and me <> current_game.black_id) then
    raise exception 'not your turn';
  end if;
  if p_uci !~ '^[a-h][1-8][a-h][1-8][qrbn]?$' then raise exception 'invalid move'; end if;

  elapsed_ms := greatest(0,
    floor(extract(epoch from (clock_timestamp() - current_game.updated_at)) * 1000)::integer);
  next_white_ms := current_game.white_ms;
  next_black_ms := current_game.black_ms;

  if current_game.ply % 2 = 0 then
    if next_white_ms <= elapsed_ms then raise exception 'clock expired'; end if;
    next_white_ms := next_white_ms - elapsed_ms + current_game.increment_seconds * 1000;
  else
    if next_black_ms <= elapsed_ms then raise exception 'clock expired'; end if;
    next_black_ms := next_black_ms - elapsed_ms + current_game.increment_seconds * 1000;
  end if;

  insert into public.game_moves
    (game_id, ply, player_id, uci, san, fen_after, white_ms, black_ms)
  values
    (p_game_id, p_expected_ply + 1, me, p_uci, p_san, p_fen_after,
     next_white_ms, next_black_ms);

  update public.games set
    ply = ply + 1,
    fen = p_fen_after,
    white_ms = next_white_ms,
    black_ms = next_black_ms,
    updated_at = clock_timestamp()
  where id = p_game_id
  returning * into current_game;

  return current_game;
end;
$$;
