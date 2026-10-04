-- Fatture: il titolare allega il PDF (fatto con il suo programma di fatturazione)
-- a uno o più ordini dello stesso cliente; il cliente lo apre dai suoi ordini.
create table public.invoices (
  id          bigint generated always as identity primary key,
  customer_id uuid not null references public.profiles(id) on delete cascade,
  number      text not null default '',
  file_path   text not null,
  created_at  timestamptz not null default now()
);
create index invoices_customer on public.invoices (customer_id, created_at desc);

alter table public.invoices enable row level security;
create policy "fatture: lettura proprie o admin" on public.invoices
  for select to authenticated using (customer_id = auth.uid() or public.is_admin());
create policy "fatture: gestione admin" on public.invoices
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

alter table public.orders add column invoice_id bigint references public.invoices(id) on delete set null;

-- PDF delle fatture: cartella per cliente (<id cliente>/...), scrive solo il titolare.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('fatture', 'fatture', false, 10485760, array['application/pdf'])
on conflict (id) do nothing;

create policy "fatture pdf: lettura proprie o admin" on storage.objects
  for select to authenticated
  using (bucket_id = 'fatture' and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin()));
create policy "fatture pdf: caricamento admin" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'fatture' and public.is_admin());
create policy "fatture pdf: eliminazione admin" on storage.objects
  for delete to authenticated
  using (bucket_id = 'fatture' and public.is_admin());

-- Registra la fattura e la collega agli ordini, tutto insieme.
create or replace function public.send_invoice(p_customer uuid, p_number text, p_file_path text, p_order_ids bigint[])
returns bigint language plpgsql security definer set search_path = public as $$
declare
  v_invoice bigint;
begin
  if not public.is_admin() then
    raise exception 'Solo il titolare può inviare fatture';
  end if;
  if coalesce(array_length(p_order_ids, 1), 0) = 0 then
    raise exception 'Scegli almeno un ordine';
  end if;
  if exists (select 1 from public.orders where id = any(p_order_ids) and customer_id <> p_customer) then
    raise exception 'Gli ordini devono essere tutti dello stesso cliente';
  end if;
  if split_part(p_file_path, '/', 1) <> p_customer::text then
    raise exception 'File non valido';
  end if;

  insert into public.invoices (customer_id, number, file_path)
  values (p_customer, coalesce(trim(p_number), ''), p_file_path)
  returning id into v_invoice;

  update public.orders set invoice_id = v_invoice where id = any(p_order_ids);
  return v_invoice;
end;
$$;
revoke execute on function public.send_invoice(uuid, text, text, bigint[]) from public, anon;
grant execute on function public.send_invoice(uuid, text, text, bigint[]) to authenticated;
