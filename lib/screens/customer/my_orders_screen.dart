import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models.dart';
import '../../repo.dart';
import '../../ui.dart';
import '../order_tile.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => MyOrdersScreenState();
}

class MyOrdersScreenState extends State<MyOrdersScreen> {
  late Future<List<Order>> _orders = context.read<Repo>().orders();

  void reload() => setState(() => _orders = context.read<Repo>().orders());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('I miei ordini')),
      body: AsyncView<List<Order>>(
        future: _orders,
        onRetry: reload,
        builder: (orders) => RefreshIndicator(
          onRefresh: () async {
            reload();
            await _orders;
          },
          child: orders.isEmpty
              ? ListView(children: const [
                  Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Non hai ancora inviato ordini'))),
                ])
              : ListView(padding: const EdgeInsets.symmetric(vertical: 6), children: [
                  for (final o in orders) OrderTile(order: o),
                ]),
        ),
      ),
    );
  }
}
