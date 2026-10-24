alter table public.history_entries
  add column if not exists image_url text;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'history-images',
  'history-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set name = excluded.name,
    public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Public can view history images" on storage.objects;
create policy "Public can view history images"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'history-images');

drop policy if exists "Admins can upload history images" on storage.objects;
create policy "Admins can upload history images"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'history-images'
    and exists (
      select 1 from public.history_admins
      where user_id = (select auth.uid())
    )
  );

drop policy if exists "Admins can update history images" on storage.objects;
create policy "Admins can update history images"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'history-images'
    and exists (
      select 1 from public.history_admins
      where user_id = (select auth.uid())
    )
  )
  with check (
    bucket_id = 'history-images'
    and exists (
      select 1 from public.history_admins
      where user_id = (select auth.uid())
    )
  );

drop policy if exists "Admins can delete history images" on storage.objects;
create policy "Admins can delete history images"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'history-images'
    and exists (
      select 1 from public.history_admins
      where user_id = (select auth.uid())
    )
  );
