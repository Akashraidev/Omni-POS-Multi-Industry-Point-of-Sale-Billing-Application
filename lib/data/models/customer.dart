class Customer {
  final String id;
  final String businessId;
  final String name;
  final String phone;
  final String email;
  final String address;
  final int loyaltyPoints;
  final double balanceDue;
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.businessId,
    required this.name,
    this.phone = '',
    this.email = '',
    this.address = '',
    this.loyaltyPoints = 0,
    this.balanceDue = 0.0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'loyalty_points': loyaltyPoints,
      'balance_due': balanceDue,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      name: map['name'] as String,
      phone: (map['phone'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      address: (map['address'] as String?) ?? '',
      loyaltyPoints: (map['loyalty_points'] as int?) ?? 0,
      balanceDue: (map['balance_due'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : DateTime.now(),
    );
  }

  Customer copyWith({
    String? id,
    String? businessId,
    String? name,
    String? phone,
    String? email,
    String? address,
    int? loyaltyPoints,
    double? balanceDue,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      balanceDue: balanceDue ?? this.balanceDue,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
