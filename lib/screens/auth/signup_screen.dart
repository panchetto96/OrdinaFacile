import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../repo.dart';
import '../../ui.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _business = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  bool _busy = false;

  String? _required(String? v) => (v ?? '').trim().isEmpty ? 'Campo obbligatorio' : null;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<Repo>().signUp(
            email: _email.text,
            password: _password.text,
            username: _username.text,
            businessName: _business.text,
            address: _address.text,
            phone: _phone.text,
          );
      if (!mounted) return;
      if (Supabase.instance.client.auth.currentUser == null) {
        // Conferma email attiva su Supabase: l'utente deve cliccare il link.
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Controlla la tua email'),
            content: Text('Ti abbiamo inviato un link a ${_email.text.trim()}. Aprilo per attivare l\'account, poi accedi.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on PostgrestException catch (e) {
      if (mounted) showError(context, e);
    } on AuthException catch (e) {
      if (!mounted) return;
      // Il trigger rifiuta nomi utente già presi o non validi.
      if (e.message.toLowerCase().contains('database error')) {
        showMessage(context, 'Nome utente già in uso o non valido (3-30 caratteri: lettere, numeri, _ e .)');
      } else {
        showError(context, e);
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrazione')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text('Account', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextFormField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v ?? '').contains('@') ? null : 'Email non valida',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _username,
            decoration: const InputDecoration(labelText: 'Nome utente', helperText: 'Lettere minuscole, numeri, _ e .'),
            validator: (v) => RegExp(r'^[a-z0-9_.]{3,30}$').hasMatch((v ?? '').trim().toLowerCase())
                ? null
                : 'Da 3 a 30 caratteri: lettere, numeri, _ e .',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _password,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
            validator: (v) => (v ?? '').length < 6 ? 'Almeno 6 caratteri' : null,
          ),
          const SizedBox(height: 24),
          Text('Profilo attività', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
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
          const SizedBox(height: 24),
          FilledButton(onPressed: _busy ? null : _submit, child: const Text('Crea account')),
        ]),
      ),
    );
  }
}
