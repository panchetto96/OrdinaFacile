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

  void clear() {
    _lines.clear();
    notifyListeners();
  }
}
