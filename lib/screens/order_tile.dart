import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';

/// Ordine espandibile con l'elenco dei prodotti. [trailing] e [footer] per le azioni del titolare.
class OrderTile extends StatelessWidget {
  const OrderTile({super.key, required this.order, this.showCustomer = false, this.footer});

  final Order order;
  final bool showCustomer;
  final Widget? footer;

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
        subtitle: Text('${showCustomer ? '#${order.id} · ' : ''}${dateTime(order.createdAt)} · ${euro(order.total)}'),
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
          for (final i in order.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                Expanded(child: Text(i.productName)),
                Text('${qty(i.quantity)} ${unitShort(i.unit)}'),
                SizedBox(width: 90, child: Text(euro(i.subtotal), textAlign: TextAlign.right)),
              ]),
            ),
          if (order.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Note: ${order.note}', style: const TextStyle(fontStyle: FontStyle.italic)),
          ],
          if (footer != null) ...[const SizedBox(height: 8), footer!],
        ],
      ),
    );
  }
}
