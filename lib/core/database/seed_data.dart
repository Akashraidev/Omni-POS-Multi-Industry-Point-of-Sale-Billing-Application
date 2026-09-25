import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../modules/business_type.dart';
import 'database_tables.dart';

class SeedData {
  static Future<void> populateAllSeedData(Database db) async {
    // 1. Clean up supermarket if present from previous runs
    await _cleanupSupermarket(db);

    // 2. Check if Gym exists, if not seed Gym
    final gymCount = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM ${DatabaseTables.tableBusinesses} WHERE type = 'gym'"),
    );
    if (gymCount == null || gymCount == 0) {
      await db.transaction((txn) async {
        await _seedGym(txn);
      });
    }

    // 3. Check if Library exists, if not seed Library
    final libCount = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM ${DatabaseTables.tableBusinesses} WHERE type = 'library'"),
    );
    if (libCount == null || libCount == 0) {
      await db.transaction((txn) async {
        await _seedLibrary(txn);
      });
    }

    // 4. Check if other businesses already exist
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseTables.tableBusinesses}'),
    );
    if (count != null && count > 2) return;

    await db.transaction((txn) async {
      await _seedMedical(txn);
      await _seedRestaurant(txn);
      await _seedGrocery(txn);
      await _seedElectronics(txn);
      await _seedGarment(txn);
    });
  }

  static Future<void> _cleanupSupermarket(Database db) async {
    try {
      await db.delete(DatabaseTables.tableSaleItems, where: 'sale_id IN (SELECT id FROM ${DatabaseTables.tableSales} WHERE business_id = ?)', whereArgs: ['biz_super_01']);
      await db.delete(DatabaseTables.tableSales, where: 'business_id = ?', whereArgs: ['biz_super_01']);
      await db.delete(DatabaseTables.tableProducts, where: 'business_id = ?', whereArgs: ['biz_super_01']);
      await db.delete(DatabaseTables.tableCategories, where: 'business_id = ?', whereArgs: ['biz_super_01']);
      await db.delete(DatabaseTables.tableBusinesses, where: "id = 'biz_super_01' OR type = 'supermarket'");
    } catch (_) {}
  }

  // -------------------------------------------------------------
  // 1. MEDICAL / PHARMACY SEED
  // -------------------------------------------------------------
  static Future<void> _seedMedical(Transaction txn) async {
    const bizId = 'biz_medical_01';
    final now = DateTime.now();

    // Business
    await txn.insert(DatabaseTables.tableBusinesses, {
      'id': bizId,
      'name': 'Apollo MedPlus Pharmacy',
      'type': BusinessType.medical.id,
      'address': 'Shop 4, Health Avenue, Medical Square',
      'phone': '+91 98765 43210',
      'email': 'care@apollomedplus.com',
      'tax_number': '27ABCDE1234F1Z5',
      'currency_symbol': '₹',
      'currency_code': 'INR',
      'invoice_prefix': 'MED-',
      'default_tax_rate': 12.0,
      'receipt_footer': 'Medicines once sold can only be returned in original blister packaging.',
      'created_at': now.toIso8601String(),
      'settings_json': jsonEncode({
        'enable_fefo': true,
        'require_doctor_for_schedule_h': true,
        'low_stock_threshold': 10,
        'expiry_warning_days': 60,
      }),
    });

    // Users
    await txn.insert(DatabaseTables.tableAppUsers, {
      'id': 'user_med_owner',
      'business_id': bizId,
      'name': 'Dr. Alok Verma (Pharmacist)',
      'role': 'Owner',
      'pin_code': '1234',
    });

    // Categories
    final categories = [
      {'id': 'cat_med_analgesics', 'name': 'Pain & Analgesics', 'icon': 'healing', 'color_hex': '#0D9488'},
      {'id': 'cat_med_antibiotics', 'name': 'Antibiotics & Anti-infective', 'icon': 'medication', 'color_hex': '#0284C7'},
      {'id': 'cat_med_respiratory', 'name': 'Cold, Cough & Allergy', 'icon': 'air', 'color_hex': '#F59E0B'},
      {'id': 'cat_med_chronic', 'name': 'Diabetes & Cardiac Care', 'icon': 'favorite', 'color_hex': '#E11D48'},
      {'id': 'cat_med_gastro', 'name': 'Gastrointestinal & Antacids', 'icon': 'spa', 'color_hex': '#10B981'},
      {'id': 'cat_med_devices', 'name': 'Devices & Diagnostic', 'icon': 'medical_services', 'color_hex': '#6366F1'},
      {'id': 'cat_med_ointments', 'name': 'Skin Care & Antiseptics', 'icon': 'healing', 'color_hex': '#059669'},
    ];
    for (final c in categories) {
      await txn.insert(DatabaseTables.tableCategories, {
        'id': c['id']!,
        'business_id': bizId,
        'name': c['name']!,
        'icon': c['icon']!,
        'color_hex': c['color_hex']!,
        'sort_order': 0,
      });
    }

    // Products with Batches & FEFO Expiry
    final products = [
      {
        'id': 'prod_med_dolo',
        'category_id': 'cat_med_analgesics',
        'name': 'Dolo 650mg Tablet',
        'sku': 'MED-DOL-650',
        'barcode': '890123456701',
        'purchase_price': 22.50,
        'selling_price': 30.50,
        'mrp': 33.00,
        'stock_qty': 150.0,
        'min_stock_alert': 20.0,
        'unit': 'strip',
        'brand': 'Micro Labs',
        'tax_rate': 12.0,
        'business_metadata_json': jsonEncode({
          'generic_name': 'Paracetamol 650mg',
          'salt_composition': 'Paracetamol IP 650 mg',
          'manufacturer': 'Micro Labs Ltd',
          'hsn_code': '30049060',
          'dosage_form': 'tablet',
          'tablets_per_strip': 10,
          'schedule_h': false,
          'is_narcotic': false,
          'batches': [
            {'batch_no': 'B-DL01', 'expiry': now.add(const Duration(days: 45)).toIso8601String().substring(0, 10), 'qty': 50, 'mrp': 33.0},
            {'batch_no': 'B-DL02', 'expiry': now.add(const Duration(days: 280)).toIso8601String().substring(0, 10), 'qty': 100, 'mrp': 33.0},
          ],
        }),
      },
      {
        'id': 'prod_med_augmentin',
        'category_id': 'cat_med_antibiotics',
        'name': 'Augmentin 625 Duo Tablet',
        'sku': 'MED-AUG-625',
        'barcode': '890123456702',
        'purchase_price': 160.00,
        'selling_price': 201.50,
        'mrp': 223.00,
        'stock_qty': 45.0,
        'min_stock_alert': 10.0,
        'unit': 'strip',
        'brand': 'GSK',
        'tax_rate': 12.0,
        'business_metadata_json': jsonEncode({
          'generic_name': 'Amoxycillin + Potassium Clavulanate',
          'salt_composition': 'Amoxycillin 500mg + Clavulanic Acid 125mg',
          'manufacturer': 'GlaxoSmithKline',
          'hsn_code': '30041010',
          'dosage_form': 'tablet',
          'tablets_per_strip': 10,
          'schedule_h': true,
          'is_narcotic': false,
          'batches': [
            {'batch_no': 'B-AG99', 'expiry': now.add(const Duration(days: 20)).toIso8601String().substring(0, 10), 'qty': 15, 'mrp': 223.0},
            {'batch_no': 'B-AG102', 'expiry': now.add(const Duration(days: 340)).toIso8601String().substring(0, 10), 'qty': 30, 'mrp': 223.0},
          ],
        }),
      },
      {
        'id': 'prod_med_azithral',
        'category_id': 'cat_med_antibiotics',
        'name': 'Azithral 500mg Tablet',
        'sku': 'MED-AZI-500',
        'barcode': '890123456703',
        'purchase_price': 95.00,
        'selling_price': 118.00,
        'mrp': 132.00,
        'stock_qty': 60.0,
        'min_stock_alert': 15.0,
        'unit': 'strip',
        'brand': 'Alembic',
        'tax_rate': 12.0,
        'business_metadata_json': jsonEncode({
          'generic_name': 'Azithromycin 500mg',
          'salt_composition': 'Azithromycin Dihydrate 500mg',
          'manufacturer': 'Alembic Pharmaceuticals',
          'hsn_code': '30042099',
          'dosage_form': 'tablet',
          'tablets_per_strip': 5,
          'schedule_h': true,
          'is_narcotic': false,
          'batches': [
            {'batch_no': 'B-AZ08', 'expiry': now.add(const Duration(days: 190)).toIso8601String().substring(0, 10), 'qty': 60, 'mrp': 132.0},
          ],
        }),
      },
      {
        'id': 'prod_med_pan40',
        'category_id': 'cat_med_gastro',
        'name': 'Pan 40 Gastro-Resistant',
        'sku': 'MED-PAN-040',
        'barcode': '890123456704',
        'purchase_price': 110.00,
        'selling_price': 142.00,
        'mrp': 155.00,
        'stock_qty': 80.0,
        'min_stock_alert': 12.0,
        'unit': 'strip',
        'brand': 'Alkem',
        'tax_rate': 12.0,
        'business_metadata_json': jsonEncode({
          'generic_name': 'Pantoprazole 40mg',
          'salt_composition': 'Pantoprazole Sodium 40mg',
          'manufacturer': 'Alkem Laboratories',
          'hsn_code': '30049099',
          'dosage_form': 'tablet',
          'tablets_per_strip': 15,
          'schedule_h': false,
          'is_narcotic': false,
          'batches': [
            {'batch_no': 'B-P401', 'expiry': now.add(const Duration(days: 400)).toIso8601String().substring(0, 10), 'qty': 80, 'mrp': 155.0},
          ],
        }),
      },
      {
        'id': 'prod_med_cough',
        'category_id': 'cat_med_respiratory',
        'name': 'Benadryl Cough Formula 100ml',
        'sku': 'MED-BEN-100',
        'barcode': '890123456705',
        'purchase_price': 90.00,
        'selling_price': 115.00,
        'mrp': 125.00,
        'stock_qty': 35.0,
        'min_stock_alert': 8.0,
        'unit': 'bottle',
        'brand': 'Johnson & Johnson',
        'tax_rate': 12.0,
        'business_metadata_json': jsonEncode({
          'generic_name': 'Diphenhydramine + Ammonium Chloride',
          'salt_composition': 'Diphenhydramine HCl 14.08mg + Ammonium Chloride 138mg',
          'manufacturer': 'Johnson & Johnson Pvt Ltd',
          'hsn_code': '30049011',
          'dosage_form': 'syrup',
          'pack_size': 100,
          'schedule_h': false,
          'is_narcotic': false,
          'batches': [
            {'batch_no': 'B-BN77', 'expiry': now.add(const Duration(days: 85)).toIso8601String().substring(0, 10), 'qty': 35, 'mrp': 125.0},
          ],
        }),
      },
      {
        'id': 'prod_med_insulin',
        'category_id': 'cat_med_chronic',
        'name': 'Lantus SoloStar 100IU/ml Insulin',
        'sku': 'MED-LAN-100',
        'barcode': '890123456706',
        'purchase_price': 580.00,
        'selling_price': 690.00,
        'mrp': 750.00,
        'stock_qty': 18.0,
        'min_stock_alert': 5.0,
        'unit': 'pen',
        'brand': 'Sanofi',
        'tax_rate': 5.0,
        'business_metadata_json': jsonEncode({
          'generic_name': 'Insulin Glargine',
          'salt_composition': 'Insulin Glargine rDNA 100IU',
          'manufacturer': 'Sanofi India',
          'hsn_code': '30043110',
          'dosage_form': 'injection',
          'pack_size': 1,
          'schedule_h': true,
          'is_narcotic': false,
          'batches': [
            {'batch_no': 'B-LT55', 'expiry': now.add(const Duration(days: 120)).toIso8601String().substring(0, 10), 'qty': 18, 'mrp': 750.0},
          ],
        }),
      },
      {
        'id': 'prod_med_omron',
        'category_id': 'cat_med_devices',
        'name': 'BP Monitor Omron HEM-7120',
        'sku': 'MED-OMR-7120',
        'barcode': '890123456707',
        'purchase_price': 1450.00,
        'selling_price': 1850.00,
        'mrp': 2150.00,
        'stock_qty': 25.0,
        'min_stock_alert': 4.0,
        'unit': 'pc',
        'brand': 'Omron',
        'tax_rate': 12.0,
        'business_metadata_json': jsonEncode({
          'generic_name': 'Digital Blood Pressure Monitor',
          'salt_composition': 'Oscillometric Method, Intellisense Technology',
          'manufacturer': 'Omron Healthcare',
          'hsn_code': '90189019',
          'dosage_form': 'device',
          'schedule_h': false,
          'is_narcotic': false,
          'batches': [
            {'batch_no': 'OMR24A', 'expiry': now.add(const Duration(days: 900)).toIso8601String().substring(0, 10), 'qty': 25, 'mrp': 2150.0},
          ],
        }),
      },
      {
        'id': 'prod_med_betadine',
        'category_id': 'cat_med_ointments',
        'name': 'Betadine 15g',
        'sku': 'MED-BET-015',
        'barcode': '890123456708',
        'purchase_price': 72.00,
        'selling_price': 98.00,
        'mrp': 98.00,
        'stock_qty': 50.0,
        'min_stock_alert': 10.0,
        'unit': 'tube',
        'brand': 'Win-Medicare',
        'tax_rate': 12.0,
        'business_metadata_json': jsonEncode({
          'generic_name': 'Povidone Iodine Ointment 5% w/w',
          'salt_composition': 'Povidone Iodine IP 5% w/w',
          'manufacturer': 'Win-Medicare Pvt Ltd',
          'hsn_code': '30049086',
          'dosage_form': 'cream',
          'schedule_h': false,
          'is_narcotic': false,
          'batches': [
            {'batch_no': 'BT2403', 'expiry': '2026-10-03', 'qty': 50, 'mrp': 98.0},
          ],
        }),
      },
      {
        'id': 'prod_med_asthalin',
        'category_id': 'cat_med_respiratory',
        'name': 'Asthalin Inhaler 100mcg',
        'sku': 'MED-AST-100',
        'barcode': '890123456709',
        'purchase_price': 130.00,
        'selling_price': 165.00,
        'mrp': 178.00,
        'stock_qty': 30.0,
        'min_stock_alert': 6.0,
        'unit': 'inhaler',
        'brand': 'Cipla',
        'tax_rate': 12.0,
        'business_metadata_json': jsonEncode({
          'generic_name': 'Salbutamol Inhaler 100mcg',
          'salt_composition': 'Salbutamol Sulphate IP 100mcg / actuation',
          'manufacturer': 'Cipla Ltd',
          'hsn_code': '30049099',
          'dosage_form': 'inhaler',
          'schedule_h': true,
          'is_narcotic': false,
          'batches': [
            {'batch_no': 'B-AST04', 'expiry': now.add(const Duration(days: 310)).toIso8601String().substring(0, 10), 'qty': 30, 'mrp': 178.0},
          ],
        }),
      },
      {
        'id': 'prod_med_becosules',
        'category_id': 'cat_med_analgesics',
        'name': 'Becosules Z Capsules',
        'sku': 'MED-BEC-020',
        'barcode': '890123456710',
        'purchase_price': 36.00,
        'selling_price': 48.00,
        'mrp': 55.00,
        'stock_qty': 90.0,
        'min_stock_alert': 15.0,
        'unit': 'strip',
        'brand': 'Pfizer',
        'tax_rate': 12.0,
        'business_metadata_json': jsonEncode({
          'generic_name': 'Vitamin B-Complex with Zinc',
          'salt_composition': 'B-Complex, Vitamin C & Zinc Sulphate',
          'manufacturer': 'Pfizer Limited',
          'hsn_code': '30045020',
          'dosage_form': 'capsule',
          'tablets_per_strip': 20,
          'schedule_h': false,
          'is_narcotic': false,
          'batches': [
            {'batch_no': 'B-BC12', 'expiry': now.add(const Duration(days: 420)).toIso8601String().substring(0, 10), 'qty': 90, 'mrp': 55.0},
          ],
        }),
      },
    ];

    for (final p in products) {
      await txn.insert(DatabaseTables.tableProducts, {
        'id': p['id']!,
        'business_id': bizId,
        'category_id': p['category_id']!,
        'name': p['name']!,
        'sku': p['sku']!,
        'barcode': p['barcode']!,
        'purchase_price': p['purchase_price']!,
        'selling_price': p['selling_price']!,
        'mrp': p['mrp']!,
        'stock_qty': p['stock_qty']!,
        'min_stock_alert': p['min_stock_alert']!,
        'unit': p['unit']!,
        'brand': p['brand']!,
        'tax_rate': p['tax_rate']!,
        'is_active': 1,
        'created_at': now.toIso8601String(),
        'business_metadata_json': p['business_metadata_json']!,
      });
    }

    // Customers
    await txn.insert(DatabaseTables.tableCustomers, {
      'id': 'cust_med_01',
      'business_id': bizId,
      'name': 'Rajesh Sharma',
      'phone': '9876511223',
      'email': 'rajesh.sharma@example.com',
      'address': 'Plot 12, Lake View Colony',
      'loyalty_points': 140,
      'balance_due': 0.0,
      'created_at': now.toIso8601String(),
    });
    await txn.insert(DatabaseTables.tableCustomers, {
      'id': 'cust_med_02',
      'business_id': bizId,
      'name': 'Meena Patil',
      'phone': '9822334455',
      'email': 'meena.patil@example.com',
      'address': 'Apt 4B, Sunrise Heights',
      'loyalty_points': 85,
      'balance_due': 250.0,
      'created_at': now.toIso8601String(),
    });

    // Suppliers
    await txn.insert(DatabaseTables.tableSuppliers, {
      'id': 'supp_med_01',
      'business_id': bizId,
      'name': 'Universal Pharma Distributors',
      'phone': '9811002233',
      'email': 'orders@universalmed.com',
      'address': 'Pharma Wholesale Hub, GIDC',
      'balance_due': 12500.0,
      'rating': 4.8,
      'created_at': now.toIso8601String(),
    });

    // Sample Sales
    await _insertSampleSale(txn, bizId, 'MED-1001', 'cust_med_01', 'Rajesh Sharma', '9876511223', [
      {'prod_id': 'prod_med_dolo', 'name': 'Dolo 650mg Tablet', 'qty': 2.0, 'price': 30.50, 'tax_rate': 12.0, 'batch': 'B-DL01', 'expiry': '2026-11-01'},
      {'prod_id': 'prod_med_cough', 'name': 'Benadryl Cough Formula', 'qty': 1.0, 'price': 115.00, 'tax_rate': 12.0, 'batch': 'B-BN77', 'expiry': '2026-12-15'},
    ], 'UPI', doctorName: 'Dr. R. K. Sen');
  }

  // -------------------------------------------------------------
  // 2. RESTAURANT / CAFE SEED
  // -------------------------------------------------------------
  static Future<void> _seedRestaurant(Transaction txn) async {
    const bizId = 'biz_rest_01';
    final now = DateTime.now();

    await txn.insert(DatabaseTables.tableBusinesses, {
      'id': bizId,
      'name': 'The Urban Bistro & Cafe',
      'type': BusinessType.restaurant.id,
      'address': 'Lane 5, Koregaon Park Gourmet Street',
      'phone': '+91 98234 56789',
      'email': 'hello@urbanbistro.com',
      'tax_number': '27FGHIJ5678K1Z2',
      'currency_symbol': '₹',
      'currency_code': 'INR',
      'invoice_prefix': 'UB-',
      'default_tax_rate': 5.0,
      'receipt_footer': '100% freshly brewed and stone-baked. Have a delightful day!',
      'created_at': now.toIso8601String(),
      'settings_json': jsonEncode({
        'enable_kot': true,
        'table_count': 12,
        'tables': [
          {'id': 'T1', 'name': 'Table 1', 'capacity': 2, 'status': 'Occupied', 'section': 'Indoor'},
          {'id': 'T2', 'name': 'Table 2', 'capacity': 4, 'status': 'Free', 'section': 'Indoor'},
          {'id': 'T3', 'name': 'Table 3', 'capacity': 4, 'status': 'Occupied', 'section': 'Indoor'},
          {'id': 'T4', 'name': 'Table 4', 'capacity': 6, 'status': 'Free', 'section': 'Indoor'},
          {'id': 'T5', 'name': 'Table 5 (Patio)', 'capacity': 2, 'status': 'Reserved', 'section': 'Outdoor Patio'},
          {'id': 'T6', 'name': 'Table 6 (Patio)', 'capacity': 4, 'status': 'Free', 'section': 'Outdoor Patio'},
          {'id': 'T7', 'name': 'Table 7 (Booth)', 'capacity': 6, 'status': 'Billing', 'section': 'Lounge'},
          {'id': 'T8', 'name': 'Table 8 (Booth)', 'capacity': 8, 'status': 'Free', 'section': 'Lounge'},
        ],
      }),
    });

    await txn.insert(DatabaseTables.tableAppUsers, {
      'id': 'user_rest_mgr',
      'business_id': bizId,
      'name': 'Chef Marco (Head Chef & Manager)',
      'role': 'Owner',
      'pin_code': '1234',
    });

    final categories = [
      {'id': 'cat_rest_coffee', 'name': 'Artisan Coffee & Tea', 'icon': 'local_cafe', 'color_hex': '#EA580C'},
      {'id': 'cat_rest_pizza', 'name': 'Woodfired Pizzas', 'icon': 'local_pizza', 'color_hex': '#E11D48'},
      {'id': 'cat_rest_pasta', 'name': 'Gourmet Pastas', 'icon': 'dinner_dining', 'color_hex': '#D97706'},
      {'id': 'cat_rest_starters', 'name': 'Small Plates & Starters', 'icon': 'tapas', 'color_hex': '#10B981'},
      {'id': 'cat_rest_desserts', 'name': 'Decadent Desserts', 'icon': 'cake', 'color_hex': '#8B5CF6'},
    ];
    for (final c in categories) {
      await txn.insert(DatabaseTables.tableCategories, {
        'id': c['id']!,
        'business_id': bizId,
        'name': c['name']!,
        'icon': c['icon']!,
        'color_hex': c['color_hex']!,
        'sort_order': 0,
      });
    }

    final products = [
      {
        'id': 'prod_rest_cappuccino',
        'category_id': 'cat_rest_coffee',
        'name': 'Hazelnut Cappuccino',
        'sku': 'UB-COF-01',
        'purchase_price': 40.00,
        'selling_price': 180.00,
        'mrp': 180.00,
        'stock_qty': 999.0,
        'unit': 'cup',
        'tax_rate': 5.0,
        'business_metadata_json': jsonEncode({
          'is_veg': true,
          'prep_time_minutes': 5,
          'is_kitchen_item': true,
          'modifier_groups': [
            {'name': 'Milk Choice', 'options': ['Whole Milk', 'Oat Milk (+₹40)', 'Almond Milk (+₹50)']},
            {'name': 'Sweetness', 'options': ['Unsweetened', 'Standard', 'Extra Sweet']},
          ],
        }),
      },
      {
        'id': 'prod_rest_margherita',
        'category_id': 'cat_rest_pizza',
        'name': 'Classic Margherita Pizza 11"',
        'sku': 'UB-PIZ-01',
        'purchase_price': 120.00,
        'selling_price': 395.00,
        'mrp': 395.00,
        'stock_qty': 999.0,
        'unit': 'portion',
        'tax_rate': 5.0,
        'business_metadata_json': jsonEncode({
          'is_veg': true,
          'prep_time_minutes': 15,
          'is_kitchen_item': true,
          'modifier_groups': [
            {'name': 'Crust', 'options': ['Hand-Tossed Classic', 'Thin & Crispy', 'Cheese Burst (+₹80)']},
            {'name': 'Add-ons', 'options': ['Extra Buffalo Mozzarella (+₹70)', 'Fresh Basil & Sun-dried Tomatoes (+₹50)', 'Jalapenos (+₹30)']},
          ],
        }),
      },
      {
        'id': 'prod_rest_truffle_pasta',
        'category_id': 'cat_rest_pasta',
        'name': 'Creamy Truffle Mushroom Fettuccine',
        'sku': 'UB-PAS-02',
        'purchase_price': 140.00,
        'selling_price': 445.00,
        'mrp': 445.00,
        'stock_qty': 999.0,
        'unit': 'portion',
        'tax_rate': 5.0,
        'business_metadata_json': jsonEncode({
          'is_veg': true,
          'prep_time_minutes': 14,
          'is_kitchen_item': true,
          'modifier_groups': [
            {'name': 'Pasta Type', 'options': ['Fettuccine', 'Penne', 'Spaghetti']},
            {'name': 'Spice Level', 'options': ['Mild & Creamy', 'Zesty Herb', 'Chilli Flakes Touch']},
          ],
        }),
      },
      {
        'id': 'prod_rest_garlic_bread',
        'category_id': 'cat_rest_starters',
        'name': 'Artisanal Cheesy Garlic Pull-Apart',
        'sku': 'UB-STA-01',
        'purchase_price': 60.00,
        'selling_price': 220.00,
        'mrp': 220.00,
        'stock_qty': 999.0,
        'unit': 'plate',
        'tax_rate': 5.0,
        'business_metadata_json': jsonEncode({
          'is_veg': true,
          'prep_time_minutes': 10,
          'is_kitchen_item': true,
          'modifier_groups': [
            {'name': 'Dip', 'options': ['Herbed Garlic Butter', 'Spicy Marinara (+₹30)']},
          ],
        }),
      },
      {
        'id': 'prod_rest_tiramisu',
        'category_id': 'cat_rest_desserts',
        'name': 'Venetian Espresso Tiramisu',
        'sku': 'UB-DES-01',
        'purchase_price': 80.00,
        'selling_price': 285.00,
        'mrp': 285.00,
        'stock_qty': 20.0,
        'unit': 'slice',
        'tax_rate': 5.0,
        'business_metadata_json': jsonEncode({
          'is_veg': false,
          'prep_time_minutes': 2,
          'is_kitchen_item': false,
          'modifier_groups': [],
        }),
      },
    ];

    for (final p in products) {
      await txn.insert(DatabaseTables.tableProducts, {
        'id': p['id']!,
        'business_id': bizId,
        'category_id': p['category_id']!,
        'name': p['name']!,
        'sku': p['sku']!,
        'purchase_price': p['purchase_price']!,
        'selling_price': p['selling_price']!,
        'mrp': p['mrp']!,
        'stock_qty': p['stock_qty']!,
        'min_stock_alert': 5.0,
        'unit': p['unit']!,
        'tax_rate': p['tax_rate']!,
        'is_active': 1,
        'created_at': now.toIso8601String(),
        'business_metadata_json': p['business_metadata_json']!,
      });
    }

    // Sample Sales
    await _insertSampleSale(txn, bizId, 'UB-4001', null, 'Walk-in Guest', '9988776655', [
      {'prod_id': 'prod_rest_margherita', 'name': 'Classic Margherita Pizza 11"', 'qty': 1.0, 'price': 395.00, 'tax_rate': 5.0, 'modifiers': 'Crust: Thin & Crispy'},
      {'prod_id': 'prod_rest_cappuccino', 'name': 'Hazelnut Cappuccino', 'qty': 2.0, 'price': 180.00, 'tax_rate': 5.0, 'modifiers': 'Oat Milk (+₹40)'},
    ], 'Card', tableNo: 'Table 1', orderType: 'Dine-In');
  }

  // -------------------------------------------------------------
  // 3. GROCERY / SUPERMARKET SEED
  // -------------------------------------------------------------
  static Future<void> _seedGrocery(Transaction txn) async {
    const bizId = 'biz_groc_01';
    final now = DateTime.now();

    await txn.insert(DatabaseTables.tableBusinesses, {
      'id': bizId,
      'name': 'Fresh Harvest Supermarket',
      'type': BusinessType.grocery.id,
      'address': 'Grand Bazaar complex, Ring Road',
      'phone': '+91 97654 32109',
      'email': 'support@freshharvest.in',
      'tax_number': '27KLMNO9012P1Z8',
      'currency_symbol': '₹',
      'currency_code': 'INR',
      'invoice_prefix': 'FH-',
      'default_tax_rate': 5.0,
      'receipt_footer': 'Eat Fresh, Live Healthy. Check your perishable items before leaving.',
      'created_at': now.toIso8601String(),
      'settings_json': jsonEncode({
        'fast_checkout_barcode_mode': true,
        'support_loose_weight': true,
      }),
    });

    final categories = [
      {'id': 'cat_groc_grains', 'name': 'Staples, Rice & Grains', 'icon': 'grain', 'color_hex': '#D97706'},
      {'id': 'cat_groc_produce', 'name': 'Fresh Produce & Fruits', 'icon': 'eco', 'color_hex': '#16A34A'},
      {'id': 'cat_groc_dairy', 'name': 'Dairy & Eggs', 'icon': 'egg', 'color_hex': '#0284C7'},
      {'id': 'cat_groc_oil', 'name': 'Oils & Condiments', 'icon': 'liquor', 'color_hex': '#EAB308'},
      {'id': 'cat_groc_packaged', 'name': 'Snacks & Packaged Food', 'icon': 'fastfood', 'color_hex': '#EA580C'},
    ];
    for (final c in categories) {
      await txn.insert(DatabaseTables.tableCategories, {
        'id': c['id']!,
        'business_id': bizId,
        'name': c['name']!,
        'icon': c['icon']!,
        'color_hex': c['color_hex']!,
        'sort_order': 0,
      });
    }

    final products = [
      {
        'id': 'prod_groc_rice',
        'category_id': 'cat_groc_grains',
        'name': 'Daawat Rozana Basmati Rice (Loose)',
        'sku': 'FH-ST-RICE',
        'barcode': '890103001',
        'purchase_price': 65.00,
        'selling_price': 85.00,
        'mrp': 95.00,
        'stock_qty': 450.0,
        'min_stock_alert': 50.0,
        'unit': 'kg',
        'brand': 'Daawat',
        'tax_rate': 0.0,
        'business_metadata_json': jsonEncode({
          'is_loose_weight': true,
          'per_gram_price': 0.085,
          'rack_location': 'Aisle 2 - Bay 4',
          'bulk_pricing_tiers': [
            {'min_qty': 10, 'discount_percent': 5.0},
            {'min_qty': 25, 'discount_percent': 10.0},
          ],
        }),
      },
      {
        'id': 'prod_groc_onions',
        'category_id': 'cat_groc_produce',
        'name': 'Nashik Red Onions (Fresh)',
        'sku': 'FH-PR-ONION',
        'barcode': '890103002',
        'purchase_price': 22.00,
        'selling_price': 32.00,
        'mrp': 35.00,
        'stock_qty': 280.0,
        'min_stock_alert': 30.0,
        'unit': 'kg',
        'brand': 'FarmDirect',
        'tax_rate': 0.0,
        'business_metadata_json': jsonEncode({
          'is_loose_weight': true,
          'per_gram_price': 0.032,
          'rack_location': 'Produce Bin 1',
        }),
      },
      {
        'id': 'prod_groc_milk',
        'category_id': 'cat_groc_dairy',
        'name': 'Amul Taaza Homogenised Toned Milk 1L',
        'sku': 'FH-DA-MILK1L',
        'barcode': '890126201005',
        'purchase_price': 58.00,
        'selling_price': 68.00,
        'mrp': 70.00,
        'stock_qty': 60.0,
        'min_stock_alert': 15.0,
        'unit': 'pack',
        'brand': 'Amul',
        'tax_rate': 0.0,
        'business_metadata_json': jsonEncode({
          'is_loose_weight': false,
          'rack_location': 'Chiller 3',
        }),
      },
      {
        'id': 'prod_groc_olive_oil',
        'category_id': 'cat_groc_oil',
        'name': 'Borges Extra Virgin Olive Oil 500ml',
        'sku': 'FH-OIL-BOR500',
        'barcode': '841017901234',
        'purchase_price': 480.00,
        'selling_price': 620.00,
        'mrp': 699.00,
        'stock_qty': 24.0,
        'min_stock_alert': 5.0,
        'unit': 'bottle',
        'brand': 'Borges',
        'tax_rate': 5.0,
        'business_metadata_json': jsonEncode({
          'is_loose_weight': false,
          'rack_location': 'Aisle 3 - Shelf C',
        }),
      },
    ];

    for (final p in products) {
      await txn.insert(DatabaseTables.tableProducts, {
        'id': p['id']!,
        'business_id': bizId,
        'category_id': p['category_id']!,
        'name': p['name']!,
        'sku': p['sku']!,
        'barcode': p['barcode'] ?? '',
        'purchase_price': p['purchase_price']!,
        'selling_price': p['selling_price']!,
        'mrp': p['mrp']!,
        'stock_qty': p['stock_qty']!,
        'min_stock_alert': p['min_stock_alert']!,
        'unit': p['unit']!,
        'brand': p['brand'] ?? '',
        'tax_rate': p['tax_rate']!,
        'is_active': 1,
        'created_at': now.toIso8601String(),
        'business_metadata_json': p['business_metadata_json']!,
      });
    }

    // Sample Sales
    await _insertSampleSale(txn, bizId, 'FH-2001', null, 'Sunita Deshmukh', '9123456780', [
      {'prod_id': 'prod_groc_rice', 'name': 'Daawat Rozana Basmati Rice (Loose)', 'qty': 5.0, 'price': 85.00, 'tax_rate': 0.0},
      {'prod_id': 'prod_groc_milk', 'name': 'Amul Taaza Milk 1L', 'qty': 2.0, 'price': 68.00, 'tax_rate': 0.0},
    ], 'UPI');
  }

  // -------------------------------------------------------------
  // 3B. GYM & FITNESS CENTER SEED
  // -------------------------------------------------------------
  static Future<void> _seedGym(Transaction txn) async {
    const bizId = 'biz_gym_01';
    final now = DateTime.now();

    await txn.insert(DatabaseTables.tableBusinesses, {
      'id': bizId,
      'name': 'IronPulse Fitness & Gym',
      'type': BusinessType.gym.id,
      'address': 'Level 3, Olympic Towers, Ring Road',
      'phone': '+91 98220 55667',
      'email': 'contact@ironpulsefitness.com',
      'tax_number': '27GYMFIT1234Z9',
      'currency_symbol': '₹',
      'currency_code': 'INR',
      'invoice_prefix': 'GYM-',
      'default_tax_rate': 18.0,
      'receipt_footer': 'Push your limits at IronPulse! Train hard, stay strong.',
      'created_at': now.toIso8601String(),
      'settings_json': jsonEncode({
        'membership_checkin_enabled': true,
        'pt_trainer_booking': true,
        'locker_management': true,
      }),
    });

    final categories = [
      {'id': 'cat_gym_memberships', 'name': 'Membership Passes', 'icon': 'card_membership', 'color_hex': '#FF5722'},
      {'id': 'cat_gym_pt', 'name': 'Personal Training', 'icon': 'sports_gymnastics', 'color_hex': '#EA580C'},
      {'id': 'cat_gym_nutrition', 'name': 'Supplements & Protein', 'icon': 'fitness_center', 'color_hex': '#10B981'},
      {'id': 'cat_gym_beverages', 'name': 'Energy Drinks & Shakes', 'icon': 'local_drink', 'color_hex': '#06B6D4'},
      {'id': 'cat_gym_gear', 'name': 'Apparel & Accessories', 'icon': 'sports_handball', 'color_hex': '#8B5CF6'},
    ];
    for (final c in categories) {
      await txn.insert(DatabaseTables.tableCategories, {
        'id': c['id']!,
        'business_id': bizId,
        'name': c['name']!,
        'icon': c['icon']!,
        'color_hex': c['color_hex']!,
        'sort_order': 0,
      });
    }

    final products = [
      {
        'id': 'prod_gym_pass_monthly',
        'category_id': 'cat_gym_memberships',
        'name': 'Monthly Standard Gym Pass (30 Days)',
        'sku': 'GYM-MEM-30D',
        'barcode': '890200101',
        'purchase_price': 800.00,
        'selling_price': 1500.00,
        'mrp': 1800.00,
        'stock_qty': 999.0,
        'min_stock_alert': 10.0,
        'unit': 'pass',
        'brand': 'IronPulse Club',
        'tax_rate': 18.0,
        'business_metadata_json': jsonEncode({
          'is_gym_plan': true,
          'plan_days': 30,
          'has_trainer': false,
        }),
      },
      {
        'id': 'prod_gym_pass_annual',
        'category_id': 'cat_gym_memberships',
        'name': 'Annual VIP All-Access Membership (365 Days)',
        'sku': 'GYM-MEM-365D',
        'barcode': '890200102',
        'purchase_price': 6000.00,
        'selling_price': 14000.00,
        'mrp': 18000.00,
        'stock_qty': 999.0,
        'min_stock_alert': 5.0,
        'unit': 'pass',
        'brand': 'IronPulse Club',
        'tax_rate': 18.0,
        'business_metadata_json': jsonEncode({
          'is_gym_plan': true,
          'plan_days': 365,
          'has_trainer': true,
        }),
      },
      {
        'id': 'prod_gym_pt_10',
        'category_id': 'cat_gym_pt',
        'name': 'Personal Training Pack (10 Sessions)',
        'sku': 'GYM-PT-10S',
        'barcode': '890200103',
        'purchase_price': 3000.00,
        'selling_price': 6000.00,
        'mrp': 7500.00,
        'stock_qty': 100.0,
        'min_stock_alert': 5.0,
        'unit': 'sessions',
        'brand': 'Elite Coaching',
        'tax_rate': 18.0,
        'business_metadata_json': jsonEncode({
          'is_gym_plan': true,
          'plan_days': 60,
          'has_trainer': true,
        }),
      },
      {
        'id': 'prod_gym_whey',
        'category_id': 'cat_gym_nutrition',
        'name': 'Optimum Nutrition Gold Standard 100% Whey 2kg',
        'sku': 'GYM-NUTR-ON2K',
        'barcode': '890200104',
        'purchase_price': 2400.00,
        'selling_price': 3200.00,
        'mrp': 3699.00,
        'stock_qty': 35.0,
        'min_stock_alert': 8.0,
        'unit': 'tub',
        'brand': 'Optimum Nutrition',
        'tax_rate': 18.0,
        'business_metadata_json': jsonEncode({
          'is_gym_plan': false,
        }),
      },
      {
        'id': 'prod_gym_monster',
        'category_id': 'cat_gym_beverages',
        'name': 'Monster Energy Ultra Zero Can 500ml',
        'sku': 'GYM-BV-MNST',
        'barcode': '890200105',
        'purchase_price': 85.00,
        'selling_price': 120.00,
        'mrp': 125.00,
        'stock_qty': 90.0,
        'min_stock_alert': 15.0,
        'unit': 'can',
        'brand': 'Monster',
        'tax_rate': 28.0,
        'business_metadata_json': jsonEncode({
          'is_gym_plan': false,
        }),
      },
      {
        'id': 'prod_gym_shaker',
        'category_id': 'cat_gym_gear',
        'name': 'IronPulse Cyclone Shaker Bottle 700ml',
        'sku': 'GYM-GR-SHK7',
        'barcode': '890200106',
        'purchase_price': 180.00,
        'selling_price': 350.00,
        'mrp': 450.00,
        'stock_qty': 45.0,
        'min_stock_alert': 10.0,
        'unit': 'pc',
        'brand': 'IronPulse',
        'tax_rate': 12.0,
        'business_metadata_json': jsonEncode({
          'is_gym_plan': false,
        }),
      },
    ];

    for (final p in products) {
      await txn.insert(DatabaseTables.tableProducts, {
        'id': p['id']!,
        'business_id': bizId,
        'category_id': p['category_id']!,
        'name': p['name']!,
        'sku': p['sku']!,
        'barcode': p['barcode'] ?? '',
        'purchase_price': p['purchase_price']!,
        'selling_price': p['selling_price']!,
        'mrp': p['mrp']!,
        'stock_qty': p['stock_qty']!,
        'min_stock_alert': p['min_stock_alert']!,
        'unit': p['unit']!,
        'brand': p['brand'] ?? '',
        'tax_rate': p['tax_rate']!,
        'is_active': 1,
        'created_at': now.toIso8601String(),
        'business_metadata_json': p['business_metadata_json']!,
      });
    }

    // Sample Sales
    await _insertSampleSale(txn, bizId, 'GYM-101', null, 'Devendra Patel', '9822011223', [
      {'prod_id': 'prod_gym_pass_annual', 'name': 'Annual VIP All-Access Membership', 'qty': 1.0, 'price': 14000.00, 'tax_rate': 18.0},
    ], 'UPI');
  }

  // -------------------------------------------------------------
  // 3C. LIBRARY & BOOK STORE SEED
  // -------------------------------------------------------------
  static Future<void> _seedLibrary(Transaction txn) async {
    const bizId = 'biz_lib_01';
    final now = DateTime.now();

    await txn.insert(DatabaseTables.tableBusinesses, {
      'id': bizId,
      'name': 'Athenaeum Central Library',
      'type': BusinessType.library.id,
      'address': '7 Heritage Boulevard, Knowledge Square',
      'phone': '+91 98450 11998',
      'email': 'info@athenaeumlib.org',
      'tax_number': '27LIBORG8899A1',
      'currency_symbol': '₹',
      'currency_code': 'INR',
      'invoice_prefix': 'LIB-',
      'default_tax_rate': 0.0,
      'receipt_footer': 'Reading is knowledge. Keep pages pristine and return on time!',
      'created_at': now.toIso8601String(),
      'settings_json': jsonEncode({
        'circulation_ledger_enabled': true,
        'overdue_fines_per_day': 5.0,
        'shelf_rack_mapping': true,
      }),
    });

    final categories = [
      {'id': 'cat_lib_membership', 'name': 'Reader Subscriptions', 'icon': 'badge', 'color_hex': '#0369A1'},
      {'id': 'cat_lib_tech', 'name': 'Computer Science & Tech', 'icon': 'terminal', 'color_hex': '#0284C7'},
      {'id': 'cat_lib_business', 'name': 'Business & Economics', 'icon': 'trending_up', 'color_hex': '#F59E0B'},
      {'id': 'cat_lib_history', 'name': 'History & Culture', 'icon': 'auto_stories', 'color_hex': '#8B5CF6'},
      {'id': 'cat_lib_services', 'name': 'Library Services & Fines', 'icon': 'receipt_long', 'color_hex': '#10B981'},
    ];
    for (final c in categories) {
      await txn.insert(DatabaseTables.tableCategories, {
        'id': c['id']!,
        'business_id': bizId,
        'name': c['name']!,
        'icon': c['icon']!,
        'color_hex': c['color_hex']!,
        'sort_order': 0,
      });
    }

    final products = [
      {
        'id': 'prod_lib_mem_annual',
        'category_id': 'cat_lib_membership',
        'name': 'Annual Library Reader Membership Pass',
        'sku': 'LIB-MEM-ANN',
        'barcode': '9780000001',
        'purchase_price': 200.00,
        'selling_price': 800.00,
        'mrp': 1000.00,
        'stock_qty': 999.0,
        'min_stock_alert': 10.0,
        'unit': 'year',
        'brand': 'Athenaeum Library',
        'tax_rate': 0.0,
        'business_metadata_json': jsonEncode({
          'isbn': '',
          'rack_location': 'Front Circulation Desk',
        }),
      },
      {
        'id': 'prod_lib_cleancode',
        'category_id': 'cat_lib_tech',
        'name': 'Clean Code: Handbook of Agile Software Craftsmanship',
        'sku': 'LIB-BK-CLNCD',
        'barcode': '9780132350884',
        'purchase_price': 450.00,
        'selling_price': 650.00,
        'mrp': 799.00,
        'stock_qty': 5.0,
        'min_stock_alert': 1.0,
        'unit': 'copy',
        'brand': 'Prentice Hall',
        'tax_rate': 0.0,
        'business_metadata_json': jsonEncode({
          'isbn': '978-0132350884',
          'author': 'Robert C. Martin',
          'rack_location': 'Rack CS-01, Shelf 2',
        }),
      },
      {
        'id': 'prod_lib_psychology',
        'category_id': 'cat_lib_business',
        'name': 'The Psychology of Money',
        'sku': 'LIB-BK-PSYMON',
        'barcode': '9789390166268',
        'purchase_price': 260.00,
        'selling_price': 399.00,
        'mrp': 499.00,
        'stock_qty': 6.0,
        'min_stock_alert': 2.0,
        'unit': 'copy',
        'brand': 'Jaico Publishing',
        'tax_rate': 0.0,
        'business_metadata_json': jsonEncode({
          'isbn': '978-9390166268',
          'author': 'Morgan Housel',
          'rack_location': 'Rack B-03, Shelf 1',
        }),
      },
      {
        'id': 'prod_lib_sapiens',
        'category_id': 'cat_lib_history',
        'name': 'Sapiens: A Brief History of Humankind',
        'sku': 'LIB-BK-SAPIENS',
        'barcode': '9780099590088',
        'purchase_price': 340.00,
        'selling_price': 499.00,
        'mrp': 599.00,
        'stock_qty': 5.0,
        'min_stock_alert': 1.0,
        'unit': 'copy',
        'brand': 'Vintage Books',
        'tax_rate': 0.0,
        'business_metadata_json': jsonEncode({
          'isbn': '978-0099590088',
          'author': 'Yuval Noah Harari',
          'rack_location': 'Rack H-02, Shelf 4',
        }),
      },
      {
        'id': 'prod_lib_fine_fee',
        'category_id': 'cat_lib_services',
        'name': 'Overdue Book Late Return Fine',
        'sku': 'LIB-FEE-LATE',
        'barcode': '9780000002',
        'purchase_price': 0.00,
        'selling_price': 20.00,
        'mrp': 20.00,
        'stock_qty': 9999.0,
        'min_stock_alert': 1.0,
        'unit': 'fee',
        'brand': 'Circulation Services',
        'tax_rate': 0.0,
        'business_metadata_json': jsonEncode({
          'isbn': '',
          'rack_location': 'Helpdesk',
        }),
      },
      {
        'id': 'prod_lib_print_service',
        'category_id': 'cat_lib_services',
        'name': 'Reading Room Document Printing / Xerox',
        'sku': 'LIB-SRV-PRINT',
        'barcode': '9780000003',
        'purchase_price': 1.50,
        'selling_price': 5.00,
        'mrp': 5.00,
        'stock_qty': 5000.0,
        'min_stock_alert': 100.0,
        'unit': 'page',
        'brand': 'Library Media Center',
        'tax_rate': 18.0,
        'business_metadata_json': jsonEncode({
          'isbn': '',
          'rack_location': 'Stationery Counter',
        }),
      },
    ];

    for (final p in products) {
      await txn.insert(DatabaseTables.tableProducts, {
        'id': p['id']!,
        'business_id': bizId,
        'category_id': p['category_id']!,
        'name': p['name']!,
        'sku': p['sku']!,
        'barcode': p['barcode'] ?? '',
        'purchase_price': p['purchase_price']!,
        'selling_price': p['selling_price']!,
        'mrp': p['mrp']!,
        'stock_qty': p['stock_qty']!,
        'min_stock_alert': p['min_stock_alert']!,
        'unit': p['unit']!,
        'brand': p['brand'] ?? '',
        'tax_rate': p['tax_rate']!,
        'is_active': 1,
        'created_at': now.toIso8601String(),
        'business_metadata_json': p['business_metadata_json']!,
      });
    }

    // Sample Sales
    await _insertSampleSale(txn, bizId, 'LIB-1001', null, 'Meera Iyer', '9845077889', [
      {'prod_id': 'prod_lib_mem_annual', 'name': 'Annual Library Reader Membership Pass', 'qty': 1.0, 'price': 800.00, 'tax_rate': 0.0},
    ], 'Cash');
  }

  // -------------------------------------------------------------
  // 4. ELECTRONICS SHOP SEED
  // -------------------------------------------------------------
  static Future<void> _seedElectronics(Transaction txn) async {
    const bizId = 'biz_elec_01';
    final now = DateTime.now();

    await txn.insert(DatabaseTables.tableBusinesses, {
      'id': bizId,
      'name': 'Nexus Electronics & Gadgets',
      'type': BusinessType.electronics.id,
      'address': 'Tech Arcade, MG Road Silicon Valley',
      'phone': '+91 99001 12233',
      'email': 'sales@nexuselectronics.com',
      'tax_number': '27PQRST3456Q1Z1',
      'currency_symbol': '₹',
      'currency_code': 'INR',
      'invoice_prefix': 'NX-',
      'default_tax_rate': 18.0,
      'receipt_footer': 'Manufacturer warranty valid at all authorized service centres with this invoice.',
      'created_at': now.toIso8601String(),
      'settings_json': jsonEncode({
        'require_imei_for_phones': true,
        'service_tracking_enabled': true,
      }),
    });

    final categories = [
      {'id': 'cat_elec_phones', 'name': 'Smartphones & Tablets', 'icon': 'smartphone', 'color_hex': '#4F46E5'},
      {'id': 'cat_elec_laptops', 'name': 'Laptops & Computers', 'icon': 'laptop_chromebook', 'color_hex': '#2563EB'},
      {'id': 'cat_elec_audio', 'name': 'Audio, Earphones & ANC', 'icon': 'headphones', 'color_hex': '#06B6D4'},
      {'id': 'cat_elec_wearables', 'name': 'Smartwatches & Fit Bands', 'icon': 'watch', 'color_hex': '#10B981'},
    ];
    for (final c in categories) {
      await txn.insert(DatabaseTables.tableCategories, {
        'id': c['id']!,
        'business_id': bizId,
        'name': c['name']!,
        'icon': c['icon']!,
        'color_hex': c['color_hex']!,
        'sort_order': 0,
      });
    }

    final products = [
      {
        'id': 'prod_elec_iphone15',
        'category_id': 'cat_elec_phones',
        'name': 'Apple iPhone 15 Pro 128GB',
        'sku': 'NX-APL-IP15P',
        'barcode': '195949012345',
        'purchase_price': 105000.00,
        'selling_price': 124900.00,
        'mrp': 134900.00,
        'stock_qty': 4.0,
        'min_stock_alert': 2.0,
        'unit': 'unit',
        'brand': 'Apple',
        'tax_rate': 18.0,
        'business_metadata_json': jsonEncode({
          'model_name': 'iPhone 15 Pro',
          'specs': {'Display': '6.1" Super Retina XDR', 'Chip': 'A17 Pro', 'Storage': '128GB', 'Color': 'Natural Titanium'},
          'warranty_months': 12,
          'imei_list': [
            '359203118234501',
            '359203118234502',
            '359203118234503',
            '359203118234504',
          ],
          'has_amc': true,
        }),
      },
      {
        'id': 'prod_elec_macbook_air',
        'category_id': 'cat_elec_laptops',
        'name': 'MacBook Air 13" M3 (16GB, 512GB SSD)',
        'sku': 'NX-APL-MBA13',
        'barcode': '195949098765',
        'purchase_price': 112000.00,
        'selling_price': 129900.00,
        'mrp': 134900.00,
        'stock_qty': 3.0,
        'min_stock_alert': 1.0,
        'unit': 'unit',
        'brand': 'Apple',
        'tax_rate': 18.0,
        'business_metadata_json': jsonEncode({
          'model_name': 'MacBook Air M3',
          'specs': {'Processor': 'Apple M3 8-Core', 'RAM': '16GB Unified', 'SSD': '512GB', 'Color': 'Midnight Blue'},
          'warranty_months': 12,
          'imei_list': ['C02FL988MD6M', 'C02FL989MD6N', 'C02FL990MD6P'],
          'has_amc': true,
        }),
      },
      {
        'id': 'prod_elec_sony_anc',
        'category_id': 'cat_elec_audio',
        'name': 'Sony WH-1000XM5 Noise Cancelling Headphones',
        'sku': 'NX-SNY-WHXM5',
        'barcode': '454873613256',
        'purchase_price': 22500.00,
        'selling_price': 28990.00,
        'mrp': 34990.00,
        'stock_qty': 8.0,
        'min_stock_alert': 2.0,
        'unit': 'unit',
        'brand': 'Sony',
        'tax_rate': 18.0,
        'business_metadata_json': jsonEncode({
          'model_name': 'WH-1000XM5',
          'specs': {'Battery': '30 Hours', 'Driver': '30mm Carbon Fiber', 'Color': 'Silver'},
          'warranty_months': 12,
          'imei_list': ['SNYXM50101', 'SNYXM50102', 'SNYXM50103'],
        }),
      },
    ];

    for (final p in products) {
      await txn.insert(DatabaseTables.tableProducts, {
        'id': p['id']!,
        'business_id': bizId,
        'category_id': p['category_id']!,
        'name': p['name']!,
        'sku': p['sku']!,
        'barcode': p['barcode'] ?? '',
        'purchase_price': p['purchase_price']!,
        'selling_price': p['selling_price']!,
        'mrp': p['mrp']!,
        'stock_qty': p['stock_qty']!,
        'min_stock_alert': p['min_stock_alert']!,
        'unit': p['unit']!,
        'brand': p['brand'] ?? '',
        'tax_rate': p['tax_rate']!,
        'is_active': 1,
        'created_at': now.toIso8601String(),
        'business_metadata_json': p['business_metadata_json']!,
      });
    }

    // Sample Sales
    await _insertSampleSale(txn, bizId, 'NX-9001', null, 'Vikram Malhotra', '9890011223', [
      {
        'prod_id': 'prod_elec_sony_anc',
        'name': 'Sony WH-1000XM5 Headphones',
        'qty': 1.0,
        'price': 28990.00,
        'tax_rate': 18.0,
        'serial': 'SNYXM50101',
      },
    ], 'Credit/Due');
  }

  // -------------------------------------------------------------
  // 5. GARMENT / APPAREL SHOP SEED
  // -------------------------------------------------------------
  static Future<void> _seedGarment(Transaction txn) async {
    const bizId = 'biz_garm_01';
    final now = DateTime.now();

    await txn.insert(DatabaseTables.tableBusinesses, {
      'id': bizId,
      'name': 'Vogue Thread Garments & Boutique',
      'type': BusinessType.garment.id,
      'address': 'Fashion Walkway, High Street Galleria',
      'phone': '+91 99112 23344',
      'email': 'care@voguethread.com',
      'tax_number': '27UVWXYZ7890R1Z0',
      'currency_symbol': '₹',
      'currency_code': 'INR',
      'invoice_prefix': 'VT-',
      'default_tax_rate': 12.0,
      'receipt_footer': 'Hassle-free size exchange within 7 days with intact brand tags.',
      'created_at': now.toIso8601String(),
      'settings_json': jsonEncode({
        'enable_size_color_matrix': true,
        'enable_exchange_without_full_return': true,
      }),
    });

    final categories = [
      {'id': 'cat_garm_men_shirts', 'name': 'Men Formal & Casual Shirts', 'icon': 'male', 'color_hex': '#9333EA'},
      {'id': 'cat_garm_denim', 'name': 'Denim & Trousers', 'icon': 'checkroom', 'color_hex': '#3B82F6'},
      {'id': 'cat_garm_women_ethnic', 'name': 'Women Kurtas & Ethnic', 'icon': 'female', 'color_hex': '#F43F5E'},
      {'id': 'cat_garm_winterwear', 'name': 'Hoodies & Winterwear', 'icon': 'ac_unit', 'color_hex': '#6366F1'},
    ];
    for (final c in categories) {
      await txn.insert(DatabaseTables.tableCategories, {
        'id': c['id']!,
        'business_id': bizId,
        'name': c['name']!,
        'icon': c['icon']!,
        'color_hex': c['color_hex']!,
        'sort_order': 0,
      });
    }

    final products = [
      {
        'id': 'prod_garm_linen_shirt',
        'category_id': 'cat_garm_men_shirts',
        'name': 'Pure Linen Slim Fit Casual Shirt',
        'sku': 'VT-MSH-LIN01',
        'barcode': '890789001',
        'purchase_price': 750.00,
        'selling_price': 1699.00,
        'mrp': 2199.00,
        'stock_qty': 35.0,
        'min_stock_alert': 5.0,
        'unit': 'piece',
        'brand': 'Raymond Tailored',
        'tax_rate': 12.0,
        'business_metadata_json': jsonEncode({
          'season': 'Summer 2026',
          'gender': 'Men',
          'sizes': ['M', 'L', 'XL', 'XXL'],
          'colors': ['Powder Blue', 'Crisp White', 'Olive Green'],
          'variant_stock': {
            'M - Powder Blue': 4,
            'L - Powder Blue': 6,
            'XL - Powder Blue': 3,
            'M - Crisp White': 5,
            'L - Crisp White': 8,
            'XL - Crisp White': 4,
            'L - Olive Green': 5,
          },
        }),
      },
      {
        'id': 'prod_garm_denim_jeans',
        'category_id': 'cat_garm_denim',
        'name': 'Slim Tapered Stretch Denim Jeans',
        'sku': 'VT-DNM-SLIM02',
        'barcode': '890789002',
        'purchase_price': 900.00,
        'selling_price': 2299.00,
        'mrp': 2999.00,
        'stock_qty': 28.0,
        'min_stock_alert': 4.0,
        'unit': 'piece',
        'brand': 'Levi Strauss Co',
        'tax_rate': 12.0,
        'business_metadata_json': jsonEncode({
          'season': 'All-Season Core',
          'gender': 'Men',
          'sizes': ['30', '32', '34', '36'],
          'colors': ['Dark Indigo', 'Washed Grey'],
          'variant_stock': {
            '30 - Dark Indigo': 4,
            '32 - Dark Indigo': 6,
            '34 - Dark Indigo': 5,
            '32 - Washed Grey': 7,
            '34 - Washed Grey': 6,
          },
        }),
      },
      {
        'id': 'prod_garm_fleece_hoodie',
        'category_id': 'cat_garm_winterwear',
        'name': 'Heavyweight Cotton Fleece Hoodie',
        'sku': 'VT-HOD-OVR03',
        'barcode': '890789003',
        'purchase_price': 650.00,
        'selling_price': 1499.00,
        'mrp': 1999.00,
        'stock_qty': 20.0,
        'min_stock_alert': 4.0,
        'unit': 'piece',
        'brand': 'Urban Threads',
        'tax_rate': 12.0,
        'business_metadata_json': jsonEncode({
          'season': 'Autumn/Winter',
          'gender': 'Unisex',
          'sizes': ['S', 'M', 'L', 'XL'],
          'colors': ['Charcoal Black', 'Heather Grey', 'Maroon'],
          'variant_stock': {
            'M - Charcoal Black': 5,
            'L - Charcoal Black': 5,
            'M - Heather Grey': 5,
            'L - Heather Grey': 5,
          },
        }),
      },
    ];

    for (final p in products) {
      await txn.insert(DatabaseTables.tableProducts, {
        'id': p['id']!,
        'business_id': bizId,
        'category_id': p['category_id']!,
        'name': p['name']!,
        'sku': p['sku']!,
        'barcode': p['barcode'] ?? '',
        'purchase_price': p['purchase_price']!,
        'selling_price': p['selling_price']!,
        'mrp': p['mrp']!,
        'stock_qty': p['stock_qty']!,
        'min_stock_alert': p['min_stock_alert']!,
        'unit': p['unit']!,
        'brand': p['brand'] ?? '',
        'tax_rate': p['tax_rate']!,
        'is_active': 1,
        'created_at': now.toIso8601String(),
        'business_metadata_json': p['business_metadata_json']!,
      });
    }

    // Sample Sales
    await _insertSampleSale(txn, bizId, 'VT-5001', null, 'Ananya Sen', '9812345678', [
      {
        'prod_id': 'prod_garm_linen_shirt',
        'name': 'Pure Linen Casual Shirt',
        'qty': 1.0,
        'price': 1699.00,
        'tax_rate': 12.0,
        'variant': 'L - Powder Blue',
      },
    ], 'UPI');
  }

  // -------------------------------------------------------------
  // Helper to Insert Sample Sales
  // -------------------------------------------------------------
  static Future<void> _insertSampleSale(
    Transaction txn,
    String bizId,
    String invoiceNo,
    String? custId,
    String custName,
    String custPhone,
    List<Map<String, dynamic>> items,
    String paymentMethod, {
    String? doctorName,
    String? tableNo,
    String? orderType,
  }) async {
    final saleId = 'sale_$invoiceNo';
    double subtotal = 0.0;
    double taxAmount = 0.0;

    for (final item in items) {
      final qty = (item['qty'] as num).toDouble();
      final price = (item['price'] as num).toDouble();
      final tRate = (item['tax_rate'] as num).toDouble();
      final lineSubtotal = qty * price;
      final lineTax = (lineSubtotal * tRate) / 100.0;
      subtotal += lineSubtotal;
      taxAmount += lineTax;
    }

    final finalTotal = subtotal + taxAmount;
    final now = DateTime.now();

    await txn.insert(DatabaseTables.tableSales, {
      'id': saleId,
      'business_id': bizId,
      'invoice_no': invoiceNo,
      'customer_id': custId,
      'customer_name': custName,
      'customer_phone': custPhone,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'discount_amount': 0.0,
      'round_off': 0.0,
      'final_total': finalTotal,
      'payment_method': paymentMethod,
      'split_breakup_json': jsonEncode({paymentMethod: finalTotal}),
      'status': 'Completed',
      'order_type': orderType ?? 'Counter',
      'table_number': tableNo,
      'doctor_name': doctorName,
      'notes': 'Demo seed transaction',
      'created_at': now.subtract(const Duration(hours: 2)).toIso8601String(),
    });

    int itemIdx = 1;
    for (final item in items) {
      final qty = (item['qty'] as num).toDouble();
      final price = (item['price'] as num).toDouble();
      final tRate = (item['tax_rate'] as num).toDouble();
      final lineSubtotal = qty * price;
      final lineTax = (lineSubtotal * tRate) / 100.0;

      await txn.insert(DatabaseTables.tableSaleItems, {
        'id': '${saleId}_item_$itemIdx',
        'sale_id': saleId,
        'product_id': item['prod_id'],
        'product_name': item['name'],
        'sku': '',
        'quantity': qty,
        'unit_price': price,
        'discount_amount': 0.0,
        'tax_rate': tRate,
        'tax_amount': lineTax,
        'line_total': lineSubtotal + lineTax,
        'batch_number': item['batch'],
        'batch_expiry': item['expiry'],
        'serial_imei': item['serial'],
        'variant': item['variant'],
        'modifiers': item['modifiers'],
      });
      itemIdx++;
    }
  }
}
