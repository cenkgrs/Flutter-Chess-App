-- Competitive puzzles have independent ratings and server-owned clocks/scores.
create table public.duel_ratings(user_id uuid primary key references public.profiles, rating integer not null default 1200, played integer not null default 0);
create table public.duel_queue(user_id uuid primary key references public.profiles, seen_at timestamptz not null default now());
create table public.puzzle_duels(
 id uuid primary key default gen_random_uuid(), a uuid not null references public.profiles,
 b uuid not null references public.profiles, puzzles uuid[] not null,
 turn integer not null default 1, step integer not null default 0, mistakes integer not null default 0,
 score_a integer not null default 0, score_b integer not null default 0,
 started_at timestamptz not null default clock_timestamp(), status text not null default 'active',
 delta_a integer, delta_b integer, rating_a integer not null, rating_b integer not null,
 history jsonb not null default '[]', check(a<>b), check(cardinality(puzzles)=20)
);
alter table public.duel_ratings enable row level security;
alter table public.duel_queue enable row level security;
alter table public.puzzle_duels enable row level security;
revoke all on public.duel_ratings,public.duel_queue,public.puzzle_duels from anon,authenticated;

create function public.duel_profile() returns jsonb
language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'authentication required'; end if;
 return jsonb_build_object('rating',coalesce((select rating from public.duel_ratings where user_id=auth.uid()),1200),
 'game_id',(select id from public.puzzle_duels where auth.uid() in(a,b) and status='active' limit 1));
end $$;

create function public.duel_matchmaking(p_cancel boolean default false) returns jsonb
language plpgsql security definer set search_path='' as $$
declare me uuid:=auth.uid(); opponent uuid; gid uuid; selected uuid[]; my_rating integer; other_rating integer;
begin
 if me is null then raise exception 'authentication required'; end if;
 perform pg_advisory_xact_lock(hashtext('rok-puzzle-duel-queue'));
 select id into gid from public.puzzle_duels where me in(a,b) and status='active' limit 1;
 if gid is not null then return jsonb_build_object('game_id',gid); end if;
 if p_cancel then delete from public.duel_queue where user_id=me; return '{}'::jsonb; end if;
 insert into public.duel_ratings(user_id) values(me) on conflict do nothing;
 select rating into my_rating from public.duel_ratings where user_id=me;
 select q.user_id,r.rating into opponent,other_rating from public.duel_queue q
 join public.duel_ratings r on r.user_id=q.user_id
 where q.user_id<>me and q.seen_at>now()-interval '15 seconds'
 order by abs(r.rating-my_rating),q.seen_at limit 1;
 if opponent is null then
   insert into public.duel_queue(user_id) values(me) on conflict(user_id) do update set seen_at=now();
   return jsonb_build_object('rating',my_rating);
 end if;
 -- Pair by mate length, then prefer the pair closest to the players' average.
 -- Randomize within each pair to avoid always giving one side the harder position.
 with candidates as (
   select id,rating,theme,row_number() over(partition by theme order by random()) as n from public.puzzles
 ), pairs as (
   select array_agg(id order by random()) as ids,avg(abs(rating-(my_rating+other_rating)/2)) as distance
   from candidates group by theme,(n-1)/2 having count(*)=2
   order by distance,random() limit 10
 ), numbered as (select ids,row_number() over() as pair from pairs)
 select array_agg(u.id order by pair,u.ord) into selected from numbered,
 lateral unnest(ids) with ordinality u(id,ord);
 if coalesce(cardinality(selected),0)<20 then raise exception 'not enough puzzles'; end if;
 if random()<0.5 then
   insert into public.puzzle_duels(a,b,puzzles,rating_a,rating_b) values(me,opponent,selected,my_rating,other_rating) returning id into gid;
 else
   insert into public.puzzle_duels(a,b,puzzles,rating_a,rating_b) values(opponent,me,selected,other_rating,my_rating) returning id into gid;
 end if;
 delete from public.duel_queue where user_id in(me,opponent);
 return jsonb_build_object('game_id',gid);
end $$;

-- Private helper, called only under the match row lock.
create function public.duel_finish(p_id uuid) returns void
language plpgsql security definer set search_path='' as $$
declare d public.puzzle_duels; outcome numeric; delta integer;
begin
 select * into strict d from public.puzzle_duels where id=p_id for update;
 if d.status<>'active' then return; end if;
 outcome:=case when d.score_a>d.score_b then 1 when d.score_a<d.score_b then 0 else .5 end;
 delta:=round(32*(outcome-1/(1+power(10::numeric,(d.rating_b-d.rating_a)/400.0))));
 update public.duel_ratings set rating=greatest(100,rating+delta),played=played+1 where user_id=d.a;
 update public.duel_ratings set rating=greatest(100,rating-delta),played=played+1 where user_id=d.b;
 update public.puzzle_duels set status='finished',
 delta_a=greatest(100,d.rating_a+delta)-d.rating_a,
 delta_b=greatest(100,d.rating_b-delta)-d.rating_b where id=p_id;
end $$;

create function public.duel_state(p_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare d public.puzzle_duels; p public.puzzles; me uuid:=auth.uid(); mine boolean;
begin
 if me is null then raise exception 'authentication required'; end if;
 select * into strict d from public.puzzle_duels where id=p_id for update;
 if me not in(d.a,d.b) then raise exception 'not participant'; end if;
 while d.status='active' and d.turn<=20 and clock_timestamp()>=d.started_at+interval '120 seconds' loop
   d.history:=d.history||jsonb_build_array(jsonb_build_object('turn',d.turn,'points',0,'reason','timeout'));
   d.turn:=d.turn+1; d.step:=0; d.mistakes:=0; d.started_at:=d.started_at+interval '120 seconds';
 end loop;
 update public.puzzle_duels set turn=d.turn,step=d.step,mistakes=d.mistakes,started_at=d.started_at,history=d.history where id=p_id;
 if d.turn>20 and d.status='active' then
   perform public.duel_finish(p_id); select * into d from public.puzzle_duels where id=p_id;
 end if;
 mine:=case when d.turn%2=1 then me=d.a else me=d.b end;
 if d.status='active' and mine then select * into p from public.puzzles where id=d.puzzles[d.turn]; end if;
 return jsonb_build_object('id',d.id,'status',d.status,'turn',d.turn,'step',d.step,'mistakes',d.mistakes,
 'my_turn',mine,'score',case when me=d.a then d.score_a else d.score_b end,
 'opponent_score',case when me=d.a then d.score_b else d.score_a end,
 'opponent',(select username from public.profiles where id=case when me=d.a then d.b else d.a end),
 'rating',case when me=d.a then d.rating_a else d.rating_b end,
 'delta',case when me=d.a then d.delta_a else d.delta_b end,
 'seconds_left',greatest(0,ceil(extract(epoch from(d.started_at+interval '120 seconds'-clock_timestamp())))),
 'fen',case when d.step=0 then p.fen else p.positions[d.step] end,
 'difficulty',p.rating,'history',d.history);
end $$;

create function public.duel_action(p_id uuid,p_turn integer,p_step integer,p_action text,p_move text default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare d public.puzzle_duels; p public.puzzles; result jsonb; reward integer:=0; elapsed numeric;
begin
 result:=public.duel_state(p_id);
 select * into strict d from public.puzzle_duels where id=p_id for update;
 if d.status<>'active' or d.turn is distinct from p_turn or d.step is distinct from p_step then return result; end if;
 if (d.turn%2=1 and auth.uid()<>d.a) or (d.turn%2=0 and auth.uid()<>d.b) then raise exception 'not your turn'; end if;
 select * into strict p from public.puzzles where id=d.puzzles[d.turn];
 if p_action='move' then
   if p_move is distinct from p.solution[d.step+1] then
     update public.puzzle_duels set mistakes=mistakes+1 where id=p_id;
     return public.duel_state(p_id)||jsonb_build_object('wrong',true);
   end if;
   d.step:=least(d.step+2,cardinality(p.solution));
   if d.step<cardinality(p.solution) then
     update public.puzzle_duels set step=d.step where id=p_id;
     return public.duel_state(p_id);
   end if;
   elapsed:=greatest(1,extract(epoch from(clock_timestamp()-d.started_at)));
   reward:=greatest(1,round(100*(1+0.5*greatest(0,1-elapsed/120))/(1+d.mistakes)));
 elsif p_action<>'skip' then raise exception 'invalid action'; end if;
 update public.puzzle_duels set
 score_a=score_a+case when d.turn%2=1 then reward else 0 end,
 score_b=score_b+case when d.turn%2=0 then reward else 0 end,
 history=history||jsonb_build_array(jsonb_build_object('turn',d.turn,'points',reward,'mistakes',d.mistakes,'reason',p_action)),
 turn=turn+1,step=0,mistakes=0,started_at=clock_timestamp() where id=p_id;
 return public.duel_state(p_id);
end $$;
revoke all on function public.duel_finish(uuid) from public,anon,authenticated;
revoke all on function public.duel_profile() from public,anon;
grant execute on function public.duel_profile() to authenticated;
revoke all on function public.duel_matchmaking(boolean) from public,anon;
revoke all on function public.duel_state(uuid) from public,anon;
revoke all on function public.duel_action(uuid,integer,integer,text,text) from public,anon;
grant execute on function public.duel_matchmaking(boolean) to authenticated;
grant execute on function public.duel_state(uuid) to authenticated;
grant execute on function public.duel_action(uuid,integer,integer,text,text) to authenticated;
