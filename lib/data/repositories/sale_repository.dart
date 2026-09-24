import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_tables.dart';
import '../models/analytics.dart';
import '../models/sale.dart';

class SaleRepository {
  final AppDatabase _db = AppDatabase.instance;
  final Uuid _uuid = const Uuid();

  /// ISO day string (yyyy-MM-dd) used for day-scoped aggregate queries.
  static String _dayArg(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Daily revenue + invoice count for the last [days] trading days ending at
  /// [endDate]. One grouped query instead of pulling every sale row into
  /// memory, so the dashboard stays fast on large histories.
  Future<List<TrendPoint>> getDailySalesTrend(
    String businessId, {
    int days = 7,
    DateTime? endDate,
  }) async {
    final db = await _db.database;
    final end = endDate ?? DateTime.now();
    final start = end.subtract(Duration(days: days - 1));

    final res = await db.rawQuery(
      '''
      SELECT date(created_at) AS day, COUNT(*) AS cnt, SUM(final_total) AS total
      FROM ${DatabaseTables.tableSales}
      WHERE business_id = ? AND status = 'Completed'
        AND date(created_at) BETWEEN ? AND ?
      GROUP BY date(created_at)
      ''',
      [businessId, _dayArg(start), _dayArg(end)],
    );

    final byDay = <String, TrendPoint>{};
    for (final row in res) {
      final dayStr = row['day'] as String?;
      if (dayStr == null) continue;
      byDay[dayStr] = TrendPoint(
        date: DateTime.parse(dayStr),
        value: (row['total'] as num?)?.toDouble() ?? 0.0,
      );
    }

    // Fill the gaps so the chart always renders a continuous series.
    final out = <TrendPoint>[];
    for (int i = 0; i < days; i++) {
      final d = start.add(Duration(days: i));
      final key = _dayArg(d);
      out.add(byDay[key] ?? TrendPoint(date: d, value: 0.0));
    }
    return out;
  }

  /// Daily gross profit = revenue - cost of goods. Cost is derived by joining
  /// sale_items to products on the recorded purchase price, so no schema
  /// change is required to surface profitability.
  Future<List<TrendPoint>> getDailyProfitTrend(
    String businessId, {
    int days = 7,
    DateTime? endDate,
  }) async {
    final db = await _db.database;
    final end = endDate ?? DateTime.now();
    final start = end.subtract(Duration(days: days - 1));

    final res = await db.rawQuery(
      '''
      SELECT date(s.created_at) AS day,
             SUM(si.line_total) AS revenue,
             SUM(si.quantity * p.purchase_price) AS cost
      FROM ${DatabaseTables.tableSaleItems} si
      JOIN ${DatabaseTables.tableSales} s ON si.sale_id = s.id
      JOIN ${DatabaseTables.tableProducts} p ON si.product_id = p.id
      WHERE s.business_id = ? AND s.status = 'Completed'
        AND date(s.created_at) BETWEEN ? AND ?
      GROUP BY date(s.created_at)
      ''',
      [businessId, _dayArg(start), _dayArg(end)],
    );

    final byDay = <String, double>{};
    for (final row in res) {
      final dayStr = row['day'] as String?;
      if (dayStr == null) continue;
      final revenue = (row['revenue'] as num?)?.toDouble() ?? 0.0;
      final cost = (row['cost'] as num?)?.toDouble() ?? 0.0;
      byDay[dayStr] = revenue - cost;
    }

    final out = <TrendPoint>[];
    for (int i = 0; i < days; i++) {
      final d = start.add(Duration(days: i));
      out.add(TrendPoint(date: d, value: byDay[_dayArg(d)] ?? 0.0));
    }
    return out;
  }

  /// Everything the dashboard needs for one trading day, in a handful of
  /// aggregate queries rather than loading whole sale documents.
  Future<DayAggregates> getDayAggregates(
    String businessId, {
    DateTime? day,
  }) async {
    final db = await _db.database;
    final target = day ?? DateTime.now();
    final dayArg = _dayArg(target);

    // Revenue, tax, discount, invoice & return counts for the day.
    final head = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS cnt,
        COALESCE(SUM(final_total), 0) AS revenue,
        COALESCE(SUM(tax_amount), 0) AS tax,
        COALESCE(SUM(discount_amount), 0) AS discount
      FROM ${DatabaseTables.tableSales}
      WHERE business_id = ? AND date(created_at) = ?
      ''',
      [businessId, dayArg],
    );

    final completed = await db.rawQuery(
      '''
      SELECT COUNT(*) AS cnt, COALESCE(SUM(final_total), 0) AS total
      FROM ${DatabaseTables.tableSales}
      WHERE business_id = ? AND date(created_at) = ? AND status = 'Completed'
      ''',
      [businessId, dayArg],
    );

    final returns = await db.rawQuery(
      '''
      SELECT COUNT(*) AS cnt, COALESCE(SUM(final_total), 0) AS total
      FROM ${DatabaseTables.tableSales}
      WHERE business_id = ? AND date(created_at) = ? AND status = 'Refunded'
      ''',
      [businessId, dayArg],
    );

    // Cost of goods sold (joined on current purchase price).
    final cogs = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(si.quantity * p.purchase_price), 0) AS cost
      FROM ${DatabaseTables.tableSaleItems} si
      JOIN ${DatabaseTables.tableSales} s ON si.sale_id = s.id
      JOIN ${DatabaseTables.tableProducts} p ON si.product_id = p.id
      WHERE s.business_id = ? AND s.status = 'Completed' AND date(s.created_at) = ?
      ''',
      [businessId, dayArg],
    );

    // Payment-method collections for completed sales of the day.
    final pay = await db.rawQuery(
      '''
      SELECT payment_method AS method, COUNT(*) AS cnt, SUM(final_total) AS total
      FROM ${DatabaseTables.tableSales}
      WHERE business_id = ? AND date(created_at) = ? AND status = 'Completed'
      GROUP BY payment_method
      ''',
      [businessId, dayArg],
    );

    final revenue = (completed.first['total'] as num?)?.toDouble() ?? 0.0;
    final cost = (cogs.first['cost'] as num?)?.toDouble() ?? 0.0;
    final invoices = (completed.first['cnt'] as num?)?.toInt() ?? 0;
    final retCount = (returns.first['cnt'] as num?)?.toInt() ?? 0;
    final retTotal = (returns.first['total'] as num?)?.toDouble() ?? 0.0;

    final buckets = <CollectionBucket>[];
    for (final row in pay) {
      buckets.add(CollectionBucket(
        method: (row['method'] as String?) ?? 'Cash',
        amount: (row['total'] as num?)?.toDouble() ?? 0.0,
        count: (row['cnt'] as num?)?.toInt() ?? 0,
      ));
    }

    return DayAggregates(
      revenue: revenue,
      cost: cost,
      profit: revenue - cost,
      profitMargin: revenue > 0 ? ((revenue - cost) / revenue) * 100.0 : 0.0,
      discount: (head.first['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (head.first['tax'] as num?)?.toDouble() ?? 0.0,
      invoiceCount: invoices,
      returnCount: retCount,
      returnsTotal: retTotal,
      collections: buckets,
    );
  }

  /// Total sales value for a single day (used by the dashboard KPI strip).
  Future<double> getDaySalesTotal(String businessId, {DateTime? day}) async {
    final db = await _db.database;
    final res = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(final_total), 0) AS total
      FROM ${DatabaseTables.tableSales}
      WHERE business_id = ? AND status = 'Completed' AND date(created_at) = ?
      ''',
      [businessId, _dayArg(day ?? DateTime.now())],
    );
    return (res.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<void> createSale(Sale sale) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      // 1. Insert master sale record
      await txn.insert(DatabaseTables.tableSales, sale.toMap());

      // 2. Insert line items, deduct stock, and update ledger
      for (final item in sale.items) {
        await txn.insert(DatabaseTables.tableSaleItems, item.toMap());

        // Deduct inventory stock
        await txn.rawUpdate(
          'UPDATE ${DatabaseTables.tableProducts} SET stock_qty = stock_qty - ? WHERE id = ?',
          [item.quantity, item.productId],
        );

        // Fetch remaining stock for ledger balance snapshot
        final prodRes = await txn.query(
          DatabaseTables.tableProducts,
          columns: ['stock_qty', 'name'],
          where: 'id = ?',
          whereArgs: [item.productId],
        );

        final balance = prodRes.isNotEmpty ? (prodRes.first['stock_qty'] as num).toDouble() : 0.0;
        final prodName = prodRes.isNotEmpty ? (prodRes.first['name'] as String) : item.productName;

        // Record stock ledger entry
        await txn.insert(DatabaseTables.tableStockLedger, {
          'id': _uuid.v4(),
          'business_id': sale.businessId,
          'product_id': item.productId,
          'product_name': prodName,
          'change_qty': -item.quantity,
          'balance_qty': balance,
          'reason': 'Sale',
          'reference_id': sale.invoiceNo,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // 3. Update customer balance due if on credit / due
      if (sale.customerId != null && sale.customerId!.isNotEmpty) {
        if (sale.paymentMethod == 'Credit/Due' || (sale.splitBreakup['Credit/Due'] != null && sale.splitBreakup['Credit/Due']! > 0)) {
          final dueAmt = sale.paymentMethod == 'Credit/Due' ? sale.finalTotal : (sale.splitBreakup['Credit/Due'] ?? 0.0);
          await txn.rawUpdate(
            'UPDATE ${DatabaseTables.tableCustomers} SET balance_due = balance_due + ? WHERE id = ?',
            [dueAmt, sale.customerId],
          );
        }

        // Add 1 loyalty point per 100 spent
        final pointsEarned = (sale.finalTotal / 100).floor();
        if (pointsEarned > 0) {
          await txn.rawUpdate(
            'UPDATE ${DatabaseTables.tableCustomers} SET loyalty_points = loyalty_points + ? WHERE id = ?',
            [pointsEarned, sale.customerId],
          );
        }
      }
    });
  }

  Future<List<Sale>> getSales({
    required String businessId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? paymentMethod,
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await _db.database;
    final List<String> whereClauses = ['business_id = ?'];
    final List<dynamic> whereArgs = [businessId];

    if (startDate != null) {
      whereClauses.add('created_at >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClauses.add('created_at <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    if (status != null && status != 'All') {
      whereClauses.add('status = ?');
      whereArgs.add(status);
    }

    if (paymentMethod != null && paymentMethod != 'All') {
      whereClauses.add('payment_method = ?');
      whereArgs.add(paymentMethod);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.tableSales,
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    final List<Sale> sales = [];
    for (final map in maps) {
      final saleId = map['id'] as String;
      final List<Map<String, dynamic>> itemMaps = await db.query(
        DatabaseTables.tableSaleItems,
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );
      final items = itemMaps.map((m) => SaleItem.fromMap(m)).toList();
      sales.add(Sale.fromMap(map, items: items));
    }

    return sales;
  }

  Future<Sale?> getSaleById(String saleId) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.tableSales,
      where: 'id = ?',
      whereArgs: [saleId],
      limit: 1,
    );
    if (maps.isEmpty) return null;

    final List<Map<String, dynamic>> itemMaps = await db.query(
      DatabaseTables.tableSaleItems,
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
    final items = itemMaps.map((m) => SaleItem.fromMap(m)).toList();
    return Sale.fromMap(maps.first, items: items);
  }

  Future<void> voidSale(String saleId, String reason) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final saleRes = await txn.query(DatabaseTables.tableSales, where: 'id = ?', whereArgs: [saleId]);
      if (saleRes.isEmpty) return;
      final sale = Sale.fromMap(saleRes.first);

      final itemMaps = await txn.query(DatabaseTables.tableSaleItems, where: 'sale_id = ?', whereArgs: [saleId]);
      final items = itemMaps.map((m) => SaleItem.fromMap(m)).toList();

      // Reverse inventory stock
      for (final item in items) {
        await txn.rawUpdate(
          'UPDATE ${DatabaseTables.tableProducts} SET stock_qty = stock_qty + ? WHERE id = ?',
          [item.quantity, item.productId],
        );

        final prodRes = await txn.query(
          DatabaseTables.tableProducts,
          columns: ['stock_qty', 'name'],
          where: 'id = ?',
          whereArgs: [item.productId],
        );
        final balance = prodRes.isNotEmpty ? (prodRes.first['stock_qty'] as num).toDouble() : 0.0;
        final prodName = prodRes.isNotEmpty ? (prodRes.first['name'] as String) : item.productName;

        await txn.insert(DatabaseTables.tableStockLedger, {
          'id': _uuid.v4(),
          'business_id': sale.businessId,
          'product_id': item.productId,
          'product_name': prodName,
          'change_qty': item.quantity,
          'balance_qty': balance,
          'reason': 'Voided: $reason',
          'reference_id': sale.invoiceNo,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Mark sale as Voided
      await txn.update(
        DatabaseTables.tableSales,
        {'status': 'Voided', 'notes': (sale.notes != null ? '${sale.notes} | ' : '') + 'Voided: $reason'},
        where: 'id = ?',
        whereArgs: [saleId],
      );
    });
  }

  Future<String> generateNextInvoiceNo(String businessId, String prefix) async {
    final db = await _db.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseTables.tableSales} WHERE business_id = ?', [businessId]),
    );
    final nextNum = (count ?? 0) + 1;
    return '$prefix${nextNum.toString().padLeft(4, '0')}';
  }
}
