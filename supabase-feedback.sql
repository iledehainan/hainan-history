create table if not exists public.history_feedback (
  id uuid primary key default gen_random_uuid(),
  entry_title text not null check (char_length(entry_title) between 1 and 200),
  kind text not null check (kind in ('like', 'review')),
  voter_id uuid not null,
  nickname text not null default '' check (char_length(nickname) <= 30),
  rating smallint,
  content text not null default '' check (char_length(content) <= 1000),
  approved boolean not null default false,
  created_at timestamptz not null default now(),
  constraint history_feedback_payload_check check (
    (kind = 'like' and rating is null and nickname = '' and content = '')
    or
    (kind = 'review' and rating is not null and rating between 1 and 5 and char_length(btrim(content)) > 0)
  )
);

create unique index if not exists history_feedback_one_like_per_visitor_idx
  on public.history_feedback (entry_title, voter_id)
  where kind = 'like';

create unique index if not exists history_feedback_one_review_per_visitor_idx
  on public.history_feedback (entry_title, voter_id)
  where kind = 'review';

create index if not exists history_feedback_public_lookup_idx
  on public.history_feedback (entry_title, created_at desc)
  where kind = 'like' or (kind = 'review' and approved);

revoke all on public.history_feedback from anon, authenticated;
grant insert on public.history_feedback to anon, authenticated;
grant select, update, delete on public.history_feedback to authenticated;

alter table public.history_feedback enable row level security;

drop policy if exists "Anyone can submit pending history feedback" on public.history_feedback;
create policy "Anyone can submit pending history feedback"
  on public.history_feedback for insert
  with check (
    approved = false
    and (
      (kind = 'like' and rating is null and nickname = '' and content = '')
      or
      (kind = 'review'
        and rating is not null
        and rating between 1 and 5
        and char_length(btrim(content)) between 1 and 1000
        and char_length(nickname) <= 30)
    )
  );

create or replace function public.get_history_feedback_summary(p_entry_title text)
returns table (like_count bigint, review_count bigint, average_rating numeric)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    count(*) filter (where kind = 'like'),
    count(*) filter (where kind = 'review' and approved),
    round(avg(rating::numeric) filter (where kind = 'review' and approved), 1)
  from public.history_feedback
  where p_entry_title is not null
    and char_length(p_entry_title) between 1 and 200
    and entry_title = p_entry_title;
$$;

create or replace function public.get_history_feedback_reviews(p_entry_title text)
returns table (nickname text, rating smallint, content text, created_at timestamptz)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select f.nickname, f.rating, f.content, f.created_at
  from public.history_feedback as f
  where f.kind = 'review'
    and f.approved
    and p_entry_title is not null
    and char_length(p_entry_title) between 1 and 200
    and f.entry_title = p_entry_title
  order by f.created_at desc
  limit 100;
$$;

revoke execute on function public.get_history_feedback_summary(text) from public;
revoke execute on function public.get_history_feedback_reviews(text) from public;
grant execute on function public.get_history_feedback_summary(text) to anon, authenticated;
grant execute on function public.get_history_feedback_reviews(text) to anon, authenticated;

drop policy if exists "Admins can manage history feedback" on public.history_feedback;
create policy "Admins can manage history feedback"
  on public.history_feedback for all
  to authenticated
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
