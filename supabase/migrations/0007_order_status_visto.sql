-- Stati ordine semplificati: nuovo, visto (dal titolare), annullato.
update public.orders set status = 'visto' where status in ('preparato', 'consegnato');
alter table public.orders drop constraint orders_status_check;
alter table public.orders add constraint orders_status_check check (status in ('nuovo', 'visto', 'annullato'));
