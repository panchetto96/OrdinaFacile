-- Ordini scritti a mano o con la foto di un foglio, oltre a quelli dal listino.
alter table public.orders
  add column body       text not null default '',
  add column photo_path text;

-- Foto degli ordini: spazio privato, ogni cliente scrive solo nella sua cartella
-- (<id utente>/...), il titolare le vede tutte.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('ordini-foto', 'ordini-foto', false, 10485760,
        array['image/jpeg', 'image/png', 'image/webp', 'image/heic'])
on conflict (id) do nothing;

create policy "foto ordini: caricamento nella propria cartella" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'ordini-foto' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "foto ordini: lettura proprie o admin" on storage.objects
  for select to authenticated
  using (bucket_id = 'ordini-foto' and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin()));

-- Invio di un ordine libero: testo e/o foto, senza righe né totale.
create or replace function public.place_free_order(p_body text default '', p_photo_path text default null, p_note text default '')
returns bigint language plpgsql security definer set search_path = public as $$
declare
  v_order bigint;
begin
  if auth.uid() is null then
    raise exception 'Accesso richiesto';
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
revoke execute on function public.place_free_order(text, text, text) from public, anon;
grant execute on function public.place_free_order(text, text, text) to authenticated;
