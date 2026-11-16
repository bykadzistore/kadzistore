create or replace function public.kds_create_jarvis_ios_bundle(
  p_telegram_user_id bigint,
  p_jarvis_plan_id uuid,
  p_certificate_plan_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_jarvis_order_id uuid;
  v_certificate_order_id uuid;
  v_product_slug text;
begin
  select p.slug into v_product_slug
  from public.kds_product_plans pl
  join public.kds_products p on p.id = pl.product_id
  where pl.id = p_jarvis_plan_id and pl.is_active = true and p.is_active = true;
  if v_product_slug is distinct from 'jarvis-ios' then
    raise exception 'PLAN_NOT_AVAILABLE';
  end if;

  if p_certificate_plan_id is not null then
    select p.slug into v_product_slug
    from public.kds_product_plans pl
    join public.kds_products p on p.id = pl.product_id
    where pl.id = p_certificate_plan_id and pl.is_active = true and p.is_active = true;
    if v_product_slug is distinct from 'ios-certificates' then
      raise exception 'PLAN_NOT_AVAILABLE';
    end if;
  end if;

  -- Both purchases run inside this transaction. If either fails, neither order nor debit is committed.
  v_jarvis_order_id := public.kds_create_order(p_telegram_user_id, p_jarvis_plan_id);
  if p_certificate_plan_id is not null then
    v_certificate_order_id := public.kds_create_order(p_telegram_user_id, p_certificate_plan_id);
  end if;

  return jsonb_build_object(
    'order_ids', case when v_certificate_order_id is null
      then jsonb_build_array(v_jarvis_order_id)
      else jsonb_build_array(v_jarvis_order_id, v_certificate_order_id) end
  );
end;
$function$;
revoke all on function public.kds_create_jarvis_ios_bundle(bigint, uuid, uuid) from public, anon, authenticated;
grant execute on function public.kds_create_jarvis_ios_bundle(bigint, uuid, uuid) to service_role;
