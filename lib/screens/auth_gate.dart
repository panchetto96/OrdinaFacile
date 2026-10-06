import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../cart.dart';
import '../models.dart';
import '../repo.dart';
import '../ui.dart';
import 'admin/admin_home.dart';
import 'auth/login_screen.dart';
import 'customer/customer_home.dart';
import 'help/tutorial_screen.dart';

/// Mostra il login o la home giusta (cliente / titolare) in base alla sessione.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, _) {
        final user = auth.currentUser;
        if (user == null) return const LoginScreen();
        return _RoleRouter(key: ValueKey(user.id));
      },
    );
  }
}

class _RoleRouter extends StatefulWidget {
  const _RoleRouter({super.key});

  @override
  State<_RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<_RoleRouter> {
  late Future<Profile> _profile;

  @override
  void initState() {
    super.initState();
    final cart = context.read<Cart>();
    WidgetsBinding.instance.addPostFrameCallback((_) => cart.clear());
    _profile = context.read<Repo>().myProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AsyncView<Profile>(
        future: _profile,
        onRetry: () => setState(() => _profile = context.read<Repo>().myProfile()),
        builder: (p) => p.isAdmin
            ? _WithTutorial(isAdmin: true, child: AdminHome(profile: p))
            : p.approved
                ? _WithTutorial(isAdmin: false, child: CustomerHome(profile: p))
                : _PendingApproval(onRetry: () => setState(() => _profile = context.read<Repo>().myProfile())),
      ),
    );
  }
}

/// Al primo ingresso di quel ruolo su questo telefono apre il tutorial.
class _WithTutorial extends StatefulWidget {
  const _WithTutorial({required this.isAdmin, required this.child});
  final bool isAdmin;
  final Widget child;

  @override
  State<_WithTutorial> createState() => _WithTutorialState();
}

class _WithTutorialState extends State<_WithTutorial> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) TutorialScreen.showIfFirstTime(context, isAdmin: widget.isAdmin);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Cliente appena registrato: niente prezzi né ordini finché il titolare non lo abilita.
class _PendingApproval extends StatelessWidget {
  const _PendingApproval({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Icon(Icons.hourglass_top, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text('In attesa di approvazione', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          const Text(
            'Il tuo account è stato creato. Appena il magazzino lo abilita potrai vedere il listino e mandare ordini.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Controlla di nuovo')),
          const SizedBox(height: 8),
          TextButton(onPressed: () => context.read<Repo>().signOut(), child: const Text('Esci')),
        ]),
      ),
    );
  }
}
