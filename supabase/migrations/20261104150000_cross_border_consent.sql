-- Record that the player agreed to their data being processed abroad.
--
-- The database runs in Frankfurt. For a player in Türkiye that is a transfer
-- outside the country under article 9 of the KVKK, and a transfer needs a
-- basis. Explicit consent is the one we can actually obtain, so sign-up asks
-- for it and the answer is kept with the profile: a consent you cannot show
-- the date of is not worth much.
--
-- Null means the account predates the question. Those accounts are not
-- broken; they simply have nothing recorded.

alter table public.profiles
  add column if not exists cross_border_consent_at timestamptz;

comment on column public.profiles.cross_border_consent_at is
  'When the player agreed to processing outside Türkiye; null for accounts created before the question existed.';

-- The trigger writes it at sign-up, in the same statement as the profile, so
-- an account can never exist without its answer being settled.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
  requested_username text;
  consented boolean;
begin
  requested_username := coalesce(new.raw_user_meta_data ->> 'username', 'oyuncu_' || left(new.id::text, 8));
  consented := coalesce(new.raw_user_meta_data ->> 'cross_border_consent', '') = 'true';

  insert into public.profiles (id, username, cross_border_consent_at)
  values (new.id, requested_username, case when consented then now() end);

  insert into public.ratings (user_id, pool)
  select new.id, pool
  from unnest(array['bullet', 'blitz', 'rapid', 'classical']) as pool;
  return new;
end;
$$;
