import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../format.dart';
import '../../models.dart';
import '../../repo.dart';
import '../../ui.dart';
import 'quantity_stepper.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late Future<List<Product>> _products;
  String _query = '';
  String? _category;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _products = context.read<Repo>().products();

  Future<void> _refresh() async {
    setState(_load);
    await _products;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalogo'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SearchBar(
              hintText: 'Cerca un prodotto',
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
        ),
      ),
      body: AsyncView<List<Product>>(
        future: _products,
        onRetry: () => setState(_load),
        builder: (all) {
          final categories = {for (final p in all) p.category}.toList()..sort();
          final shown = all
              .where((p) => _category == null || p.category == _category)
              .where((p) => _query.isEmpty || p.name.toLowerCase().contains(_query) || p.category.toLowerCase().contains(_query))
              .toList();
          return Column(children: [
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  _chip('Tutti', null),
                  for (final c in categories) _chip(c, c),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: shown.isEmpty
                    ? ListView(children: const [
                        Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Nessun prodotto trovato'))),
                      ])
                    : ListView.separated(
                        itemCount: shown.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final p = shown[i];
                          return ListTile(
                            title: Text(p.name),
                            subtitle: Text.rich(TextSpan(children: [
                              TextSpan(text: '${p.category} · ${pricePerUnit(p.price, p.unit)}'),
                              if (p.customPrice && p.price < p.listPrice)
                                TextSpan(
                                  text: '  ${euro(p.listPrice)}',
                                  style: const TextStyle(decoration: TextDecoration.lineThrough),
                                ),
                              if (p.customPrice)
                                TextSpan(
                                  text: '\nPrezzo riservato a te',
                                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
                                ),
                            ])),
                            trailing: QuantityStepper(product: p),
                          );
                        },
                      ),
              ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _chip(String label, String? value) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: _category == value,
          onSelected: (_) => setState(() => _category = value),
        ),
      );
}
