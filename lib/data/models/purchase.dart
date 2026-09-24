class PurchaseItem {
  final String id;
  final String purchaseId;
  final String productId;
  final String productName;
  final double quantity;
  final double unitCost;
  final double totalCost;
  final String? batchNumber;
  final String? batchExpiry;
  final double freeQuantity;
  final double taxRate;
  final double taxAmount;
  final double discountAmount;
  final double? mrp;

  PurchaseItem({
    required this.id,
    required this.purchaseId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitCost,
    required this.totalCost,
    this.batchNumber,
    this.batchExpiry,
    this.freeQuantity = 0.0,
    this.taxRate = 0.0,
    this.taxAmount = 0.0,
    this.discountAmount = 0.0,
    this.mrp,
  });

  /// Real effective cost accounting for free scheme units
  double get effectiveCostPerUnit {
    final totalUnits = quantity + freeQuantity;
    return totalUnits > 0 ? (totalCost / totalUnits) : unitCost;
  }

  PurchaseItem copyWith({
    String? id,
    String? purchaseId,
    String? productId,
    String? productName,
    double? quantity,
    double? unitCost,
    double? totalCost,
    String? batchNumber,
    String? batchExpiry,
    double? freeQuantity,
    double? taxRate,
    double? taxAmount,
    double? discountAmount,
    double? mrp,
  }) {
    return PurchaseItem(
      id: id ?? this.id,
      purchaseId: purchaseId ?? this.purchaseId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      totalCost: totalCost ?? this.totalCost,
      batchNumber: batchNumber ?? this.batchNumber,
      batchExpiry: batchExpiry ?? this.batchExpiry,
      freeQuantity: freeQuantity ?? this.freeQuantity,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      mrp: mrp ?? this.mrp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'purchase_id': purchaseId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_cost': unitCost,
      'total_cost': totalCost,
      'batch_number': batchNumber,
      'batch_expiry': batchExpiry,
      'free_quantity': freeQuantity,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'mrp': mrp,
    };
  }

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      id: map['id'] as String,
      purchaseId: map['purchase_id'] as String,
      productId: map['product_id'] as String,
      productName: map['product_name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unitCost: (map['unit_cost'] as num).toDouble(),
      totalCost: (map['total_cost'] as num).toDouble(),
      batchNumber: map['batch_number'] as String?,
      batchExpiry: map['batch_expiry'] as String?,
      freeQuantity: (map['free_quantity'] as num?)?.toDouble() ?? 0.0,
      taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
      mrp: (map['mrp'] as num?)?.toDouble(),
    );
  }
}

class Purchase {
  final String id;
  final String businessId;
  final String? supplierId;
  final String? supplierName;
  final String invoiceNo;
  final double totalAmount;
  final String status; // 'Draft', 'Ordered', 'Received', 'Voided'
  final String? notes;
  final DateTime createdAt;
  List<PurchaseItem> items;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double roundOff;
  final String paymentStatus; // 'Paid', 'Partial', 'Due'
  final String paymentMethod; // 'Cash', 'Bank / UPI', 'Cheque', 'Credit / Due'
  final double paidAmount;
  final double dueAmount;
  final DateTime? dueDate;

  Purchase({
    required this.id,
    required this.businessId,
    this.supplierId,
    this.supplierName,
    required this.invoiceNo,
    required this.totalAmount,
    this.status = 'Received',
    this.notes,
    DateTime? createdAt,
    List<PurchaseItem>? items,
    double? subtotal,
    this.taxAmount = 0.0,
    this.discountAmount = 0.0,
    this.roundOff = 0.0,
    this.paymentStatus = 'Paid',
    this.paymentMethod = 'Cash',
    double? paidAmount,
    double? dueAmount,
    this.dueDate,
  })  : createdAt = createdAt ?? DateTime.now(),
        items = items ?? [],
        subtotal = subtotal ?? totalAmount,
        paidAmount = paidAmount ?? (paymentStatus == 'Due' ? 0.0 : totalAmount),
        dueAmount = dueAmount ?? (paymentStatus == 'Due' ? totalAmount : 0.0);

  bool get isReceived => status.toLowerCase() == 'received';
  bool get isVoided => status.toLowerCase() == 'voided';
  bool get isDraft => status.toLowerCase() == 'draft';

  double get totalUnitsCount =>
      items.fold(0.0, (sum, it) => sum + it.quantity + it.freeQuantity);

  double get totalFreeUnits =>
      items.fold(0.0, (sum, it) => sum + it.freeQuantity);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'invoice_no': invoiceNo,
      'total_amount': totalAmount,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'round_off': roundOff,
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      'paid_amount': paidAmount,
      'due_amount': dueAmount,
      'due_date': dueDate?.toIso8601String(),
    };
  }

  factory Purchase.fromMap(Map<String, dynamic> map, {List<PurchaseItem>? items}) {
    final total = (map['total_amount'] as num).toDouble();
    final dueDateStr = map['due_date'] as String?;

    return Purchase(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      supplierId: map['supplier_id'] as String?,
      supplierName: map['supplier_name'] as String?,
      invoiceNo: map['invoice_no'] as String,
      totalAmount: total,
      status: (map['status'] as String?) ?? 'Received',
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : DateTime.now(),
      items: items ?? [],
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? total,
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
      roundOff: (map['round_off'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: (map['payment_status'] as String?) ?? 'Paid',
      paymentMethod: (map['payment_method'] as String?) ?? 'Cash',
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? total,
      dueAmount: (map['due_amount'] as num?)?.toDouble() ?? 0.0,
      dueDate: dueDateStr != null ? DateTime.tryParse(dueDateStr) : null,
    );
  }
}
