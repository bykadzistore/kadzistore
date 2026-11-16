-- KADZI STORE V15: hierarchical catalogue sections, subcategories and per-game filters.
alter table public.kds_game_categories
  add column if not exists parent_id uuid references public.kds_game_categories(id) on delete restrict,
  add column if not exists node_type text not null default 'section';

alter table public.kds_game_categories
  drop constraint if exists kds_game_categories_node_type_check;
alter table public.kds_game_categories
  add constraint kds_game_categories_node_type_check
  check (node_type in ('section','subcategory','filter'));

alter table public.kds_products add column if not exists catalog_section text;

update public.kds_game_categories set node_type='section' where parent_id is null;
update public.kds_game_categories set category_value='Ключи',display_name='Ключи'
where category_value='Софт';
update public.kds_products set subcategory='Ключи',catalog_section='Ключи'
where subcategory='Софт';
update public.kds_products set catalog_section='Сертификаты'
where subcategory='Сертификаты' and catalog_section is null;
update public.kds_products set catalog_section='Донат'
where subcategory='Донат' and catalog_section is null;

insert into public.kds_games (slug,name,sort_order,is_active)
values ('rapira-online','Rapira Online',8,true)
on conflict (slug) do update set name=excluded.name,is_active=true,updated_at=now();

-- Required top-level sections. Donat is available in every game.
insert into public.kds_game_categories (game_id,category_value,display_name,node_type,sort_order)
select g.id,x.val,x.label,'section',x.ord
from public.kds_games g
cross join (values ('Ключи','Ключи',10),('Сертификаты','Сертификаты',20),('Донат','Донат',30)) as x(val,label,ord)
where (g.name in ('Oxide Survival Island','PUBG Mobile','Counter Flame') and x.val in ('Ключи','Сертификаты','Донат'))
   or (g.name not in ('Oxide Survival Island','PUBG Mobile','Counter Flame') and x.val='Донат')
on conflict (game_id,category_value) do update
set display_name=excluded.display_name,node_type='section',parent_id=null,sort_order=excluded.sort_order,is_active=true,updated_at=now();

-- Donation subcategories by game.
insert into public.kds_game_categories (game_id,parent_id,category_value,display_name,node_type,sort_order)
select g.id,parent.id,x.val,x.label,'subcategory',x.ord
from public.kds_games g
join public.kds_game_categories parent on parent.game_id=g.id and parent.category_value='Донат' and parent.node_type='section'
cross join (values ('Пополнение по ID','Пополнение по ID',10),('По рынку','По рынку',20),('Голда','Голда',30),('Боевой пропуск','Боевой пропуск',40)) as x(val,label,ord)
where x.val='Пополнение по ID'
   or (x.val='По рынку' and g.name in ('Standoff 2','Rapira Online'))
   or (x.val in ('Голда','Боевой пропуск') and g.name='Rapira Online')
on conflict (game_id,category_value) do update
set parent_id=excluded.parent_id,display_name=excluded.display_name,node_type='subcategory',sort_order=excluded.sort_order,is_active=true,updated_at=now();

-- Platform filters are managed per game and can be edited/hidden/deleted in the admin panel.
insert into public.kds_game_categories (game_id,category_value,display_name,node_type,sort_order)
select g.id,x.val,x.label,'filter',x.ord
from public.kds_games g
cross join (values ('Android','ANDROID',10),('iOS','iOS',20),('PC','PC',30)) as x(val,label,ord)
on conflict (game_id,category_value) do update
set display_name=excluded.display_name,node_type='filter',parent_id=null,sort_order=excluded.sort_order,is_active=true,updated_at=now();

update public.kds_products
set catalog_section=case when subcategory in ('Ключи','Сертификаты','Донат') then subcategory else coalesce(catalog_section,subcategory) end
where catalog_section is null;

create index if not exists kds_game_categories_parent_idx
  on public.kds_game_categories(game_id,parent_id,node_type,sort_order);

-- Rapira Online uses only its requested donation catalogue; no platform filter chips by default.
delete from public.kds_game_categories c using public.kds_games g
where c.game_id=g.id and g.slug='rapira-online' and c.node_type='filter';
