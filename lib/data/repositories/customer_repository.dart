import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_tables.dart';
import '../models/customer.dart';

class CustomerRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<List<Customer>> getCustomers(String businessId, {String? query}) async {
    final db = await _db.database;
    final List<String> whereClauses = ['business_id = ?'];
    final List<dynamic> whereArgs = [businessId];

    if (query != null && query.trim().isNotEmpty) {
      final q = '%${query.trim()}%';
      whereClauses.add('(name LIKE ? OR phone LIKE ? OR email LIKE ?)');
      whereArgs.addAll([q, q, q]);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.tableCustomers,
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );

    return maps.map((m) => Customer.fromMap(m)).toList();
  }

  Future<Customer?> getCustomerByPhone(String businessId, String phone) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.tableCustomers,
      where: 'business_id = ? AND phone = ?',
      whereArgs: [businessId, phone],
      limit: 1,
    );
    if (maps.isNotEmpty) return Customer.fromMap(maps.first);
    return null;
  }

  Future<void> insertCustomer(Customer customer) async {
    final db = await _db.database;
    await db.insert(
      DatabaseTables.tableCustomers,
      customer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCustomer(Customer customer) async {
    final db = await _db.database;
    await db.update(
      DatabaseTables.tableCustomers,
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<void> deleteCustomer(String id) async {
    final db = await _db.database;
    await db.delete(
      DatabaseTables.tableCustomers,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> collectDuePayment(String customerId, double amountPaid) async {
    final db = await _db.database;
    await db.rawUpdate(
      'UPDATE ${DatabaseTables.tableCustomers} SET balance_due = MAX(0, balance_due - ?) WHERE id = ?',
      [amountPaid, customerId],
    );
  }
}
