-- Disposable local database, after migrations.
begin;
insert into auth.users(id,raw_user_meta_data) values
 ('00000000-0000-0000-0000-000000000001','{"username":"Alice"}'),
 ('00000000-0000-0000-0000-000000000002','{"username":"Bobby"}');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);
do $$ begin
 assert jsonb_array_length(public.search_players('Bob'))=1;
 assert jsonb_array_length(public.search_players('Ali'))=0;
 perform public.friend_action('00000000-0000-0000-0000-000000000002','send');
 perform public.friend_action('00000000-0000-0000-0000-000000000002','send');
 assert jsonb_array_length(public.friend_list())=1;
 begin
   perform public.friend_action('00000000-0000-0000-0000-000000000002','accept');
   raise exception 'sender accepted own request';
 exception when raise_exception then assert sqlerrm='invalid request'; end;
end $$;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000002',true);
do $$ begin
 assert (public.friend_list()->0->>'incoming')::boolean;
 perform public.friend_action('00000000-0000-0000-0000-000000000001','decline');
 assert jsonb_array_length(public.friend_list())=0;
 perform public.friend_action('00000000-0000-0000-0000-000000000001','send');
 perform public.friend_action('00000000-0000-0000-0000-000000000001','cancel');
 assert jsonb_array_length(public.friend_list())=0;
 perform public.friend_action('00000000-0000-0000-0000-000000000001','send');
end $$;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);
do $$ begin
 perform public.friend_action('00000000-0000-0000-0000-000000000002','accept');
 assert public.friend_list()->0->>'status'='accepted';
end $$;
select set_config('request.jwt.claim.sub','',true);
do $$ begin
 begin perform public.friend_list(); raise exception 'anonymous access allowed';
 exception when raise_exception then assert sqlerrm='authentication required'; end;
end $$;
rollback;
