import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Number formatter (comma separated, e.g. 12,345)
final NumberFormat numberFormatter = NumberFormat("#,##0");

/// Currency formatter (₹ by default)
final NumberFormat currencyFormatter = NumberFormat.currency(
  locale: "en_IN",
  symbol: "₹",
  decimalDigits: 0,
);

/// Format kWh unit (electricity unit)
String formatUnits(double value) {
  return "${value.toStringAsFixed(0)} Units";
}

/// Input Formatter - allow only numbers (no decimal)
final List<TextInputFormatter> integerInputFormatter = [
  FilteringTextInputFormatter.digitsOnly,
];

/// Input Formatter - allow decimal numbers
final List<TextInputFormatter> decimalInputFormatter = [
  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
];

/// Format final bill with ₹ symbol
String formatBill(double value) {
  return currencyFormatter.format(value);
}
