-- Run once in Supabase Dashboard -> SQL Editor.
-- Only authenticated owners can read or change their own notes.

create table if not exists public.notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  body text not null default '',
  color text not null default 'yellow',
  pos_x double precision not null default 50,
  pos_y double precision not null default 50,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists notes_user_created_idx on public.notes (user_id, created_at);
alter table public.notes enable row level security;

create policy "Only owner may read notes"
  on public.notes for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "Only owner may insert notes"
  on public.notes for insert to authenticated
  with check ((select auth.uid()) = user_id);

create policy "Only owner may update notes"
  on public.notes for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "Only owner may delete notes"
  on public.notes for delete to authenticated
  using ((select auth.uid()) = user_id);

-- Supabase Postgres Changes are opt-in per table.
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (
       select 1 from pg_publication_tables
       where pubname = 'supabase_realtime'
         and schemaname = 'public' and tablename = 'notes'
     ) then
    alter publication supabase_realtime add table public.notes;
  end if;
end $$;
