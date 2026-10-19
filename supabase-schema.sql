create extension if not exists pgcrypto;

create table if not exists public.history_admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);

create table if not exists public.history_entries (
  id uuid primary key default gen_random_uuid(),
  year integer not null,
  period text not null check (period in ('先秦至汉', '魏晋至宋元', '明清时期', '近现代', '当代')),
  type text not null check (type in ('person', 'event', 'trade', 'place', 'artifact')),
  date text not null,
  title text not null,
  place text not null default '',
  summary text not null,
  detail text not null,
  source text not null default '',
  source_url text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists history_entries_year_idx on public.history_entries (year);
create index if not exists history_entries_period_idx on public.history_entries (period);

grant usage on schema public to anon, authenticated;
grant select on public.history_entries to anon, authenticated;
grant insert, update, delete on public.history_entries to authenticated;
grant select on public.history_admins to authenticated;

alter table public.history_admins enable row level security;
alter table public.history_entries enable row level security;

drop policy if exists "Anyone can read history entries" on public.history_entries;
create policy "Anyone can read history entries"
  on public.history_entries for select
  using (true);

drop policy if exists "Admins can manage history entries" on public.history_entries;
create policy "Admins can manage history entries"
  on public.history_entries for all
  using (
    exists (
      select 1 from public.history_admins
      where user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.history_admins
      where user_id = (select auth.uid())
    )
  );

drop policy if exists "Admins can read their own admin record" on public.history_admins;
create policy "Admins can read their own admin record"
  on public.history_admins for select
  using (user_id = (select auth.uid()));
