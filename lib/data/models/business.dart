import 'dart:convert';
import '../../modules/business_type.dart';

class Business {
  final String id;
  final String name;
  final BusinessType type;
  final String? logoUrl;
  final String address;
  final String phone;
  final String email;
  final String taxNumber; // GSTIN / VAT
  final String currencySymbol;
  final String currencyCode;
  final String invoicePrefix;
  final double defaultTaxRate;
  final String? receiptFooter;
  final DateTime createdAt;
  final Map<String, dynamic> settings;

  Business({
    required this.id,
    required this.name,
    required this.type,
    this.logoUrl,
    this.address = '',
    this.phone = '',
    this.email = '',
    this.taxNumber = '',
    this.currencySymbol = '₹',
    this.currencyCode = 'INR',
    this.invoicePrefix = 'INV-',
    this.defaultTaxRate = 5.0,
    this.receiptFooter = 'Thank you for your business! Visit again.',
    DateTime? createdAt,
    Map<String, dynamic>? settings,
  })  : createdAt = createdAt ?? DateTime.now(),
        settings = settings ?? {};

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.id,
      'logo_url': logoUrl,
      'address': address,
      'phone': phone,
      'email': email,
      'tax_number': taxNumber,
      'currency_symbol': currencySymbol,
      'currency_code': currencyCode,
      'invoice_prefix': invoicePrefix,
      'default_tax_rate': defaultTaxRate,
      'receipt_footer': receiptFooter,
      'created_at': createdAt.toIso8601String(),
      'settings_json': jsonEncode(settings),
    };
  }

  factory Business.fromMap(Map<String, dynamic> map) {
    return Business(
      id: map['id'] as String,
      name: map['name'] as String,
      type: BusinessTypeExtension.fromString(map['type'] as String),
      logoUrl: map['logo_url'] as String?,
      address: (map['address'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      taxNumber: (map['tax_number'] as String?) ?? '',
      currencySymbol: (map['currency_symbol'] as String?) ?? '₹',
      currencyCode: (map['currency_code'] as String?) ?? 'INR',
      invoicePrefix: (map['invoice_prefix'] as String?) ?? 'INV-',
      defaultTaxRate: (map['default_tax_rate'] as num?)?.toDouble() ?? 5.0,
      receiptFooter: (map['receipt_footer'] as String?) ?? 'Thank you for your business!',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : DateTime.now(),
      settings: map['settings_json'] != null
          ? Map<String, dynamic>.from(jsonDecode(map['settings_json'] as String) as Map)
          : {},
    );
  }

  Business copyWith({
    String? id,
    String? name,
    BusinessType? type,
    String? logoUrl,
    String? address,
    String? phone,
    String? email,
    String? taxNumber,
    String? currencySymbol,
    String? currencyCode,
    String? invoicePrefix,
    double? defaultTaxRate,
    String? receiptFooter,
    DateTime? createdAt,
    Map<String, dynamic>? settings,
  }) {
    return Business(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      logoUrl: logoUrl ?? this.logoUrl,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      taxNumber: taxNumber ?? this.taxNumber,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      currencyCode: currencyCode ?? this.currencyCode,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      defaultTaxRate: defaultTaxRate ?? this.defaultTaxRate,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      createdAt: createdAt ?? this.createdAt,
      settings: settings ?? this.settings,
    );
  }
}
