import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

/// Accesso ai dati su Supabase.
class Repo {
  Repo(this.db);
  final SupabaseClient db;

  static const _orderSelect = '*, order_items(*), profiles(*)';

  // --- Account ---------------------------------------------------------------

  /// Accetta email oppure nome utente.
  Future<void> signIn(String login, String password) async {
    var email = login.trim();
    if (!email.contains('@')) {
      final found = await db.rpc('email_for_username', params: {'p_username': email});
      if (found == null) throw const AuthException('Nome utente non trovato');
      email = found as String;
    }
    await db.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required String businessName,
    required String address,
    required String phone,
  }) async {
    await db.auth.signUp(email: email.trim(), password: password, data: {
      'username': username.trim().toLowerCase(),
      'business_name': businessName.trim(),
      'address': address.trim(),
      'phone': phone.trim(),
    });
  }

  Future<void> signOut() => db.auth.signOut();

  Future<Profile> myProfile() async {
    final row = await db.from('profiles').select().eq('id', db.auth.currentUser!.id).single();
    return Profile.fromMap(row);
  }

  Future<void> updateProfile({required String businessName, required String address, required String phone}) async {
    await db.from('profiles').update({
      'business_name': businessName.trim(),
      'address': address.trim(),
      'phone': phone.trim(),
    }).eq('id', db.auth.currentUser!.id);
  }

  // --- Catalogo --------------------------------------------------------------

  Future<List<Product>> products({bool onlyAvailable = true}) async {
    var q = db.from('products').select();
    if (onlyAvailable) q = q.eq('available', true);
    final rows = await q.order('category').order('name');
    return rows.map(Product.fromMap).toList();
  }

  Future<void> saveProduct({
    int? id,
    required String name,
    required String category,
    required double price,
    required String unit,
    required bool available,
  }) async {
    final data = {
      'name': name.trim(),
      'category': category.trim().isEmpty ? 'Altro' : category.trim(),
      'price': price,
      'unit': unit,
      'available': available,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (id == null) {
      await db.from('products').insert(data);
    } else {
      await db.from('products').update(data).eq('id', id);
    }
  }

  Future<void> deleteProduct(int id) => db.from('products').delete().eq('id', id);

  /// Inserisce o aggiorna (per nome) i prodotti importati da file.
  Future<void> upsertProducts(List<Map<String, dynamic>> rows) async {
    final now = DateTime.now().toUtc().toIso8601String();
    for (var i = 0; i < rows.length; i += 500) {
      final chunk = rows.sublist(i, i + 500 > rows.length ? rows.length : i + 500);
      await db.from('products').upsert([for (final r in chunk) {...r, 'updated_at': now}], onConflict: 'name');
    }
  }

  // --- Ordini ----------------------------------------------------------------

  Future<int> placeOrder(Map<int, double> quantities, String note) async {
    final id = await db.rpc('place_order', params: {
      'p_items': [for (final e in quantities.entries) {'product_id': e.key, 'quantity': e.value}],
      'p_note': note.trim(),
    });
    return id as int;
  }

  /// Per il cliente RLS restituisce solo i suoi ordini, per il titolare tutti.
  Future<List<Order>> orders({String? status}) async {
    var q = db.from('orders').select(_orderSelect);
    if (status != null) q = q.eq('status', status);
    final rows = await q.order('created_at', ascending: false).limit(200);
    return rows.map(Order.fromMap).toList();
  }

  /// Notifica ogni modifica alla tabella ordini (per aggiornare la lista del titolare).
  RealtimeChannel watchOrders(void Function() onChange) {
    return db
        .channel('orders-admin')
        .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'orders', callback: (_) => onChange())
        .subscribe();
  }

  Future<void> setOrderStatus(int id, String status) => db.from('orders').update({'status': status}).eq('id', id);
}
