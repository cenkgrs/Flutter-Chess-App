-- Free-tier daily allowances for the two engine-backed features: one
-- assisted game and one engine game analysis per day.
--
-- The count lives on the server because that is the only place it can be
-- trusted. ROK links Stockfish and ships under GPL-3.0-or-later, so anyone
-- may rebuild the app without a client-side check; a counter in Supabase is
-- what makes the allowance real for everyone using the published build.
--
-- Only signed-in players are counted: a guest has no account to charge, and
-- the client lets them through rather than forcing an account for an
-- offline game. Signing out therefore lifts the limit in 1.0.
--
-- 1.1 moves the engine behind an API and adds subscriptions. That closes
-- the guest route, since a request without an account cannot be served.
-- The limit is read from `daily_feature_limit`, so lifting it for a
-- subscriber is a server change and needs no new app release.
--
-- The day turns over at midnight Europe/Istanbul, the same boundary the
-- daily puzzle uses.

create function public.rok_today() returns date
language sql stable set search_path='' as $$
  select (now() at time zone 'Europe/Istanbul')::date
$$;

create table public.daily_feature_usage (
 user_id uuid not null references auth.users on delete cascade,
 day date not null,
 feature text not null check(feature in ('assistant_game','game_analysis')),
 used integer not null default 0 check(used >= 0),
 primary key (user_id, day, feature)
);

alter table public.daily_feature_usage enable row level security;
revoke all on public.daily_feature_usage from anon, authenticated;

-- Null means the feature is unknown; callers must reject it rather than
-- treat it as unlimited.
create function public.daily_feature_limit(p_feature text) returns integer
language sql stable set search_path='' as $$
  select case p_feature
    when 'assistant_game' then 1
    when 'game_analysis' then 1
  end
$$;

create function public.daily_feature_reset_at() returns timestamptz
language sql stable set search_path='' as $$
  select (public.rok_today() + 1)::timestamp at time zone 'Europe/Istanbul'
$$;

-- What the player has left today, without spending anything.
create function public.daily_feature_status() returns jsonb
language plpgsql security definer set search_path='' as $$
declare me uuid := auth.uid(); today date := public.rok_today(); out jsonb := '{}'::jsonb;
        f text; cap integer; current integer;
begin
 if me is null then raise exception 'authentication required'; end if;
 foreach f in array array['assistant_game','game_analysis'] loop
   cap := public.daily_feature_limit(f);
   select used into current from public.daily_feature_usage
     where user_id = me and day = today and feature = f;
   current := coalesce(current, 0);
   out := out || jsonb_build_object(f, jsonb_build_object(
     'used', current, 'limit', cap,
     'remaining', greatest(0, cap - current)));
 end loop;
 return out || jsonb_build_object('resets_at', public.daily_feature_reset_at());
end $$;

-- Spends one use if the player has one left. The insert-or-increment is a
-- single statement, so two devices racing cannot both get the last use: the
-- conditional DO UPDATE returns no row once the cap is reached.
create function public.claim_daily_feature(p_feature text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare me uuid := auth.uid(); today date := public.rok_today();
        cap integer; current integer;
begin
 if me is null then raise exception 'authentication required'; end if;
 cap := public.daily_feature_limit(p_feature);
 if cap is null then raise exception 'unknown feature %', p_feature; end if;

 if cap > 0 then
   insert into public.daily_feature_usage(user_id, day, feature, used)
   values (me, today, p_feature, 1)
   on conflict (user_id, day, feature) do update
     set used = public.daily_feature_usage.used + 1
     where public.daily_feature_usage.used < cap
   returning used into current;
 end if;

 if current is null then
   select used into current from public.daily_feature_usage
     where user_id = me and day = today and feature = p_feature;
   return jsonb_build_object('allowed', false, 'used', coalesce(current, 0),
     'limit', cap, 'remaining', 0,
     'resets_at', public.daily_feature_reset_at());
 end if;

 return jsonb_build_object('allowed', true, 'used', current, 'limit', cap,
   'remaining', greatest(0, cap - current),
   'resets_at', public.daily_feature_reset_at());
end $$;

revoke all on function public.rok_today() from public,anon,authenticated;
revoke all on function public.daily_feature_limit(text) from public,anon,authenticated;
revoke all on function public.daily_feature_reset_at() from public,anon,authenticated;
revoke all on function public.daily_feature_status() from public,anon;
revoke all on function public.claim_daily_feature(text) from public,anon;
grant execute on function public.daily_feature_status() to authenticated;
grant execute on function public.claim_daily_feature(text) to authenticated;
