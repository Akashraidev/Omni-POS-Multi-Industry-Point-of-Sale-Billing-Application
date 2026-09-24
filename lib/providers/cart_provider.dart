import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/models/cart_item.dart';
import '../data/models/customer.dart';
import '../data/models/held_bill.dart';
import '../data/models/product.dart';
import '../data/repositories/stock_repository.dart';

class CartProvider extends ChangeNotifier {
  final StockRepository _stockRepository = StockRepository();
  final Uuid _uuid = const Uuid();

  final List<CartItem> _items = [];
  Customer? _selectedCustomer;
  double _globalDiscountPercent = 0.0;
  String _orderType = 'Counter'; // 'Counter', 'Dine-In', 'Takeaway', 'Delivery'
  String? _tableNumber;
  String? _doctorName;
  String? _notes;

  List<CartItem> get items => _items;
  Customer? get selectedCustomer => _selectedCustomer;
  double get globalDiscountPercent => _globalDiscountPercent;
  String get orderType => _orderType;
  String? get tableNumber => _tableNumber;
  String? get doctorName => _doctorName;
  String? get notes => _notes;

  // Cart summary calculations
  int get itemCount => _items.fold(0, (sum, it) => sum + (it.quantity.round() > 0 ? it.quantity.round() : 1));

  double get subtotal => _items.fold(0.0, (sum, it) => sum + (it.unitPrice * it.quantity));

  double get itemDiscountTotal => _items.fold(0.0, (sum, it) => sum + it.discountAmount);

  double get globalDiscountAmount => (subtotal - itemDiscountTotal) * (_globalDiscountPercent / 100.0);

  double get totalDiscount => itemDiscountTotal + globalDiscountAmount;

  double get totalTax => _items.fold(0.0, (sum, it) {
        final lineSub = (it.unitPrice * it.quantity) - it.discountAmount;
        return sum + ((lineSub * it.taxRate) / 100.0);
      });

  double get rawPayable => (subtotal - totalDiscount) + totalTax;

  double get roundOff => (rawPayable.roundToDouble() - rawPayable);

  double get finalTotal => rawPayable.roundToDouble();

  /// Total free-scheme units across the cart (e.g. buy-2-get-1-free).
  int get freeUnitCount =>
      _items.fold(0, (sum, it) => sum + it.freeQuantity.round());

  /// Value of all free units in the cart — shown as a saved amount.
  double get totalFreeValue => _items.fold(0.0, (sum, it) => sum + it.freeValue);

  // Helper to check if item is in cart and return its quantity
  double getItemQuantity(String productId) {
    for (final it in _items) {
      if (it.product.id == productId) {
        return it.quantity;
      }
    }
    return 0.0;
  }

  CartItem? getItem(String productId) {
    try {
      return _items.firstWhere((it) => it.product.id == productId);
    } catch (_) {
      return null;
    }
  }

  double getFreeQuantity(String productId) {
    for (final it in _items) {
      if (it.product.id == productId) return it.freeQuantity;
    }
    return 0.0;
  }

  void addToCart(
    Product product, {
    double quantity = 1.0,
    double? unitPrice,
    double discountAmount = 0.0,
    String? batch,
    String? batchExpiry,
    List<String>? modifiers,
    double? weightGram,
    String? imei,
    String? variant,
    String? dosageForm,
    String? packagingType,
    int? stripCount,
    int? looseCount,
    int? packSize,
    String? packagingDesc,
  }) {
    // Check if matching item exists (matching product, batch, variant, and packaging)
    final existingIdx = _items.indexWhere((it) =>
        it.product.id == product.id &&
        it.selectedBatch == batch &&
        it.selectedVariant == variant &&
        it.selectedImei == imei &&
        it.packagingType == packagingType);

    if (existingIdx >= 0) {
      _items[existingIdx].quantity += quantity;
      if (stripCount != null && _items[existingIdx].stripCount != null) {
        _items[existingIdx].stripCount = (_items[existingIdx].stripCount ?? 0) + stripCount;
      }
      if (looseCount != null && _items[existingIdx].looseCount != null) {
        _items[existingIdx].looseCount = (_items[existingIdx].looseCount ?? 0) + looseCount;
      }
      if (unitPrice != null) {
        _items[existingIdx].unitPrice = unitPrice;
      }
    } else {
      _items.add(CartItem(
        product: product,
        quantity: quantity,
        unitPrice: unitPrice ?? product.sellingPrice,
        discountAmount: discountAmount,
        taxRate: product.taxRate,
        selectedBatch: batch,
        batchExpiry: batchExpiry,
        selectedModifiers: modifiers,
        selectedWeightGram: weightGram,
        selectedImei: imei,
        selectedVariant: variant,
        dosageForm: dosageForm,
        packagingType: packagingType,
        stripCount: stripCount,
        looseCount: looseCount,
        packSize: packSize,
        packagingDesc: packagingDesc,
      ));
    }
    notifyListeners();
  }

  void incrementQuantity(String productId) {
    final idx = _items.indexWhere((it) => it.product.id == productId);
    if (idx >= 0) {
      incrementQuantityByIndex(idx);
    }
  }

  void decrementQuantity(String productId) {
    final idx = _items.indexWhere((it) => it.product.id == productId);
    if (idx >= 0) {
      decrementQuantityByIndex(idx);
    }
  }

  void incrementQuantityByIndex(int index) {
    if (index >= 0 && index < _items.length) {
      _items[index].quantity += 1.0;
      notifyListeners();
    }
  }

  void decrementQuantityByIndex(int index) {
    if (index >= 0 && index < _items.length) {
      if (_items[index].quantity > 1.0) {
        _items[index].quantity -= 1.0;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void updateItemQuantityByIndex(int index, double qty) {
    if (index >= 0 && index < _items.length) {
      if (qty <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = qty;
      }
      notifyListeners();
    }
  }

  /// Sets the absolute billed quantity for a line (used by the line editor).
  /// Removes the line when set to zero or less.
  void setItemQuantity(String productId, double qty) {
    final idx = _items.indexWhere((it) => it.product.id == productId);
    if (idx < 0) return;
    if (qty <= 0) {
      _items.removeAt(idx);
    } else {
      _items[idx].quantity = qty;
    }
    notifyListeners();
  }

  /// Re-assigns the dispensed batch for a line (FEFO overrides at billing).
  void setItemBatch(String productId, String batchNo, String expiry) {
    final idx = _items.indexWhere((it) => it.product.id == productId);
    if (idx >= 0) {
      _items[idx].selectedBatch = batchNo;
      _items[idx].batchExpiry = expiry;
      notifyListeners();
    }
  }

  CartItem? removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      final removed = _items.removeAt(index);
      notifyListeners();
      return removed;
    }
    return null;
  }

  void insertItem(int index, CartItem item) {
    _items.insert(index, item);
    notifyListeners();
  }

  void updateItemPrice(int index, double newPrice) {
    if (index >= 0 && index < _items.length) {
      _items[index].unitPrice = newPrice;
      notifyListeners();
    }
  }

  void updateItemDiscount(int index, double discount) {
    if (index >= 0 && index < _items.length) {
      _items[index].discountAmount = discount;
      notifyListeners();
    }
  }

  void updateCartItem(
    int index, {
    double? quantity,
    double? unitPrice,
    double? discountAmount,
    double? freeQuantity,
    String? batch,
    String? batchExpiry,
    String? dosageForm,
    String? packagingType,
    int? stripCount,
    int? looseCount,
    int? packSize,
    String? packagingDesc,
    String? notes,
  }) {
    if (index >= 0 && index < _items.length) {
      final it = _items[index];
      if (quantity != null) it.quantity = quantity;
      if (unitPrice != null) it.unitPrice = unitPrice;
      if (discountAmount != null) it.discountAmount = discountAmount;
      if (freeQuantity != null) it.freeQuantity = freeQuantity;
      if (batch != null) it.selectedBatch = batch;
      if (batchExpiry != null) it.batchExpiry = batchExpiry;
      if (dosageForm != null) it.dosageForm = dosageForm;
      if (packagingType != null) it.packagingType = packagingType;
      if (stripCount != null) it.stripCount = stripCount;
      if (looseCount != null) it.looseCount = looseCount;
      if (packSize != null) it.packSize = packSize;
      if (packagingDesc != null) it.packagingDesc = packagingDesc;
      if (notes != null) it.notes = notes;
      notifyListeners();
    }
  }

  /// Applies a free-scheme quantity to a line (e.g. buy 2 get 1 free).
  /// Free units are never charged, so they reduce the line value without
  /// touching the billed quantity.
  void setFreeQuantity(String productId, double freeQty) {
    final idx = _items.indexWhere((it) => it.product.id == productId);
    if (idx >= 0) {
      _items[idx].freeQuantity = freeQty.clamp(0.0, 999999.0);
      notifyListeners();
    }
  }

  void setCustomer(Customer? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void setGlobalDiscount(double percent) {
    _globalDiscountPercent = percent;
    notifyListeners();
  }

  void setOrderType(String type, {String? table}) {
    _orderType = type;
    _tableNumber = table;
    notifyListeners();
  }

  void setDoctorName(String? doctor) {
    _doctorName = doctor;
    notifyListeners();
  }

  void setNotes(String? n) {
    _notes = n;
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _selectedCustomer = null;
    _globalDiscountPercent = 0.0;
    _orderType = 'Counter';
    _tableNumber = null;
    _doctorName = null;
    _notes = null;
    notifyListeners();
  }

  // Hold / Park Bill
  Future<void> holdCurrentBill(String businessId, String title) async {
    if (_items.isEmpty) return;

    final cartData = {
      'items': _items.map((it) => it.toMap()).toList(),
      'customer_id': _selectedCustomer?.id,
      'customer_name': _selectedCustomer?.name,
      'customer_phone': _selectedCustomer?.phone,
      'order_type': _orderType,
      'table_number': _tableNumber,
      'notes': _notes,
    };

    final held = HeldBill(
      id: _uuid.v4(),
      businessId: businessId,
      title: title.isNotEmpty ? title : 'Bill #${DateTime.now().minute}',
      customerName: _selectedCustomer?.name,
      customerPhone: _selectedCustomer?.phone,
      cartJson: jsonEncode(cartData),
      totalAmount: finalTotal,
    );

    await _stockRepository.insertHeldBill(held);
    clearCart();
  }

  // Resume Held Bill
  Future<void> resumeHeldBill(HeldBill held, List<Product> availableProducts) async {
    try {
      final decoded = jsonDecode(held.cartJson) as Map<String, dynamic>;
      final rawItems = decoded['items'] as List;

      clearCart();

      for (final raw in rawItems) {
        final prodId = raw['product_id'] as String;
        final product = availableProducts.firstWhere(
          (p) => p.id == prodId,
          orElse: () => Product(
            id: prodId,
            businessId: held.businessId,
            categoryId: '',
            name: raw['product_name'] ?? 'Item',
            sku: raw['sku'] ?? '',
            purchasePrice: 0,
            sellingPrice: (raw['unit_price'] as num).toDouble(),
            mrp: (raw['unit_price'] as num).toDouble(),
          ),
        );

        _items.add(CartItem(
          product: product,
          quantity: (raw['quantity'] as num).toDouble(),
          unitPrice: (raw['unit_price'] as num).toDouble(),
          discountAmount: (raw['discount_amount'] as num?)?.toDouble() ?? 0.0,
          taxRate: (raw['tax_rate'] as num?)?.toDouble() ?? 0.0,
          freeQuantity: (raw['free_quantity'] as num?)?.toDouble() ?? 0.0,
          selectedBatch: raw['selected_batch'],
          batchExpiry: raw['batch_expiry'],
          selectedWeightGram: (raw['selected_weight_gram'] as num?)?.toDouble(),
          selectedImei: raw['selected_imei'],
          selectedVariant: raw['selected_variant'],
          notes: raw['notes'],
          dosageForm: raw['dosage_form'],
          packagingType: raw['packaging_type'],
          stripCount: raw['strip_count'] as int?,
          looseCount: raw['loose_count'] as int?,
          packSize: raw['pack_size'] as int?,
          packagingDesc: raw['packaging_desc'],
        ));
      }

      _orderType = decoded['order_type'] ?? 'Counter';
      _tableNumber = decoded['table_number'];
      _notes = decoded['notes'];

      await _stockRepository.deleteHeldBill(held.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error resuming bill: $e');
    }
  }
}
