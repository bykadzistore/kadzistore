-- KADZI STORE V13
-- Universal certificate checkout for all iOS software and shared catalog certificate.

create or replace function public.kds_create_ios_certificate_bundle(
  p_telegram_user_id bigint,
  p_ios_plan_id uuid,
  p_certificate_plan_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_ios_order_id uuid;
  v_certificate_order_id uuid;
  v_product_slug text;
  v_platform text;
begin
  select p.slug, p.platform into v_product_slug, v_platform
  from public.kds_product_plans pl
  join public.kds_products p on p.id = pl.product_id
  where pl.id = p_ios_plan_id and pl.is_active = true and p.is_active = true;

  if v_product_slug is null or v_platform is distinct from 'iOS' or v_product_slug = 'ios-certificates' then
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

  -- Both purchases run in one transaction; a failure rolls back both orders and debits.
  v_ios_order_id := public.kds_create_order(p_telegram_user_id, p_ios_plan_id);
  if p_certificate_plan_id is not null then
    v_certificate_order_id := public.kds_create_order(p_telegram_user_id, p_certificate_plan_id);
  end if;

  return jsonb_build_object(
    'order_ids',
    case when v_certificate_order_id is null
      then jsonb_build_array(v_ios_order_id)
      else jsonb_build_array(v_ios_order_id, v_certificate_order_id)
    end
  );
end;
$function$;

revoke all on function public.kds_create_ios_certificate_bundle(bigint, uuid, uuid) from public, anon, authenticated;
grant execute on function public.kds_create_ios_certificate_bundle(bigint, uuid, uuid) to service_role;

-- Make the existing universal certificate a dedicated catalog category and set its artwork.
update public.kds_products
set subcategory = 'Сертификаты',
    image_url = 'https://i.ibb.co/RGw3YYws/19.jpg'
where slug = 'ios-certificates';
