import 'package:flutter/foundation.dart';

import 'models.dart';

class CartLine {
  CartLine(this.product, this.quantity);
  final Product product;
  double quantity;
  double get subtotal => product.price * quantity;
}

/// Carrello locale; viene inviato al server con [Repo.placeOrder].
class Cart extends ChangeNotifier {
  final Map<int, CartLine> _lines = {};

  List<CartLine> get lines => _lines.values.toList();
  bool get isEmpty => _lines.isEmpty;
  int get count => _lines.length;
  double get total => _lines.values.fold(0, (s, l) => s + l.subtotal);

  double quantityOf(Product p) => _lines[p.id]?.quantity ?? 0;

  void setQuantity(Product p, double quantity) {
    if (quantity <= 0) {
      _lines.remove(p.id);
    } else {
      _lines.putIfAbsent(p.id, () => CartLine(p, 0)).quantity = quantity;
    }
    notifyListeners();
  }

  void add(Product p) => setQuantity(p, quantityOf(p) + p.step);
  void remove(Product p) => setQuantity(p, quantityOf(p) - p.step);

  /// Rimette nel carrello i prodotti di un ordine passato, ai prezzi di oggi
  /// ([current]: catalogo attuale del cliente, solo prodotti disponibili).
  /// Le quantità sostituiscono quelle già nel carrello per lo stesso prodotto.
  /// Restituisce i nomi dei prodotti non più disponibili.
  List<String> reorder(List<OrderItem> items, Map<int, Product> current) {
    final missing = <String>[];
    for (final item in items) {
      final product = current[item.productId];
      if (product == null) {
        missing.add(item.productName);
      } else {
        _lines.putIfAbsent(product.id, () => CartLine(product, 0)).quantity = item.quantity;
      }
    }
    notifyListeners();
    return missing;
  }

  void clear() {
    _lines.clear();
    notifyListeners();
  }
}
