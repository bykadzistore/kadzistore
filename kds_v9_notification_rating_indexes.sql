-- Additional indexes for KADZI STORE v9 foreign-key lookups.
create index if not exists kds_product_ratings_user_idx on public.kds_product_ratings(user_id);
create index if not exists kds_notifications_order_idx on public.kds_notifications(order_id);
create index if not exists kds_notifications_announcement_idx on public.kds_notifications(announcement_id);
create index if not exists kds_broadcast_logs_announcement_idx on public.kds_broadcast_logs(announcement_id);
