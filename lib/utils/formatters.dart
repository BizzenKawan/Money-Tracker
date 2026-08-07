import 'package:intl/intl.dart';

final NumberFormat _whole = NumberFormat('#,##0');
final NumberFormat _withDecimals = NumberFormat('#,##0.##');

/// Formats an amount for display. Hides ".00" on whole numbers, which is how
/// most amounts in this app will look.
String money(double value) {
  if (value == value.roundToDouble()) return _whole.format(value);
  return _withDecimals.format(value);
}

/// Signed version used in transaction rows.
String signedMoney(double value, String type) {
  final prefix = type == 'income' ? '+' : (type == 'expense' ? '-' : '');
  return '$prefix${money(value.abs())}';
}
