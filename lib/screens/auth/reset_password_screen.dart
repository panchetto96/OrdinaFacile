import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../repo.dart';
import '../../ui.dart';

/// Password dimenticata: 1) email → arriva un codice, 2) codice + nuova password.
/// Con il codice l'utente entra direttamente, senza link da aprire nel browser.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.email = ''});
  final String email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email.trim());
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;

  Future<void> _sendCode() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<Repo>().sendPasswordReset(_email.text);
      if (!mounted) return;
      setState(() => _codeSent = true);
      showMessage(context, 'Ti abbiamo mandato un codice via email');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<Repo>().resetPassword(email: _email.text, code: _code.text, password: _password.text);
      if (!mounted) return;
      showMessage(context, 'Password cambiata');
      // Dopo il codice l'utente è già dentro: si torna alla schermata principale.
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Password dimenticata')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(24), children: [
          Text(
            _codeSent
                ? 'Scrivi il codice che hai ricevuto via email e scegli una nuova password. Se non lo trovi, guarda nella posta indesiderata.'
                : 'Scrivi l\'email del tuo account: ti mandiamo un codice per scegliere una nuova password.',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _email,
            enabled: !_codeSent,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v ?? '').contains('@') ? null : 'Inserisci la tua email',
          ),
          if (_codeSent) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _code,
              decoration: const InputDecoration(labelText: 'Codice ricevuto'),
              keyboardType: TextInputType.number,
              validator: (v) => RegExp(r'^\d{6,10}$').hasMatch((v ?? '').trim()) ? null : 'Scrivi il codice di 6 cifre',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              decoration: const InputDecoration(labelText: 'Nuova password'),
              obscureText: true,
              validator: (v) => (v ?? '').length < 6 ? 'Almeno 6 caratteri' : null,
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : (_codeSent ? _reset : _sendCode),
            child: Text(_codeSent ? 'Cambia password' : 'Mandami il codice'),
          ),
          if (_codeSent)
            TextButton(
              onPressed: _busy ? null : _sendCode,
              child: const Text('Non è arrivato? Manda di nuovo'),
            ),
        ]),
      ),
    );
  }
}
