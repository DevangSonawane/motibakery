-- Motibakery: orders table for Counter + Cake Room workflows.
-- Run this after `002_reset_users_minimal.sql`.

create extension if not exists pgcrypto;

create table if not exists public.orders (
  uid uuid primary key default gen_random_uuid(),
  order_id text not null unique,
  cake_id text not null,
  cake_name text not null,
  flavour text not null,
  weight numeric(10, 3) not null check (weight > 0),
  delivery_date timestamptz not null,
  delivery_time timestamptz,
  customer_name text,
  customer_phone text,
  notes text,
  reference_image_url text,
  cake_image_url text,
  base_rate_per_kg numeric(10, 2),
  flavour_increment_per_kg numeric(10, 2) not null default 0,
  total_price numeric(10, 2) not null check (total_price >= 0),
  status text not null default 'new' check (status in ('new', 'in_progress', 'prepared', 'delivered')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid not null references auth.users(id) on delete restrict
);

-- Ensure expected columns exist for already-created tables.
alter table public.orders add column if not exists order_id text;
alter table public.orders add column if not exists cake_id text;
alter table public.orders add column if not exists cake_name text;
alter table public.orders add column if not exists flavour text;
alter table public.orders add column if not exists weight numeric(10, 3);
alter table public.orders add column if not exists delivery_date timestamptz;
alter table public.orders add column if not exists delivery_time timestamptz;
alter table public.orders add column if not exists customer_name text;
alter table public.orders add column if not exists customer_phone text;
alter table public.orders add column if not exists notes text;
alter table public.orders add column if not exists reference_image_url text;
alter table public.orders add column if not exists cake_image_url text;
alter table public.orders add column if not exists base_rate_per_kg numeric(10, 2);
alter table public.orders add column if not exists flavour_increment_per_kg numeric(10, 2) not null default 0;
alter table public.orders add column if not exists total_price numeric(10, 2);
alter table public.orders add column if not exists status text not null default 'new';
alter table public.orders add column if not exists created_at timestamptz not null default now();
alter table public.orders add column if not exists updated_at timestamptz not null default now();
alter table public.orders add column if not exists created_by uuid;

create unique index if not exists orders_order_id_uidx on public.orders(order_id);
create index if not exists orders_status_idx on public.orders(status);
create index if not exists orders_delivery_date_idx on public.orders(delivery_date);
create index if not exists orders_created_at_idx on public.orders(created_at desc);
create index if not exists orders_created_by_idx on public.orders(created_by);

create or replace function public.set_updated_at_orders()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_orders_set_updated_at on public.orders;
create trigger trg_orders_set_updated_at
before update on public.orders
for each row
execute function public.set_updated_at_orders();

alter table public.orders enable row level security;

drop policy if exists orders_select_own_or_ops on public.orders;
create policy orders_select_own_or_ops
on public.orders
for select
to authenticated
using (
  created_by = auth.uid()
  or exists (
    select 1
    from public.users u
    where u.uid = auth.uid()
      and u.role in ('admin', 'cake_room')
  )
);

drop policy if exists orders_insert_counter_or_admin on public.orders;
create policy orders_insert_counter_or_admin
on public.orders
for insert
to authenticated
with check (
  created_by = auth.uid()
  and exists (
    select 1
    from public.users u
    where u.uid = auth.uid()
      and u.role in ('admin', 'counter')
  )
);

drop policy if exists orders_update_cake_or_admin on public.orders;
create policy orders_update_cake_or_admin
on public.orders
for update
to authenticated
using (
  exists (
    select 1
    from public.users u
    where u.uid = auth.uid()
      and u.role in ('admin', 'cake_room')
  )
)
with check (
  exists (
    select 1
    from public.users u
    where u.uid = auth.uid()
      and u.role in ('admin', 'cake_room')
  )
);

drop policy if exists orders_update_counter_delivered_own on public.orders;
create policy orders_update_counter_delivered_own
on public.orders
for update
to authenticated
using (
  created_by = auth.uid()
  and status = 'prepared'
  and exists (
    select 1
    from public.users u
    where u.uid = auth.uid()
      and u.role in ('admin', 'counter')
  )
)
with check (
  created_by = auth.uid()
  and status = 'delivered'
  and exists (
    select 1
    from public.users u
    where u.uid = auth.uid()
      and u.role in ('admin', 'counter')
  )
);

drop policy if exists orders_delete_admin_only on public.orders;
create policy orders_delete_admin_only
on public.orders
for delete
to authenticated
using (
  exists (
    select 1
    from public.users u
    where u.uid = auth.uid()
      and u.role = 'admin'
  )
);

grant select, insert, update, delete on public.orders to authenticated;
