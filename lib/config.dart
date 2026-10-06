// Progetto Supabase "OrdinaFacile". URL e chiave publishable sono pensati per
// stare nell'app: la sicurezza dei dati è garantita dalle regole RLS nel database.
// Si possono sovrascrivere in build con --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...
const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://stknnostvolacmuyvydk.supabase.co');
const supabaseKey = String.fromEnvironment('SUPABASE_KEY', defaultValue: 'sb_publishable_wuqkGGvM2cuD9tv9Fm7Exg_IHOTx3Ey');

// Contatti di Dofrelli Distribuzione mostrati ai clienti nel listino.
const contactMobile = '331 2130481';
const contactPhone = '06 20766404';
const contactEmail = 'info@dofrellidistribuzione.it';
