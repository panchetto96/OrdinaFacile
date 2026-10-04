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
  final String unit; // 'kg' | 'etto' | 'pz'
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
  OrderItem({required this.productName, required this.unit, required this.unitPrice, required this.quantity});

  final String productName;
  final String unit;
  final double unitPrice;
  final double quantity;

  double get subtotal => unitPrice * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
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
    this.customer,
  });

  final int id;
  final String status;
  final String note;
  final double total;
  final DateTime createdAt;
  final List<OrderItem> items;
  final Profile? customer;

  factory Order.fromMap(Map<String, dynamic> m) => Order(
        id: m['id'] as int,
        status: m['status'] as String,
        note: m['note'] as String? ?? '',
        total: (m['total'] as num).toDouble(),
        createdAt: DateTime.parse(m['created_at'] as String),
        items: [for (final i in (m['order_items'] as List? ?? [])) OrderItem.fromMap(i as Map<String, dynamic>)],
        customer: m['profiles'] == null ? null : Profile.fromMap(m['profiles'] as Map<String, dynamic>),
      );
}

const orderStatuses = ['nuovo', 'preparato', 'consegnato', 'annullato'];

String statusLabel(String s) => switch (s) {
      'nuovo' => 'Nuovo',
      'preparato' => 'Preparato',
      'consegnato' => 'Consegnato',
      'annullato' => 'Annullato',
      _ => s,
    };
