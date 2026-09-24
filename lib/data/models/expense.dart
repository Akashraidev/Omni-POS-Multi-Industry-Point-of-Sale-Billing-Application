class Expense {
  final String id;
  final String businessId;
  final String title;
  final String category; // 'Rent', 'Utilities', 'Salaries', 'Supplies', 'Marketing', 'Maintenance', 'Misc'
  final double amount;
  final String paymentMethod;
  final DateTime date;
  final String? notes;

  Expense({
    required this.id,
    required this.businessId,
    required this.title,
    required this.category,
    required this.amount,
    this.paymentMethod = 'Cash',
    DateTime? date,
    this.notes,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'title': title,
      'category': category,
      'amount': amount,
      'payment_method': paymentMethod,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      title: map['title'] as String,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      paymentMethod: (map['payment_method'] as String?) ?? 'Cash',
      date: map['date'] != null ? DateTime.parse(map['date'] as String) : DateTime.now(),
      notes: map['notes'] as String?,
    );
  }
}
