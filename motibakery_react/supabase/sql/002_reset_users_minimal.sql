-- Motibakery: reset users schema to minimal fields only.
-- WARNING: This drops public.users and removes existing data.

drop table if exists public.users cascade;

create table public.users (
  uid uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  gmail text not null unique check (gmail like '%@gmail.com'),
  password text not null,
  role text not null check (role in ('admin', 'counter', 'cake_room'))
);

create or replace function public.fill_user_uid_from_auth_email()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.uid is null then
    select au.id into new.uid
    from auth.users au
    where lower(au.email) = lower(new.gmail)
    limit 1;

    if new.uid is null then
      raise exception 'No auth.users record found for gmail: %', new.gmail;
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_fill_user_uid_from_auth_email on public.users;
create trigger trg_fill_user_uid_from_auth_email
before insert on public.users
for each row
execute function public.fill_user_uid_from_auth_email();

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.users u
    where u.uid = auth.uid()
      and u.role = 'admin'
  );
$$;

grant execute on function public.is_admin() to authenticated;

alter table public.users enable row level security;

drop policy if exists users_select_own_or_admin on public.users;
create policy users_select_own_or_admin
on public.users
for select
to authenticated
using (
  uid = auth.uid() or public.is_admin()
);

drop policy if exists users_insert_admin_only on public.users;
create policy users_insert_admin_only
on public.users
for insert
to authenticated
with check (public.is_admin());

drop policy if exists users_update_admin_only on public.users;
create policy users_update_admin_only
on public.users
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists users_delete_admin_only on public.users;
create policy users_delete_admin_only
on public.users
for delete
to authenticated
using (public.is_admin());
