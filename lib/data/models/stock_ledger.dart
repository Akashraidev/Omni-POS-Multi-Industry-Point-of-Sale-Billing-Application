class StockLedgerEntry {
  final String id;
  final String businessId;
  final String productId;
  final String productName;
  final double changeQty;
  final double balanceQty;
  final String reason; // 'Sale', 'Purchase', 'Return', 'Adjustment', 'Damage', 'Transfer'
  final String? referenceId; // InvoiceNo or PurchaseNo
  final DateTime createdAt;

  StockLedgerEntry({
    required this.id,
    required this.businessId,
    required this.productId,
    required this.productName,
    required this.changeQty,
    required this.balanceQty,
    required this.reason,
    this.referenceId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'product_id': productId,
      'product_name': productName,
      'change_qty': changeQty,
      'balance_qty': balanceQty,
      'reason': reason,
      'reference_id': referenceId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StockLedgerEntry.fromMap(Map<String, dynamic> map) {
    return StockLedgerEntry(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      productId: map['product_id'] as String,
      productName: (map['product_name'] as String?) ?? '',
      changeQty: (map['change_qty'] as num).toDouble(),
      balanceQty: (map['balance_qty'] as num).toDouble(),
      reason: map['reason'] as String,
      referenceId: map['reference_id'] as String?,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : DateTime.now(),
    );
  }
}
