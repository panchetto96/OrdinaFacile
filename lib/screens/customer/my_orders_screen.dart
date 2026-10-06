import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../cart.dart';
import '../../models.dart';
import '../../repo.dart';
import '../../ui.dart';
import '../order_tile.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key, required this.onReordered});

  /// Chiamato dopo "Riordina", per portare il cliente al carrello.
  final VoidCallback onReordered;

  @override
  State<MyOrdersScreen> createState() => MyOrdersScreenState();
}

class MyOrdersScreenState extends State<MyOrdersScreen> {
  late Future<List<Order>> _orders = context.read<Repo>().orders();

  void reload() => setState(() => _orders = context.read<Repo>().orders());

  Future<void> _reorder(Order order) async {
    final cart = context.read<Cart>();
    try {
      final products = await context.read<Repo>().products();
      final missing = cart.reorder(order.items, {for (final p in products) p.id: p});
      if (!mounted) return;
      widget.onReordered();
      showMessage(
        context,
        missing.isEmpty
            ? 'Prodotti dell\'ordine #${order.id} aggiunti al carrello'
            : 'Aggiunti al carrello. Non più disponibili: ${missing.join(', ')}',
      );
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('I miei ordini')),
      body: AsyncView<List<Order>>(
        future: _orders,
        onRetry: reload,
        builder: (orders) => RefreshIndicator(
          onRefresh: () async {
            reload();
            await _orders;
          },
          child: orders.isEmpty
              ? ListView(children: const [
                  Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Non hai ancora inviato ordini'))),
                ])
              : ListView(padding: const EdgeInsets.symmetric(vertical: 6), children: [
                  for (final o in orders)
                    OrderTile(
                      order: o,
                      footer: o.isFree ? null : Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.tonalIcon(
                          onPressed: () => _reorder(o),
                          icon: const Icon(Icons.replay),
                          label: const Text('Riordina'),
                        ),
                      ),
                    ),
                ]),
        ),
      ),
    );
  }
}
