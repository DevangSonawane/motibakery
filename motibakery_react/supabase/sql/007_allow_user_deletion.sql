-- Motibakery: allow deleting auth users without losing order history.
-- This changes orders.created_by to SET NULL on delete instead of RESTRICT.

alter table public.orders
  alter column created_by drop not null;

alter table public.orders
  drop constraint if exists orders_created_by_fkey;

alter table public.orders
  add constraint orders_created_by_fkey
  foreign key (created_by)
  references auth.users(id)
  on delete set null;
