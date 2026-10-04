-- Le funzioni dei trigger non devono essere chiamabili via API.
revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.protect_role() from public, anon, authenticated;
-- Solo gli utenti registrati possono inviare ordini.
revoke execute on function public.place_order(jsonb, text) from public, anon;
grant execute on function public.place_order(jsonb, text) to authenticated;
-- pg_trgm fuori dallo schema pubblico.
alter extension pg_trgm set schema extensions;
