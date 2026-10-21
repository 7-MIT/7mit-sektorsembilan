-- Sektor Sembilan: lobi ruangan, papan skor, obrolan (Server Fathan / Supabase)
-- Semua penulisan lewat fungsi RPC yang memvalidasi input; tabel hanya bisa dibaca anon.

create table public.s9_rooms (
  code text primary key check (code ~ '^[a-z0-9]{3,12}$'),
  kind text not null check (kind in ('ffa','duel','tdm','coop')),
  host text not null check (char_length(host) between 1 and 16),
  map text not null default 'sektor' check (char_length(map) between 1 and 16),
  players int not null default 1 check (players between 0 and 8),
  max_players int not null default 8 check (max_players between 2 and 8),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index s9_rooms_updated_idx on public.s9_rooms (updated_at desc);

create table public.s9_scores (
  id bigint generated always as identity primary key,
  name text not null check (char_length(name) between 1 and 16),
  mode text not null check (mode in ('survival','ffa','duel','tdm','coop')),
  score int not null check (score between 0 and 1000000),
  kills int not null default 0 check (kills between 0 and 100000),
  created_at timestamptz not null default now()
);
create index s9_scores_mode_score_idx on public.s9_scores (mode, score desc);

create table public.s9_chat (
  id bigint generated always as identity primary key,
  channel text not null check (channel ~ '^[a-z0-9]{1,12}$'),
  name text not null check (char_length(name) between 1 and 16),
  msg text not null check (char_length(msg) between 1 and 140),
  created_at timestamptz not null default now()
);
create index s9_chat_channel_idx on public.s9_chat (channel, id desc);

alter table public.s9_rooms enable row level security;
alter table public.s9_scores enable row level security;
alter table public.s9_chat enable row level security;

create policy "baca ruangan" on public.s9_rooms for select to anon, authenticated using (true);
create policy "baca skor" on public.s9_scores for select to anon, authenticated using (true);
create policy "baca obrolan" on public.s9_chat for select to anon, authenticated using (true);

create or replace function public.s9_room_beat(p_code text, p_kind text, p_host text, p_map text, p_players int, p_max int)
returns void language plpgsql security definer set search_path = public as $$
begin
  if p_code !~ '^[a-z0-9]{3,12}$' or p_kind not in ('ffa','duel','tdm','coop') then return; end if;
  insert into public.s9_rooms (code, kind, host, map, players, max_players, updated_at)
  values (p_code, p_kind, left(coalesce(nullif(trim(p_host), ''), 'Pemain'), 16), left(coalesce(p_map, 'sektor'), 16),
          greatest(0, least(coalesce(p_players, 1), 8)), greatest(2, least(coalesce(p_max, 8), 8)), now())
  on conflict (code) do update set
    kind = excluded.kind, map = excluded.map, players = excluded.players,
    max_players = excluded.max_players, updated_at = now();
end $$;

create or replace function public.s9_room_close(p_code text)
returns void language sql security definer set search_path = public as $$
  update public.s9_rooms set players = 0, updated_at = now() - interval '1 hour' where code = p_code;
$$;

create or replace function public.s9_submit_score(p_name text, p_mode text, p_score int, p_kills int)
returns void language plpgsql security definer set search_path = public as $$
begin
  if p_mode not in ('survival','ffa','duel','tdm','coop') or p_score is null or p_score <= 0 or p_score > 1000000 then return; end if;
  if exists (select 1 from public.s9_scores where name = left(trim(p_name), 16) and mode = p_mode and created_at > now() - interval '5 seconds') then return; end if;
  insert into public.s9_scores (name, mode, score, kills)
  values (left(coalesce(nullif(trim(p_name), ''), 'Pemain'), 16), p_mode, p_score, greatest(0, least(coalesce(p_kills, 0), 100000)));
end $$;

create or replace function public.s9_post_chat(p_channel text, p_name text, p_msg text)
returns void language plpgsql security definer set search_path = public as $$
declare m text := left(trim(coalesce(p_msg, '')), 140); n text := left(coalesce(nullif(trim(p_name), ''), 'Pemain'), 16);
begin
  if m = '' or p_channel !~ '^[a-z0-9]{1,12}$' then return; end if;
  if exists (select 1 from public.s9_chat where name = n and created_at > now() - interval '1 second') then return; end if;
  insert into public.s9_chat (channel, name, msg) values (p_channel, n, m);
  delete from public.s9_chat where created_at < now() - interval '2 days';
end $$;

grant execute on function public.s9_room_beat(text,text,text,text,int,int) to anon, authenticated;
grant execute on function public.s9_room_close(text) to anon, authenticated;
grant execute on function public.s9_submit_score(text,text,int,int) to anon, authenticated;
grant execute on function public.s9_post_chat(text,text,text) to anon, authenticated;
