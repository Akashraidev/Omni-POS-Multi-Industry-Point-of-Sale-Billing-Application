import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount, {String symbol = '₹', int decimalDigits = 2}) {
    final format = NumberFormat.currency(
      symbol: symbol.isNotEmpty ? '$symbol ' : '',
      decimalDigits: decimalDigits,
    );
    return format.format(amount);
  }

  static String compact(double amount, {String symbol = '₹'}) {
    final format = NumberFormat.compact();
    final formatted = format.format(amount);
    return symbol.isNotEmpty ? '$symbol$formatted' : formatted;
  }
}
