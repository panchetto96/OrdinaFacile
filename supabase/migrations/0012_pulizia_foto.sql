-- Le foto degli ordini si cancellano in automatico dopo 60 giorni (scelta di Matteo,
-- 2026-10-06) per restare nello spazio file del piano gratuito. L'ordine resta;
-- photo_removed_at dice all'app di mostrare "Foto eliminata".
alter table public.orders add column if not exists photo_removed_at timestamptz;

create extension if not exists pg_cron;
create extension if not exists pg_net;

-- Ogni notte alle 3 (UTC) chiama la funzione pulizia-foto, che cancella i file
-- tramite le API di Storage. Chiamarla più volte non fa danni: tocca solo le
-- foto più vecchie di 60 giorni non ancora eliminate.
select cron.schedule(
  'pulizia-foto-ordini',
  '0 3 * * *',
  $$ select net.http_post(
       url := 'https://stknnostvolacmuyvydk.supabase.co/functions/v1/pulizia-foto',
       headers := '{"Content-Type": "application/json"}'::jsonb,
       body := '{}'::jsonb
     ) $$
);
