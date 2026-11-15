-- KADZI STORE v9: product ratings, customer notification preferences/inbox,
-- Telegram recipients, and broadcast history.
-- Applied to Supabase project vpuaihznkswrpsqxgcvm.

create table if not exists public.kds_product_ratings (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.kds_products(id) on delete cascade,
  user_id uuid not null references public.kds_users(id) on delete cascade,
  stars smallint not null check (stars between 1 and 5),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (product_id, user_id)
);
create index if not exists kds_product_ratings_product_stars_idx
  on public.kds_product_ratings(product_id, stars);

create table if not exists public.kds_notification_settings (
  user_id uuid primary key references public.kds_users(id) on delete cascade,
  payment_confirmation boolean not null default true,
  order_status boolean not null default true,
  order_fulfilled boolean not null default true,
  announcements boolean not null default true,
  updated_at timestamptz not null default now()
);

create table if not exists public.kds_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.kds_users(id) on delete cascade,
  notification_type text not null check (notification_type in ('payment_confirmation','order_status','order_fulfilled','announcement')),
  title text not null,
  body text not null default '',
  order_id uuid references public.kds_orders(id) on delete set null,
  announcement_id uuid references public.kds_announcements(id) on delete set null,
  created_at timestamptz not null default now(),
  read_at timestamptz
);
create index if not exists kds_notifications_user_created_idx
  on public.kds_notifications(user_id, created_at desc);
create index if not exists kds_notifications_unread_idx
  on public.kds_notifications(user_id) where read_at is null;

create table if not exists public.kds_bot_subscribers (
  telegram_user_id bigint primary key,
  chat_id bigint not null,
  username text,
  first_name text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists kds_bot_subscribers_active_idx
  on public.kds_bot_subscribers(is_active, telegram_user_id);

create table if not exists public.kds_broadcast_logs (
  id uuid primary key default gen_random_uuid(),
  announcement_id uuid references public.kds_announcements(id) on delete set null,
  audience text not null check (audience in ('app_users','bot_subscribers','selected')),
  send_in_app boolean not null default false,
  send_telegram boolean not null default false,
  recipients integer not null default 0,
  telegram_sent integer not null default 0,
  telegram_failed integer not null default 0,
  created_by bigint not null,
  created_at timestamptz not null default now()
);
create index if not exists kds_broadcast_logs_created_idx
  on public.kds_broadcast_logs(created_at desc);

alter table public.kds_product_ratings enable row level security;
alter table public.kds_notification_settings enable row level security;
alter table public.kds_notifications enable row level security;
alter table public.kds_bot_subscribers enable row level security;
alter table public.kds_broadcast_logs enable row level security;

revoke all on public.kds_product_ratings, public.kds_notification_settings,
  public.kds_notifications, public.kds_bot_subscribers, public.kds_broadcast_logs
  from anon, authenticated;
grant all on public.kds_product_ratings, public.kds_notification_settings,
  public.kds_notifications, public.kds_bot_subscribers, public.kds_broadcast_logs
  to service_role;
