-- Only for a disposable local PostgreSQL instance. Never run in Supabase.
-- Run after tools/test_bootstrap.sql and the migrations, then roll back.
--
--   psql -f tools/test_bootstrap.sql
--   psql -f supabase/migrations/20261024130000_daily_feature_limits.sql
--   psql -f tools/daily_feature_limits_test.sql

begin;

insert into auth.users(id) values
 ('11111111-1111-1111-1111-111111111111'),
 ('22222222-2222-2222-2222-222222222222');

create function pg_temp.act_as(p uuid) returns void language sql as
$$ select set_config('request.jwt.claim.sub', p::text, true)::void $$;

do $$
declare r jsonb; first uuid := '11111111-1111-1111-1111-111111111111';
        second uuid := '22222222-2222-2222-2222-222222222222';
begin
 -- A signed-out caller is refused outright.
 perform set_config('request.jwt.claim.sub', '', true);
 begin
   perform public.claim_daily_feature('assistant_game');
   raise exception 'TEST FAILED: an anonymous claim was allowed';
 exception when others then
   if sqlerrm <> 'authentication required' then raise; end if;
 end;

 perform pg_temp.act_as(first);

 -- Nothing is spent before the first claim.
 r := public.daily_feature_status();
 if (r->'assistant_game'->>'remaining')::int <> 1
    or (r->'assistant_game'->>'used')::int <> 0 then
   raise exception 'TEST FAILED: fresh status was %', r;
 end if;

 -- The first claim is allowed and spends the day's single use.
 r := public.claim_daily_feature('assistant_game');
 if (r->>'allowed')::boolean is not true or (r->>'remaining')::int <> 0 then
   raise exception 'TEST FAILED: first claim was %', r;
 end if;

 -- The second is refused, and refusing does not inflate the count.
 r := public.claim_daily_feature('assistant_game');
 if (r->>'allowed')::boolean is not false or (r->>'used')::int <> 1 then
   raise exception 'TEST FAILED: second claim was %', r;
 end if;
 r := public.claim_daily_feature('assistant_game');
 if (r->>'used')::int <> 1 then
   raise exception 'TEST FAILED: a refused claim still counted: %', r;
 end if;

 -- The two features hold separate counts.
 r := public.claim_daily_feature('game_analysis');
 if (r->>'allowed')::boolean is not true then
   raise exception 'TEST FAILED: analysis shares the assistant count: %', r;
 end if;

 -- Another player is unaffected.
 perform pg_temp.act_as(second);
 r := public.claim_daily_feature('assistant_game');
 if (r->>'allowed')::boolean is not true then
   raise exception 'TEST FAILED: one player exhausted another: %', r;
 end if;

 -- An unknown feature is rejected rather than treated as unlimited.
 begin
   perform public.claim_daily_feature('unlimited_everything');
   raise exception 'TEST FAILED: an unknown feature was allowed';
 exception when others then
   if sqlerrm not like 'unknown feature%' then raise; end if;
 end;

 -- Yesterday's use does not carry over.
 perform pg_temp.act_as(first);
 update public.daily_feature_usage set day = day - 1 where user_id = first;
 r := public.claim_daily_feature('assistant_game');
 if (r->>'allowed')::boolean is not true then
   raise exception 'TEST FAILED: the day did not roll over: %', r;
 end if;

 -- Deleting the account takes the counts with it.
 delete from auth.users where id = second;
 if exists(select 1 from public.daily_feature_usage where user_id = second) then
   raise exception 'TEST FAILED: usage survived account deletion';
 end if;

 raise notice 'daily feature limits: all checks passed';
end $$;

rollback;
