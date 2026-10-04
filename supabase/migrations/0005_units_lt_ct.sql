-- Il listino Dofrelli vende anche a litro (LT) e a cartone (CT).
alter table public.products drop constraint products_unit_check;
alter table public.products add constraint products_unit_check check (unit in ('kg', 'etto', 'pz', 'lt', 'ct'));
