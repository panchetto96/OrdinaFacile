import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../cart.dart';
import '../../format.dart';
import '../../repo.dart';
import '../../ui.dart';
import 'quantity_stepper.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key, required this.onOrderSent});
  final VoidCallback onOrderSent;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _note = TextEditingController();
  bool _busy = false;

  Future<void> _send(Cart cart) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Inviare l\'ordine?'),
        content: Text('${cart.count} prodotti, totale stimato ${euro(cart.total)}.\nIl pagamento si concorda alla consegna.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Invia')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final id = await context.read<Repo>().placeOrder(
            {for (final l in cart.lines) l.product.id: l.quantity},
            _note.text,
          );
      cart.clear();
      _note.clear();
      if (!mounted) return;
      showMessage(context, 'Ordine #$id inviato!');
      widget.onOrderSent();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<Cart>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrello'),
        actions: [
          if (!cart.isEmpty) TextButton(onPressed: cart.clear, child: const Text('Svuota')),
        ],
      ),
      body: cart.isEmpty
          ? const Center(child: Text('Il carrello è vuoto.\nAggiungi prodotti dal catalogo.', textAlign: TextAlign.center))
          : ListView(children: [
              for (final l in cart.lines) ...[
                ListTile(
                  title: Text(l.product.name),
                  subtitle: Text('${pricePerUnit(l.product.price, l.product.unit)} · ${euro(l.subtotal)}'),
                  trailing: QuantityStepper(product: l.product),
                ),
                const Divider(height: 1),
              ],
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _note,
                  decoration: const InputDecoration(labelText: 'Note per il magazzino (opzionale)'),
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
            ]),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Expanded(
                    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Totale stimato'),
                      Text(euro(cart.total), style: Theme.of(context).textTheme.titleLarge),
                    ]),
                  ),
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _send(cart),
                    icon: const Icon(Icons.send),
                    label: const Text('Invia ordine'),
                  ),
                ]),
              ),
            ),
    );
  }
}
