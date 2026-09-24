import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_tables.dart';
import '../models/category.dart';
import '../models/product.dart';

class ProductRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<List<Product>> getProducts({
    required String businessId,
    String? categoryId,
    String? query,
    String? brand,
    bool onlyLowStock = false,
    String sortBy = 'name_asc',
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await _db.database;

    final List<String> whereClauses = ['business_id = ?', 'is_active = 1'];
    final List<dynamic> whereArgs = [businessId];

    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
      whereClauses.add('category_id = ?');
      whereArgs.add(categoryId);
    }

    if (brand != null && brand.isNotEmpty && brand != 'all') {
      whereClauses.add('brand = ?');
      whereArgs.add(brand);
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = '%${query.trim()}%';
      whereClauses.add('(name LIKE ? OR sku LIKE ? OR barcode LIKE ? OR brand LIKE ?)');
      whereArgs.addAll([q, q, q, q]);
    }

    if (onlyLowStock) {
      whereClauses.add('stock_qty <= min_stock_alert');
    }

    String orderBy;
    switch (sortBy) {
      case 'price_low':
        orderBy = 'selling_price ASC';
        break;
      case 'price_high':
        orderBy = 'selling_price DESC';
        break;
      case 'stock_low':
        orderBy = 'stock_qty ASC';
        break;
      case 'stock_high':
        orderBy = 'stock_qty DESC';
        break;
      case 'newest':
        orderBy = 'created_at DESC';
        break;
      case 'name_desc':
        orderBy = 'name DESC';
        break;
      case 'name_asc':
      default:
        orderBy = 'name ASC';
    }

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.tableProducts,
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<Product?> getProductById(String id) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.tableProducts,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Category>> getCategories(String businessId) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseTables.tableCategories,
      where: 'business_id = ?',
      whereArgs: [businessId],
      orderBy: 'sort_order ASC, name ASC',
    );
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  Future<void> insertCategory(Category category) async {
    final db = await _db.database;
    await db.insert(
      DatabaseTables.tableCategories,
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertProduct(Product product) async {
    final db = await _db.database;
    await db.insert(
      DatabaseTables.tableProducts,
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateProduct(Product product) async {
    final db = await _db.database;
    await db.update(
      DatabaseTables.tableProducts,
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> deleteProduct(String id) async {
    final db = await _db.database;
    await db.delete(
      DatabaseTables.tableProducts,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateStock(String productId, double delta) async {
    final db = await _db.database;
    await db.rawUpdate(
      'UPDATE ${DatabaseTables.tableProducts} SET stock_qty = stock_qty + ? WHERE id = ?',
      [delta, productId],
    );
  }
}
