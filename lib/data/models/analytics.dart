/// One bucket in a time-series trend (sales / purchases / profit).
class TrendPoint {
  final DateTime date;
  final double value;

  const TrendPoint({required this.date, required this.value});

  /// Short day label, e.g. "Mon 12".
  String get shortLabel {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[date.weekday - 1]} ${date.day}';
  }
}

/// Payment-method collection bucket for a single trading day.
class CollectionBucket {
  final String method;
  final double amount;
  final int count;

  const CollectionBucket({
    required this.method,
    required this.amount,
    required this.count,
  });
}

/// Aggregated trading-day KPIs computed by a single efficient SQL pass.
class DayAggregates {
  final double revenue;
  final double cost;
  final double profit;
  final double profitMargin;
  final double discount;
  final double tax;
  final int invoiceCount;
  final int returnCount;
  final double returnsTotal;
  final List<CollectionBucket> collections;

  const DayAggregates({
    required this.revenue,
    required this.cost,
    required this.profit,
    required this.profitMargin,
    required this.discount,
    required this.tax,
    required this.invoiceCount,
    required this.returnCount,
    required this.returnsTotal,
    required this.collections,
  });

  double collectionFor(String method) {
    for (final b in collections) {
      if (b.method == method) return b.amount;
    }
    return 0.0;
  }

  int collectionCountFor(String method) {
    for (final b in collections) {
      if (b.method == method) return b.count;
    }
    return 0;
  }

  static DayAggregates empty() => const DayAggregates(
        revenue: 0,
        cost: 0,
        profit: 0,
        profitMargin: 0,
        discount: 0,
        tax: 0,
        invoiceCount: 0,
        returnCount: 0,
        returnsTotal: 0,
        collections: [],
      );
}
