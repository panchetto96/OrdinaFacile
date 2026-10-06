import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

/// Accesso ai dati su Supabase.
class Repo {
  Repo(this.db);
  final SupabaseClient db;

  static const _orderSelect = '*, order_items(*), profiles(*), invoices(*)';

  // --- Account ---------------------------------------------------------------

  Future<void> signIn(String email, String password) async {
    await db.auth.signInWithPassword(email: email.trim(), password: password);
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

  /// Manda all'email il codice per reimpostare la password (modello email
  /// "Reset Password" di Supabase con {{ .Token }}).
  Future<void> sendPasswordReset(String email) => db.auth.resetPasswordForEmail(email.trim());

  /// Verifica il codice ricevuto (che fa entrare l'utente) e imposta la nuova password.
  Future<void> resetPassword({required String email, required String code, required String password}) async {
    await db.auth.verifyOTP(email: email.trim(), token: code.trim(), type: OtpType.recovery);
    await db.auth.updateUser(UserAttributes(password: password));
  }

  /// Cancella i dati personali del cliente e disattiva l'accesso; ordini e fatture
  /// restano senza dati personali per la contabilità.
  Future<void> deleteMyAccount() async {
    await db.rpc('delete_my_account');
    await db.auth.signOut();
  }

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

  /// [onlyAvailable] = vista cliente: catalogo con i prezzi riservati al cliente collegato.
  /// Altrimenti listino generale completo (per il titolare).
  Future<List<Product>> products({bool onlyAvailable = true}) async {
    var q = db.from(onlyAvailable ? 'my_catalog' : 'products').select();
    if (onlyAvailable) q = q.eq('available', true);
    final rows = await q.order('category', ascending: true).order('name', ascending: true);
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

  // --- Clienti e prezzi riservati --------------------------------------------

  Future<List<Profile>> customers() async {
    final rows = await db.from('profiles').select().eq('role', 'customer').order('business_name', ascending: true);
    return rows.map(Profile.fromMap).toList();
  }

  Future<void> setCustomerApproved(String customerId, bool approved) =>
      db.rpc('set_customer_approved', params: {'p_customer': customerId, 'p_approved': approved});

  /// productId -> prezzo riservato al cliente.
  Future<Map<int, double>> customerPrices(String customerId) async {
    final rows = await db.from('customer_prices').select('product_id, price').eq('customer_id', customerId);
    return {for (final r in rows) r['product_id'] as int: (r['price'] as num).toDouble()};
  }

  Future<void> setCustomerPrice(String customerId, int productId, double price) async {
    await db.from('customer_prices').upsert({
      'customer_id': customerId,
      'product_id': productId,
      'price': price,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> removeCustomerPrice(String customerId, int productId) =>
      db.from('customer_prices').delete().eq('customer_id', customerId).eq('product_id', productId);

  // --- Ordini ----------------------------------------------------------------

  Future<int> placeOrder(Map<int, double> quantities, String note) async {
    final id = await db.rpc('place_order', params: {
      'p_items': [for (final e in quantities.entries) {'product_id': e.key, 'quantity': e.value}],
      'p_note': note.trim(),
    });
    return id as int;
  }

  /// Ordine scritto a mano e/o con foto. La foto va nella cartella del cliente.
  Future<int> placeFreeOrder({String body = '', Uint8List? photo, String photoExt = 'jpg', String note = ''}) async {
    String? path;
    if (photo != null) {
      final ext = photoExt.toLowerCase();
      path = '${db.auth.currentUser!.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await db.storage.from(photoBucket).uploadBinary(path, photo,
          fileOptions: FileOptions(contentType: ext == 'png' ? 'image/png' : ext == 'webp' ? 'image/webp' : ext == 'heic' ? 'image/heic' : 'image/jpeg'));
    }
    final id = await db.rpc('place_free_order', params: {'p_body': body.trim(), 'p_photo_path': path, 'p_note': note.trim()});
    return id as int;
  }

  static const photoBucket = 'ordini-foto';

  /// Link temporaneo per vedere la foto di un ordine.
  Future<String> photoUrl(String path) => db.storage.from(photoBucket).createSignedUrl(path, 3600);

  /// Per il cliente RLS restituisce solo i suoi ordini, per il titolare tutti.
  Future<List<Order>> orders({String? status, String? customerId}) async {
    var q = db.from('orders').select(_orderSelect);
    if (status != null) q = q.eq('status', status);
    if (customerId != null) q = q.eq('customer_id', customerId);
    final rows = await q.order('created_at', ascending: false).limit(200);
    return rows.map(Order.fromMap).toList();
  }

  // --- Fatture ---------------------------------------------------------------

  static const invoiceBucket = 'fatture';

  /// Carica il PDF nella cartella del cliente e lo collega agli ordini scelti.
  Future<void> sendInvoice({required String customerId, required String number, required Uint8List pdf, required List<int> orderIds}) async {
    final path = '$customerId/${DateTime.now().millisecondsSinceEpoch}.pdf';
    await db.storage.from(invoiceBucket).uploadBinary(path, pdf, fileOptions: const FileOptions(contentType: 'application/pdf'));
    try {
      await db.rpc('send_invoice', params: {'p_customer': customerId, 'p_number': number.trim(), 'p_file_path': path, 'p_order_ids': orderIds});
    } catch (_) {
      await db.storage.from(invoiceBucket).remove([path]);
      rethrow;
    }
  }

  /// Link temporaneo per aprire il PDF della fattura.
  Future<String> invoiceUrl(String path) => db.storage.from(invoiceBucket).createSignedUrl(path, 3600);

  /// Notifica ogni modifica alla tabella ordini (per aggiornare la lista del titolare).
  RealtimeChannel watchOrders(void Function() onChange) {
    return db
        .channel('orders-admin')
        .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'orders', callback: (_) => onChange())
        .subscribe();
  }

  Future<void> setOrderStatus(int id, String status) => db.from('orders').update({'status': status}).eq('id', id);
}
