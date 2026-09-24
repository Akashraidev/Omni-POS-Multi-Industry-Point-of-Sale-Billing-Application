class EstimateItem {
  final String id;
  final String estimateId;
  final String productId;
  final String productName;
  final String sku;
  final double quantity;
  final double unitPrice;
  final double discountAmount;
  final double taxRate;
  final double taxAmount;
  final double lineTotal;
  final String? batchNumber;
  final String? batchExpiry;
  final String? dosageForm;
  final String? packagingType;
  final int? stripCount;
  final int? looseCount;
  final int? packSize;
  final String? packagingDesc;
  final String? notes;

  EstimateItem({
    required this.id,
    required this.estimateId,
    required this.productId,
    required this.productName,
    this.sku = '',
    required this.quantity,
    required this.unitPrice,
    this.discountAmount = 0.0,
    this.taxRate = 0.0,
    required this.taxAmount,
    required this.lineTotal,
    this.batchNumber,
    this.batchExpiry,
    this.dosageForm,
    this.packagingType,
    this.stripCount,
    this.looseCount,
    this.packSize,
    this.packagingDesc,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'estimate_id': estimateId,
      'product_id': productId,
      'product_name': productName,
      'sku': sku,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount_amount': discountAmount,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'line_total': lineTotal,
      'batch_number': batchNumber,
      'batch_expiry': batchExpiry,
      'dosage_form': dosageForm,
      'packaging_type': packagingType,
      'strip_count': stripCount,
      'loose_count': looseCount,
      'pack_size': packSize,
      'packaging_desc': packagingDesc,
      'notes': notes,
    };
  }

  factory EstimateItem.fromMap(Map<String, dynamic> map) {
    return EstimateItem(
      id: map['id'] as String,
      estimateId: map['estimate_id'] as String,
      productId: map['product_id'] as String,
      productName: map['product_name'] as String,
      sku: (map['sku'] as String?) ?? '',
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
      taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0.0,
      lineTotal: (map['line_total'] as num).toDouble(),
      batchNumber: map['batch_number'] as String?,
      batchExpiry: map['batch_expiry'] as String?,
      dosageForm: map['dosage_form'] as String?,
      packagingType: map['packaging_type'] as String?,
      stripCount: map['strip_count'] as int?,
      looseCount: map['loose_count'] as int?,
      packSize: map['pack_size'] as int?,
      packagingDesc: map['packaging_desc'] as String?,
      notes: map['notes'] as String?,
    );
  }
}

class Estimate {
  final String id;
  final String businessId;
  final String estimateNo;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double roundOff;
  final double finalTotal;
  final String status; // 'Active', 'Converted', 'Expired', 'Voided'
  final String? convertedSaleId;
  final DateTime? validUntil;
  final String? notes;
  final DateTime createdAt;
  List<EstimateItem> items;

  Estimate({
    required this.id,
    required this.businessId,
    required this.estimateNo,
    this.customerId,
    this.customerName,
    this.customerPhone,
    required this.subtotal,
    required this.taxAmount,
    this.discountAmount = 0.0,
    this.roundOff = 0.0,
    required this.finalTotal,
    this.status = 'Active',
    this.convertedSaleId,
    this.validUntil,
    this.notes,
    DateTime? createdAt,
    List<EstimateItem>? items,
  })  : createdAt = createdAt ?? DateTime.now(),
        items = items ?? [];

  bool get isConverted => status.toLowerCase() == 'converted';
  bool get isVoided => status.toLowerCase() == 'voided';

  bool get isExpired {
    if (isConverted || isVoided) return false;
    if (validUntil == null) return false;
    return DateTime.now().isAfter(validUntil!);
  }

  bool get isActive => !isConverted && !isVoided && !isExpired;

  String get displayStatus {
    if (isConverted) return 'Converted';
    if (isVoided) return 'Voided';
    if (isExpired) return 'Expired';
    return 'Active';
  }

  int? get daysRemaining {
    if (validUntil == null) return null;
    final diff = validUntil!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'estimate_no': estimateNo,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'round_off': roundOff,
      'final_total': finalTotal,
      'status': isExpired ? 'Expired' : status,
      'converted_sale_id': convertedSaleId,
      'valid_until': validUntil?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Estimate.fromMap(Map<String, dynamic> map, {List<EstimateItem>? items}) {
    final validUntilStr = map['valid_until'] as String?;
    final rawStatus = (map['status'] as String?) ?? 'Active';

    final createdAt = DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now();
    final validUntil = validUntilStr != null ? DateTime.tryParse(validUntilStr) : null;

    String resolvedStatus = rawStatus;
    if (rawStatus.toLowerCase() != 'converted' && rawStatus.toLowerCase() != 'voided') {
      if (validUntil != null && DateTime.now().isAfter(validUntil)) {
        resolvedStatus = 'Expired';
      }
    }

    return Estimate(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      estimateNo: map['estimate_no'] as String,
      customerId: map['customer_id'] as String?,
      customerName: map['customer_name'] as String?,
      customerPhone: map['customer_phone'] as String?,
      subtotal: (map['subtotal'] as num).toDouble(),
      taxAmount: (map['tax_amount'] as num).toDouble(),
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
      roundOff: (map['round_off'] as num?)?.toDouble() ?? 0.0,
      finalTotal: (map['final_total'] as num).toDouble(),
      status: resolvedStatus,
      convertedSaleId: map['converted_sale_id'] as String?,
      validUntil: validUntil,
      notes: map['notes'] as String?,
      createdAt: createdAt,
      items: items ?? [],
    );
  }
}
