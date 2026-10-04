import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Messaggio d'errore leggibile per l'utente.
String errorText(Object e) => switch (e) {
      AuthException(:final message) => _authMessage(message),
      PostgrestException(:final message) => message,
      _ => 'Qualcosa è andato storto. Controlla la connessione e riprova.',
    };

String _authMessage(String m) {
  final l = m.toLowerCase();
  if (l.contains('invalid login')) return 'Email o password errati';
  if (l.contains('already registered')) return 'Esiste già un account con questa email';
  if (l.contains('email not confirmed')) return 'Conferma prima l\'email cliccando il link che ti abbiamo inviato';
  if (l.contains('password')) return 'La password deve avere almeno 6 caratteri';
  return m;
}

void showError(BuildContext context, Object e) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(e))));
}

void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

/// Mostra caricamento / errore / contenuto per un Future ricaricabile.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({super.key, required this.future, required this.builder, required this.onRetry});

  final Future<T> future;
  final Widget Function(T data) builder;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(errorText(snap.error!), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Riprova')),
            ]),
          );
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        return builder(snap.data as T);
      },
    );
  }
}

/// Con la lista ordinata per categoria, aggiunge sopra a [tile] il nome della
/// categoria quando [i] è il primo prodotto di una nuova categoria.
Widget withCategoryHeader(BuildContext context, List<String> categories, int i, Widget tile) {
  if (i > 0 && categories[i] == categories[i - 1]) return tile;
  final theme = Theme.of(context);
  return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Container(
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Text(
        categories[i].toUpperCase(),
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
      ),
    ),
    tile,
  ]);
}
