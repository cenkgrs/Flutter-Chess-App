begin;
insert into auth.users(id,raw_user_meta_data) values
 ('00000000-0000-0000-0000-000000000001','{"username":"Alice"}'),
 ('00000000-0000-0000-0000-000000000002','{"username":"Bobby"}'),
 ('00000000-0000-0000-0000-000000000003','{"username":"Carol"}');
insert into public.friendships(sender_id,recipient_id,status) values
 ('00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002','accepted');
insert into public.puzzles(fingerprint,fen,solution,positions,rating,expected_seconds,theme)
 select 'test'||n,'fixture',array['a1a2'],array['finished'],900,45,'test' from generate_series(1,30) n;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);
do $$ declare invite uuid; gid uuid; next_game uuid; d public.puzzle_duels; r jsonb; begin
 begin perform public.send_duel_invitation('00000000-0000-0000-0000-000000000003'); raise exception 'nonfriend allowed';
 exception when raise_exception then assert sqlerrm='not friends'; end;
 invite:=public.send_duel_invitation('00000000-0000-0000-0000-000000000002');
 assert public.send_duel_invitation('00000000-0000-0000-0000-000000000002')=invite;
 begin perform public.respond_duel_invitation(invite,true); raise exception 'sender accepted';
 exception when raise_exception then assert sqlerrm='not recipient'; end;
 perform set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000002',true);
 gid:=public.respond_duel_invitation(invite,true);
 assert public.respond_duel_invitation(invite,true)=gid;
 select * into d from public.puzzle_duels where id=gid;
 perform set_config('request.jwt.claim.sub',d.a::text,true);
 r:=public.duel_action(gid,1,0,'move','a1a2');
 assert (r->'history'->0) ? 'seconds';
 assert (r->'history'->0) ? 'mistakes';
 assert r->>'is_a'='true';
 update public.puzzle_duels set started_at=now()-interval '11 minutes' where id=gid;
 r:=public.duel_state(gid); assert r->>'status'='finished';
 assert (r->'history'->1->>'seconds')::int=30;
 r:=public.duel_rematch(gid); assert r->>'status'='pending';
 assert public.duel_rematch(gid)->>'status'='pending';
 perform set_config('request.jwt.claim.sub',d.b::text,true);
 assert public.duel_rematch_status(gid)->>'incoming'='true';
 r:=public.duel_rematch(gid); assert r->>'status'='accepted';
 next_game:=(r->>'game_id')::uuid;
 assert next_game<>gid;
 assert public.duel_rematch(gid)->>'game_id'=next_game::text;
 assert (select count(*) from public.puzzle_duels)=2;
 perform set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000003',true);
 begin perform public.duel_rematch_status(gid); raise exception 'outsider accessed';
 exception when raise_exception then assert sqlerrm='invalid rematch'; end;
end $$;
rollback;
