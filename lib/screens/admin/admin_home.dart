import 'package:flutter/material.dart';

import '../../models.dart';
import '../profile_screen.dart';
import 'admin_catalog_screen.dart';
import 'admin_customers_screen.dart';
import 'admin_orders_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key, required this.profile});
  final Profile profile;

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: [
        const AdminOrdersScreen(),
        const AdminCatalogScreen(),
        const AdminCustomersScreen(),
        ProfileScreen(profile: widget.profile),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.inbox_outlined), selectedIcon: Icon(Icons.inbox), label: 'Ordini'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Catalogo'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Clienti'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profilo'),
        ],
      ),
    );
  }
}
