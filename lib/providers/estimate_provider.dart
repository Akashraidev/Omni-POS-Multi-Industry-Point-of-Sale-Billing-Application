import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/models/cart_item.dart';
import '../data/models/estimate.dart';
import '../data/models/product.dart';
import '../data/repositories/estimate_repository.dart';
import 'cart_provider.dart';

class EstimateProvider extends ChangeNotifier {
  final EstimateRepository _repository = EstimateRepository();
  final Uuid _uuid = const Uuid();

  List<Estimate> _estimates = [];
  bool _isLoading = false;
  String _selectedFilter = 'All'; // 'All', 'Active', 'Converted', 'Expired'
  String _searchQuery = '';
  String? _currentBusinessId;

  List<Estimate> get estimates => _estimates;
  bool get isLoading => _isLoading;
  String get selectedFilter => _selectedFilter;
  String get searchQuery => _searchQuery;

  int get activeCount => _estimates.where((e) => e.isActive).length;
  int get convertedCount => _estimates.where((e) => e.isConverted).length;
  int get expiredCount => _estimates.where((e) => e.isExpired).length;
  int get totalCount => _estimates.length;

  double get activeTotalValue => _estimates
      .where((e) => e.isActive)
      .fold(0.0, (sum, e) => sum + e.finalTotal);

  List<Estimate> get filteredEstimates {
    return _estimates.where((est) {
      // Status filter
      if (_selectedFilter == 'Active' && !est.isActive) return false;
      if (_selectedFilter == 'Converted' && !est.isConverted) return false;
      if (_selectedFilter == 'Expired' && !est.isExpired) return false;

      // Search query filter
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchesNo = est.estimateNo.toLowerCase().contains(q);
        final matchesCustomer = est.customerName?.toLowerCase().contains(q) ?? false;
        final matchesPhone = est.customerPhone?.toLowerCase().contains(q) ?? false;
        final matchesItems = est.items.any((it) => it.productName.toLowerCase().contains(q));
        if (!matchesNo && !matchesCustomer && !matchesPhone && !matchesItems) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadEstimates(String businessId) async {
    _currentBusinessId = businessId;
    _isLoading = true;
    notifyListeners();

    try {
      _estimates = await _repository.getEstimates(businessId);
    } catch (e) {
      debugPrint('Error loading estimates: $e');
      _estimates = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Estimate> createEstimateFromCart({
    required String businessId,
    required CartProvider cart,
    String? customerName,
    String? customerPhone,
    String? customerId,
    DateTime? validUntil,
    String? notes,
  }) async {
    final estId = _uuid.v4();
    final estimateNo = await _repository.getNextEstimateNumber(businessId);

    final estimateItems = cart.items.map((ci) {
      final lineSub = (ci.unitPrice * ci.quantity) - ci.discountAmount;
      final taxAmt = (lineSub * ci.taxRate) / 100.0;
      final lineTotal = lineSub + taxAmt;

      return EstimateItem(
        id: _uuid.v4(),
        estimateId: estId,
        productId: ci.product.id,
        productName: ci.product.name,
        sku: ci.product.sku,
        quantity: ci.quantity,
        unitPrice: ci.unitPrice,
        discountAmount: ci.discountAmount,
        taxRate: ci.taxRate,
        taxAmount: taxAmt,
        lineTotal: lineTotal,
        batchNumber: ci.selectedBatch,
        batchExpiry: ci.batchExpiry,
        dosageForm: ci.dosageForm,
        packagingType: ci.packagingType,
        stripCount: ci.stripCount,
        looseCount: ci.looseCount,
        packSize: ci.packSize,
        packagingDesc: ci.packagingDesc,
        notes: ci.notes,
      );
    }).toList();

    final estimate = Estimate(
      id: estId,
      businessId: businessId,
      estimateNo: estimateNo,
      customerId: customerId ?? cart.selectedCustomer?.id,
      customerName: customerName ?? cart.selectedCustomer?.name,
      customerPhone: customerPhone ?? cart.selectedCustomer?.phone,
      subtotal: cart.subtotal,
      taxAmount: cart.totalTax,
      discountAmount: cart.totalDiscount,
      roundOff: cart.roundOff,
      finalTotal: cart.finalTotal,
      status: 'Active',
      validUntil: validUntil ?? DateTime.now().add(const Duration(days: 15)),
      notes: notes,
      createdAt: DateTime.now(),
      items: estimateItems,
    );

    await _repository.insertEstimate(estimate);
    await loadEstimates(businessId);
    return estimate;
  }

  Future<void> convertEstimateToCart({
    required Estimate estimate,
    required CartProvider cart,
    required List<Product> availableProducts,
  }) async {
    cart.clearCart();

    for (final it in estimate.items) {
      final product = availableProducts.firstWhere(
        (p) => p.id == it.productId,
        orElse: () => Product(
          id: it.productId,
          businessId: estimate.businessId,
          categoryId: '',
          name: it.productName,
          sku: it.sku,
          purchasePrice: 0,
          sellingPrice: it.unitPrice,
          mrp: it.unitPrice,
        ),
      );

      cart.items.add(CartItem(
        product: product,
        quantity: it.quantity,
        unitPrice: it.unitPrice,
        discountAmount: it.discountAmount,
        taxRate: it.taxRate,
        selectedBatch: it.batchNumber,
        batchExpiry: it.batchExpiry,
        dosageForm: it.dosageForm,
        packagingType: it.packagingType,
        stripCount: it.stripCount,
        looseCount: it.looseCount,
        packSize: it.packSize,
        packagingDesc: it.packagingDesc,
        notes: it.notes,
      ));
    }

    if (estimate.notes != null) {
      cart.setNotes(estimate.notes);
    }
  }

  Future<void> markConverted(String estimateId, String saleId) async {
    await _repository.updateEstimateStatus(
      estimateId,
      'Converted',
      convertedSaleId: saleId,
    );
    if (_currentBusinessId != null) {
      await loadEstimates(_currentBusinessId!);
    }
  }

  Future<void> voidEstimate(String estimateId) async {
    await _repository.updateEstimateStatus(estimateId, 'Voided');
    if (_currentBusinessId != null) {
      await loadEstimates(_currentBusinessId!);
    }
  }

  Future<void> deleteEstimate(String estimateId) async {
    await _repository.deleteEstimate(estimateId);
    if (_currentBusinessId != null) {
      await loadEstimates(_currentBusinessId!);
    }
  }
}
