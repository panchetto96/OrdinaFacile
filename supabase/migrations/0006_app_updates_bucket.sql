-- Spazio pubblico in sola lettura per l'APK e il file version.json.
-- Scrive solo la CI (con la chiave secret, che ignora RLS).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('app', 'app', true, 209715200,
        array['application/vnd.android.package-archive', 'application/json', 'application/octet-stream'])
on conflict (id) do nothing;
