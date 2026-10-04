-- Prezzi personalizzati: il listino generale vale per tutti, ma il titolare
-- può fissare un prezzo diverso per un singolo cliente su un singolo prodotto.

create table public.customer_prices (
  customer_id uuid not null references public.profiles(id) on delete cascade,
  product_id  bigint not null references public.products(id) on delete cascade,
  price       numeric(10, 2) not null check (price >= 0),
  updated_at  timestamptz not null default now(),
  primary key (customer_id, product_id)
);
create index customer_prices_product on public.customer_prices (product_id);

alter table public.customer_prices enable row level security;
create policy "prezzi cliente: lettura propri o admin" on public.customer_prices
  for select to authenticated using (customer_id = auth.uid() or public.is_admin());
create policy "prezzi cliente: gestione admin" on public.customer_prices
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Catalogo visto dall'utente collegato, con il suo prezzo effettivo.
-- security_invoker: valgono le regole RLS di chi legge.
create view public.my_catalog with (security_invoker = true) as
select
  p.id,
  p.name,
  p.category,
  coalesce(cp.price, p.price) as price,
  p.price as list_price,
  cp.price is not null as custom_price,
  p.unit,
  p.available
from public.products p
left join public.customer_prices cp
  on cp.product_id = p.id and cp.customer_id = auth.uid();

grant select on public.my_catalog to authenticated;
revoke all on public.my_catalog from anon;

-- Invio ordine: ora usa il prezzo del cliente quando esiste.
create or replace function public.place_order(p_items jsonb, p_note text default '')
returns bigint language plpgsql security definer set search_path = public as $$
declare
  v_order bigint;
begin
  if auth.uid() is null then
    raise exception 'Accesso richiesto';
  end if;
  if jsonb_array_length(coalesce(p_items, '[]'::jsonb)) = 0 then
    raise exception 'Il carrello è vuoto';
  end if;

  insert into public.orders (customer_id, note)
  values (auth.uid(), coalesce(p_note, ''))
  returning id into v_order;

  insert into public.order_items (order_id, product_id, product_name, unit, unit_price, quantity)
  select v_order, p.id, p.name, p.unit, coalesce(cp.price, p.price), (i->>'quantity')::numeric
  from jsonb_array_elements(p_items) i
  join public.products p on p.id = (i->>'product_id')::bigint and p.available
  left join public.customer_prices cp on cp.product_id = p.id and cp.customer_id = auth.uid();

  if not found then
    raise exception 'Nessun prodotto disponibile nel carrello';
  end if;

  update public.orders
  set total = (select coalesce(sum(unit_price * quantity), 0) from public.order_items where order_id = v_order)
  where id = v_order;

  return v_order;
end;
$$;
revoke execute on function public.place_order(jsonb, text) from public, anon;
grant execute on function public.place_order(jsonb, text) to authenticated;
