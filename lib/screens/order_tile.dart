import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../format.dart';
import '../models.dart';
import '../repo.dart';
import '../ui.dart';

/// Ordine espandibile con l'elenco dei prodotti. [trailing] e [footer] per le azioni del titolare.
class OrderTile extends StatelessWidget {
  const OrderTile({super.key, required this.order, this.showCustomer = false, this.footer});

  final Order order;
  final bool showCustomer;
  final Widget? footer;

  String get _freeLabel => order.photoPath != null ? 'Ordine con foto' : 'Ordine scritto';

  @override
  Widget build(BuildContext context) {
    final c = order.customer;
    final scheme = Theme.of(context).colorScheme;
    final statusColor = switch (order.status) {
      'nuovo' => scheme.primary,
      'annullato' => scheme.error,
      _ => scheme.outline,
    };
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        shape: const Border(),
        title: Text(showCustomer && c != null ? c.displayName : 'Ordine #${order.id}'),
        subtitle: Text('${showCustomer ? '#${order.id} · ' : ''}${dateTime(order.createdAt)} · ${order.isFree ? _freeLabel : '${order.items.length} prodotti'}'),
        trailing: Chip(
          label: Text(statusLabel(order.status)),
          labelStyle: TextStyle(color: statusColor),
          side: BorderSide(color: statusColor),
          visualDensity: VisualDensity.compact,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showCustomer && c != null) ...[
            Text('${c.address}\nTel. ${c.phone}'),
            const SizedBox(height: 8),
          ],
          if (order.body.isNotEmpty) ...[
            SelectableText(order.body, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
          ],
          if (order.photoPath != null) _OrderPhoto(path: order.photoPath!),
          for (final i in order.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                Expanded(child: Text(i.productName)),
                Text('${qty(i.quantity)} ${unitShort(i.unit)}'),
                // Il prezzo lo vede solo il titolare.
                if (showCustomer) SizedBox(width: 100, child: Text(pricePerUnit(i.unitPrice, i.unit), textAlign: TextAlign.right)),
              ]),
            ),
          if (order.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Note: ${order.note}', style: const TextStyle(fontStyle: FontStyle.italic)),
          ],
          if (order.invoice != null) ...[
            const SizedBox(height: 8),
            InvoiceButton(invoice: order.invoice!),
          ],
          if (footer != null) ...[const SizedBox(height: 8), footer!],
        ],
      ),
    );
  }
}

/// Apre il PDF della fattura nel browser o nel lettore PDF del telefono.
class InvoiceButton extends StatelessWidget {
  const InvoiceButton({super.key, required this.invoice});
  final Invoice invoice;

  Future<void> _open(BuildContext context) async {
    try {
      final url = await context.read<Repo>().invoiceUrl(invoice.filePath);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _open(context),
      icon: const Icon(Icons.picture_as_pdf),
      label: Text(invoice.label),
    );
  }
}

/// Anteprima della foto dell'ordine; toccandola si apre a schermo intero con lo zoom.
class _OrderPhoto extends StatefulWidget {
  const _OrderPhoto({required this.path});
  final String path;

  @override
  State<_OrderPhoto> createState() => _OrderPhotoState();
}

class _OrderPhotoState extends State<_OrderPhoto> {
  late final Future<String> _url = context.read<Repo>().photoUrl(widget.path);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _url,
      builder: (context, snap) {
        if (snap.hasError) return const Text('Foto non disponibile');
        if (!snap.hasData) return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
        final url = snap.data!;
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _FullPhoto(url: url))),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(url, height: 240, width: double.infinity, fit: BoxFit.cover),
          ),
        );
      },
    );
  }
}

class _FullPhoto extends StatelessWidget {
  const _FullPhoto({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: InteractiveViewer(maxScale: 5, child: Center(child: Image.network(url))),
    );
  }
}
