create extension if not exists pgcrypto;

alter table public.products add column if not exists option2_name text;
alter table public.products add column if not exists option2_value text;
alter table public.products add column if not exists flavours integer;

alter table public.products add column if not exists flavour_items jsonb not null default '[]'::jsonb;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'products_flavour_items_is_array'
  ) then
    alter table public.products
      add constraint products_flavour_items_is_array
      check (jsonb_typeof(flavour_items) = 'array');
  end if;
end $$;

update public.products
set flavour_items = case
  when flavour_items is null or flavour_items = '[]'::jsonb then
    case
      when option2_name = 'flavours' and option2_value is not null and option2_value ~ '^[[:space:]]*\\[' then option2_value::jsonb
      else '[]'::jsonb
    end
  else flavour_items
end;

update public.products
set flavours = 1
where flavours is null or flavours < 1;

update public.products
set flavours = greatest(1, jsonb_array_length(flavour_items))
where flavour_items is not null
  and jsonb_typeof(flavour_items) = 'array'
  and jsonb_array_length(flavour_items) > 0;

alter table public.products alter column flavours set not null;
