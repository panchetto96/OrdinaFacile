-- Privacy: niente più login con nome utente (permetteva di risalire all'email
-- di un cliente conoscendone il nome utente) e cancellazione account dal cliente.
revoke execute on function public.email_for_username(text) from public, anon, authenticated;

-- "Elimina il mio account": i dati personali vengono cancellati e l'accesso
-- disattivato. Ordini e fatture restano, senza dati personali, perché vanno
-- conservati per la contabilità.
create or replace function public.delete_my_account()
returns void language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_tag text := 'eliminato_' || left(replace(auth.uid()::text, '-', ''), 12);
begin
  if v_uid is null then
    raise exception 'Accesso richiesto';
  end if;
  if public.is_admin() then
    raise exception 'L''account del titolare non si può eliminare dall''app';
  end if;

  update public.profiles
  set username = v_tag, email = v_tag || '@eliminato.invalid', business_name = 'Cliente eliminato',
      address = '', phone = '', push_token = null
  where id = v_uid;

  update auth.users
  set email = v_tag || '@eliminato.invalid', phone = null, encrypted_password = '',
      raw_user_meta_data = '{}'::jsonb, banned_until = 'infinity'
  where id = v_uid;
  -- Con l'utente bloccato le sessioni aperte non si possono rinnovare: l'app lo fa uscire subito.
  update auth.identities set identity_data = jsonb_build_object('sub', v_uid::text) where user_id = v_uid;
end;
$$;
revoke execute on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
