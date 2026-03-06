-- Hotfix for existing deployments:
-- 1) allow delivered status
-- 2) allow counter/admin to mark own prepared orders as delivered

alter table public.orders
drop constraint if exists orders_status_check;

alter table public.orders
add constraint orders_status_check
check (status in ('new', 'in_progress', 'prepared', 'delivered'));

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
