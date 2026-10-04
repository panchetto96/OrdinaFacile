// Valori passati in fase di build:
// flutter build apk --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseKey = String.fromEnvironment('SUPABASE_KEY');
