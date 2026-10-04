import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../cart.dart';
import '../../format.dart';
import '../../models.dart';

/// Pulsanti − quantità + per un prodotto; tocco sulla quantità per scriverla a mano.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({super.key, required this.product});
  final Product product;

  Future<void> _edit(BuildContext context, Cart cart) async {
    final ctrl = TextEditingController(text: cart.quantityOf(product) > 0 ? qty(cart.quantityOf(product)) : '');
    final value = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(product.name),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: 'Quantità', suffixText: unitShort(product.unit)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (value != null) cart.setQuantity(product, product.unit == 'pz' ? value.roundToDouble() : value);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<Cart>();
    final q = cart.quantityOf(product);
    if (q == 0) {
      return FilledButton.tonalIcon(
        onPressed: () => cart.add(product),
        icon: const Icon(Icons.add_shopping_cart, size: 18),
        label: const Text('Aggiungi'),
      );
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton.filledTonal(onPressed: () => cart.remove(product), icon: const Icon(Icons.remove), visualDensity: VisualDensity.compact),
      InkWell(
        onTap: () => _edit(context, cart),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text('${qty(q)} ${unitShort(product.unit)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
      IconButton.filledTonal(onPressed: () => cart.add(product), icon: const Icon(Icons.add), visualDensity: VisualDensity.compact),
    ]);
  }
}
