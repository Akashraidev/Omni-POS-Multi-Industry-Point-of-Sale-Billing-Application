import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_tables.dart';
import '../models/estimate.dart';

class EstimateRepository {
  final AppDatabase _db = AppDatabase.instance;
  final Uuid _uuid = const Uuid();

  Future<List<Estimate>> getEstimates(String businessId, {String? status}) async {
    final db = await _db.database;

    String whereClause = 'business_id = ?';
    List<dynamic> whereArgs = [businessId];

    if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
      whereClause += ' AND status = ?';
      whereArgs.add(status);
    }

    final estimateRows = await db.query(
      DatabaseTables.tableEstimates,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    if (estimateRows.isEmpty) return [];

    final estimates = <Estimate>[];
    for (final row in estimateRows) {
      final estId = row['id'] as String;
      final itemRows = await db.query(
        DatabaseTables.tableEstimateItems,
        where: 'estimate_id = ?',
        whereArgs: [estId],
      );

      final items = itemRows.map((ir) => EstimateItem.fromMap(ir)).toList();
      estimates.add(Estimate.fromMap(row, items: items));
    }

    return estimates;
  }

  Future<Estimate?> getEstimateById(String id) async {
    final db = await _db.database;

    final rows = await db.query(
      DatabaseTables.tableEstimates,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final itemRows = await db.query(
      DatabaseTables.tableEstimateItems,
      where: 'estimate_id = ?',
      whereArgs: [id],
    );

    final items = itemRows.map((ir) => EstimateItem.fromMap(ir)).toList();
    return Estimate.fromMap(rows.first, items: items);
  }

  Future<String> insertEstimate(Estimate estimate) async {
    final db = await _db.database;
    final estId = estimate.id.isNotEmpty ? estimate.id : _uuid.v4();

    await db.transaction((txn) async {
      final estMap = estimate.toMap();
      estMap['id'] = estId;

      await txn.insert(
        DatabaseTables.tableEstimates,
        estMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (final item in estimate.items) {
        final itemId = item.id.isNotEmpty ? item.id : _uuid.v4();
        final itemMap = item.toMap();
        itemMap['id'] = itemId;
        itemMap['estimate_id'] = estId;

        await txn.insert(
          DatabaseTables.tableEstimateItems,
          itemMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });

    return estId;
  }

  Future<void> updateEstimateStatus(
    String id,
    String status, {
    String? convertedSaleId,
  }) async {
    final db = await _db.database;
    final updates = <String, dynamic>{'status': status};
    if (convertedSaleId != null) {
      updates['converted_sale_id'] = convertedSaleId;
    }

    await db.update(
      DatabaseTables.tableEstimates,
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Atomically marks an estimate as Converted **only** if it is still Active.
  ///
  /// Returns `true` if the row was actually updated (i.e. first caller wins),
  /// `false` if another process already converted it (row was no longer Active).
  /// This is the race-condition–safe version of [updateEstimateStatus].
  Future<bool> atomicMarkConverted(String id, {String? saleId}) async {
    final db = await _db.database;
    final updates = <String, dynamic>{'status': 'Converted'};
    if (saleId != null) updates['converted_sale_id'] = saleId;

    final affected = await db.update(
      DatabaseTables.tableEstimates,
      updates,
      // Only update when status is still 'Active' — prevents double-conversion.
      where: 'id = ? AND status = ?',
      whereArgs: [id, 'Active'],
    );
    return affected > 0;
  }

  Future<void> deleteEstimate(String id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete(
        DatabaseTables.tableEstimateItems,
        where: 'estimate_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        DatabaseTables.tableEstimates,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<String> getNextEstimateNumber(String businessId) async {
    final db = await _db.database;

    final res = await db.rawQuery(
      '''
      SELECT COUNT(*) AS total FROM ${DatabaseTables.tableEstimates}
      WHERE business_id = ?
      ''',
      [businessId],
    );

    final count = (res.first['total'] as num?)?.toInt() ?? 0;
    final nextNum = 1001 + count;
    return 'EST-$nextNum';
  }
}
