-- Disposable local database only. Fixtures are rolled back.
begin;
insert into auth.users(id,raw_user_meta_data) values
 ('00000000-0000-0000-0000-000000000001','{"username":"delete_me"}'),
 ('00000000-0000-0000-0000-000000000002','{"username":"keep_me"}'),
 ('00000000-0000-0000-0000-000000000003','{"username":"keep_too"}');
insert into public.games(id,white_id,black_id,pool,initial_minutes,increment_seconds,white_ms,black_ms) values
 ('10000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002','blitz',3,2,180000,180000),
 ('10000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000003','blitz',3,2,180000,180000);
insert into public.game_moves(game_id,ply,player_id,uci,san,fen_after,white_ms,black_ms)
values ('10000000-0000-0000-0000-000000000001',1,'00000000-0000-0000-0000-000000000001','e2e4','e4','fixture',180000,180000);
insert into public.game_invitations(sender_id,recipient_id,pool,minutes,increment,game_id)
values ('00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000001','blitz',3,2,'10000000-0000-0000-0000-000000000001');
insert into public.friendships(sender_id,recipient_id) values ('00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002');
insert into public.private_rooms(code,owner_id,pool,initial_minutes,increment_seconds)
values ('ABCDEF','00000000-0000-0000-0000-000000000001','blitz',3,2);
insert into public.duel_ratings(user_id) values ('00000000-0000-0000-0000-000000000001');
insert into public.duel_queue(user_id) values ('00000000-0000-0000-0000-000000000001');
insert into public.puzzle_duels(id,a,b,puzzles,rating_a,rating_b)
values ('20000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002',array_fill(gen_random_uuid(),array[20]),1200,1200);
insert into public.duel_invitations(sender_id,recipient_id,previous_match,match_id)
values ('00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001');
insert into public.puzzles(id,fingerprint,fen,solution,positions,rating,expected_seconds,theme)
values ('30000000-0000-0000-0000-000000000001','delete-test','fixture',array['a1a2'],array['fixture'],1200,30,'test');
insert into public.puzzle_ratings(user_id) values ('00000000-0000-0000-0000-000000000001');
insert into public.puzzle_attempts(user_id,puzzle_id,puzzle_rating)
values ('00000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001',1200);
delete from auth.users where id='00000000-0000-0000-0000-000000000001';
do $$ begin
 if exists(select 1 from public.profiles where username='delete_me') then raise exception 'profile remains'; end if;
 if (select count(*) from auth.users)<>2 then raise exception 'opponent deleted'; end if;
 if (select count(*) from public.games)<>1 then raise exception 'unrelated game changed'; end if;
 if (select count(*) from public.ratings)<>8 then raise exception 'opponent ratings changed'; end if;
 if exists(select 1 from public.game_moves) or exists(select 1 from public.friendships)
 or exists(select 1 from public.game_invitations) or exists(select 1 from public.private_rooms)
 or exists(select 1 from public.puzzle_attempts) or exists(select 1 from public.puzzle_ratings)
 or exists(select 1 from public.duel_queue) or exists(select 1 from public.duel_ratings)
 or exists(select 1 from public.puzzle_duels) or exists(select 1 from public.duel_invitations)
 then raise exception 'personal records remain'; end if;
 if (select count(*) from public.puzzles)<>1 then raise exception 'puzzle library deleted'; end if;
 if has_function_privilege('authenticated','public.cleanup_deleted_account()','EXECUTE')
 or has_function_privilege('anon','public.cleanup_deleted_account()','EXECUTE')
 then raise exception 'privileged function exposed'; end if;
end $$;
rollback;
