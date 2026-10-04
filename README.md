# list&check

App Android per gli ordini dei clienti di un magazzino all'ingrosso alimentare.
I clienti si registrano, sfogliano il catalogo (filtri per categoria e ricerca),
riempiono il carrello e inviano l'ordine. Il titolare riceve l'avviso e gestisce
gli ordini dalla stessa app. Nessun pagamento passa dall'app.

- **App:** Flutter (`lib/`)
- **Backend:** Supabase: login, database, tempo reale (`supabase/`)
- **Avviso ordini:** email tramite Resend (`supabase/functions/notify-order`);
  notifiche push Firebase in arrivo
- **APK:** generato da GitHub Actions (`.github/workflows/build-apk.yml`)

## Struttura

| Percorso | Contenuto |
| --- | --- |
| `lib/screens/auth/` | Accesso (email o nome utente) e registrazione con profilo attività |
| `lib/screens/customer/` | Catalogo, carrello, i miei ordini |
| `lib/screens/admin/` | Ordini in arrivo (tempo reale, cambio stato), gestione catalogo e import Excel/CSV |
| `lib/catalog_import.dart` | Lettura del catalogo da `.xlsx` o `.csv` |
| `supabase/migrations/0001_init.sql` | Tabelle, regole di sicurezza (RLS), funzione `place_order` |
| `docs/catalogo_esempio.csv` | Esempio del file catalogo |

## Messa in funzione

1. **Supabase**: crea un progetto gratuito su supabase.com ed esegui
   `supabase/migrations/0001_init.sql` nell'SQL Editor.
2. **Titolare**: registrati dall'app, poi nell'SQL Editor:
   `update profiles set role = 'admin' where username = 'NOME_UTENTE';`
3. **Avviso email**: crea una chiave su resend.com, poi
   - pubblica la funzione: `supabase functions deploy notify-order`
   - imposta i segreti `RESEND_API_KEY`, `ORDER_EMAIL_TO`, `ORDER_EMAIL_FROM`
   - in Database → Webhooks crea un webhook su INSERT di `orders` verso la funzione.
4. **APK**: nel repository GitHub, Settings → Secrets and variables → Actions → Variables,
   aggiungi `SUPABASE_URL` e `SUPABASE_KEY` (la chiave *publishable* del progetto).
   Ogni push su `main` genera l'APK, scaricabile dalla pagina della run in Actions.

## Formato del catalogo

Prima riga con le intestazioni (ordine libero):
`nome; categoria; prezzo; unita (kg | etto | pz); disponibile (si/no, opzionale)`.
I prodotti con lo stesso nome vengono aggiornati, quelli nuovi aggiunti.

## Sviluppo

```sh
flutter pub get
flutter test
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...
```
