import 'dart:convert';

class SaleItem {
  final String id;
  final String saleId;
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
  final String? serialImei;
  final String? variant;
  final String? modifiers;

  SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
    this.discountAmount = 0.0,
    this.taxRate = 0.0,
    required this.taxAmount,
    required this.lineTotal,
    this.batchNumber,
    this.batchExpiry,
    this.serialImei,
    this.variant,
    this.modifiers,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_id': saleId,
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
      'serial_imei': serialImei,
      'variant': variant,
      'modifiers': modifiers,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'] as String,
      saleId: map['sale_id'] as String,
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
      serialImei: map['serial_imei'] as String?,
      variant: map['variant'] as String?,
      modifiers: map['modifiers'] as String?,
    );
  }
}

class Sale {
  final String id;
  final String businessId;
  final String invoiceNo;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double roundOff;
  final double finalTotal;
  final String paymentMethod; // 'Cash', 'Card', 'UPI', 'Due', 'Split'
  final Map<String, double> splitBreakup;
  final String status; // 'Completed', 'Voided', 'Refunded'
  final String? orderType; // 'Counter', 'Dine-In', 'Takeaway', 'Delivery'
  final String? tableNumber;
  final String? doctorName;
  final String? notes;
  final DateTime createdAt;
  List<SaleItem> items;

  Sale({
    required this.id,
    required this.businessId,
    required this.invoiceNo,
    this.customerId,
    this.customerName,
    this.customerPhone,
    required this.subtotal,
    required this.taxAmount,
    this.discountAmount = 0.0,
    this.roundOff = 0.0,
    required this.finalTotal,
    this.paymentMethod = 'Cash',
    Map<String, double>? splitBreakup,
    this.status = 'Completed',
    this.orderType = 'Counter',
    this.tableNumber,
    this.doctorName,
    this.notes,
    DateTime? createdAt,
    List<SaleItem>? items,
  })  : splitBreakup = splitBreakup ?? {},
        createdAt = createdAt ?? DateTime.now(),
        items = items ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'invoice_no': invoiceNo,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'round_off': roundOff,
      'final_total': finalTotal,
      'payment_method': paymentMethod,
      'split_breakup_json': jsonEncode(splitBreakup),
      'status': status,
      'order_type': orderType,
      'table_number': tableNumber,
      'doctor_name': doctorName,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map, {List<SaleItem>? items}) {
    Map<String, double> split = {};
    if (map['split_breakup_json'] != null) {
      try {
        final decoded = jsonDecode(map['split_breakup_json'] as String) as Map;
        split = decoded.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
      } catch (_) {}
    }

    return Sale(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      invoiceNo: map['invoice_no'] as String,
      customerId: map['customer_id'] as String?,
      customerName: map['customer_name'] as String?,
      customerPhone: map['customer_phone'] as String?,
      subtotal: (map['subtotal'] as num).toDouble(),
      taxAmount: (map['tax_amount'] as num).toDouble(),
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
      roundOff: (map['round_off'] as num?)?.toDouble() ?? 0.0,
      finalTotal: (map['final_total'] as num).toDouble(),
      paymentMethod: (map['payment_method'] as String?) ?? 'Cash',
      splitBreakup: split,
      status: (map['status'] as String?) ?? 'Completed',
      orderType: (map['order_type'] as String?) ?? 'Counter',
      tableNumber: map['table_number'] as String?,
      doctorName: map['doctor_name'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : DateTime.now(),
      items: items ?? [],
    );
  }
}
