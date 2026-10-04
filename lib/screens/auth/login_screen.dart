import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../repo.dart';
import '../../ui.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _login = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<Repo>().signIn(_login.text, _password.text);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Image.asset('assets/images/logo.png', height: 160),
                const SizedBox(height: 12),
                Text('OrdinaFacile', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
                Text('Ordini all\'ingrosso, in pochi tocchi', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _login,
                  decoration: const InputDecoration(labelText: 'Email o nome utente'),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.username],
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Campo obbligatorio' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) => (v ?? '').isEmpty ? 'Campo obbligatorio' : null,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Accedi'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignupScreen())),
                  child: const Text('Non hai un account? Registrati'),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
