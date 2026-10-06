import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordinafacile/screens/help/manual_screen.dart';
import 'package:ordinafacile/screens/help/tutorial_screen.dart';

void main() {
  testWidgets('tutorial cliente: si scorre fino a Inizia', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TutorialScreen(isAdmin: false)));
    expect(find.text('Benvenuto in OrdinaFacile'), findsOneWidget);
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.text('Avanti'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Serve aiuto?'), findsOneWidget);
    expect(find.text('Inizia'), findsOneWidget);
    expect(find.text('Salta'), findsNothing);
  });

  testWidgets('tutorial titolare: contenuti diversi', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TutorialScreen(isAdmin: true)));
    expect(find.text('Benvenuto, titolare'), findsOneWidget);
  });

  testWidgets('manuale: sezioni per ruolo', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ManualScreen(isAdmin: false)));
    expect(find.text('Scrivere un ordine'), findsOneWidget);
    expect(find.text('Fatture'), findsNothing);
    await tester.pumpWidget(const MaterialApp(home: ManualScreen(isAdmin: true)));
    expect(find.text('Nuovi clienti'), findsOneWidget);
  });
}
