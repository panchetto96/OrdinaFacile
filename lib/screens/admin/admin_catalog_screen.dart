import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../catalog_import.dart';
import '../../format.dart';
import '../../models.dart';
import '../../repo.dart';
import '../../ui.dart';

/// Gestione catalogo del titolare: import da Excel/CSV e modifica dei singoli prodotti.
class AdminCatalogScreen extends StatefulWidget {
  const AdminCatalogScreen({super.key});

  @override
  State<AdminCatalogScreen> createState() => _AdminCatalogScreenState();
}

class _AdminCatalogScreenState extends State<AdminCatalogScreen> {
  late final Repo _repo = context.read<Repo>();
  late Future<List<Product>> _products;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _products = _repo.products(onlyAvailable: false);

  Future<void> _import() async {
    final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx', 'csv']);
    if (files.isEmpty || !mounted) return;
    final file = files.first;
    final ImportResult result;
    try {
      result = parseCatalog(await file.xFile.readAsBytes(), file.name);
    } catch (e) {
      if (mounted) showMessage(context, 'Impossibile leggere il file. Usa un file Excel (.xlsx) o CSV.');
      return;
    }
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importa catalogo'),
        content: SingleChildScrollView(
          child: Text([
            '${result.rows.length} prodotti pronti da caricare. I prodotti con lo stesso nome vengono aggiornati, gli altri restano invariati.',
            if (result.errors.isNotEmpty) '\n${result.errors.length} righe saltate:\n${result.errors.take(20).join('\n')}',
          ].join('\n')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          if (result.rows.isNotEmpty) FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Importa')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repo.upsertProducts(result.rows);
      if (!mounted) return;
      showMessage(context, 'Catalogo aggiornato: ${result.rows.length} prodotti');
      setState(_load);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _edit([Product? p]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProductForm(repo: _repo, product: p),
    );
    if (saved == true && mounted) setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalogo'),
        actions: [
          IconButton(tooltip: 'Formato del file', icon: const Icon(Icons.help_outline), onPressed: _showHelp),
          IconButton(tooltip: 'Importa da Excel/CSV', icon: const Icon(Icons.upload_file), onPressed: _import),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('Prodotto'),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: SearchBar(
            hintText: 'Cerca',
            leading: const Icon(Icons.search),
            elevation: const WidgetStatePropertyAll(0),
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: AsyncView<List<Product>>(
            future: _products,
            onRetry: () => setState(_load),
            builder: (all) {
              final shown = all.where((p) => _query.isEmpty || p.name.toLowerCase().contains(_query)).toList();
              if (all.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Il catalogo è vuoto. Importa un file Excel/CSV con il pulsante in alto o aggiungi un prodotto.',
                        textAlign: TextAlign.center),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: shown.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final p = shown[i];
                  return ListTile(
                    title: Text(p.name, style: p.available ? null : const TextStyle(decoration: TextDecoration.lineThrough)),
                    subtitle: Text('${p.category} · ${pricePerUnit(p.price, p.unit)}${p.available ? '' : ' · esaurito'}'),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => _edit(p),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Formato del file'),
        content: const Text(
          'Usa un file Excel (.xlsx) o CSV con queste colonne nella prima riga:\n\n'
          '• nome\n• categoria\n• prezzo (es. 12,50)\n• unita: kg, etto o pz\n• disponibile (opzionale: si/no)\n\n'
          'Ogni importazione aggiorna i prodotti con lo stesso nome e aggiunge quelli nuovi.',
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }
}

class _ProductForm extends StatefulWidget {
  const _ProductForm({required this.repo, this.product});
  final Repo repo;
  final Product? product;

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.product?.name);
  late final _category = TextEditingController(text: widget.product?.category);
  late final _price = TextEditingController(text: widget.product == null ? '' : widget.product!.price.toStringAsFixed(2).replaceAll('.', ','));
  late String _unit = widget.product?.unit ?? 'kg';
  late bool _available = widget.product?.available ?? true;
  bool _busy = false;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await widget.repo.saveProduct(
        id: widget.product?.id,
        name: _name.text,
        category: _category.text,
        price: parsePrice(_price.text)!,
        unit: _unit,
        available: _available,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminare il prodotto?'),
        content: const Text('Gli ordini già inviati non vengono modificati.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Elimina')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.repo.deleteProduct(widget.product!.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(widget.product == null ? 'Nuovo prodotto' : 'Modifica prodotto', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nome'),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Campo obbligatorio' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _category, decoration: const InputDecoration(labelText: 'Categoria')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _price,
                decoration: const InputDecoration(labelText: 'Prezzo', prefixText: '€ '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => parsePrice(v ?? '') == null ? 'Prezzo non valido' : null,
              ),
            ),
            const SizedBox(width: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'kg', label: Text('kg')),
                ButtonSegment(value: 'etto', label: Text('etto')),
                ButtonSegment(value: 'pz', label: Text('pz')),
              ],
              selected: {_unit},
              onSelectionChanged: (s) => setState(() => _unit = s.first),
            ),
          ]),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Disponibile'),
            value: _available,
            onChanged: (v) => setState(() => _available = v),
          ),
          const SizedBox(height: 8),
          Row(children: [
            if (widget.product != null) TextButton(onPressed: _delete, child: const Text('Elimina')),
            const Spacer(),
            FilledButton(onPressed: _busy ? null : _save, child: const Text('Salva')),
          ]),
        ]),
      ),
    );
  }
}
