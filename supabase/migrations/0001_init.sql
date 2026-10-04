-- list&check: schema iniziale
-- Ruoli: 'customer' (cliente) e 'admin' (titolare del magazzino).

create extension if not exists pg_trgm;

-- PROFILI -------------------------------------------------------------------
create table public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  username      text not null unique check (username ~ '^[a-z0-9_.]{3,30}$'),
  email         text not null,
  business_name text not null default '',
  address       text not null default '',
  phone         text not null default '',
  role          text not null default 'customer' check (role in ('customer', 'admin')),
  push_token    text,
  created_at    timestamptz not null default now()
);

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;

-- Crea il profilo alla registrazione con i dati passati dall'app.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, username, email, business_name, address, phone)
  values (
    new.id,
    lower(new.raw_user_meta_data->>'username'),
    new.email,
    coalesce(new.raw_user_meta_data->>'business_name', ''),
    coalesce(new.raw_user_meta_data->>'address', ''),
    coalesce(new.raw_user_meta_data->>'phone', '')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Login con nome utente: restituisce l'email associata.
create or replace function public.email_for_username(p_username text)
returns text language sql stable security definer set search_path = public as $$
  select email from public.profiles where username = lower(p_username);
$$;
grant execute on function public.email_for_username(text) to anon, authenticated;

-- Il cliente non può promuoversi admin.
create or replace function public.protect_role()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.role <> old.role and not public.is_admin() then
    raise exception 'Non autorizzato a cambiare ruolo';
  end if;
  return new;
end;
$$;

create trigger profiles_protect_role
  before update on public.profiles
  for each row execute function public.protect_role();

alter table public.profiles enable row level security;
create policy "profilo: lettura propria o admin" on public.profiles
  for select using (id = auth.uid() or public.is_admin());
create policy "profilo: modifica propria" on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

-- PRODOTTI ------------------------------------------------------------------
create table public.products (
  id         bigint generated always as identity primary key,
  name       text not null unique,
  category   text not null default 'Altro',
  price      numeric(10, 2) not null check (price >= 0),
  unit       text not null check (unit in ('kg', 'etto', 'pz')),
  available  boolean not null default true,
  updated_at timestamptz not null default now()
);
create index products_name_trgm on public.products using gin (name gin_trgm_ops);
create index products_category on public.products (category);

alter table public.products enable row level security;
create policy "prodotti: lettura utenti registrati" on public.products
  for select to authenticated using (true);
create policy "prodotti: gestione admin" on public.products
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- ORDINI --------------------------------------------------------------------
create table public.orders (
  id          bigint generated always as identity primary key,
  customer_id uuid not null references public.profiles(id) on delete cascade,
  status      text not null default 'nuovo' check (status in ('nuovo', 'preparato', 'consegnato', 'annullato')),
  note        text not null default '',
  total       numeric(10, 2) not null default 0,
  created_at  timestamptz not null default now()
);
create index orders_customer on public.orders (customer_id, created_at desc);

create table public.order_items (
  id           bigint generated always as identity primary key,
  order_id     bigint not null references public.orders(id) on delete cascade,
  product_id   bigint references public.products(id) on delete set null,
  product_name text not null,
  unit         text not null,
  unit_price   numeric(10, 2) not null,
  quantity     numeric(10, 2) not null check (quantity > 0)
);
create index order_items_order on public.order_items (order_id);

alter table public.orders enable row level security;
create policy "ordini: lettura propri o admin" on public.orders
  for select using (customer_id = auth.uid() or public.is_admin());
create policy "ordini: stato modificabile da admin" on public.orders
  for update using (public.is_admin()) with check (public.is_admin());

alter table public.order_items enable row level security;
create policy "righe: lettura se si vede l'ordine" on public.order_items
  for select using (exists (
    select 1 from public.orders o
    where o.id = order_id and (o.customer_id = auth.uid() or public.is_admin())
  ));

-- Invio ordine: prezzi presi dal catalogo lato server, tutto in una transazione.
-- p_items: [{"product_id": 1, "quantity": 2.5}, ...]
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
  select v_order, p.id, p.name, p.unit, p.price, (i->>'quantity')::numeric
  from jsonb_array_elements(p_items) i
  join public.products p on p.id = (i->>'product_id')::bigint and p.available;

  if not found then
    raise exception 'Nessun prodotto disponibile nel carrello';
  end if;

  update public.orders
  set total = (select coalesce(sum(unit_price * quantity), 0) from public.order_items where order_id = v_order)
  where id = v_order;

  return v_order;
end;
$$;
grant execute on function public.place_order(jsonb, text) to authenticated;

-- Aggiornamenti in tempo reale per la schermata ordini del titolare.
alter publication supabase_realtime add table public.orders;
