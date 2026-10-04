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
      if (!mounted) return;
      setState(_load);
      showMessage(context, 'Ordine #${o.id}: ${statusLabel(status).toLowerCase()}. Lo trovi in "${_filterLabel(status)}".');
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _cancel(Order o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Annullare l\'ordine #${o.id}?'),
        content: const Text('Potrai riaprirlo dalla scheda Annullati.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Annulla ordine')),
        ],
      ),
    );
    if (ok == true) await _setStatus(o, 'annullato');
  }

  /// Etichetta del filtro in cui finisce un ordine con questo stato.
  static String _filterLabel(String status) => switch (status) {
        'nuovo' => 'Da preparare',
        'preparato' => 'Da consegnare',
        'consegnato' => 'Consegnati',
        _ => 'Annullati',
      };

  /// Azioni per lo stato attuale: il passo successivo in evidenza, poi annulla o riapri.
  Widget _actions(Order o) {
    final next = switch (o.status) {
      'nuovo' => 'preparato',
      'preparato' => 'consegnato',
      _ => null,
    };
    return Wrap(spacing: 8, runSpacing: 4, alignment: WrapAlignment.end, children: [
      if (next == null)
        TextButton.icon(
          onPressed: () => _setStatus(o, 'nuovo'),
          icon: const Icon(Icons.undo),
          label: const Text('Riapri'),
        )
      else ...[
        TextButton(onPressed: () => _cancel(o), child: const Text('Annulla ordine')),
        FilledButton.icon(
          onPressed: () => _setStatus(o, next),
          icon: const Icon(Icons.check),
          label: Text(next == 'preparato' ? 'Preparato' : 'Consegnato'),
        ),
      ],
    ]);
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
                  label: Text(s == null ? 'Tutti' : _filterLabel(s)),
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
                          footer: _actions(o),
                        ),
                    ]),
            ),
          ),
        ),
      ]),
    );
  }
}
