# Supabase Setup (Motibakery)

## 1) Run SQL
Open Supabase SQL editor and run:

- `supabase/sql/002_reset_users_minimal.sql`
- `supabase/sql/003_create_products.sql`
- `supabase/sql/004_seed_products_from_swiggy_menu.sql`

This creates:
- `public.users` table
- RLS policies
- `public.is_admin()` helper

## 2) Bootstrap first admin
Create your first auth user in Supabase Auth, then insert one admin row.
You can insert with or without `uid` now (trigger auto-fills by gmail).

```sql
insert into public.users (
  uid,
  full_name,
  gmail,
  password,
  role
)
select
  id,
  'Admin User',
  'admin@gmail.com',
  'your_password_here',
  'admin'
from auth.users
where email = 'admin@gmail.com';
```

Or without uid:

```sql
insert into public.users (full_name, gmail, password, role)
values ('Admin User', 'admin@gmail.com', 'your_password_here', 'admin');
```

## 3) Deploy edge function
From repo root:

```bash
supabase login
supabase link --project-ref jygsbebawnkvyaqohxes
supabase secrets set SUPABASE_URL=https://jygsbebawnkvyaqohxes.supabase.co
supabase secrets set SUPABASE_PUBLISHABLE_KEY=<your-publishable-key>
supabase secrets set SUPABASE_SECRET_KEY=<your-secret-key>
supabase functions deploy admin-create-user --project-ref jygsbebawnkvyaqohxes
```

## 4) Frontend env
Only these are required in `client/.env`:

- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`

Do not keep service-role key in frontend env.
