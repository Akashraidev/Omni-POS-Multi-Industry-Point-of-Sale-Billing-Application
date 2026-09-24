class Category {
  final String id;
  final String businessId;
  final String name;
  final String icon;
  final String colorHex;
  final int sortOrder;

  Category({
    required this.id,
    required this.businessId,
    required this.name,
    this.icon = 'category',
    this.colorHex = '#4F46E5',
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      'icon': icon,
      'color_hex': colorHex,
      'sort_order': sortOrder,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      name: map['name'] as String,
      icon: (map['icon'] as String?) ?? 'category',
      colorHex: (map['color_hex'] as String?) ?? '#4F46E5',
      sortOrder: (map['sort_order'] as int?) ?? 0,
    );
  }
}
