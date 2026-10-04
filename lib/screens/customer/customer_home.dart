import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../cart.dart';
import '../../models.dart';
import '../../ui.dart';
import '../profile_screen.dart';
import 'cart_screen.dart';
import 'catalog_screen.dart';
import 'free_order_screen.dart';
import 'home_choice_screen.dart';
import 'my_orders_screen.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key, required this.profile});
  final Profile profile;

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  static const _home = 0, _catalog = 1, _cart = 2, _orders = 3;

  int _tab = _home;

  /// Catalogo con i pulsanti per aggiungere: solo entrando da "Aggiungi ordine dal listino".
  bool _ordering = false;
  final _ordersKey = GlobalKey<MyOrdersScreenState>();

  void _go(int tab, {bool ordering = false}) {
    setState(() {
      _tab = tab;
      _ordering = ordering;
    });
    if (tab == _orders) _ordersKey.currentState?.reload();
  }

  Future<void> _freeOrder({required bool withPhoto}) async {
    final id = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => FreeOrderScreen(withPhoto: withPhoto)),
    );
    if (id == null || !mounted) return;
    showMessage(context, 'Ordine #$id inviato!');
    _go(_orders);
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.select<Cart, int>((c) => c.count);
    return Scaffold(
      body: IndexedStack(index: _tab, children: [
        HomeChoiceScreen(
          onWrite: () => _freeOrder(withPhoto: false),
          onPhoto: () => _freeOrder(withPhoto: true),
          onOrderFromList: () => _go(_catalog, ordering: true),
          onBrowseList: () => _go(_catalog),
        ),
        CatalogScreen(ordering: _ordering, onOpenCart: () => _go(_cart)),
        CartScreen(onOrderSent: () => _go(_orders), onAddMore: () => _go(_catalog, ordering: true)),
        MyOrdersScreen(key: _ordersKey, onReordered: () => _go(_cart)),
        ProfileScreen(profile: widget.profile),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _go,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
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
