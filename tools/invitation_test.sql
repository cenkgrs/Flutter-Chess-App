begin;
insert into auth.users(id,raw_user_meta_data) values
 ('00000000-0000-0000-0000-000000000001','{"username":"Alice"}'),
 ('00000000-0000-0000-0000-000000000002','{"username":"Bobby"}'),
 ('00000000-0000-0000-0000-000000000003','{"username":"Carol"}');
insert into public.friendships(sender_id,recipient_id,status) values
 ('00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002','accepted');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);
do $$ declare invite uuid; game uuid; begin
 begin
 perform public.send_game_invitation('00000000-0000-0000-0000-000000000003','blitz',3,2);
 raise exception 'nonfriend invited';
 exception when raise_exception then assert sqlerrm='not friends'; end;
 invite:=public.send_game_invitation('00000000-0000-0000-0000-000000000002','blitz',3,2);
 begin
 perform public.respond_game_invitation(invite,true); raise exception 'sender accepted';
 exception when raise_exception then assert sqlerrm='not recipient'; end;
 perform set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000002',true);
 assert jsonb_array_length(public.game_invitation_list())=1;
 game:=public.respond_game_invitation(invite,true);
 assert public.respond_game_invitation(invite,true)=game;
 assert (select count(*) from public.games)=1;
 assert (select increment_seconds from public.games where id=game)=2;
end $$;
rollback;
