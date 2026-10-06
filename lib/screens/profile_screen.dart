import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../repo.dart';
import '../ui.dart';
import 'help/manual_screen.dart';
import 'help/tutorial_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.profile});
  final Profile profile;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final _business = TextEditingController(text: widget.profile.businessName);
  late final _address = TextEditingController(text: widget.profile.address);
  late final _phone = TextEditingController(text: widget.profile.phone);
  bool _busy = false;

  String? _required(String? v) => (v ?? '').trim().isEmpty ? 'Campo obbligatorio' : null;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<Repo>().updateProfile(businessName: _business.text, address: _address.text, phone: _phone.text);
      if (mounted) showMessage(context, 'Profilo salvato');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminare il tuo account?'),
        content: const Text(
          'Nome attività, indirizzo, telefono ed email verranno cancellati e non potrai più accedere. '
          'Gli ordini e le fatture già fatti restano al magazzino, senza i tuoi dati, perché servono per la contabilità.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<Repo>().deleteMyAccount();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Profilo'), actions: [
        IconButton(tooltip: 'Esci', icon: const Icon(Icons.logout), onPressed: () => context.read<Repo>().signOut()),
      ]),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.store)),
            title: Text('@${p.username}'),
            subtitle: Text(p.email + (p.isAdmin ? ' · titolare' : '')),
          ),
          const SizedBox(height: 16),
          TextFormField(controller: _business, decoration: const InputDecoration(labelText: 'Nome attività'), validator: _required),
          const SizedBox(height: 12),
          TextFormField(controller: _address, decoration: const InputDecoration(labelText: 'Indirizzo di consegna'), validator: _required),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            decoration: const InputDecoration(labelText: 'Telefono'),
            keyboardType: TextInputType.phone,
            validator: _required,
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _busy ? null : _save, child: const Text('Salva')),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TutorialScreen(isAdmin: p.isAdmin))),
            icon: const Icon(Icons.school_outlined),
            label: const Text('Rivedi tutorial'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ManualScreen(isAdmin: p.isAdmin))),
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('Manuale utente'),
          ),
          if (!p.isAdmin) ...[
            const SizedBox(height: 40),
            TextButton.icon(
              onPressed: _busy ? null : _deleteAccount,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Elimina il mio account'),
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            ),
          ],
        ]),
      ),
    );
  }
}
