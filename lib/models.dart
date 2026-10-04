class Product {
  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.unit,
    required this.available,
    double? listPrice,
    this.customPrice = false,
  }) : listPrice = listPrice ?? price;

  final int id;
  final String name;
  final String category;
  final double price;
  final String unit; // 'kg' | 'etto' | 'pz' | 'lt' | 'ct'
  final bool available;

  /// Prezzo di listino generale; [price] è quello effettivo per l'utente collegato.
  final double listPrice;

  /// true se il titolare ha fissato un prezzo riservato a questo cliente.
  final bool customPrice;

  /// Passo per i pulsanti +/- del carrello.
  double get step => unit == 'kg' ? 0.5 : 1;

  factory Product.fromMap(Map<String, dynamic> m) => Product(
        id: m['id'] as int,
        name: m['name'] as String,
        category: m['category'] as String,
        price: (m['price'] as num).toDouble(),
        unit: m['unit'] as String,
        available: m['available'] as bool,
        listPrice: (m['list_price'] as num?)?.toDouble(),
        customPrice: m['custom_price'] as bool? ?? false,
      );
}

class Profile {
  Profile({
    required this.id,
    required this.username,
    required this.email,
    required this.businessName,
    required this.address,
    required this.phone,
    required this.role,
  });

  final String id;
  final String username;
  final String email;
  final String businessName;
  final String address;
  final String phone;
  final String role;

  bool get isAdmin => role == 'admin';
  String get displayName => businessName.isNotEmpty ? businessName : username;

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'] as String,
        username: m['username'] as String,
        email: m['email'] as String,
        businessName: m['business_name'] as String? ?? '',
        address: m['address'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        role: m['role'] as String? ?? 'customer',
      );
}

class OrderItem {
  OrderItem({this.productId, required this.productName, required this.unit, required this.unitPrice, required this.quantity});

  /// null se nel frattempo il prodotto è stato eliminato dal catalogo.
  final int? productId;
  final String productName;
  final String unit;
  final double unitPrice;
  final double quantity;

  double get subtotal => unitPrice * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
        productId: m['product_id'] as int?,
        productName: m['product_name'] as String,
        unit: m['unit'] as String,
        unitPrice: (m['unit_price'] as num).toDouble(),
        quantity: (m['quantity'] as num).toDouble(),
      );
}

class Order {
  Order({
    required this.id,
    required this.status,
    required this.note,
    required this.total,
    required this.createdAt,
    required this.items,
    this.body = '',
    this.photoPath,
    this.invoice,
    this.customer,
  });

  final int id;
  final String status;
  final String note;
  final double total;
  final DateTime createdAt;
  final List<OrderItem> items;

  /// Ordine scritto a mano dal cliente (vuoto per gli ordini dal listino).
  final String body;

  /// Foto dell'ordine nello spazio privato `ordini-foto`, se allegata.
  final String? photoPath;

  /// Fattura allegata dal titolare (può coprire più ordini).
  final Invoice? invoice;
  final Profile? customer;

  /// Ordine scritto o con foto: niente righe né totale, il prezzo lo fa il titolare.
  bool get isFree => items.isEmpty && (body.isNotEmpty || photoPath != null);

  factory Order.fromMap(Map<String, dynamic> m) => Order(
        id: m['id'] as int,
        status: m['status'] as String,
        note: m['note'] as String? ?? '',
        total: (m['total'] as num).toDouble(),
        createdAt: DateTime.parse(m['created_at'] as String),
        body: m['body'] as String? ?? '',
        photoPath: m['photo_path'] as String?,
        invoice: m['invoices'] == null ? null : Invoice.fromMap(m['invoices'] as Map<String, dynamic>),
        items: [for (final i in (m['order_items'] as List? ?? [])) OrderItem.fromMap(i as Map<String, dynamic>)],
        customer: m['profiles'] == null ? null : Profile.fromMap(m['profiles'] as Map<String, dynamic>),
      );
}

class Invoice {
  Invoice({required this.id, required this.number, required this.filePath, required this.createdAt});

  final int id;
  final String number;

  /// PDF nello spazio privato `fatture`, cartella del cliente.
  final String filePath;
  final DateTime createdAt;

  String get label => number.isEmpty ? 'Fattura' : 'Fattura n. $number';

  factory Invoice.fromMap(Map<String, dynamic> m) => Invoice(
        id: m['id'] as int,
        number: m['number'] as String? ?? '',
        filePath: m['file_path'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}

const orderStatuses = ['nuovo', 'visto', 'annullato'];

String statusLabel(String s) => switch (s) {
      'nuovo' => 'Nuovo',
      'visto' => 'Visto',
      'annullato' => 'Annullato',
      _ => s,
    };
