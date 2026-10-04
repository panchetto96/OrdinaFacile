import 'package:intl/intl.dart';

final _euro = NumberFormat.currency(locale: 'it_IT', symbol: '€');
final _qty = NumberFormat('#,##0.##', 'it_IT');
final _date = DateFormat('dd/MM/yyyy HH:mm', 'it_IT');

String euro(num value) => _euro.format(value);
String qty(num value) => _qty.format(value);
String dateTime(DateTime value) => _date.format(value.toLocal());

/// Etichetta breve dell'unità di vendita.
String unitShort(String unit) => switch (unit) {
      'kg' => 'kg',
      'etto' => 'hg',
      _ => 'pz',
    };

/// "€ 12,50 / kg"
String pricePerUnit(num price, String unit) => '${euro(price)} / ${unit == 'etto' ? 'etto' : unitShort(unit)}';
