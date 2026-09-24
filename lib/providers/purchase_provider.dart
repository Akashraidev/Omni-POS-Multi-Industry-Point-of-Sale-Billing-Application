import 'package:flutter/material.dart';
import '../data/models/purchase.dart';
import '../data/repositories/purchase_repository.dart';

class PurchaseProvider extends ChangeNotifier {
  final PurchaseRepository _repository = PurchaseRepository();

  List<Purchase> _purchases = [];
  bool _isLoading = false;
  String _statusFilter = 'All'; // All, Received, Pending, Voided
  String _searchQuery = '';
  String? _errorMessage;

  List<Purchase> get purchases => _purchases;
  bool get isLoading => _isLoading;
  String get statusFilter => _statusFilter;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;

  /// Filtered purchases based on status filter and search query
  List<Purchase> get filteredPurchases {
    return _purchases.where((purchase) {
      // Status filter
      if (_statusFilter != 'All' &&
          purchase.status.toLowerCase() != _statusFilter.toLowerCase()) {
        return false;
      }

      // Search query filter (matches invoiceNo, supplierName, notes)
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesInvoice =
            purchase.invoiceNo.toLowerCase().contains(query);
        final matchesSupplier =
            (purchase.supplierName ?? '').toLowerCase().contains(query);
        final matchesNotes =
            (purchase.notes ?? '').toLowerCase().contains(query);
        if (!matchesInvoice && !matchesSupplier && !matchesNotes) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Total sum of non-voided purchases
  double get totalPurchaseValue {
    return _purchases
        .where((p) => p.status != 'Voided')
        .fold(0.0, (sum, p) => sum + p.totalAmount);
  }

  /// Current month's total inward purchase value
  double get monthlyPurchaseValue {
    final now = DateTime.now();
    return _purchases.where((p) {
      if (p.status == 'Voided') return false;
      return p.createdAt.year == now.year && p.createdAt.month == now.month;
    }).fold(0.0, (sum, p) => sum + p.totalAmount);
  }

  /// Outstanding supplier balance dues from purchases
  double get totalDueAmount {
    return _purchases
        .where((p) => p.status != 'Voided')
        .fold(0.0, (sum, p) => sum + p.dueAmount);
  }

  int get receivedCount =>
      _purchases.where((p) => p.status == 'Received').length;
  int get pendingCount =>
      _purchases.where((p) => p.status == 'Pending').length;
  int get voidedCount =>
      _purchases.where((p) => p.status == 'Voided').length;

  void setFilter(String filter) {
    if (_statusFilter != filter) {
      _statusFilter = filter;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  Future<void> loadPurchases(String businessId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _purchases = await _repository.getPurchases(businessId);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error loading purchases: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createPurchase(Purchase purchase) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.createPurchase(purchase);
      _purchases = await _repository.getPurchases(purchase.businessId);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error creating purchase: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> voidPurchase(String purchaseId, String businessId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.voidPurchase(purchaseId);
      _purchases = await _repository.getPurchases(businessId);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error voiding purchase: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePurchase(String purchaseId, String businessId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deletePurchase(purchaseId);
      _purchases = await _repository.getPurchases(businessId);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error deleting purchase: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> getNextInvoiceNumber(String businessId) async {
    try {
      return await _repository.getNextPurchaseInvoiceNumber(businessId);
    } catch (e) {
      return 'PUR-${DateTime.now().millisecondsSinceEpoch % 10000}';
    }
  }
}
