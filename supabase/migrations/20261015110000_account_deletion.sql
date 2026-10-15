-- Auth Admin deletion and related application cleanup run in one transaction.
-- No client-callable privileged deletion RPC. The Edge Function verifies the
-- bearer token and derives the user ID from Auth, never from request input.
create or replace function public.cleanup_deleted_account()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  -- FK locks prevent new references while this account is being removed.
  perform 1 from public.profiles where id = old.id for update;
  delete from public.duel_invitations
  where sender_id = old.id or recipient_id = old.id
     or previous_match in (select id from public.puzzle_duels where a = old.id or b = old.id)
     or match_id in (select id from public.puzzle_duels where a = old.id or b = old.id);
  delete from public.game_invitations
  where sender_id = old.id or recipient_id = old.id
     or game_id in (select id from public.games where white_id = old.id or black_id = old.id);
  delete from public.duel_queue where user_id = old.id;
  delete from public.duel_ratings where user_id = old.id;
  delete from public.puzzle_duels where a = old.id or b = old.id;
  delete from public.game_moves where player_id = old.id;
  delete from public.games where white_id = old.id or black_id = old.id;
  -- profiles, ratings, private rooms, friends, matchmaking, puzzle attempts and
  -- puzzle ratings have ON DELETE CASCADE references. Opponent accounts and
  -- their earned ratings, plus the shared puzzle library, are not removed.
  return old;
end;
$$;
revoke all on function public.cleanup_deleted_account() from public, anon, authenticated;
create trigger cleanup_account_before_auth_delete
before delete on auth.users for each row execute function public.cleanup_deleted_account();
