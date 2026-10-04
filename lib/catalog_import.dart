import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';

/// Risultato della lettura di un file di catalogo.
class ImportResult {
  ImportResult(this.rows, this.errors);
  final List<Map<String, dynamic>> rows;
  final List<String> errors;
}

/// Legge un catalogo da Excel (.xlsx) o CSV.
///
/// Colonne attese nella prima riga (l'ordine non conta, maiuscole ignorate):
///   nome | categoria | prezzo | unita (kg, etto, pz, lt, ct) | disponibile (opzionale, si/no)
ImportResult parseCatalog(Uint8List bytes, String fileName) {
  final table = fileName.toLowerCase().endsWith('.csv') ? _readCsv(bytes) : _readXlsx(bytes);
  if (table.isEmpty) return ImportResult([], ['Il file è vuoto']);

  final header = [for (final h in table.first) _norm(h)];
  int col(List<String> names) => header.indexWhere(names.contains);
  final iName = col(['nome', 'prodotto', 'descrizione']);
  final iCat = col(['categoria', 'reparto']);
  final iPrice = col(['prezzo', 'prezzo €', 'prezzo eur', 'euro']);
  final iUnit = col(['unita', 'unità', 'um', 'u.m.', 'unita di misura']);
  final iAvail = col(['disponibile', 'disponibilita', 'disponibilità']);

  final missing = [
    if (iName < 0) 'nome',
    if (iPrice < 0) 'prezzo',
    if (iUnit < 0) 'unita',
  ];
  if (missing.isNotEmpty) {
    return ImportResult([], ['Mancano le colonne: ${missing.join(', ')}']);
  }

  final rows = <Map<String, dynamic>>[];
  final errors = <String>[];
  final seen = <String>{};
  for (var r = 1; r < table.length; r++) {
    final line = table[r];
    String cell(int i) => i >= 0 && i < line.length ? line[i].trim() : '';
    final name = cell(iName);
    if (name.isEmpty) continue;

    final price = parsePrice(cell(iPrice));
    final unit = parseUnit(cell(iUnit));
    if (price == null) {
      errors.add('Riga ${r + 1} ($name): prezzo non valido "${cell(iPrice)}"');
      continue;
    }
    if (unit == null) {
      errors.add('Riga ${r + 1} ($name): unità non valida "${cell(iUnit)}" (usa kg, etto, pz, lt o ct)');
      continue;
    }
    if (!seen.add(name.toLowerCase())) {
      errors.add('Riga ${r + 1} ($name): prodotto duplicato, ignorato');
      continue;
    }
    final avail = _norm(cell(iAvail));
    rows.add({
      'name': name,
      'category': cell(iCat).isEmpty ? 'Altro' : cell(iCat),
      'price': price,
      'unit': unit,
      'available': !['no', 'n', '0', 'false', 'esaurito'].contains(avail),
    });
  }
  return ImportResult(rows, errors);
}

/// "12,50", "€ 12.50", "1.234,5" -> numero.
double? parsePrice(String raw) {
  var s = raw.replaceAll(RegExp(r'[€\s]|eur', caseSensitive: false), '');
  if (s.contains(',')) s = s.replaceAll('.', '').replaceAll(',', '.');
  final v = double.tryParse(s);
  return v == null || v < 0 ? null : v;
}

/// "kg", "al kg", "€/kg", "all'etto", "hg", "pezzo", "litro", "cartone" -> unità interna.
String? parseUnit(String raw) {
  final s = _norm(raw).replaceAll(RegExp(r'[^a-z0-9]'), '').replaceFirst(RegExp(r'^(all|al|per|a)'), '');
  return switch (s) {
    'kg' || 'kilo' || 'chilo' || 'kilogrammo' || 'chilogrammo' => 'kg',
    'etto' || 'hg' || 'ettogrammo' || '100g' || '100gr' => 'etto',
    'pz' || 'pezzo' || 'pezzi' || 'cad' || 'conf' || 'confezione' => 'pz',
    'lt' || 'l' || 'litro' || 'litri' => 'lt',
    'ct' || 'cartone' || 'cartoni' => 'ct',
    _ => null,
  };
}

String _norm(String s) => s.trim().toLowerCase();

List<List<String>> _readXlsx(Uint8List bytes) {
  final excel = Excel.decodeBytes(bytes);
  if (excel.tables.isEmpty) return [];
  final sheet = excel.tables.values.first;
  return [
    for (final row in sheet.rows) [for (final c in row) _cellText(c?.value)],
  ];
}

String _cellText(CellValue? v) => switch (v) {
      null => '',
      DoubleCellValue(:final value) => value.toString(),
      IntCellValue(:final value) => value.toString(),
      _ => v.toString(),
    };

/// CSV con separatore ";" o "," (rilevato dalla prima riga) e campi tra virgolette.
List<List<String>> _readCsv(Uint8List bytes) {
  var text = utf8.decode(bytes, allowMalformed: true);
  if (text.startsWith('﻿')) text = text.substring(1);
  final lines = const LineSplitter().convert(text).where((l) => l.trim().isNotEmpty).toList();
  if (lines.isEmpty) return [];
  final sep = lines.first.contains(';') ? ';' : ',';
  return [for (final l in lines) _splitCsvLine(l, sep)];
}

List<String> _splitCsvLine(String line, String sep) {
  final out = <String>[];
  final buf = StringBuffer();
  var quoted = false;
  for (var i = 0; i < line.length; i++) {
    final ch = line[i];
    if (ch == '"') {
      if (quoted && i + 1 < line.length && line[i + 1] == '"') {
        buf.write('"');
        i++;
      } else {
        quoted = !quoted;
      }
    } else if (ch == sep && !quoted) {
      out.add(buf.toString());
      buf.clear();
    } else {
      buf.write(ch);
    }
  }
  out.add(buf.toString());
  return out;
}
