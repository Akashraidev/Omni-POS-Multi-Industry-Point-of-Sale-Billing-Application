import 'product.dart';

class CartItem {
  final Product product;
  double quantity;
  double unitPrice;
  double discountAmount;
  double taxRate;
  double freeQuantity;
  String? selectedBatch;
  String? batchExpiry;
  List<String> selectedModifiers;
  double? selectedWeightGram;
  String? selectedImei;
  String? selectedVariant;
  String? notes;
  String? dosageForm;
  String? packagingType;
  int? stripCount;
  int? looseCount;
  int? packSize;
  String? packagingDesc;

  CartItem({
    required this.product,
    this.quantity = 1.0,
    double? unitPrice,
    this.discountAmount = 0.0,
    double? taxRate,
    this.freeQuantity = 0.0,
    this.selectedBatch,
    this.batchExpiry,
    List<String>? selectedModifiers,
    this.selectedWeightGram,
    this.selectedImei,
    this.selectedVariant,
    this.notes,
    this.dosageForm,
    this.packagingType,
    this.stripCount,
    this.looseCount,
    this.packSize,
    this.packagingDesc,
  })  : unitPrice = unitPrice ?? product.sellingPrice,
        taxRate = taxRate ?? product.taxRate,
        selectedModifiers = selectedModifiers ?? [];

  /// Value of the free units on this line (scheme units are never charged).
  double get freeValue => unitPrice * freeQuantity;

  /// Charged line value after line discount and free-scheme units.
  double get subtotal => (unitPrice * quantity) - discountAmount - freeValue;

  double get taxAmount => (subtotal * taxRate) / 100.0;

  double get total => subtotal + taxAmount;

  CartItem copyWith({
    Product? product,
    double? quantity,
    double? unitPrice,
    double? discountAmount,
    double? taxRate,
    double? freeQuantity,
    String? selectedBatch,
    String? batchExpiry,
    List<String>? selectedModifiers,
    double? selectedWeightGram,
    String? selectedImei,
    String? selectedVariant,
    String? notes,
    String? dosageForm,
    String? packagingType,
    int? stripCount,
    int? looseCount,
    int? packSize,
    String? packagingDesc,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discountAmount: discountAmount ?? this.discountAmount,
      taxRate: taxRate ?? this.taxRate,
      freeQuantity: freeQuantity ?? this.freeQuantity,
      selectedBatch: selectedBatch ?? this.selectedBatch,
      batchExpiry: batchExpiry ?? this.batchExpiry,
      selectedModifiers: selectedModifiers ?? List.from(this.selectedModifiers),
      selectedWeightGram: selectedWeightGram ?? this.selectedWeightGram,
      selectedImei: selectedImei ?? this.selectedImei,
      selectedVariant: selectedVariant ?? this.selectedVariant,
      notes: notes ?? this.notes,
      dosageForm: dosageForm ?? this.dosageForm,
      packagingType: packagingType ?? this.packagingType,
      stripCount: stripCount ?? this.stripCount,
      looseCount: looseCount ?? this.looseCount,
      packSize: packSize ?? this.packSize,
      packagingDesc: packagingDesc ?? this.packagingDesc,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': product.id,
      'product_name': product.name,
      'sku': product.sku,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount_amount': discountAmount,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'total': total,
      'free_quantity': freeQuantity,
      'selected_batch': selectedBatch,
      'batch_expiry': batchExpiry,
      'modifiers': selectedModifiers.join(', '),
      'selected_weight_gram': selectedWeightGram,
      'selected_imei': selectedImei,
      'selected_variant': selectedVariant,
      'notes': notes,
      'dosage_form': dosageForm,
      'packaging_type': packagingType,
      'strip_count': stripCount,
      'loose_count': looseCount,
      'pack_size': packSize,
      'packaging_desc': packagingDesc,
    };
  }
}
