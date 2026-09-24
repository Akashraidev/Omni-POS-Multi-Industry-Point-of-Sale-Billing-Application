class HeldBill {
  final String id;
  final String businessId;
  final String title;
  final String? customerName;
  final String? customerPhone;
  final String cartJson;
  final double totalAmount;
  final DateTime createdAt;

  HeldBill({
    required this.id,
    required this.businessId,
    required this.title,
    this.customerName,
    this.customerPhone,
    required this.cartJson,
    required this.totalAmount,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'title': title,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'cart_json': cartJson,
      'total_amount': totalAmount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HeldBill.fromMap(Map<String, dynamic> map) {
    return HeldBill(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      title: map['title'] as String,
      customerName: map['customer_name'] as String?,
      customerPhone: map['customer_phone'] as String?,
      cartJson: map['cart_json'] as String,
      totalAmount: (map['total_amount'] as num).toDouble(),
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : DateTime.now(),
    );
  }
}
