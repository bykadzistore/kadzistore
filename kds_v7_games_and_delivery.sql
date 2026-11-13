-- Applied to Supabase project vpuaihznkswrpsqxgcvm
create table if not exists public.kds_games (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null unique,
  image_url text,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint kds_games_slug_check check (slug ~ '^[a-z0-9][a-z0-9-]{1,63}$'),
  constraint kds_games_name_check check (char_length(name) between 1 and 80),
  constraint kds_games_image_check check (image_url is null or (image_url ~* '^https://' and char_length(image_url) <= 2000))
);
alter table public.kds_games enable row level security;
insert into public.kds_games(slug,name,sort_order) values
 ('oxide-survival-island','Oxide Survival Island',1),
 ('pubg-mobile','PUBG Mobile',2),
 ('standoff-2','Standoff 2',3),
 ('mobile-legends','Mobile Legends',4),
 ('genshin-impact','Genshin Impact',5),
 ('free-fire','Free Fire',6),
 ('counter-flame','Counter Flame',7)
on conflict (slug) do update set name=excluded.name, sort_order=excluded.sort_order, updated_at=now();

-- Function bodies for kds_admin_fulfill_order and kds_auto_fulfill_key were updated
-- in the live database. Their full definitions are maintained in Supabase Edge/SQL
-- history; see BACKEND_CHANGES.txt for the deployed behavior and signatures.
