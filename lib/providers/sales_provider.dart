import 'package:flutter/material.dart';
import '../data/models/sale.dart';
import '../data/repositories/sale_repository.dart';

class SalesProvider extends ChangeNotifier {
  final SaleRepository _repository = SaleRepository();

  List<Sale> _sales = [];
  bool _isLoading = false;

  // Filter state
  DateTime? _startDate;
  DateTime? _endDate;
  String _statusFilter = 'All';
  String _paymentFilter = 'All';

  List<Sale> get sales => _sales;
  bool get isLoading => _isLoading;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String get statusFilter => _statusFilter;
  String get paymentFilter => _paymentFilter;

  // Metrics
  double get todaySalesTotal {
    final now = DateTime.now();
    return _sales.where((s) {
      return s.createdAt.year == now.year &&
          s.createdAt.month == now.month &&
          s.createdAt.day == now.day &&
          s.status == 'Completed';
    }).fold(0.0, (sum, s) => sum + s.finalTotal);
  }

  int get todaySalesCount {
    final now = DateTime.now();
    return _sales.where((s) {
      return s.createdAt.year == now.year &&
          s.createdAt.month == now.month &&
          s.createdAt.day == now.day &&
          s.status == 'Completed';
    }).length;
  }

  Future<void> loadSales(String businessId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _sales = await _repository.getSales(
        businessId: businessId,
        startDate: _startDate,
        endDate: _endDate,
        status: _statusFilter,
        paymentMethod: _paymentFilter,
      );
    } catch (e) {
      debugPrint('Error loading sales: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setDateRange(String businessId, DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    loadSales(businessId);
  }

  void setStatusFilter(String businessId, String status) {
    _statusFilter = status;
    loadSales(businessId);
  }

  void setPaymentFilter(String businessId, String method) {
    _paymentFilter = method;
    loadSales(businessId);
  }

  Future<void> voidSale(String businessId, String saleId, String reason) async {
    await _repository.voidSale(saleId, reason);
    await loadSales(businessId);
  }
}
