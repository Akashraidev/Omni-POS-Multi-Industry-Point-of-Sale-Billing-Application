import 'package:flutter/material.dart';
import '../data/models/product.dart';
import '../data/models/sale.dart';

class ReportsProvider extends ChangeNotifier {
  String _selectedPeriod = '30 Days'; // 'Today', '7 Days', '30 Days', 'This Month'

  String get selectedPeriod => _selectedPeriod;

  void setPeriod(String period) {
    _selectedPeriod = period;
    notifyListeners();
  }

  // Generate 7-day sales trend points
  List<double> getSalesTrend(List<Sale> sales) {
    final now = DateTime.now();
    final List<double> dailyTotals = List.filled(7, 0.0);

    for (int i = 0; i < 7; i++) {
      final targetDate = now.subtract(Duration(days: 6 - i));
      final daySales = sales.where((s) {
        return s.status == 'Completed' &&
            s.createdAt.year == targetDate.year &&
            s.createdAt.month == targetDate.month &&
            s.createdAt.day == targetDate.day;
      });
      dailyTotals[i] = daySales.fold(0.0, (sum, s) => sum + s.finalTotal);
    }
    return dailyTotals;
  }

  // Top products sales count
  Map<String, int> getTopProducts(List<Sale> sales) {
    final Map<String, int> productCounts = {};
    for (final s in sales) {
      if (s.status == 'Completed') {
        for (final it in s.items) {
          productCounts[it.productName] = (productCounts[it.productName] ?? 0) + it.quantity.round();
        }
      }
    }
    // Return top 5
    final sorted = productCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(5));
  }

  // Category-wise revenue
  Map<String, double> getCategoryRevenue(List<Sale> sales, List<Product> products) {
    final Map<String, double> categoryRev = {};
    final Map<String, String> prodToCat = {};

    for (final p in products) {
      prodToCat[p.id] = p.categoryId;
    }

    for (final s in sales) {
      if (s.status == 'Completed') {
        for (final it in s.items) {
          final cat = prodToCat[it.productId] ?? 'General';
          final cleanCat = cat.replaceFirst('cat_', '').split('_').first.toUpperCase();
          categoryRev[cleanCat] = (categoryRev[cleanCat] ?? 0.0) + it.lineTotal;
        }
      }
    }
    return categoryRev;
  }

  // Export report to CSV
  String generateCsvReport(List<Sale> sales) {
    final buffer = StringBuffer();
    buffer.writeln('Invoice No,Date,Customer,Order Type,Payment Method,Subtotal,Tax,Discount,Final Total,Status');

    for (final s in sales) {
      buffer.writeln(
        '${s.invoiceNo},${s.createdAt.toIso8601String().substring(0, 10)},"${s.customerName ?? 'Walk-in'}","${s.orderType ?? 'Counter'}","${s.paymentMethod}",${s.subtotal},${s.taxAmount},${s.discountAmount},${s.finalTotal},"${s.status}"',
      );
    }
    return buffer.toString();
  }
}
