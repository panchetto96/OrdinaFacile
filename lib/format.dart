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
      'lt' => 'lt',
      'ct' => 'ct',
      _ => 'pz',
    };

/// "€ 12,50 / kg"
String pricePerUnit(num price, String unit) => '${euro(price)} / ${unitLong(unit)}';

/// Nome per esteso dell'unità, per i prezzi: "kg", "etto", "litro", "cartone", "pezzo".
String unitLong(String unit) => switch (unit) {
      'kg' => 'kg',
      'etto' => 'etto',
      'lt' => 'litro',
      'ct' => 'cartone',
      _ => 'pezzo',
    };

/// Unità di vendita ammesse, nell'ordine in cui il titolare le sceglie.
const units = ['kg', 'etto', 'pz', 'lt', 'ct'];

/// true per le unità che si ordinano solo a numeri interi.
bool wholeUnit(String unit) => unit == 'pz' || unit == 'ct';
