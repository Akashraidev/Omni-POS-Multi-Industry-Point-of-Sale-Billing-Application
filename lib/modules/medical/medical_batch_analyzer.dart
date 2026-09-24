import '../../data/models/product.dart';
import 'medical_palette.dart';

/// Extracts FEFO batch rows from the product catalog.
///
/// Both the dashboard hero widget and the expiry tracker screen use this so
/// the numbers they show are always computed the same way.
class MedicalBatchAnalyzer {
  MedicalBatchAnalyzer._();

  /// Flattens every product's `batches` metadata into a row with its parsed
  /// expiry date and days remaining. Batches without a parseable expiry are
  /// skipped so the UI never renders bogus dates.
  static List<MedicalBatchRow> extractRows(List<Product> products) {
    final now = DateTime.now();
    final rows = <MedicalBatchRow>[];

    for (final product in products) {
      final batches = product.metadata['batches'] as List?;
      if (batches == null) continue;

      for (final b in batches) {
        final expStr = b['expiry'] as String?;
        if (expStr == null) continue;
        final expDate = DateTime.tryParse(expStr);
        if (expDate == null) continue;

        rows.add(MedicalBatchRow(
          product: product,
          batchNo: (b['batch_no'] as String?) ?? 'N/A',
          expiryDate: expDate,
          daysLeft: expDate.difference(now).inDays,
          qty: (b['qty'] as num?)?.toDouble() ?? product.stockQty,
          mrp: (b['mrp'] as num?)?.toDouble() ?? product.mrp,
        ));
      }
    }

    rows.sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
    return rows;
  }

  /// Count of batches expiring within [days] (negative = already expired).
  static int expiringWithin(List<Product> products, int days) {
    return extractRows(products).where((r) => r.daysLeft <= days).length;
  }

  /// Total batches that are already past their expiry date.
  static int expiredCount(List<Product> products) {
    return extractRows(products).where((r) => r.daysLeft < 0).length;
  }

  /// Products flagged Schedule H / narcotic.
  static int restrictedCount(List<Product> products) {
    return products
        .where((p) =>
            p.metadata['schedule_h'] == true || p.metadata['is_narcotic'] == true)
        .length;
  }

  /// Out-of-stock medicine count for the dashboard alert strip.
  static int outOfStockCount(List<Product> products) {
    return products.where((p) => p.isOutOfStock).length;
  }

  /// Low-stock medicine count (below reorder trigger, still available).
  static int lowStockCount(List<Product> products) {
    return products.where((p) => p.isLowStock && !p.isOutOfStock).length;
  }

  /// Earliest-expiry, in-stock batch for a product — the one FEFO billing
  /// should consume first. Returns null when the product carries no batches.
  static MedicalBatchRow? earliestBatch(Product product) {
    final rows = extractRows([product]);
    if (rows.isEmpty) return null;
    rows.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return rows.first;
  }

  /// FEFO-ordered batches for a single product (nearest expiry first).
  static List<MedicalBatchRow> batchesFor(Product product) {
    final rows = extractRows([product]);
    rows.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return rows;
  }

  /// Condensed expiry snapshot used by POS medicine cards.
  static ProductExpiryInfo? expiryInfo(Product product) {
    final rows = extractRows([product]);
    if (rows.isEmpty) return null;
    rows.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    final nearest = rows.first;
    return ProductExpiryInfo(
      nearestBatch: nearest.batchNo,
      nearestExpiry: nearest.expiryDate,
      daysLeft: nearest.daysLeft,
      severity: nearest.severity,
      batchCount: rows.length,
      expiredBatches: rows.where((r) => r.isExpired).length,
    );
  }
}

/// Compact expiry summary for a single medicine (POS card / quick glance).
class ProductExpiryInfo {
  final String nearestBatch;
  final DateTime nearestExpiry;
  final int daysLeft;
  final ExpirySeverity severity;
  final int batchCount;
  final int expiredBatches;

  const ProductExpiryInfo({
    required this.nearestBatch,
    required this.nearestExpiry,
    required this.daysLeft,
    required this.severity,
    required this.batchCount,
    required this.expiredBatches,
  });

  bool get isCritical => severity == ExpirySeverity.critical;

  bool get isExpired => daysLeft < 0;

  String get daysLabel {
    if (isExpired) return 'Expired ${-daysLeft}d ago';
    if (daysLeft == 0) return 'Expires today';
    if (daysLeft == 1) return 'Expires tomorrow';
    return '$daysLeft days left';
  }
}

/// A single FEFO batch row surfaced to the UI.
class MedicalBatchRow {
  final Product product;
  final String batchNo;
  final DateTime expiryDate;
  final int daysLeft;
  final double qty;
  final double mrp;

  const MedicalBatchRow({
    required this.product,
    required this.batchNo,
    required this.expiryDate,
    required this.daysLeft,
    required this.qty,
    required this.mrp,
  });

  ExpirySeverity get severity => ExpirySeverityX.fromDays(daysLeft);

  bool get isExpired => daysLeft < 0;

  String get daysLabel {
    if (isExpired) return 'Expired ${-daysLeft}d ago';
    if (daysLeft == 0) return 'Expires today';
    if (daysLeft == 1) return 'Expires tomorrow';
    return '$daysLeft days left';
  }
}
