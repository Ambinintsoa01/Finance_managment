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
  is_need boolean not null default true,
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
-- TABLE : budgets (enveloppes et plafonds de dépenses mensuelles par catégorie)
-- =============================================================================
create table if not exists public.budgets (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  category_id uuid not null references public.categories(id) on delete cascade,
  amount numeric not null check (amount > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_deleted boolean not null default false
);

-- =============================================================================
-- TABLE : recurring_transactions (charges fixes & revenus récurrents)
-- =============================================================================
create table if not exists public.recurring_transactions (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  amount numeric not null check (amount > 0),
  type text not null check (type in ('income','expense')),
  account_id uuid not null references public.accounts(id) on delete cascade,
  category_id uuid references public.categories(id) on delete set null,
  day_of_month integer not null check (day_of_month between 1 and 31),
  note text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_deleted boolean not null default false
);

-- =============================================================================
-- TABLE : savings_goals (cagnottes et fonds d'urgence)
-- =============================================================================
create table if not exists public.savings_goals (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  target_amount numeric not null check (target_amount > 0),
  current_amount numeric not null default 0 check (current_amount >= 0),
  target_date timestamptz,
  color text not null default '#2E7D5B',
  icon text not null default 'savings',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_deleted boolean not null default false
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

create index if not exists idx_budgets_user on public.budgets(user_id);
create index if not exists idx_budgets_category on public.budgets(category_id);
create index if not exists idx_budgets_updated on public.budgets(updated_at);

create index if not exists idx_recurring_user on public.recurring_transactions(user_id);
create index if not exists idx_recurring_updated on public.recurring_transactions(updated_at);

create index if not exists idx_savings_goals_user on public.savings_goals(user_id);
create index if not exists idx_savings_goals_updated on public.savings_goals(updated_at);

-- =============================================================================
-- TRIGGER : mise à jour automatique de updated_at à chaque modification
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

drop trigger if exists set_updated_at_budgets on public.budgets;
create trigger set_updated_at_budgets
  before update on public.budgets
  for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at_recurring on public.recurring_transactions;
create trigger set_updated_at_recurring
  before update on public.recurring_transactions
  for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at_savings on public.savings_goals;
create trigger set_updated_at_savings
  before update on public.savings_goals
  for each row execute function public.set_updated_at();

-- =============================================================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================================================
alter table public.accounts enable row level security;
alter table public.categories enable row level security;
alter table public.transactions enable row level security;
alter table public.budgets enable row level security;
alter table public.recurring_transactions enable row level security;
alter table public.savings_goals enable row level security;

-- --- ACCOUNTS ---
drop policy if exists "accounts_select_own" on public.accounts;
create policy "accounts_select_own" on public.accounts for select using (auth.uid() = user_id);
drop policy if exists "accounts_insert_own" on public.accounts;
create policy "accounts_insert_own" on public.accounts for insert with check (auth.uid() = user_id);
drop policy if exists "accounts_update_own" on public.accounts;
create policy "accounts_update_own" on public.accounts for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "accounts_delete_own" on public.accounts;
create policy "accounts_delete_own" on public.accounts for delete using (auth.uid() = user_id);

-- --- CATEGORIES ---
drop policy if exists "categories_select_own" on public.categories;
create policy "categories_select_own" on public.categories for select using (auth.uid() = user_id);
drop policy if exists "categories_insert_own" on public.categories;
create policy "categories_insert_own" on public.categories for insert with check (auth.uid() = user_id);
drop policy if exists "categories_update_own" on public.categories;
create policy "categories_update_own" on public.categories for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "categories_delete_own" on public.categories;
create policy "categories_delete_own" on public.categories for delete using (auth.uid() = user_id);

-- --- TRANSACTIONS ---
drop policy if exists "transactions_select_own" on public.transactions;
create policy "transactions_select_own" on public.transactions for select using (auth.uid() = user_id);
drop policy if exists "transactions_insert_own" on public.transactions;
create policy "transactions_insert_own" on public.transactions for insert with check (auth.uid() = user_id);
drop policy if exists "transactions_update_own" on public.transactions;
create policy "transactions_update_own" on public.transactions for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "transactions_delete_own" on public.transactions;
create policy "transactions_delete_own" on public.transactions for delete using (auth.uid() = user_id);

-- --- BUDGETS ---
drop policy if exists "budgets_select_own" on public.budgets;
create policy "budgets_select_own" on public.budgets for select using (auth.uid() = user_id);
drop policy if exists "budgets_insert_own" on public.budgets;
create policy "budgets_insert_own" on public.budgets for insert with check (auth.uid() = user_id);
drop policy if exists "budgets_update_own" on public.budgets;
create policy "budgets_update_own" on public.budgets for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "budgets_delete_own" on public.budgets;
create policy "budgets_delete_own" on public.budgets for delete using (auth.uid() = user_id);

-- --- RECURRING TRANSACTIONS ---
drop policy if exists "recurring_select_own" on public.recurring_transactions;
create policy "recurring_select_own" on public.recurring_transactions for select using (auth.uid() = user_id);
drop policy if exists "recurring_insert_own" on public.recurring_transactions;
create policy "recurring_insert_own" on public.recurring_transactions for insert with check (auth.uid() = user_id);
drop policy if exists "recurring_update_own" on public.recurring_transactions;
create policy "recurring_update_own" on public.recurring_transactions for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "recurring_delete_own" on public.recurring_transactions;
create policy "recurring_delete_own" on public.recurring_transactions for delete using (auth.uid() = user_id);

-- --- SAVINGS GOALS ---
drop policy if exists "savings_select_own" on public.savings_goals;
create policy "savings_select_own" on public.savings_goals for select using (auth.uid() = user_id);
drop policy if exists "savings_insert_own" on public.savings_goals;
create policy "savings_insert_own" on public.savings_goals for insert with check (auth.uid() = user_id);
drop policy if exists "savings_update_own" on public.savings_goals;
create policy "savings_update_own" on public.savings_goals for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "savings_delete_own" on public.savings_goals;
create policy "savings_delete_own" on public.savings_goals for delete using (auth.uid() = user_id);
