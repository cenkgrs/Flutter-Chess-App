-- Only for a disposable local PostgreSQL instance. Never run in Supabase.
create role anon;
create role authenticated;
create schema auth;
create table auth.users(id uuid primary key,raw_user_meta_data jsonb default '{}');
create function auth.uid() returns uuid language sql as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
create publication supabase_realtime;
