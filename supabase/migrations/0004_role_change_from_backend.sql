-- Il ruolo si può cambiare dall'SQL Editor / backend (nessun utente collegato)
-- o da un admin; mai da un cliente via app. Prima bloccava anche il backend,
-- e quindi non si poteva nominare il primo titolare.
create or replace function public.protect_role()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.role <> old.role and auth.uid() is not null and not public.is_admin() then
    raise exception 'Non autorizzato a cambiare ruolo';
  end if;
  return new;
end;
$$;
revoke execute on function public.protect_role() from public, anon, authenticated;
