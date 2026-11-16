-- KADZI STORE V14
-- Product availability notices, per-game catalogue categories and private delivery files.

alter table public.kds_products
  add column if not exists notice_status text,
  add column if not exists notice_text text;

-- Private bucket: files are only delivered through short-lived signed URLs
-- created by the authenticated Edge Function after checking the order owner.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'kds-delivery-files',
  'kds-delivery-files',
  false,
  104857600,
  array[
    'application/vnd.android.package-archive',
    'application/zip',
    'application/x-7z-compressed',
    'application/x-rar-compressed',
    'application/pdf',
    'text/plain',
    'application/octet-stream',
    'application/x-msdownload',
    'application/x-apple-diskimage'
  ]
)
on conflict (id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Categories belong to a game. Hiding a category never deletes its products.
create table if not exists public.kds_game_categories (
  id uuid primary key default gen_random_uuid(),
  game_id uuid not null references public.kds_games(id) on delete cascade,
  category_value text not null,
  display_name text not null,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint kds_game_categories_value_nonempty check (length(trim(category_value)) between 1 and 80),
  constraint kds_game_categories_display_nonempty check (length(trim(display_name)) between 1 and 80),
  constraint kds_game_categories_sort_nonnegative check (sort_order >= 0),
  constraint kds_game_categories_game_value_unique unique (game_id, category_value)
);

insert into public.kds_game_categories (game_id, category_value, display_name, sort_order)
select distinct g.id, p.subcategory,
       case when p.subcategory = 'Софт' then 'Ключи' else p.subcategory end,
       case p.subcategory when 'Софт' then 10 when 'Донат' then 20 when 'Сертификаты' then 30 else 100 end
from public.kds_products p
join public.kds_games g on g.name = p.game_category
where nullif(trim(p.subcategory), '') is not null
on conflict (game_id, category_value) do nothing;

alter table public.kds_game_categories enable row level security;
revoke all on public.kds_game_categories from anon, authenticated;
grant all on public.kds_game_categories to service_role;

-- Existing kds_admin_audit table is reused; no duplicate audit table is created.
