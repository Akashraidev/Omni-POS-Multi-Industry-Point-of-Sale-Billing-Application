import 'package:flutter/material.dart';
import '../data/models/expense.dart';
import '../data/repositories/expense_repository.dart';

class ExpenseProvider extends ChangeNotifier {
  final ExpenseRepository _repository = ExpenseRepository();

  List<Expense> _expenses = [];
  bool _isLoading = false;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;

  double get totalExpenses => _expenses.fold(0.0, (sum, e) => sum + e.amount);

  Future<void> loadExpenses(String businessId, {DateTime? start, DateTime? end}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _expenses = await _repository.getExpenses(businessId, startDate: start, endDate: end);
    } catch (e) {
      debugPrint('Error loading expenses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addExpense(Expense expense) async {
    await _repository.insertExpense(expense);
    await loadExpenses(expense.businessId);
  }

  Future<void> deleteExpense(String businessId, String id) async {
    await _repository.deleteExpense(id);
    await loadExpenses(businessId);
  }
}
