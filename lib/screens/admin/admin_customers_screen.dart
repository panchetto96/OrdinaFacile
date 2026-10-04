import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../catalog_import.dart';
import '../../format.dart';
import '../../models.dart';
import '../../repo.dart';
import '../../ui.dart';
import 'send_invoice_screen.dart';

/// Elenco clienti del titolare; da qui si aprono i prezzi riservati di ciascuno.
class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  late final Repo _repo = context.read<Repo>();
  late Future<List<Profile>> _customers = _repo.customers();
  String _query = '';

  void _reload() => setState(() => _customers = _repo.customers());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clienti')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: SearchBar(
            hintText: 'Cerca cliente',
            leading: const Icon(Icons.search),
            elevation: const WidgetStatePropertyAll(0),
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: AsyncView<List<Profile>>(
            future: _customers,
            onRetry: _reload,
            builder: (all) {
              final shown = all
                  .where((c) => _query.isEmpty || '${c.displayName} ${c.username} ${c.address}'.toLowerCase().contains(_query))
                  .toList();
              return RefreshIndicator(
                onRefresh: () async {
                  _reload();
                  await _customers;
                },
                child: shown.isEmpty
                    ? ListView(children: const [
                        Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Nessun cliente registrato'))),
                      ])
                    : ListView.separated(
                        itemCount: shown.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final c = shown[i];
                          return ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.store)),
                            title: Text(c.displayName),
                            subtitle: Text('@${c.username} · ${c.phone}\n${c.address}'),
                            isThreeLine: true,
                            trailing: TextButton.icon(
                              icon: const Icon(Icons.receipt_long),
                              label: const Text('Fattura'),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => SendInvoiceScreen(customer: c)),
                              ),
                            ),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => CustomerPricesScreen(customer: c)),
                            ),
                          );
                        },
                      ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

/// Listino del singolo cliente: per ogni prodotto il prezzo generale e, se c'è, quello riservato.
class CustomerPricesScreen extends StatefulWidget {
  const CustomerPricesScreen({super.key, required this.customer});
  final Profile customer;

  @override
  State<CustomerPricesScreen> createState() => _CustomerPricesScreenState();
}

class _CustomerPricesScreenState extends State<CustomerPricesScreen> {
  late final Repo _repo = context.read<Repo>();
  late Future<(List<Product>, Map<int, double>)> _data = _load();
  String _query = '';
  bool _onlyCustom = false;

  Future<(List<Product>, Map<int, double>)> _load() async {
    final results = await Future.wait([
      _repo.products(onlyAvailable: false),
      _repo.customerPrices(widget.customer.id),
    ]);
    return (results[0] as List<Product>, results[1] as Map<int, double>);
  }

  void _reload() => setState(() => _data = _load());

  Future<void> _edit(Product p, double? current) async {
    final ctrl = TextEditingController(text: current?.toStringAsFixed(2).replaceAll('.', ','));
    // null = annulla, -1 = rimuovi il prezzo riservato, altrimenti nuovo prezzo.
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(p.name),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Prezzo di listino: ${pricePerUnit(p.listPrice, p.unit)}'),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Prezzo per ${widget.customer.displayName}',
              prefixText: '€ ',
              suffixText: '/ ${unitLong(p.unit)}',
            ),
          ),
        ]),
        actions: [
          if (current != null) TextButton(onPressed: () => Navigator.pop(ctx, -1.0), child: const Text('Usa listino')),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          FilledButton(
            onPressed: () {
              final v = parsePrice(ctrl.text);
              if (v != null) Navigator.pop(ctx, v);
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
    if (result == null) return;
    try {
      if (result < 0) {
        await _repo.removeCustomerPrice(widget.customer.id, p.id);
      } else {
        await _repo.setCustomerPrice(widget.customer.id, p.id, result);
      }
      _reload();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    return Scaffold(
      appBar: AppBar(title: Text('Prezzi · ${c.displayName}')),
      body: AsyncView<(List<Product>, Map<int, double>)>(
        future: _data,
        onRetry: _reload,
        builder: (data) {
          final (products, custom) = data;
          final shown = products
              .where((p) => !_onlyCustom || custom.containsKey(p.id))
              .where((p) => _query.isEmpty || p.name.toLowerCase().contains(_query))
              .toList();
          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: SearchBar(
                hintText: 'Cerca prodotto',
                leading: const Icon(Icons.search),
                elevation: const WidgetStatePropertyAll(0),
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              ),
            ),
            SwitchListTile(
              title: Text('Solo prezzi riservati (${custom.length})'),
              value: _onlyCustom,
              onChanged: (v) => setState(() => _onlyCustom = v),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: shown.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final p = shown[i];
                  final special = custom[p.id];
                  return ListTile(
                    title: Text(p.name),
                    subtitle: Text('Listino ${pricePerUnit(p.listPrice, p.unit)}'),
                    trailing: special == null
                        ? const Text('—')
                        : Text(
                            pricePerUnit(special, p.unit),
                            style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                          ),
                    onTap: () => _edit(p, special),
                  );
                },
              ),
            ),
          ]);
        },
      ),
    );
  }
}
