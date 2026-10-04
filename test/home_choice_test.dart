import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordinafacile/screens/customer/home_choice_screen.dart';

void main() {
  testWidgets('la Home mostra i 4 modi di ordinare', (tester) async {
    final tapped = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: HomeChoiceScreen(
        onWrite: () => tapped.add('scrivi'),
        onPhoto: () => tapped.add('foto'),
        onOrderFromList: () => tapped.add('listino'),
        onBrowseList: () => tapped.add('visita'),
      ),
    ));
    for (final label in ['Scrivi ordine', 'Carica foto ordine', 'Aggiungi ordine dal listino prezzi', 'Visita listino prezzi']) {
      await tester.tap(find.text(label));
    }
    expect(tapped, ['scrivi', 'foto', 'listino', 'visita']);
  });
}
