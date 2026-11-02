-- Only for a disposable local PostgreSQL instance. Never run in Supabase.
-- Run after tools/test_bootstrap.sql and every migration, then roll back.

begin;

insert into auth.users(id) values
 ('aaaaaaaa-0000-0000-0000-000000000001'),
 ('bbbbbbbb-0000-0000-0000-000000000002'),
 ('cccccccc-0000-0000-0000-000000000003');
-- handle_new_user already made a profile for each; just name them.
update public.profiles set username = 'admin_user' where id = 'aaaaaaaa-0000-0000-0000-000000000001';
update public.profiles set username = 'player_one' where id = 'bbbbbbbb-0000-0000-0000-000000000002';
update public.profiles set username = 'player_two' where id = 'cccccccc-0000-0000-0000-000000000003';
insert into public.analytics_admins(user_id)
 values ('aaaaaaaa-0000-0000-0000-000000000001');

create function pg_temp.act_as(p text) returns void language sql as
$$ select set_config('request.jwt.claim.sub', p, true)::void $$;

do $$
declare admin text := 'aaaaaaaa-0000-0000-0000-000000000001';
        player text := 'bbbbbbbb-0000-0000-0000-000000000002';
        n bigint; row record; o jsonb;
begin
 -- A guest writes with no session, and the row carries no user.
 perform pg_temp.act_as('');
 perform public.log_analytics_event('app_opened', '{"cold":true}'::jsonb, '1.0.0', 'ios');
 select count(*) into n from public.analytics_events where user_id is null;
 if n <> 1 then raise exception 'TEST FAILED: guest event not stored as null user (%)', n; end if;

 -- A member's event is attributed to them, from the session, not an argument.
 perform pg_temp.act_as(player);
 perform public.log_analytics_event('game_started', '{"mode":"offline"}'::jsonb, '1.0.0', 'ios');
 perform public.log_analytics_event('assistant_used', '{}'::jsonb, '1.0.0', 'ios');
 perform public.log_analytics_event('analysis_used', '{}'::jsonb, '1.0.0', 'ios');
 select count(*) into n from public.analytics_events where user_id = player::uuid;
 if n <> 3 then raise exception 'TEST FAILED: member events not attributed (%)', n; end if;

 -- An unknown event name is dropped without raising, so a future client
 -- sending something this schema has not learned cannot break the app.
 perform public.log_analytics_event('not_a_real_event');
 select count(*) into n from public.analytics_events;
 if n <> 4 then raise exception 'TEST FAILED: unknown event was stored (%)', n; end if;

 -- A member cannot read any reporting function.
 begin
   perform public.analytics_overview(now() - interval '1 day', now() + interval '1 day');
   raise exception 'TEST FAILED: a non-admin read the overview';
 exception when others then
   if sqlerrm <> 'admin required' then raise; end if;
 end;
 begin
   perform * from public.analytics_users(now() - interval '1 day', now() + interval '1 day');
   raise exception 'TEST FAILED: a non-admin read the user list';
 exception when others then
   if sqlerrm <> 'admin required' then raise; end if;
 end;
 begin
   perform * from public.analytics_event_log(now() - interval '1 day', now() + interval '1 day');
   raise exception 'TEST FAILED: a non-admin read the event log';
 exception when others then
   if sqlerrm <> 'admin required' then raise; end if;
 end;
 begin
   perform * from public.analytics_daily(now() - interval '1 day', now() + interval '1 day');
   raise exception 'TEST FAILED: a non-admin read the daily series';
 exception when others then
   if sqlerrm <> 'admin required' then raise; end if;
 end;

 -- The admin can, and the numbers add up.
 perform pg_temp.act_as(admin);
 o := public.analytics_overview(now() - interval '1 day', now() + interval '1 day');
 if (o->>'games_started')::int <> 1 or (o->>'assistant_used')::int <> 1
    or (o->>'analysis_used')::int <> 1 then
   raise exception 'TEST FAILED: overview counts were %', o;
 end if;
 if (o->>'guest_events')::int <> 1 then
   raise exception 'TEST FAILED: guest events miscounted: %', o;
 end if;
 if (o->>'total_users')::int <> 3 then
   raise exception 'TEST FAILED: total users was %', o->>'total_users';
 end if;

 -- The user list identifies people by username and never by email.
 select * into row from public.analytics_users(now() - interval '1 day', now() + interval '1 day')
   where label = 'player_one';
 if row.games <> 1 or row.assistant <> 1 or row.analysis <> 1 then
   raise exception 'TEST FAILED: per-user counts were %', row;
 end if;

 -- The log labels a guest as such rather than inventing a user.
 select count(*) into n from public.analytics_event_log(
   now() - interval '1 day', now() + interval '1 day') where label = 'guest';
 if n <> 1 then raise exception 'TEST FAILED: guest label missing (%)', n; end if;

 -- Filtering by event works and the window excludes older rows.
 select count(*) into n from public.analytics_event_log(
   now() - interval '1 day', now() + interval '1 day', 'game_started');
 if n <> 1 then raise exception 'TEST FAILED: event filter returned %', n; end if;
 select count(*) into n from public.analytics_event_log(
   now() - interval '10 days', now() - interval '9 days');
 if n <> 0 then raise exception 'TEST FAILED: window ignored, got %', n; end if;

 -- Deleting the account takes its events with it.
 delete from auth.users where id = player::uuid;
 select count(*) into n from public.analytics_events where user_id = player::uuid;
 if n <> 0 then raise exception 'TEST FAILED: events survived account deletion'; end if;

 raise notice 'analytics: all checks passed';
end $$;

rollback;
