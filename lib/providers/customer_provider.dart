import 'package:flutter/material.dart';
import '../data/models/customer.dart';
import '../data/repositories/customer_repository.dart';

class CustomerProvider extends ChangeNotifier {
  final CustomerRepository _repository = CustomerRepository();

  List<Customer> _customers = [];
  bool _isLoading = false;

  List<Customer> get customers => _customers;
  bool get isLoading => _isLoading;

  double get totalOutstandingDue => _customers.fold(0.0, (sum, c) => sum + c.balanceDue);

  Future<void> loadCustomers(String businessId, {String? query}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _customers = await _repository.getCustomers(businessId, query: query);
    } catch (e) {
      debugPrint('Error loading customers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Customer?> findByPhone(String businessId, String phone) async {
    return await _repository.getCustomerByPhone(businessId, phone);
  }

  Future<void> saveCustomer(Customer customer) async {
    await _repository.insertCustomer(customer);
    await loadCustomers(customer.businessId);
  }

  Future<void> collectDue(String businessId, String customerId, double amount) async {
    await _repository.collectDuePayment(customerId, amount);
    await loadCustomers(businessId);
  }
}
