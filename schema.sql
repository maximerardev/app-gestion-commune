-- Tâches à deux — Schéma Supabase
-- À coller dans l'éditeur SQL de Supabase (Database > SQL Editor)

-- 1. Foyers
create table if not exists houses (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  invite_code text unique not null,
  member1_name text,
  member2_name text,
  created_at timestamptz default now()
);

-- 2. Membres
create table if not exists members (
  id uuid default gen_random_uuid() primary key,
  house_id uuid references houses(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  name text not null,
  is_owner boolean default false,
  created_at timestamptz default now(),
  unique(house_id, user_id)
);

-- 3. Tâches du foyer (personnalisées)
create table if not exists house_tasks (
  id uuid default gen_random_uuid() primary key,
  house_id uuid references houses(id) on delete cascade,
  category text not null,
  task_name text not null,
  created_at timestamptz default now()
);

-- 4. Entrées de temps
create table if not exists entries (
  id uuid default gen_random_uuid() primary key,
  house_id uuid references houses(id) on delete cascade,
  who text not null,
  date date not null,
  task_name text not null,
  category text,
  minutes integer default 0,
  is_cm boolean default false,
  created_at timestamptz default now()
);

-- RLS (Row Level Security) — chaque utilisateur ne voit que son foyer

alter table houses enable row level security;
alter table members enable row level security;
alter table house_tasks enable row level security;
alter table entries enable row level security;

-- Politique : membre peut voir/modifier les données de son foyer
create policy "members can read their house" on houses
  for select using (
    id in (select house_id from members where user_id = auth.uid())
  );

create policy "members can read members of their house" on members
  for select using (
    house_id in (select house_id from members where user_id = auth.uid())
  );

create policy "members can insert themselves" on members
  for insert with check (user_id = auth.uid());

create policy "members can read tasks of their house" on house_tasks
  for select using (
    house_id in (select house_id from members where user_id = auth.uid())
  );

create policy "members can insert tasks in their house" on house_tasks
  for insert with check (
    house_id in (select house_id from members where user_id = auth.uid())
  );

create policy "members can read entries of their house" on entries
  for select using (
    house_id in (select house_id from members where user_id = auth.uid())
  );

create policy "members can insert entries in their house" on entries
  for insert with check (
    house_id in (select house_id from members where user_id = auth.uid())
  );

create policy "members can delete their own entries" on entries
  for delete using (
    house_id in (select house_id from members where user_id = auth.uid())
  );

create policy "owner can insert house" on houses
  for insert with check (true);

-- Activer realtime sur entries (pour la synchro temps réel)
alter publication supabase_realtime add table entries;
