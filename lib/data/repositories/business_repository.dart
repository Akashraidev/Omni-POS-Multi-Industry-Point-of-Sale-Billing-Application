import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_tables.dart';
import '../models/business.dart';

class BusinessRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<List<Business>> getAllBusinesses() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.tableBusinesses,
      orderBy: 'name ASC',
    );
    return maps.map((m) => Business.fromMap(m)).toList();
  }

  Future<Business?> getBusinessById(String id) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.tableBusinesses,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Business.fromMap(maps.first);
    }
    return null;
  }

  Future<void> insertBusiness(Business business) async {
    final db = await _db.database;
    await db.insert(
      DatabaseTables.tableBusinesses,
      business.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateBusiness(Business business) async {
    final db = await _db.database;
    await db.update(
      DatabaseTables.tableBusinesses,
      business.toMap(),
      where: 'id = ?',
      whereArgs: [business.id],
    );
  }

  Future<void> deleteBusiness(String id) async {
    final db = await _db.database;
    await db.delete(
      DatabaseTables.tableBusinesses,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
