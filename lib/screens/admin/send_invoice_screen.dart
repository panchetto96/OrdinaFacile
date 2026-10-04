import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../format.dart';
import '../../models.dart';
import '../../repo.dart';
import '../../ui.dart';

/// Il titolare sceglie uno o più ordini del cliente, allega il PDF della fattura
/// (fatto con il suo programma di fatturazione) e la invia: il cliente la apre dai suoi ordini.
class SendInvoiceScreen extends StatefulWidget {
  const SendInvoiceScreen({super.key, required this.customer});
  final Profile customer;

  @override
  State<SendInvoiceScreen> createState() => _SendInvoiceScreenState();
}

class _SendInvoiceScreenState extends State<SendInvoiceScreen> {
  late final Repo _repo = context.read<Repo>();
  late Future<List<Order>> _orders = _load();
  final _selected = <int>{};
  final _number = TextEditingController();
  PlatformFile? _pdf;
  bool _busy = false;

  Future<List<Order>> _load() async {
    final all = await _repo.orders(customerId: widget.customer.id);
    return all.where((o) => o.status != 'annullato').toList();
  }

  Future<void> _pickPdf() async {
    final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (files.isEmpty || !mounted) return;
    setState(() => _pdf = files.first);
  }

  Future<void> _send() async {
    if (_selected.isEmpty) return showMessage(context, 'Scegli almeno un ordine');
    if (_pdf == null) return showMessage(context, 'Allega il PDF della fattura');
    setState(() => _busy = true);
    try {
      await _repo.sendInvoice(
        customerId: widget.customer.id,
        number: _number.text,
        pdf: await _pdf!.xFile.readAsBytes(),
        orderIds: _selected.toList(),
      );
      if (!mounted) return;
      showMessage(context, 'Fattura inviata a ${widget.customer.displayName}');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fattura · ${widget.customer.displayName}')),
      body: AsyncView<List<Order>>(
        future: _orders,
        onRetry: () => setState(() => _orders = _load()),
        builder: (orders) => ListView(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('1. Scegli gli ordini', style: Theme.of(context).textTheme.titleMedium),
          ),
          if (orders.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('Questo cliente non ha ordini.')),
          for (final o in orders)
            CheckboxListTile(
              value: _selected.contains(o.id),
              // Un ordine già fatturato non si riassegna per sbaglio.
              onChanged: o.invoice != null || _busy
                  ? null
                  : (v) => setState(() => v == true ? _selected.add(o.id) : _selected.remove(o.id)),
              title: Text('Ordine #${o.id} · ${dateTime(o.createdAt)}'),
              subtitle: Text(o.invoice?.label ?? (o.isFree ? (o.photoPath != null ? 'Ordine con foto' : 'Ordine scritto') : '${o.items.length} prodotti')),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text('2. Allega la fattura', style: Theme.of(context).textTheme.titleMedium),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              TextField(controller: _number, decoration: const InputDecoration(labelText: 'Numero fattura (opzionale)')),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : _pickPdf,
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(_pdf?.name ?? 'Scegli il PDF'),
              ),
            ]),
          ),
        ]),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _busy ? null : _send,
            icon: const Icon(Icons.send),
            label: Text(_selected.length > 1 ? 'Invia fattura per ${_selected.length} ordini' : 'Invia fattura'),
          ),
        ),
      ),
    );
  }
}
