import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// "Ricordami" all'accesso: se attivo, l'app resta collegata e propone l'email
/// al prossimo accesso; se spento, a ogni nuova apertura dell'app si rientra.
class RememberMe {
  static const _flag = 'remember_me';
  static const _email = 'remember_email';

  /// (ricordami attivo, email salvata). Chi non ha mai scelto resta ricordato.
  static Future<(bool, String)> load() async {
    final p = await SharedPreferences.getInstance();
    return (p.getBool(_flag) ?? true, p.getString(_email) ?? '');
  }

  static Future<void> save({required bool remember, required String email}) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_flag, remember);
    if (remember) {
      await p.setString(_email, email.trim());
    } else {
      await p.remove(_email);
    }
  }

  /// All'avvio: chi ha tolto "Ricordami" deve accedere di nuovo.
  static Future<void> applyOnStartup(SupabaseClient db) async {
    final (remember, _) = await load();
    if (!remember && db.auth.currentSession != null) await db.auth.signOut();
  }
}
