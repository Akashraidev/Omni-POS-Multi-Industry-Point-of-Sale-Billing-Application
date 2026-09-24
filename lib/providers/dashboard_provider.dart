import 'package:flutter/material.dart';
import '../data/models/analytics.dart';
import '../data/repositories/expense_repository.dart';
import '../data/repositories/purchase_repository.dart';
import '../data/repositories/sale_repository.dart';

/// Derived, read-only dashboard statistics.
///
/// This provider never holds a second copy of transactional rows — it runs a
/// handful of aggregate SQL queries and exposes the results. List-style data
/// (recent sales, products, outstanding parties) continues to come from the
/// providers that own it, so there is exactly one source of truth per record.
class DashboardProvider extends ChangeNotifier {
  final SaleRepository _saleRepo = SaleRepository();
  final PurchaseRepository _purchaseRepo = PurchaseRepository();
  final ExpenseRepository _expenseRepo = ExpenseRepository();

  bool _isLoading = false;
  String? _error;
  DateTime _selectedDate = DateTime.now();
  int _trendDays = 7;
  DateTime? _lastRefreshed;

  DayAggregates _aggregates = DayAggregates.empty();
  List<TrendPoint> _salesTrend = const [];
  List<double> _purchaseTrend = const [];
  List<TrendPoint> _profitTrend = const [];
  double _todayPurchases = 0.0;
  double _todayExpenses = 0.0;

  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedDate => _selectedDate;
  int get trendDays => _trendDays;
  DateTime? get lastRefreshed => _lastRefreshed;
  DayAggregates get aggregates => _aggregates;
  List<TrendPoint> get salesTrend => _salesTrend;
  List<double> get purchaseTrend => _purchaseTrend;
  List<TrendPoint> get profitTrend => _profitTrend;
  double get todayPurchases => _todayPurchases;
  double get todayExpenses => _todayExpenses;

  /// Net cash effect of the trading day (sales - expenses).
  double get netCashFlow => _aggregates.revenue - _todayExpenses;

  /// True once at least one successful load has completed.
  bool get hasData =>
      _aggregates.invoiceCount > 0 ||
      _todayPurchases > 0 ||
      _todayExpenses > 0;

  /// Reloads every dashboard aggregate for [businessId].
  ///
  /// Safe to call repeatedly; each call replaces the previous snapshot. Any
  /// query failure is captured into [error] instead of crashing the screen.
  Future<void> load(String businessId, {DateTime? date}) async {
    final target = date ?? _selectedDate;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _saleRepo.getDayAggregates(businessId, day: target),
        _saleRepo.getDailySalesTrend(businessId, days: _trendDays, endDate: target),
        _saleRepo.getDailyProfitTrend(businessId, days: _trendDays, endDate: target),
        _purchaseRepo.getDailyPurchaseTrend(businessId, days: _trendDays, endDate: target),
        _purchaseRepo.getDayPurchaseTotal(businessId, day: target),
        _expenseRepo.getDayExpenseTotal(businessId, day: target),
      ]);

      _aggregates = results[0] as DayAggregates;
      _salesTrend = results[1] as List<TrendPoint>;
      _profitTrend = results[2] as List<TrendPoint>;
      _purchaseTrend = results[3] as List<double>;
      _todayPurchases = results[4] as double;
      _todayExpenses = results[5] as double;
      _selectedDate = target;
      _lastRefreshed = DateTime.now();
    } catch (e) {
      _error = 'Unable to load dashboard figures. Please check the database and retry.';
      debugPrint('DashboardProvider load error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSelectedDate(String businessId, DateTime date) {
    _selectedDate = date;
    load(businessId);
  }

  void jumpToToday(String businessId) {
    _selectedDate = DateTime.now();
    load(businessId);
  }

  void stepDate(String businessId, int days) {
    _selectedDate = _selectedDate.add(Duration(days: days));
    load(businessId);
  }

  void setTrendWindow(String businessId, int days) {
    _trendDays = days;
    load(businessId);
  }
}
