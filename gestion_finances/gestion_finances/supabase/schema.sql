-- =============================================================================
-- SCHEMA SUPABASE - Application "Mes Finances"
-- Gestion de finances personnelles multi-comptes (offline-first)
-- =============================================================================
-- À exécuter dans : Supabase Dashboard > SQL Editor > New query
-- =============================================================================

-- Extension nécessaire pour uuid_generate_v4() (généralement déjà activée)
create extension if not exists "uuid-ossp";

-- =============================================================================
-- TABLE : accounts (comptes financiers)
-- =============================================================================
create table if not exists public.accounts (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  type text not null check (type in ('cash','bank','mobile_money','savings','other')),
  initial_balance numeric not null default 0,
  currency text not null default 'MGA',
  icon text not null default 'wallet',
  color text not null default '#2E7D5B',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_deleted boolean not null default false
);

-- =============================================================================
-- TABLE : categories
-- =============================================================================
create table if not exists public.categories (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  type text not null check (type in ('income','expense')),
  icon text not null default 'category',
  color text not null default '#3E7CB1',
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_deleted boolean not null default false
);

-- =============================================================================
-- TABLE : transactions (mouvements : revenu / dépense / transfert)
-- =============================================================================
create table if not exists public.transactions (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  account_id uuid not null references public.accounts(id) on delete cascade,
  destination_account_id uuid references public.accounts(id) on delete set null,
  category_id uuid references public.categories(id) on delete set null,
  amount numeric not null check (amount >= 0),
  type text not null check (type in ('income','expense','transfer')),
  date timestamptz not null,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_deleted boolean not null default false,

  -- Un transfert doit avoir un compte de destination différent du compte source ;
  -- un revenu/dépense n'en a pas.
  constraint transfer_has_destination check (
    (type = 'transfer' and destination_account_id is not null and destination_account_id <> account_id)
    or (type <> 'transfer' and destination_account_id is null)
  )
);

-- =============================================================================
-- INDEXES (performance des requêtes de synchronisation et de filtrage)
-- =============================================================================
create index if not exists idx_accounts_user on public.accounts(user_id);
create index if not exists idx_accounts_updated on public.accounts(updated_at);

create index if not exists idx_categories_user on public.categories(user_id);
create index if not exists idx_categories_updated on public.categories(updated_at);

create index if not exists idx_transactions_user on public.transactions(user_id);
create index if not exists idx_transactions_account on public.transactions(account_id);
create index if not exists idx_transactions_dest_account on public.transactions(destination_account_id);
create index if not exists idx_transactions_date on public.transactions(date);
create index if not exists idx_transactions_updated on public.transactions(updated_at);

-- =============================================================================
-- TRIGGER : mise à jour automatique de updated_at à chaque modification
-- (indispensable pour la stratégie de synchronisation incrémentale du client)
-- =============================================================================
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists set_updated_at_accounts on public.accounts;
create trigger set_updated_at_accounts
  before update on public.accounts
  for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at_categories on public.categories;
create trigger set_updated_at_categories
  before update on public.categories
  for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at_transactions on public.transactions;
create trigger set_updated_at_transactions
  before update on public.transactions
  for each row execute function public.set_updated_at();

-- =============================================================================
-- ROW LEVEL SECURITY (RLS)
-- Chaque utilisateur ne peut lire/écrire QUE ses propres données.
-- Indispensable car la clé "anon" de Supabase est publique côté client.
-- =============================================================================
alter table public.accounts enable row level security;
alter table public.categories enable row level security;
alter table public.transactions enable row level security;

-- --- ACCOUNTS ---
drop policy if exists "accounts_select_own" on public.accounts;
create policy "accounts_select_own" on public.accounts
  for select using (auth.uid() = user_id);

drop policy if exists "accounts_insert_own" on public.accounts;
create policy "accounts_insert_own" on public.accounts
  for insert with check (auth.uid() = user_id);

drop policy if exists "accounts_update_own" on public.accounts;
create policy "accounts_update_own" on public.accounts
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "accounts_delete_own" on public.accounts;
create policy "accounts_delete_own" on public.accounts
  for delete using (auth.uid() = user_id);

-- --- CATEGORIES ---
drop policy if exists "categories_select_own" on public.categories;
create policy "categories_select_own" on public.categories
  for select using (auth.uid() = user_id);

drop policy if exists "categories_insert_own" on public.categories;
create policy "categories_insert_own" on public.categories
  for insert with check (auth.uid() = user_id);

drop policy if exists "categories_update_own" on public.categories;
create policy "categories_update_own" on public.categories
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "categories_delete_own" on public.categories;
create policy "categories_delete_own" on public.categories
  for delete using (auth.uid() = user_id);

-- --- TRANSACTIONS ---
drop policy if exists "transactions_select_own" on public.transactions;
create policy "transactions_select_own" on public.transactions
  for select using (auth.uid() = user_id);

drop policy if exists "transactions_insert_own" on public.transactions;
create policy "transactions_insert_own" on public.transactions
  for insert with check (auth.uid() = user_id);

drop policy if exists "transactions_update_own" on public.transactions;
create policy "transactions_update_own" on public.transactions
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "transactions_delete_own" on public.transactions;
create policy "transactions_delete_own" on public.transactions
  for delete using (auth.uid() = user_id);

-- =============================================================================
-- REALTIME (optionnel) : permet une synchro instantanée multi-appareil
-- si l'utilisateur est connecté simultanément sur 2 téléphones.
-- Décommente si tu veux activer les mises à jour en temps réel.
-- =============================================================================
-- alter publication supabase_realtime add table public.accounts;
-- alter publication supabase_realtime add table public.categories;
-- alter publication supabase_realtime add table public.transactions;

-- =============================================================================
-- FIN DU SCHEMA
-- =============================================================================
