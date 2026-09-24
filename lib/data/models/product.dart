import 'dart:convert';

class Product {
  final String id;
  final String businessId;
  final String categoryId;
  final String name;
  final String sku;
  final String barcode;
  final double purchasePrice;
  final double sellingPrice;
  final double mrp;
  final double stockQty;
  final double minStockAlert;
  final String unit; // 'pcs', 'kg', 'g', 'pack', 'box', 'strip'
  final String brand;
  final String? imageUrl;
  final double taxRate; // percentage e.g. 5.0, 12.0, 18.0
  final bool isActive;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  Product({
    required this.id,
    required this.businessId,
    required this.categoryId,
    required this.name,
    required this.sku,
    this.barcode = '',
    required this.purchasePrice,
    required this.sellingPrice,
    required this.mrp,
    this.stockQty = 0.0,
    this.minStockAlert = 5.0,
    this.unit = 'pcs',
    this.brand = '',
    this.imageUrl,
    this.taxRate = 0.0,
    this.isActive = true,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  })  : createdAt = createdAt ?? DateTime.now(),
        metadata = metadata ?? {};

  bool get isLowStock => stockQty <= minStockAlert;
  bool get isOutOfStock => stockQty <= 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'category_id': categoryId,
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'mrp': mrp,
      'stock_qty': stockQty,
      'min_stock_alert': minStockAlert,
      'unit': unit,
      'brand': brand,
      'image_url': imageUrl,
      'tax_rate': taxRate,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'business_metadata_json': jsonEncode(metadata),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      categoryId: map['category_id'] as String,
      name: map['name'] as String,
      sku: map['sku'] as String,
      barcode: (map['barcode'] as String?) ?? '',
      purchasePrice: (map['purchase_price'] as num).toDouble(),
      sellingPrice: (map['selling_price'] as num).toDouble(),
      mrp: (map['mrp'] as num).toDouble(),
      stockQty: (map['stock_qty'] as num).toDouble(),
      minStockAlert: (map['min_stock_alert'] as num?)?.toDouble() ?? 5.0,
      unit: (map['unit'] as String?) ?? 'pcs',
      brand: (map['brand'] as String?) ?? '',
      imageUrl: map['image_url'] as String?,
      taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 0.0,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : DateTime.now(),
      metadata: map['business_metadata_json'] != null
          ? Map<String, dynamic>.from(jsonDecode(map['business_metadata_json'] as String) as Map)
          : {},
    );
  }

  Product copyWith({
    String? id,
    String? businessId,
    String? categoryId,
    String? name,
    String? sku,
    String? barcode,
    double? purchasePrice,
    double? sellingPrice,
    double? mrp,
    double? stockQty,
    double? minStockAlert,
    String? unit,
    String? brand,
    String? imageUrl,
    double? taxRate,
    bool? isActive,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return Product(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      mrp: mrp ?? this.mrp,
      stockQty: stockQty ?? this.stockQty,
      minStockAlert: minStockAlert ?? this.minStockAlert,
      unit: unit ?? this.unit,
      brand: brand ?? this.brand,
      imageUrl: imageUrl ?? this.imageUrl,
      taxRate: taxRate ?? this.taxRate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
