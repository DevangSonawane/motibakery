-- Motibakery: single products migration.
-- Includes:
-- 1) CSV inventory fields
-- 2) CMS fields
-- 3) image field for per-product image
-- 4) RLS policies (admin write, authenticated read)
-- Run this after `002_reset_users_minimal.sql`.

create extension if not exists pgcrypto;

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  handle text not null unique,
  title text not null,
  option1_name text,
  option1_value text,
  option2_name text,
  option2_value text,
  option3_name text,
  option3_value text,
  sku text,
  hs_code text,
  coo text,
  location text,
  bin_name text,
  incoming integer not null default 0,
  unavailable integer not null default 0,
  committed integer not null default 0,
  available integer not null default 0,
  on_hand_current integer not null default 0,
  on_hand_new integer,
  name text not null default '',
  category text not null default 'General',
  rate text not null default '-',
  weight text not null default '-',
  flavours integer not null default 1 check (flavours >= 1),
  status text not null default 'active' check (status in ('active', 'inactive')),
  image text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Backward compatibility: if old schema has image_url, rename it once.
do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'products'
      and column_name = 'image_url'
  ) and not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'products'
      and column_name = 'image'
  ) then
    alter table public.products rename column image_url to image;
  end if;
end $$;

-- Ensure all expected columns exist for already-created tables.
alter table public.products add column if not exists title text;
alter table public.products add column if not exists option1_name text;
alter table public.products add column if not exists option1_value text;
alter table public.products add column if not exists option2_name text;
alter table public.products add column if not exists option2_value text;
alter table public.products add column if not exists option3_name text;
alter table public.products add column if not exists option3_value text;
alter table public.products add column if not exists sku text;
alter table public.products add column if not exists hs_code text;
alter table public.products add column if not exists coo text;
alter table public.products add column if not exists location text;
alter table public.products add column if not exists bin_name text;
alter table public.products add column if not exists incoming integer not null default 0;
alter table public.products add column if not exists unavailable integer not null default 0;
alter table public.products add column if not exists committed integer not null default 0;
alter table public.products add column if not exists available integer not null default 0;
alter table public.products add column if not exists on_hand_current integer not null default 0;
alter table public.products add column if not exists on_hand_new integer;
alter table public.products add column if not exists name text not null default '';
alter table public.products add column if not exists category text not null default 'General';
alter table public.products add column if not exists rate text not null default '-';
alter table public.products add column if not exists weight text not null default '-';
alter table public.products add column if not exists flavours integer not null default 1;
alter table public.products add column if not exists status text not null default 'active';
alter table public.products add column if not exists image text not null default '';
alter table public.products add column if not exists created_at timestamptz not null default now();
alter table public.products add column if not exists updated_at timestamptz not null default now();

-- Keep title/name aligned for old/new inserts.
update public.products
set title = coalesce(nullif(title, ''), name, handle)
where title is null or title = '';

update public.products
set name = coalesce(nullif(name, ''), title, handle)
where name is null or name = '';

alter table public.products alter column title set not null;
alter table public.products alter column name set not null;

create index if not exists products_category_idx on public.products(category);
create index if not exists products_status_idx on public.products(status);
create index if not exists products_created_at_idx on public.products(created_at desc);
create index if not exists products_handle_idx on public.products(handle);
create index if not exists products_title_idx on public.products(title);

create or replace function public.set_updated_at_products()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_products_set_updated_at on public.products;
create trigger trg_products_set_updated_at
before update on public.products
for each row
execute function public.set_updated_at_products();

alter table public.products enable row level security;

drop policy if exists products_select_authenticated on public.products;
create policy products_select_authenticated
on public.products
for select
to authenticated
using (true);

drop policy if exists products_insert_admin_only on public.products;
create policy products_insert_admin_only
on public.products
for insert
to authenticated
with check (public.is_admin());

drop policy if exists products_update_admin_only on public.products;
create policy products_update_admin_only
on public.products
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists products_delete_admin_only on public.products;
create policy products_delete_admin_only
on public.products
for delete
to authenticated
using (public.is_admin());

grant select, insert, update, delete on public.products to authenticated;
