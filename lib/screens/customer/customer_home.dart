import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../cart.dart';
import '../../models.dart';
import '../profile_screen.dart';
import 'cart_screen.dart';
import 'catalog_screen.dart';
import 'my_orders_screen.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key, required this.profile});
  final Profile profile;

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int _tab = 0;
  final _ordersKey = GlobalKey<MyOrdersScreenState>();

  @override
  Widget build(BuildContext context) {
    final cartCount = context.select<Cart, int>((c) => c.count);
    return Scaffold(
      body: IndexedStack(index: _tab, children: [
        const CatalogScreen(),
        CartScreen(onOrderSent: () {
          setState(() => _tab = 2);
          _ordersKey.currentState?.reload();
        }),
        MyOrdersScreen(key: _ordersKey, onReordered: () => setState(() => _tab = 1)),
        ProfileScreen(profile: widget.profile),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) {
          setState(() => _tab = i);
          if (i == 2) _ordersKey.currentState?.reload();
        },
        destinations: [
          const NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Catalogo'),
          NavigationDestination(
            icon: Badge(isLabelVisible: cartCount > 0, label: Text('$cartCount'), child: const Icon(Icons.shopping_cart_outlined)),
            selectedIcon: Badge(isLabelVisible: cartCount > 0, label: Text('$cartCount'), child: const Icon(Icons.shopping_cart)),
            label: 'Carrello',
          ),
          const NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Ordini'),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profilo'),
        ],
      ),
    );
  }
}
