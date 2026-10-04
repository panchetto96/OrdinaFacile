import 'package:flutter/material.dart';

/// Prima schermata del cliente: quattro pulsanti grandi, uno per modo di ordinare.
class HomeChoiceScreen extends StatelessWidget {
  const HomeChoiceScreen({
    super.key,
    required this.onWrite,
    required this.onPhoto,
    required this.onOrderFromList,
    required this.onBrowseList,
  });

  final VoidCallback onWrite;
  final VoidCallback onPhoto;
  final VoidCallback onOrderFromList;
  final VoidCallback onBrowseList;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Come vuoi ordinare?')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _BigButton(icon: Icons.edit_note, label: 'Scrivi ordine', onPressed: onWrite),
            _BigButton(icon: Icons.photo_camera, label: 'Carica foto ordine', onPressed: onPhoto),
            _BigButton(icon: Icons.add_shopping_cart, label: 'Aggiungi ordine dal listino prezzi', onPressed: onOrderFromList),
            _BigButton(icon: Icons.menu_book, label: 'Visita listino prezzi', onPressed: onBrowseList, tonal: true),
          ]),
        ),
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({required this.icon, required this.label, required this.onPressed, this.tonal = false});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      alignment: Alignment.centerLeft,
    );
    final child = Row(children: [
      Icon(icon, size: 36),
      const SizedBox(width: 16),
      Expanded(child: Text(label)),
    ]);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: tonal
            ? FilledButton.tonal(onPressed: onPressed, style: style, child: child)
            : FilledButton(onPressed: onPressed, style: style, child: child),
      ),
    );
  }
}
