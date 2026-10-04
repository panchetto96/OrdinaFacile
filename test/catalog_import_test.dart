import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listcheck/cart.dart';
import 'package:listcheck/catalog_import.dart';
import 'package:listcheck/models.dart';

Uint8List csv(String s) => Uint8List.fromList(utf8.encode(s));

void main() {
  test('prezzi in formato italiano', () {
    expect(parsePrice('12,50'), 12.5);
    expect(parsePrice('€ 1.234,5'), 1234.5);
    expect(parsePrice('3.20'), 3.2);
    expect(parsePrice('abc'), isNull);
  });

  test('unità', () {
    expect(parseUnit('al kg'), 'kg');
    expect(parseUnit('€/kg'), 'kg');
    expect(parseUnit("all'etto"), 'etto');
    expect(parseUnit('hg'), 'etto');
    expect(parseUnit('Pezzo'), 'pz');
    expect(parseUnit('litro'), isNull);
  });

  test('CSV con punto e virgola, virgolette e righe errate', () {
    final r = parseCatalog(
      csv('﻿Nome;Categoria;Prezzo;Unità;Disponibile\n'
          '"Prosciutto crudo; Parma";Salumi;"2,80";etto;si\n'
          'Parmigiano 24 mesi;Formaggi;18,90;kg;\n'
          'Olio;Dispensa;??;kg;\n'
          'Mozzarella;Latticini;9;kg;no\n'),
      'catalogo.csv',
    );
    expect(r.rows.length, 3);
    expect(r.rows[0], {'name': 'Prosciutto crudo; Parma', 'category': 'Salumi', 'price': 2.8, 'unit': 'etto', 'available': true});
    expect(r.rows[2]['available'], false);
    expect(r.errors.single, contains('Olio'));
  });

  test('colonne mancanti', () {
    final r = parseCatalog(csv('nome,categoria\nPane,Forno\n'), 'x.csv');
    expect(r.rows, isEmpty);
    expect(r.errors.single, contains('prezzo'));
  });

  test('Excel', () {
    final excel = Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet()!];
    sheet.appendRow([TextCellValue('nome'), TextCellValue('categoria'), TextCellValue('prezzo'), TextCellValue('unita')]);
    sheet.appendRow([TextCellValue('Salame'), TextCellValue('Salumi'), DoubleCellValue(2.5), TextCellValue('etto')]);
    sheet.appendRow([TextCellValue('Uova'), TextCellValue('Altro'), IntCellValue(3), TextCellValue('pz')]);
    final r = parseCatalog(Uint8List.fromList(excel.encode()!), 'catalogo.xlsx');
    expect(r.errors, isEmpty);
    expect(r.rows.map((e) => e['price']), [2.5, 3.0]);
  });

  test('carrello: passi per kg e pezzi', () {
    final kg = Product(id: 1, name: 'Formaggio', category: 'F', price: 10, unit: 'kg', available: true);
    final pz = Product(id: 2, name: 'Uova', category: 'A', price: 0.5, unit: 'pz', available: true);
    final cart = Cart()
      ..add(kg)
      ..add(kg)
      ..add(pz)
      ..remove(pz);
    expect(cart.quantityOf(kg), 1.0);
    expect(cart.count, 1);
    expect(cart.total, 10);
  });
}
