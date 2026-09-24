import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_tables.dart';
import '../models/purchase.dart';

class PurchaseRepository {
  final AppDatabase _db = AppDatabase.instance;
  final Uuid _uuid = const Uuid();

  Future<void> createPurchase(Purchase purchase) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.insert(
        DatabaseTables.tablePurchases,
        purchase.toMap(),
      );

      for (final item in purchase.items) {
        await txn.insert(
          DatabaseTables.tablePurchaseItems,
          item.toMap(),
        );

        // If status is Received, increment stock, register batch, and log in ledger
        if (purchase.status == 'Received') {
          final totalQtyInward = item.quantity + item.freeQuantity;

          // 1. Increment physical product stock
          await txn.rawUpdate(
            'UPDATE ${DatabaseTables.tableProducts} SET stock_qty = stock_qty + ?, purchase_price = ? WHERE id = ?',
            [totalQtyInward, item.unitCost, item.productId],
          );

          // Update MRP if provided
          if (item.mrp != null && item.mrp! > 0) {
            await txn.rawUpdate(
              'UPDATE ${DatabaseTables.tableProducts} SET mrp = ? WHERE id = ?',
              [item.mrp, item.productId],
            );
          }

          // 2. Fetch current product record for ledger balance and metadata
          final prodRes = await txn.query(
            DatabaseTables.tableProducts,
            columns: ['stock_qty', 'name', 'business_metadata_json'],
            where: 'id = ?',
            whereArgs: [item.productId],
          );

          final balance = prodRes.isNotEmpty
              ? (prodRes.first['stock_qty'] as num).toDouble()
              : totalQtyInward;
          final prodName = prodRes.isNotEmpty
              ? (prodRes.first['name'] as String)
              : item.productName;

          // 3. Register / update batch in product metadata if batch number provided
          if (item.batchNumber != null && item.batchNumber!.trim().isNotEmpty) {
            final rawMeta = prodRes.isNotEmpty
                ? prodRes.first['business_metadata_json'] as String?
                : null;
            Map<String, dynamic> metadata = {};
            if (rawMeta != null && rawMeta.isNotEmpty) {
              try {
                metadata = jsonDecode(rawMeta) as Map<String, dynamic>;
              } catch (_) {}
            }

            final List<dynamic> batches =
                List.from(metadata['batches'] as List<dynamic>? ?? []);

            final existingBatchIdx = batches.indexWhere(
              (b) => (b['batch_no'] as String? ?? '').trim().toLowerCase() ==
                  item.batchNumber!.trim().toLowerCase(),
            );

            if (existingBatchIdx >= 0) {
              final existing = Map<String, dynamic>.from(batches[existingBatchIdx] as Map);
              final oldStock = (existing['stock'] as num?)?.toDouble() ?? 0.0;
              existing['stock'] = oldStock + totalQtyInward;
              if (item.batchExpiry != null && item.batchExpiry!.isNotEmpty) {
                existing['expiry'] = item.batchExpiry;
              }
              if (item.mrp != null) {
                existing['mrp'] = item.mrp;
              }
              batches[existingBatchIdx] = existing;
            } else {
              batches.add({
                'batch_no': item.batchNumber!.trim(),
                'expiry': item.batchExpiry ?? '',
                'stock': totalQtyInward,
                'mrp': item.mrp ?? 0.0,
                'inward_date': DateTime.now().toIso8601String(),
              });
            }

            metadata['batches'] = batches;
            await txn.update(
              DatabaseTables.tableProducts,
              {'business_metadata_json': jsonEncode(metadata)},
              where: 'id = ?',
              whereArgs: [item.productId],
            );
          }

          // 4. Log in Stock Ledger
          await txn.insert(DatabaseTables.tableStockLedger, {
            'id': _uuid.v4(),
            'business_id': purchase.businessId,
            'product_id': item.productId,
            'product_name': prodName,
            'change_qty': totalQtyInward,
            'balance_qty': balance,
            'reason': 'Purchase Inward - ${purchase.invoiceNo}',
            'reference_id': purchase.invoiceNo,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }

      // Update supplier balance due if partial or credit purchase
      if (purchase.supplierId != null &&
          purchase.supplierId!.isNotEmpty &&
          purchase.dueAmount > 0) {
        await txn.rawUpdate(
          'UPDATE ${DatabaseTables.tableSuppliers} SET balance_due = balance_due + ? WHERE id = ?',
          [purchase.dueAmount, purchase.supplierId],
        );
      }
    });
  }

  Future<void> voidPurchase(String purchaseId) async {
    final db = await _db.database;

    final purchList = await db.query(
      DatabaseTables.tablePurchases,
      where: 'id = ?',
      whereArgs: [purchaseId],
      limit: 1,
    );
    if (purchList.isEmpty) return;

    final purchase = Purchase.fromMap(purchList.first);
    if (purchase.status == 'Voided') return;

    final itemRows = await db.query(
      DatabaseTables.tablePurchaseItems,
      where: 'purchase_id = ?',
      whereArgs: [purchaseId],
    );
    final items = itemRows.map((ir) => PurchaseItem.fromMap(ir)).toList();

    await db.transaction((txn) async {
      if (purchase.status == 'Received') {
        for (final item in items) {
          final totalQty = item.quantity + item.freeQuantity;

          // Deduct product physical stock
          await txn.rawUpdate(
            'UPDATE ${DatabaseTables.tableProducts} SET stock_qty = stock_qty - ? WHERE id = ?',
            [totalQty, item.productId],
          );

          // Deduct batch stock in metadata if batch was specified
          if (item.batchNumber != null && item.batchNumber!.trim().isNotEmpty) {
            final prodRes = await txn.query(
              DatabaseTables.tableProducts,
              columns: ['business_metadata_json'],
              where: 'id = ?',
              whereArgs: [item.productId],
            );
            if (prodRes.isNotEmpty) {
              final rawMeta = prodRes.first['business_metadata_json'] as String?;
              if (rawMeta != null && rawMeta.isNotEmpty) {
                try {
                  final metadata = jsonDecode(rawMeta) as Map<String, dynamic>;
                  final batches = List.from(metadata['batches'] as List<dynamic>? ?? []);
                  final bIdx = batches.indexWhere(
                    (b) => (b['batch_no'] as String? ?? '').trim().toLowerCase() ==
                        item.batchNumber!.trim().toLowerCase(),
                  );
                  if (bIdx >= 0) {
                    final b = Map<String, dynamic>.from(batches[bIdx] as Map);
                    final curStock = (b['stock'] as num?)?.toDouble() ?? 0.0;
                    b['stock'] = (curStock - totalQty).clamp(0.0, 999999.0);
                    batches[bIdx] = b;
                    metadata['batches'] = batches;
                    await txn.update(
                      DatabaseTables.tableProducts,
                      {'business_metadata_json': jsonEncode(metadata)},
                      where: 'id = ?',
                      whereArgs: [item.productId],
                    );
                  }
                } catch (_) {}
              }
            }
          }

          // Fetch current stock after deduction for ledger balance
          final pRes = await txn.query(
            DatabaseTables.tableProducts,
            columns: ['stock_qty', 'name'],
            where: 'id = ?',
            whereArgs: [item.productId],
          );
          final balance = pRes.isNotEmpty ? (pRes.first['stock_qty'] as num).toDouble() : 0.0;
          final prodName = pRes.isNotEmpty ? (pRes.first['name'] as String) : item.productName;

          // Audit in Stock Ledger
          await txn.insert(DatabaseTables.tableStockLedger, {
            'id': _uuid.v4(),
            'business_id': purchase.businessId,
            'product_id': item.productId,
            'product_name': prodName,
            'change_qty': -totalQty,
            'balance_qty': balance,
            'reason': 'Purchase Voided - ${purchase.invoiceNo}',
            'reference_id': purchase.invoiceNo,
            'created_at': DateTime.now().toIso8601String(),
          });
        }

        // Revert supplier balance due
        if (purchase.supplierId != null &&
            purchase.supplierId!.isNotEmpty &&
            purchase.dueAmount > 0) {
          await txn.rawUpdate(
            'UPDATE ${DatabaseTables.tableSuppliers} SET balance_due = balance_due - ? WHERE id = ?',
            [purchase.dueAmount, purchase.supplierId],
          );
        }
      }

      await txn.update(
        DatabaseTables.tablePurchases,
        {'status': 'Voided'},
        where: 'id = ?',
        whereArgs: [purchaseId],
      );
    });
  }

  Future<void> deletePurchase(String purchaseId) async {
    final db = await _db.database;
    await voidPurchase(purchaseId);
    await db.transaction((txn) async {
      await txn.delete(
        DatabaseTables.tablePurchaseItems,
        where: 'purchase_id = ?',
        whereArgs: [purchaseId],
      );
      await txn.delete(
        DatabaseTables.tablePurchases,
        where: 'id = ?',
        whereArgs: [purchaseId],
      );
    });
  }

  Future<String> getNextPurchaseInvoiceNumber(String businessId) async {
    final db = await _db.database;
    final res = await db.rawQuery(
      '''
      SELECT COUNT(*) AS total FROM ${DatabaseTables.tablePurchases}
      WHERE business_id = ?
      ''',
      [businessId],
    );

    final count = (res.first['total'] as num?)?.toInt() ?? 0;
    return 'PUR-${1001 + count}';
  }

  /// Total purchase value booked for a single trading day.
  Future<double> getDayPurchaseTotal(String businessId, {DateTime? day}) async {
    final db = await _db.database;
    final dayArg = (day ?? DateTime.now()).toIso8601String().substring(0, 10);
    final res = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(total_amount), 0) AS total
      FROM ${DatabaseTables.tablePurchases}
      WHERE business_id = ? AND date(created_at) = ? AND status = 'Received'
      ''',
      [businessId, dayArg],
    );
    return (res.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Daily purchase totals for the last [days] days (dashboard trend chart).
  Future<List<double>> getDailyPurchaseTrend(
    String businessId, {
    int days = 7,
    DateTime? endDate,
  }) async {
    final db = await _db.database;
    final end = endDate ?? DateTime.now();
    final start = end.subtract(Duration(days: days - 1));

    final res = await db.rawQuery(
      '''
      SELECT date(created_at) AS day, SUM(total_amount) AS total
      FROM ${DatabaseTables.tablePurchases}
      WHERE business_id = ? AND status = 'Received'
        AND date(created_at) BETWEEN ? AND ?
      GROUP BY date(created_at)
      ''',
      [
        businessId,
        start.toIso8601String().substring(0, 10),
        end.toIso8601String().substring(0, 10),
      ],
    );

    final byDay = <String, double>{};
    for (final row in res) {
      final dayStr = row['day'] as String?;
      if (dayStr != null) {
        byDay[dayStr] = (row['total'] as num?)?.toDouble() ?? 0.0;
      }
    }

    final out = <double>[];
    for (int i = 0; i < days; i++) {
      out.add(byDay[start.add(Duration(days: i)).toIso8601String().substring(0, 10)] ?? 0.0);
    }
    return out;
  }

  Future<List<Purchase>> getPurchases(String businessId) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.tablePurchases,
      where: 'business_id = ?',
      whereArgs: [businessId],
      orderBy: 'created_at DESC',
    );

    final List<Purchase> purchases = [];
    for (final map in maps) {
      final purchaseId = map['id'] as String;
      final List<Map<String, dynamic>> itemMaps = await db.query(
        DatabaseTables.tablePurchaseItems,
        where: 'purchase_id = ?',
        whereArgs: [purchaseId],
      );
      final items = itemMaps.map((m) => PurchaseItem.fromMap(m)).toList();
      purchases.add(Purchase.fromMap(map, items: items));
    }

    return purchases;
  }
}
