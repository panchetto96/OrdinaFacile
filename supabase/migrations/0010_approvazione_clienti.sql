-- Approvazione dei nuovi clienti: chi si registra non vede prezzi e non ordina
-- finché il titolare non lo abilita dalla scheda Clienti.
alter table public.profiles add column approved boolean not null default false;
-- Gli account già esistenti (titolare e clienti di prova) restano abilitati.
update public.profiles set approved = true;

create or replace function public.is_approved()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and (approved or role = 'admin'));
$$;

-- Il cliente non può abilitarsi da solo (né cambiarsi ruolo).
create or replace function public.protect_role()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is not null and not public.is_admin()
     and (new.role <> old.role or new.approved <> old.approved) then
    raise exception 'Non autorizzato';
  end if;
  return new;
end;
$$;
revoke execute on function public.protect_role() from public, anon, authenticated;

-- Listino e prezzi riservati: solo per clienti approvati (e titolare).
drop policy "prodotti: lettura utenti registrati" on public.products;
create policy "prodotti: lettura clienti approvati" on public.products
  for select to authenticated using (public.is_approved());

drop policy "prezzi cliente: lettura propri o admin" on public.customer_prices;
create policy "prezzi cliente: lettura propri o admin" on public.customer_prices
  for select to authenticated using ((customer_id = auth.uid() and public.is_approved()) or public.is_admin());

-- Foto ordini: caricamento solo da clienti approvati.
drop policy "foto ordini: caricamento nella propria cartella" on storage.objects;
create policy "foto ordini: caricamento nella propria cartella" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'ordini-foto' and (storage.foldername(name))[1] = auth.uid()::text and public.is_approved());

-- Invio ordini: stesso controllo dentro le funzioni (girano come security definer).
create or replace function public.place_order(p_items jsonb, p_note text default '')
returns bigint language plpgsql security definer set search_path = public as $$
declare
  v_order bigint;
begin
  if auth.uid() is null then
    raise exception 'Accesso richiesto';
  end if;
  if not public.is_approved() then
    raise exception 'Il tuo account è in attesa di approvazione';
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

create or replace function public.place_free_order(p_body text default '', p_photo_path text default null, p_note text default '')
returns bigint language plpgsql security definer set search_path = public as $$
declare
  v_order bigint;
begin
  if auth.uid() is null then
    raise exception 'Accesso richiesto';
  end if;
  if not public.is_approved() then
    raise exception 'Il tuo account è in attesa di approvazione';
  end if;
  if coalesce(trim(p_body), '') = '' and p_photo_path is null then
    raise exception 'Scrivi l''ordine o allega una foto';
  end if;
  if p_photo_path is not null and split_part(p_photo_path, '/', 1) <> auth.uid()::text then
    raise exception 'Foto non valida';
  end if;

  insert into public.orders (customer_id, body, photo_path, note)
  values (auth.uid(), coalesce(trim(p_body), ''), p_photo_path, coalesce(trim(p_note), ''))
  returning id into v_order;
  return v_order;
end;
$$;

-- Il titolare abilita (o sospende) un cliente.
create or replace function public.set_customer_approved(p_customer uuid, p_approved boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then
    raise exception 'Solo il titolare può approvare i clienti';
  end if;
  update public.profiles set approved = p_approved where id = p_customer and role = 'customer';
end;
$$;
revoke execute on function public.set_customer_approved(uuid, boolean) from public, anon;
grant execute on function public.set_customer_approved(uuid, boolean) to authenticated;
