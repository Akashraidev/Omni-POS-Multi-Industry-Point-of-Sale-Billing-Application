class DatabaseTables {
  static const String tableBusinesses = 'businesses';
  static const String tableCategories = 'categories';
  static const String tableProducts = 'products';
  static const String tableSales = 'sales';
  static const String tableSaleItems = 'sale_items';
  static const String tableCustomers = 'customers';
  static const String tableSuppliers = 'suppliers';
  static const String tablePurchases = 'purchases';
  static const String tablePurchaseItems = 'purchase_items';
  static const String tableExpenses = 'expenses';
  static const String tableStockLedger = 'stock_ledger';
  static const String tableHeldBills = 'held_bills';
  static const String tableAppUsers = 'app_users';
  static const String tableEstimates = 'estimates';
  static const String tableEstimateItems = 'estimate_items';

  static const List<String> createTableStatements = [
    '''
    CREATE TABLE IF NOT EXISTS $tableBusinesses (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      logo_url TEXT,
      address TEXT,
      phone TEXT,
      email TEXT,
      tax_number TEXT,
      currency_symbol TEXT DEFAULT '₹',
      currency_code TEXT DEFAULT 'INR',
      invoice_prefix TEXT DEFAULT 'INV-',
      default_tax_rate REAL DEFAULT 5.0,
      receipt_footer TEXT,
      created_at TEXT NOT NULL,
      settings_json TEXT
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS $tableCategories (
      id TEXT PRIMARY KEY,
      business_id TEXT NOT NULL,
      name TEXT NOT NULL,
      icon TEXT DEFAULT 'category',
      color_hex TEXT DEFAULT '#4F46E5',
      sort_order INTEGER DEFAULT 0,
      FOREIGN KEY (business_id) REFERENCES $tableBusinesses(id) ON DELETE CASCADE
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS $tableProducts (
      id TEXT PRIMARY KEY,
      business_id TEXT NOT NULL,
      category_id TEXT NOT NULL,
      name TEXT NOT NULL,
      sku TEXT NOT NULL,
      barcode TEXT DEFAULT '',
      purchase_price REAL NOT NULL,
      selling_price REAL NOT NULL,
      mrp REAL NOT NULL,
      stock_qty REAL DEFAULT 0,
      min_stock_alert REAL DEFAULT 5,
      unit TEXT DEFAULT 'pcs',
      brand TEXT DEFAULT '',
      image_url TEXT,
      tax_rate REAL DEFAULT 0,
      is_active INTEGER DEFAULT 1,
      created_at TEXT NOT NULL,
      business_metadata_json TEXT,
      FOREIGN KEY (business_id) REFERENCES $tableBusinesses(id) ON DELETE CASCADE,
      FOREIGN KEY (category_id) REFERENCES $tableCategories(id) ON DELETE RESTRICT
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS $tableSales (
      id TEXT PRIMARY KEY,
      business_id TEXT NOT NULL,
      invoice_no TEXT NOT NULL,
      customer_id TEXT,
      customer_name TEXT,
      customer_phone TEXT,
      subtotal REAL NOT NULL,
      tax_amount REAL NOT NULL,
      discount_amount REAL DEFAULT 0,
      round_off REAL DEFAULT 0,
      final_total REAL NOT NULL,
      payment_method TEXT DEFAULT 'Cash',
      split_breakup_json TEXT,
      status TEXT DEFAULT 'Completed',
      order_type TEXT DEFAULT 'Counter',
      table_number TEXT,
      doctor_name TEXT,
      notes TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY (business_id) REFERENCES $tableBusinesses(id) ON DELETE CASCADE,
      FOREIGN KEY (customer_id) REFERENCES $tableCustomers(id) ON DELETE SET NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS $tableSaleItems (
      id TEXT PRIMARY KEY,
      sale_id TEXT NOT NULL,
      product_id TEXT NOT NULL,
      product_name TEXT NOT NULL,
      sku TEXT DEFAULT '',
      quantity REAL NOT NULL,
      unit_price REAL NOT NULL,
      discount_amount REAL DEFAULT 0,
      tax_rate REAL DEFAULT 0,
      tax_amount REAL NOT NULL,
      line_total REAL NOT NULL,
      batch_number TEXT,
      batch_expiry TEXT,
      serial_imei TEXT,
      variant TEXT,
      modifiers TEXT,
      FOREIGN KEY (sale_id) REFERENCES $tableSales(id) ON DELETE CASCADE,
      FOREIGN KEY (product_id) REFERENCES $tableProducts(id) ON DELETE RESTRICT
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS $tableCustomers (
      id TEXT PRIMARY KEY,
      business_id TEXT NOT NULL,
      name TEXT NOT NULL,
      phone TEXT DEFAULT '',
      email TEXT DEFAULT '',
      address TEXT DEFAULT '',
      loyalty_points INTEGER DEFAULT 0,
      balance_due REAL DEFAULT 0,
      created_at TEXT NOT NULL,
      FOREIGN KEY (business_id) REFERENCES $tableBusinesses(id) ON DELETE CASCADE
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS $tableSuppliers (
      id TEXT PRIMARY KEY,
      business_id TEXT NOT NULL,
      name TEXT NOT NULL,
      phone TEXT DEFAULT '',
      email TEXT DEFAULT '',
      address TEXT DEFAULT '',
      balance_due REAL DEFAULT 0,
      rating REAL DEFAULT 5.0,
      created_at TEXT NOT NULL,
      FOREIGN KEY (business_id) REFERENCES $tableBusinesses(id) ON DELETE CASCADE
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS $tablePurchases (
      id TEXT PRIMARY KEY,
      business_id TEXT NOT NULL,
      supplier_id TEXT,
      supplier_name TEXT,
      invoice_no TEXT NOT NULL,
      total_amount REAL NOT NULL,
      status TEXT DEFAULT 'Received',
      notes TEXT,
      created_at TEXT NOT NULL,
      subtotal REAL,
      tax_amount REAL DEFAULT 0,
      discount_amount REAL DEFAULT 0,
      round_off REAL DEFAULT 0,
      payment_status TEXT DEFAULT 'Paid',
      payment_method TEXT DEFAULT 'Cash',
      paid_amount REAL,
      due_amount REAL DEFAULT 0,
      due_date TEXT,
      FOREIGN KEY (business_id) REFERENCES $tableBusinesses(id) ON DELETE CASCADE,
      FOREIGN KEY (supplier_id) REFERENCES $tableSuppliers(id) ON DELETE SET NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS $tablePurchaseItems (
      id TEXT PRIMARY KEY,
      purchase_id TEXT NOT NULL,
      product_id TEXT NOT NULL,
      product_name TEXT NOT NULL,
      quantity REAL NOT NULL,
      unit_cost REAL NOT NULL,
      total_cost REAL NOT NULL,
      batch_number TEXT,
      batch_expiry TEXT,
      free_quantity REAL DEFAULT 0,
      tax_rate REAL DEFAULT 0,
      tax_amount REAL DEFAULT 0,
      discount_amount REAL DEFAULT 0,
      mrp REAL,
      FOREIGN KEY (purchase_id) REFERENCES $tablePurchases(id) ON DELETE CASCADE,
      FOREIGN KEY (product_id) REFERENCES $tableProducts(id) ON DELETE RESTRICT
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS $tableExpenses (
      id TEXT PRIMARY KEY,
      business_id TEXT NOT NULL,
      title TEXT NOT NULL,
      category TEXT NOT NULL,
      amount REAL NOT NULL,
      payment_method TEXT DEFAULT 'Cash',
      date TEXT NOT NULL,
      notes TEXT,
      FOREIGN KEY (business_id) REFERENCES $tableBusinesses(id) ON DELETE CASCADE
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS $tableStockLedger (
      id TEXT PRIMARY KEY,
      business_id TEXT NOT NULL,
      product_id TEXT NOT NULL,
      product_name TEXT NOT NULL,
      change_qty REAL NOT NULL,
      balance_qty REAL NOT NULL,
      reason TEXT NOT NULL,
      reference_id TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY (business_id) REFERENCES $tableBusinesses(id) ON DELETE CASCADE,
      FOREIGN KEY (product_id) REFERENCES $tableProducts(id) ON DELETE CASCADE
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS $tableHeldBills (
      id TEXT PRIMARY KEY,
      business_id TEXT NOT NULL,
      title TEXT NOT NULL,
      customer_name TEXT,
      customer_phone TEXT,
      cart_json TEXT NOT NULL,
      total_amount REAL NOT NULL,
      created_at TEXT NOT NULL,
      FOREIGN KEY (business_id) REFERENCES $tableBusinesses(id) ON DELETE CASCADE
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS $tableAppUsers (
      id TEXT PRIMARY KEY,
      business_id TEXT NOT NULL,
      name TEXT NOT NULL,
      role TEXT NOT NULL,
      pin_code TEXT DEFAULT '1234',
      FOREIGN KEY (business_id) REFERENCES $tableBusinesses(id) ON DELETE CASCADE
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS $tableEstimates (
      id TEXT PRIMARY KEY,
      business_id TEXT NOT NULL,
      estimate_no TEXT NOT NULL,
      customer_id TEXT,
      customer_name TEXT,
      customer_phone TEXT,
      subtotal REAL NOT NULL,
      tax_amount REAL NOT NULL,
      discount_amount REAL DEFAULT 0,
      round_off REAL DEFAULT 0,
      final_total REAL NOT NULL,
      status TEXT DEFAULT 'Active',
      converted_sale_id TEXT,
      valid_until TEXT,
      notes TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY (business_id) REFERENCES $tableBusinesses(id) ON DELETE CASCADE,
      FOREIGN KEY (customer_id) REFERENCES $tableCustomers(id) ON DELETE SET NULL
    );
    ''',
    '''
    CREATE TABLE IF NOT EXISTS $tableEstimateItems (
      id TEXT PRIMARY KEY,
      estimate_id TEXT NOT NULL,
      product_id TEXT NOT NULL,
      product_name TEXT NOT NULL,
      sku TEXT,
      quantity REAL NOT NULL,
      unit_price REAL NOT NULL,
      discount_amount REAL DEFAULT 0,
      tax_rate REAL DEFAULT 0,
      tax_amount REAL NOT NULL,
      line_total REAL NOT NULL,
      batch_number TEXT,
      batch_expiry TEXT,
      dosage_form TEXT,
      packaging_type TEXT,
      strip_count INTEGER,
      loose_count INTEGER,
      pack_size INTEGER,
      packaging_desc TEXT,
      notes TEXT,
      FOREIGN KEY (estimate_id) REFERENCES $tableEstimates(id) ON DELETE CASCADE,
      FOREIGN KEY (product_id) REFERENCES $tableProducts(id) ON DELETE RESTRICT
    );
    ''',
  ];

  static const List<String> createIndexStatements = [
    'CREATE INDEX IF NOT EXISTS idx_products_business ON $tableProducts(business_id);',
    'CREATE INDEX IF NOT EXISTS idx_products_category ON $tableProducts(category_id);',
    'CREATE INDEX IF NOT EXISTS idx_products_sku ON $tableProducts(sku);',
    'CREATE INDEX IF NOT EXISTS idx_products_barcode ON $tableProducts(barcode);',
    'CREATE INDEX IF NOT EXISTS idx_sales_business ON $tableSales(business_id);',
    'CREATE INDEX IF NOT EXISTS idx_sales_created ON $tableSales(created_at);',
    'CREATE INDEX IF NOT EXISTS idx_sales_invoice ON $tableSales(invoice_no);',
    'CREATE INDEX IF NOT EXISTS idx_sale_items_sale ON $tableSaleItems(sale_id);',
    'CREATE INDEX IF NOT EXISTS idx_stock_ledger_product ON $tableStockLedger(product_id);',
    'CREATE INDEX IF NOT EXISTS idx_estimates_business ON $tableEstimates(business_id);',
    'CREATE INDEX IF NOT EXISTS idx_estimates_created ON $tableEstimates(created_at);',
    'CREATE INDEX IF NOT EXISTS idx_estimates_no ON $tableEstimates(estimate_no);',
    'CREATE INDEX IF NOT EXISTS idx_estimate_items_est ON $tableEstimateItems(estimate_id);',
    'CREATE INDEX IF NOT EXISTS idx_purchases_business ON $tablePurchases(business_id);',
    'CREATE INDEX IF NOT EXISTS idx_purchases_created ON $tablePurchases(created_at);',
    'CREATE INDEX IF NOT EXISTS idx_purchases_invoice ON $tablePurchases(invoice_no);',
    'CREATE INDEX IF NOT EXISTS idx_purchase_items_purch ON $tablePurchaseItems(purchase_id);',
  ];
}
