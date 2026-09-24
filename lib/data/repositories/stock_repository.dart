import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_tables.dart';
import '../models/held_bill.dart';
import '../models/stock_ledger.dart';

class StockRepository {
  final AppDatabase _db = AppDatabase.instance;
  final Uuid _uuid = const Uuid();

  Future<List<StockLedgerEntry>> getLedger(String businessId, {int limit = 50}) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.tableStockLedger,
      where: 'business_id = ?',
      whereArgs: [businessId],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return maps.map((m) => StockLedgerEntry.fromMap(m)).toList();
  }

  Future<void> adjustStock({
    required String businessId,
    required String productId,
    required String productName,
    required double changeQty,
    required String reason,
    String? referenceId,
  }) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE ${DatabaseTables.tableProducts} SET stock_qty = stock_qty + ? WHERE id = ?',
        [changeQty, productId],
      );

      final prodRes = await txn.query(
        DatabaseTables.tableProducts,
        columns: ['stock_qty'],
        where: 'id = ?',
        whereArgs: [productId],
      );
      final balance = prodRes.isNotEmpty ? (prodRes.first['stock_qty'] as num).toDouble() : 0.0;

      await txn.insert(DatabaseTables.tableStockLedger, {
        'id': _uuid.v4(),
        'business_id': businessId,
        'product_id': productId,
        'product_name': productName,
        'change_qty': changeQty,
        'balance_qty': balance,
        'reason': reason,
        'reference_id': referenceId,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
  }

  // Held Bills
  Future<List<HeldBill>> getHeldBills(String businessId) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.tableHeldBills,
      where: 'business_id = ?',
      whereArgs: [businessId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => HeldBill.fromMap(m)).toList();
  }

  Future<void> insertHeldBill(HeldBill bill) async {
    final db = await _db.database;
    await db.insert(
      DatabaseTables.tableHeldBills,
      bill.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteHeldBill(String id) async {
    final db = await _db.database;
    await db.delete(
      DatabaseTables.tableHeldBills,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
