-- Leaving an active duel resolves it immediately. The match row lock and the
-- status guard make repeated requests safe and prevent duplicate rating writes.
create or replace function public.duel_forfeit(p_id uuid)
returns jsonb
language plpgsql
security definer set search_path = ''
as $$
declare
  d public.puzzle_duels;
  me uuid := auth.uid();
begin
  if me is null then raise exception 'authentication required'; end if;

  select * into strict d
  from public.puzzle_duels
  where id = p_id
  for update;

  if me not in (d.a, d.b) then raise exception 'not participant'; end if;
  if d.status <> 'active' then
    return jsonb_build_object('status', d.status);
  end if;

  update public.puzzle_duels set
    score_a = case when me = d.b then greatest(d.score_a, d.score_b + 1) else d.score_a end,
    score_b = case when me = d.a then greatest(d.score_b, d.score_a + 1) else d.score_b end,
    history = d.history || jsonb_build_array(jsonb_build_object(
      'turn', d.turn,
      'points', 0,
      'reason', 'forfeit',
      'mistakes', d.mistakes,
      'seconds', greatest(0, round(extract(epoch from (clock_timestamp() - d.started_at)), 1))
    ))
  where id = p_id;

  perform public.duel_finish(p_id);
  return jsonb_build_object('status', 'finished');
end;
$$;

revoke all on function public.duel_forfeit(uuid) from public, anon;
grant execute on function public.duel_forfeit(uuid) to authenticated;
