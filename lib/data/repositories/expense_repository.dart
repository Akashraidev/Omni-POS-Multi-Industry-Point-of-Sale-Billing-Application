import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_tables.dart';
import '../models/expense.dart';

class ExpenseRepository {
  final AppDatabase _db = AppDatabase.instance;

  /// Total expenses recorded for a single trading day.
  Future<double> getDayExpenseTotal(String businessId, {DateTime? day}) async {
    final db = await _db.database;
    final dayArg = (day ?? DateTime.now()).toIso8601String().substring(0, 10);
    final res = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM ${DatabaseTables.tableExpenses}
      WHERE business_id = ? AND date(date) = ?
      ''',
      [businessId, dayArg],
    );
    return (res.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<Expense>> getExpenses(String businessId, {DateTime? startDate, DateTime? endDate}) async {
    final db = await _db.database;
    final List<String> whereClauses = ['business_id = ?'];
    final List<dynamic> whereArgs = [businessId];

    if (startDate != null) {
      whereClauses.add('date >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClauses.add('date <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.tableExpenses,
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );

    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  Future<void> insertExpense(Expense expense) async {
    final db = await _db.database;
    await db.insert(
      DatabaseTables.tableExpenses,
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteExpense(String id) async {
    final db = await _db.database;
    await db.delete(
      DatabaseTables.tableExpenses,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
