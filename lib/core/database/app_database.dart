import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'database_tables.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  AppDatabase._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String dbPath;

    if (kIsWeb) {
      // Use Web SQLite FFI via IndexedDB / WebAssembly
      databaseFactory = databaseFactoryFfiWeb;
      dbPath = 'ominipos_web_v1.db';
    } else {
      // Desktop platforms (Windows, Linux, macOS) or unit tests
      if (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
      final documentsDir = await getApplicationDocumentsDirectory();
      dbPath = p.join(documentsDir.path, 'ominipos_v1.db');
    }

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
      onOpen: (db) async {
        for (final statement in DatabaseTables.createTableStatements) {
          await db.execute(statement);
        }
        for (final indexStatement in DatabaseTables.createIndexStatements) {
          await db.execute(indexStatement);
        }
        await _runSafeColumnMigrations(db);
      },
    );
  }

  Future<void> _runSafeColumnMigrations(Database db) async {
    final migrations = [
      'ALTER TABLE ${DatabaseTables.tablePurchases} ADD COLUMN subtotal REAL',
      'ALTER TABLE ${DatabaseTables.tablePurchases} ADD COLUMN tax_amount REAL DEFAULT 0',
      'ALTER TABLE ${DatabaseTables.tablePurchases} ADD COLUMN discount_amount REAL DEFAULT 0',
      'ALTER TABLE ${DatabaseTables.tablePurchases} ADD COLUMN round_off REAL DEFAULT 0',
      'ALTER TABLE ${DatabaseTables.tablePurchases} ADD COLUMN payment_status TEXT DEFAULT "Paid"',
      'ALTER TABLE ${DatabaseTables.tablePurchases} ADD COLUMN payment_method TEXT DEFAULT "Cash"',
      'ALTER TABLE ${DatabaseTables.tablePurchases} ADD COLUMN paid_amount REAL',
      'ALTER TABLE ${DatabaseTables.tablePurchases} ADD COLUMN due_amount REAL DEFAULT 0',
      'ALTER TABLE ${DatabaseTables.tablePurchases} ADD COLUMN due_date TEXT',
      'ALTER TABLE ${DatabaseTables.tablePurchaseItems} ADD COLUMN batch_number TEXT',
      'ALTER TABLE ${DatabaseTables.tablePurchaseItems} ADD COLUMN batch_expiry TEXT',
      'ALTER TABLE ${DatabaseTables.tablePurchaseItems} ADD COLUMN free_quantity REAL DEFAULT 0',
      'ALTER TABLE ${DatabaseTables.tablePurchaseItems} ADD COLUMN tax_rate REAL DEFAULT 0',
      'ALTER TABLE ${DatabaseTables.tablePurchaseItems} ADD COLUMN tax_amount REAL DEFAULT 0',
      'ALTER TABLE ${DatabaseTables.tablePurchaseItems} ADD COLUMN discount_amount REAL DEFAULT 0',
      'ALTER TABLE ${DatabaseTables.tablePurchaseItems} ADD COLUMN mrp REAL',
    ];

    for (final sql in migrations) {
      try {
        await db.execute(sql);
      } catch (_) {
        // Column already exists or table freshly created
      }
    }
  }

  Future<void> _onConfigure(Database db) async {
    if (!kIsWeb) {
      await db.execute('PRAGMA foreign_keys = ON');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Run table creation scripts
    for (final statement in DatabaseTables.createTableStatements) {
      await db.execute(statement);
    }

    // Run index creation scripts
    for (final indexStatement in DatabaseTables.createIndexStatements) {
      await db.execute(indexStatement);
    }
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(DatabaseTables.tableSaleItems);
      await txn.delete(DatabaseTables.tableSales);
      await txn.delete(DatabaseTables.tablePurchaseItems);
      await txn.delete(DatabaseTables.tablePurchases);
      await txn.delete(DatabaseTables.tableStockLedger);
      await txn.delete(DatabaseTables.tableHeldBills);
      await txn.delete(DatabaseTables.tableExpenses);
      await txn.delete(DatabaseTables.tableProducts);
      await txn.delete(DatabaseTables.tableCategories);
      await txn.delete(DatabaseTables.tableCustomers);
      await txn.delete(DatabaseTables.tableSuppliers);
      await txn.delete(DatabaseTables.tableAppUsers);
      await txn.delete(DatabaseTables.tableBusinesses);
    });
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }
}
