import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_tables.dart';
import '../models/supplier.dart';

class SupplierRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<List<Supplier>> getSuppliers(String businessId, {String? query}) async {
    final db = await _db.database;
    final List<String> whereClauses = ['business_id = ?'];
    final List<dynamic> whereArgs = [businessId];

    if (query != null && query.trim().isNotEmpty) {
      final q = '%${query.trim()}%';
      whereClauses.add('(name LIKE ? OR phone LIKE ? OR email LIKE ?)');
      whereArgs.addAll([q, q, q]);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.tableSuppliers,
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );

    return maps.map((m) => Supplier.fromMap(m)).toList();
  }

  Future<void> insertSupplier(Supplier supplier) async {
    final db = await _db.database;
    await db.insert(
      DatabaseTables.tableSuppliers,
      supplier.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateSupplier(Supplier supplier) async {
    final db = await _db.database;
    await db.update(
      DatabaseTables.tableSuppliers,
      supplier.toMap(),
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  Future<void> deleteSupplier(String id) async {
    final db = await _db.database;
    await db.delete(
      DatabaseTables.tableSuppliers,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
