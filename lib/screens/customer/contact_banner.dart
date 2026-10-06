import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config.dart';

/// Pulsante in cima al listino: i clienti non vedono i prezzi, quindi per
/// info e prezzi chiamano o scrivono al magazzino.
class ContactBanner extends StatelessWidget {
  const ContactBanner({super.key});

  Future<void> _open(BuildContext context, Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossibile aprire il contatto')));
    }
  }

  void _show(BuildContext context) {
    String digits(String n) => n.replaceAll(' ', '');
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Per info e prezzi contattaci', style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.smartphone),
            title: const Text('Chiama il cellulare'),
            subtitle: const Text(contactMobile),
            onTap: () => _open(context, Uri(scheme: 'tel', path: digits(contactMobile))),
          ),
          ListTile(
            leading: const Icon(Icons.phone),
            title: const Text('Chiama l\'ufficio'),
            subtitle: const Text(contactPhone),
            onTap: () => _open(context, Uri(scheme: 'tel', path: digits(contactPhone))),
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Scrivi una email'),
            subtitle: const Text(contactEmail),
            onTap: () => _open(context, Uri(scheme: 'mailto', path: contactEmail)),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton.icon(
          onPressed: () => _show(context),
          icon: const Icon(Icons.support_agent),
          label: const Text('Per info e prezzi contattaci', style: TextStyle(fontSize: 17)),
        ),
      ),
    );
  }
}
