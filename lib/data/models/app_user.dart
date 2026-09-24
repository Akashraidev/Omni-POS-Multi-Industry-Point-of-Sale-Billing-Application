class AppUser {
  final String id;
  final String businessId;
  final String name;
  final String role; // 'Owner', 'Manager', 'Cashier', 'Staff'
  final String pinCode;

  AppUser({
    required this.id,
    required this.businessId,
    required this.name,
    required this.role,
    this.pinCode = '1234',
  });

  bool get isOwner => role == 'Owner';
  bool get isManager => role == 'Manager' || isOwner;
  bool get canDiscount => isManager || role == 'Cashier';
  bool get canVoidBill => isManager;
  bool get canViewReports => isManager;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      'role': role,
      'pin_code': pinCode,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      name: map['name'] as String,
      role: (map['role'] as String?) ?? 'Cashier',
      pinCode: (map['pin_code'] as String?) ?? '1234',
    );
  }
}
