-- Disposable local database only. Fixtures are rolled back.
begin;

insert into auth.users(id, raw_user_meta_data) values
 ('00000000-0000-0000-0000-0000000000a1','{"username":"Alice"}'),
 ('00000000-0000-0000-0000-0000000000b1','{"username":"Bob"}'),
 ('00000000-0000-0000-0000-0000000000c1','{"username":"Carol"}'),
 ('00000000-0000-0000-0000-0000000000d1','{"username":"Dave"}');

update public.ratings set rating=1800, games_played=12
 where user_id='00000000-0000-0000-0000-0000000000a1' and pool='blitz';
update public.ratings set rating=2000, games_played=30
 where user_id='00000000-0000-0000-0000-0000000000b1' and pool='blitz';
update public.ratings set rating=1600, games_played=5
 where user_id='00000000-0000-0000-0000-0000000000c1' and pool='blitz';
-- Dave has a rating row but has never played; he is not on the board.
update public.ratings set rating=2500, games_played=0
 where user_id='00000000-0000-0000-0000-0000000000d1' and pool='blitz';

insert into public.friendships(sender_id,recipient_id,status) values
 ('00000000-0000-0000-0000-0000000000a1','00000000-0000-0000-0000-0000000000b1','accepted'),
 ('00000000-0000-0000-0000-0000000000c1','00000000-0000-0000-0000-0000000000a1','pending');

-- Read the board as Alice.
create or replace function auth.uid() returns uuid language sql stable as
 $f$ select '00000000-0000-0000-0000-0000000000a1'::uuid $f$;

do $$ declare board jsonb; leaders jsonb; begin
  board := public.chess_leaderboard('blitz');
  leaders := board->'leaders';

  assert jsonb_array_length(leaders)=3, 'only players who have played are listed';
  assert leaders->0->>'username'='Bob', 'the highest rating leads';
  assert (leaders->0->>'place')::int=1, 'and carries the first place';
  assert leaders->2->>'username'='Carol', 'the lowest rating closes the board';

  assert leaders->0->>'friendship'='accepted', 'an accepted friend can be challenged';
  assert leaders->1->>'friendship'='self', 'the reader is marked as themselves';
  assert leaders->2->>'friendship'='pending', 'a request already sent is not sent twice';

  assert board->'me'->>'username'='Alice', 'the reader finds their own row';
  assert (board->'me'->>'place')::int=2, 'with their own place';
end $$;

-- A pool nobody plays is empty rather than an error.
do $$ declare board jsonb; begin
  board := public.chess_leaderboard('bullet');
  assert board->'leaders'='[]'::jsonb, 'an unplayed pool is an empty board';
  assert board->'me' is null or board->'me'='null'::jsonb, 'and has no own row';
end $$;

-- A pool that does not exist is refused.
do $$ begin
  begin
    perform public.chess_leaderboard('armageddon');
    assert false, 'an unknown pool must be refused';
  exception when others then
    assert sqlerrm like '%unknown pool%', 'and refused by name: ' || sqlerrm;
  end;
end $$;

rollback;
