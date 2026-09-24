import 'package:intl/intl.dart';

class DateFormatter {
  static String formatShort(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatWithTime(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  static String formatTimeOnly(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  static String formatIsoDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String daysUntil(DateTime targetDate) {
    final diff = targetDate.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Expired ${-diff} days ago';
    if (diff == 0) return 'Expires today';
    if (diff == 1) return 'Expires tomorrow';
    return 'Expires in $diff days';
  }
}
