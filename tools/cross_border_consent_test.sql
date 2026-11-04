-- Disposable local database only. Fixtures are rolled back.
begin;

-- A sign-up that carries the consent is stamped with the moment it was given.
insert into auth.users(id, raw_user_meta_data) values
 ('00000000-0000-0000-0000-00000000c001',
  '{"username":"Consenting","cross_border_consent":"true"}');

do $$ declare stamped timestamptz; begin
  select cross_border_consent_at into stamped from public.profiles
   where id='00000000-0000-0000-0000-00000000c001';
  assert stamped is not null, 'consent given at sign-up is recorded';
  assert stamped > clock_timestamp() - interval '1 minute', 'and it is recorded now';
end $$;

-- A sign-up without it records nothing rather than guessing.
insert into auth.users(id, raw_user_meta_data) values
 ('00000000-0000-0000-0000-00000000c002', '{"username":"Quiet"}');

do $$ declare stamped timestamptz; begin
  select cross_border_consent_at into stamped from public.profiles
   where id='00000000-0000-0000-0000-00000000c002';
  assert stamped is null, 'no answer means no claim of consent';
end $$;

-- An explicit refusal is not consent either.
insert into auth.users(id, raw_user_meta_data) values
 ('00000000-0000-0000-0000-00000000c003',
  '{"username":"Refusing","cross_border_consent":"false"}');

do $$ declare stamped timestamptz; begin
  select cross_border_consent_at into stamped from public.profiles
   where id='00000000-0000-0000-0000-00000000c003';
  assert stamped is null, 'a refusal is recorded as no consent';
end $$;

-- The rest of sign-up still happens: the profile and its four ratings.
do $$ declare pools int; begin
  select count(*) into pools from public.ratings
   where user_id='00000000-0000-0000-0000-00000000c001';
  assert pools = 4, 'the four rating pools are still created';
end $$;

rollback;
