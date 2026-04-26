create table if not exists public.users (
  email text primary key,
  name text not null default '',
  tier text not null default 'personal',
  billing_cycle text not null default 'monthly',
  payment_status text not null default 'pending',
  razorpay_order_id text not null default '',
  razorpay_payment_id text not null default '',
  trial_started_at timestamptz not null,
  trial_ends_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.workspace_members (
  owner_email text not null references public.users(email) on delete cascade,
  member_email text not null,
  created_at timestamptz not null default now(),
  primary key (owner_email, member_email)
);

create table if not exists public.monthly_usage (
  period_key text not null,
  email text not null references public.users(email) on delete cascade,
  pages_used integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key (period_key, email)
);

create table if not exists public.trial_usage (
  email text primary key references public.users(email) on delete cascade,
  pdfs_used integer not null default 0,
  pages_used integer not null default 0,
  updated_at timestamptz not null default now()
);

create index if not exists idx_workspace_members_owner_email
  on public.workspace_members(owner_email);

create index if not exists idx_monthly_usage_email
  on public.monthly_usage(email);

create index if not exists idx_trial_usage_updated_at
  on public.trial_usage(updated_at);
