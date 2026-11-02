-- Product analytics: one append-only event table, written through an RPC and
-- read only by admins.
--
-- Why an RPC rather than an insert policy: the client would otherwise send
-- its own user_id, and anyone holding the anon key could attribute events to
-- another account. `log_analytics_event` takes the id from auth.uid(), so a
-- guest writes null and a member can only write as themselves.
--
-- Nothing here is readable by the app. The dashboard signs in as an admin and
-- calls the reporting functions; the service-role key is never shipped.
--
-- Account deletion removes a member's events, the same promise the rest of
-- the schema makes. Aggregate history for deleted accounts is lost on
-- purpose: keeping it would mean keeping their activity trail.

create table public.analytics_events (
 id uuid primary key default gen_random_uuid(),
 user_id uuid references auth.users on delete cascade,
 event_name text not null check (event_name in (
   'app_opened','user_signed_up','user_logged_in','game_started',
   'game_finished','assistant_used','analysis_used','subscription_started',
   'subscription_restored','theme_changed','piece_set_changed')),
 created_at timestamptz not null default now(),
 metadata jsonb not null default '{}'::jsonb,
 app_version text check (app_version is null or length(app_version) <= 32),
 platform text check (platform is null or platform in
   ('ios','android','macos','windows','linux','web','unknown'))
);

create index analytics_events_created_idx on public.analytics_events (created_at desc);
create index analytics_events_name_created_idx on public.analytics_events (event_name, created_at desc);
create index analytics_events_user_idx on public.analytics_events (user_id, created_at desc);

-- Membership is granted by hand in the SQL editor; there is no way to add
-- yourself from the app.
create table public.analytics_admins (
 user_id uuid primary key references auth.users on delete cascade,
 added_at timestamptz not null default now()
);

alter table public.analytics_events enable row level security;
alter table public.analytics_admins enable row level security;
revoke all on public.analytics_events, public.analytics_admins from anon, authenticated;

create function public.is_analytics_admin() returns boolean
language sql stable security definer set search_path='' as $$
  select exists(select 1 from public.analytics_admins where user_id = auth.uid())
$$;

-- Writing ---------------------------------------------------------------

-- Returns nothing: analytics must never tell the client anything, and a
-- caller that ignores the result cannot leak timing either.
create function public.log_analytics_event(
  p_event text,
  p_metadata jsonb default '{}'::jsonb,
  p_app_version text default null,
  p_platform text default null) returns void
language plpgsql security definer set search_path='' as $$
begin
 insert into public.analytics_events(user_id, event_name, metadata, app_version, platform)
 values (auth.uid(), p_event,
         coalesce(p_metadata, '{}'::jsonb),
         left(p_app_version, 32),
         p_platform);
exception when others then
 -- A rejected event must never surface as an app error.
 return;
end $$;

-- Reading ---------------------------------------------------------------

create function public.analytics_overview(p_from timestamptz, p_to timestamptz)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare out jsonb;
begin
 if not public.is_analytics_admin() then raise exception 'admin required'; end if;
 select jsonb_build_object(
   'total_users', (select count(*) from public.profiles),
   'new_users', (select count(*) from public.profiles
                 where created_at >= p_from and created_at < p_to),
   'active_24h', (select count(distinct user_id) from public.analytics_events
                  where user_id is not null and created_at >= now() - interval '24 hours'),
   'active_7d', (select count(distinct user_id) from public.analytics_events
                 where user_id is not null and created_at >= now() - interval '7 days'),
   'games_started', public.analytics_count('game_started', p_from, p_to),
   'games_finished', public.analytics_count('game_finished', p_from, p_to),
   'assistant_used', public.analytics_count('assistant_used', p_from, p_to),
   'analysis_used', public.analytics_count('analysis_used', p_from, p_to),
   -- No server-side subscription record exists; StoreKit verifies on device.
   -- This counts accounts that reported a start or restore and is an
   -- estimate, not a billing figure.
   'subscriptions_reported', (select count(distinct user_id)
     from public.analytics_events
     where user_id is not null
       and event_name in ('subscription_started','subscription_restored')
       and created_at >= p_from and created_at < p_to),
   'guest_events', (select count(*) from public.analytics_events
                    where user_id is null and created_at >= p_from and created_at < p_to)
 ) into out;
 return out;
end $$;

create function public.analytics_count(p_event text, p_from timestamptz, p_to timestamptz)
returns bigint language sql stable security definer set search_path='' as $$
  select count(*) from public.analytics_events
  where event_name = p_event and created_at >= p_from and created_at < p_to
$$;

create function public.analytics_daily(p_from timestamptz, p_to timestamptz)
returns table(day date, signups bigint, active_users bigint, games_started bigint,
              games_finished bigint, assistant_used bigint, analysis_used bigint,
              subscriptions_started bigint)
language plpgsql stable security definer set search_path='' as $$
begin
 if not public.is_analytics_admin() then raise exception 'admin required'; end if;
 return query
 with days as (
   select generate_series(date_trunc('day', p_from), date_trunc('day', p_to - interval '1 ms'), interval '1 day')::date as d
 )
 select days.d,
   (select count(*) from public.profiles p where p.created_at::date = days.d),
   (select count(distinct e.user_id) from public.analytics_events e
     where e.user_id is not null and e.created_at::date = days.d),
   (select count(*) from public.analytics_events e where e.event_name='game_started' and e.created_at::date = days.d),
   (select count(*) from public.analytics_events e where e.event_name='game_finished' and e.created_at::date = days.d),
   (select count(*) from public.analytics_events e where e.event_name='assistant_used' and e.created_at::date = days.d),
   (select count(*) from public.analytics_events e where e.event_name='analysis_used' and e.created_at::date = days.d),
   (select count(*) from public.analytics_events e where e.event_name='subscription_started' and e.created_at::date = days.d)
 from days order by days.d;
end $$;

-- Never returns an email. A member is shown by username; an account without
-- one falls back to a short hash of the id.
create function public.analytics_users(p_from timestamptz, p_to timestamptz,
  p_limit integer default 100, p_offset integer default 0)
returns table(label text, created_at timestamptz, last_seen timestamptz,
              games bigint, assistant bigint, analysis bigint, subscription text)
language plpgsql stable security definer set search_path='' as $$
begin
 if not public.is_analytics_admin() then raise exception 'admin required'; end if;
 return query
 -- Driven by profiles, never auth.users: this function has no business
 -- reading the auth schema, where the email lives.
 select pr.username::text,
   pr.created_at,
   (select max(e.created_at) from public.analytics_events e where e.user_id = pr.id),
   (select count(*) from public.analytics_events e where e.user_id=pr.id and e.event_name='game_started' and e.created_at >= p_from and e.created_at < p_to),
   (select count(*) from public.analytics_events e where e.user_id=pr.id and e.event_name='assistant_used' and e.created_at >= p_from and e.created_at < p_to),
   (select count(*) from public.analytics_events e where e.user_id=pr.id and e.event_name='analysis_used' and e.created_at >= p_from and e.created_at < p_to),
   case when exists(select 1 from public.analytics_events e where e.user_id=pr.id
     and e.event_name in ('subscription_started','subscription_restored'))
     then 'reported' else 'none' end
 from public.profiles pr
 order by 3 desc nulls last
 limit least(coalesce(p_limit, 100), 500) offset greatest(coalesce(p_offset, 0), 0);
end $$;

create function public.analytics_event_log(p_from timestamptz, p_to timestamptz,
  p_event text default null, p_limit integer default 200, p_offset integer default 0)
returns table(created_at timestamptz, event_name text, label text, metadata jsonb,
              app_version text, platform text)
language plpgsql stable security definer set search_path='' as $$
begin
 if not public.is_analytics_admin() then raise exception 'admin required'; end if;
 return query
 select e.created_at, e.event_name,
   case when e.user_id is null then 'guest'
        else coalesce(pr.username::text, 'user-' || left(md5(e.user_id::text), 8)) end,
   e.metadata, e.app_version, e.platform
 from public.analytics_events e
 left join public.profiles pr on pr.id = e.user_id
 where e.created_at >= p_from and e.created_at < p_to
   and (p_event is null or e.event_name = p_event)
 order by e.created_at desc
 limit least(coalesce(p_limit, 200), 1000) offset greatest(coalesce(p_offset, 0), 0);
end $$;

revoke all on function public.is_analytics_admin() from public,anon,authenticated;
revoke all on function public.analytics_count(text,timestamptz,timestamptz) from public,anon,authenticated;
revoke all on function public.log_analytics_event(text,jsonb,text,text) from public;
revoke all on function public.analytics_overview(timestamptz,timestamptz) from public,anon;
revoke all on function public.analytics_daily(timestamptz,timestamptz) from public,anon;
revoke all on function public.analytics_users(timestamptz,timestamptz,integer,integer) from public,anon;
revoke all on function public.analytics_event_log(timestamptz,timestamptz,text,integer,integer) from public,anon;

-- Guests write with the anon key, members with their own session.
grant execute on function public.log_analytics_event(text,jsonb,text,text) to anon, authenticated;
grant execute on function public.analytics_overview(timestamptz,timestamptz) to authenticated;
grant execute on function public.analytics_daily(timestamptz,timestamptz) to authenticated;
grant execute on function public.analytics_users(timestamptz,timestamptz,integer,integer) to authenticated;
grant execute on function public.analytics_event_log(timestamptz,timestamptz,text,integer,integer) to authenticated;
