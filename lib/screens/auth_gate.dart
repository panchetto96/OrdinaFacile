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
        builder: (p) => p.isAdmin ? AdminHome(profile: p) : CustomerHome(profile: p),
      ),
    );
  }
}
