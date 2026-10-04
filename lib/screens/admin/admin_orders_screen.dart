import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models.dart';
import '../../repo.dart';
import '../../ui.dart';
import '../order_tile.dart';

/// Ordini in arrivo, aggiornati in tempo reale.
class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  late final Repo _repo = context.read<Repo>();
  late Future<List<Order>> _orders;
  RealtimeChannel? _channel;
  String? _status = 'nuovo';

  @override
  void initState() {
    super.initState();
    _load();
    _channel = _repo.watchOrders(() {
      if (mounted) setState(_load);
    });
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  void _load() => _orders = _repo.orders(status: _status);

  Future<void> _setStatus(Order o, String status) async {
    try {
      await _repo.setOrderStatus(o.id, status);
      if (mounted) setState(_load);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ordini')),
      body: Column(children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            for (final s in [...orderStatuses, null])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(s == null ? 'Tutti' : statusLabel(s)),
                  selected: _status == s,
                  onSelected: (_) => setState(() {
                    _status = s;
                    _load();
                  }),
                ),
              ),
          ]),
        ),
        Expanded(
          child: AsyncView<List<Order>>(
            future: _orders,
            onRetry: () => setState(_load),
            builder: (orders) => RefreshIndicator(
              onRefresh: () async {
                setState(_load);
                await _orders;
              },
              child: orders.isEmpty
                  ? ListView(children: const [
                      Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Nessun ordine'))),
                    ])
                  : ListView(children: [
                      for (final o in orders)
                        OrderTile(
                          order: o,
                          showCustomer: true,
                          footer: Wrap(spacing: 8, children: [
                            for (final s in orderStatuses.where((s) => s != o.status))
                              OutlinedButton(onPressed: () => _setStatus(o, s), child: Text('Segna ${statusLabel(s).toLowerCase()}')),
                          ]),
                        ),
                    ]),
            ),
          ),
        ),
      ]),
    );
  }
}
