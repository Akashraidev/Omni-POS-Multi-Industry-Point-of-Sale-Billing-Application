import 'package:flutter/material.dart';
import '../data/models/supplier.dart';
import '../data/repositories/supplier_repository.dart';

class SupplierProvider extends ChangeNotifier {
  final SupplierRepository _repository = SupplierRepository();

  List<Supplier> _suppliers = [];
  bool _isLoading = false;

  List<Supplier> get suppliers => _suppliers;
  bool get isLoading => _isLoading;

  double get totalSupplierPayables => _suppliers.fold(0.0, (sum, s) => sum + s.balanceDue);

  Future<void> loadSuppliers(String businessId, {String? query}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _suppliers = await _repository.getSuppliers(businessId, query: query);
    } catch (e) {
      debugPrint('Error loading suppliers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveSupplier(Supplier supplier) async {
    await _repository.insertSupplier(supplier);
    await loadSuppliers(supplier.businessId);
  }

  Future<void> deleteSupplier(String businessId, String id) async {
    await _repository.deleteSupplier(id);
    await loadSuppliers(businessId);
  }
}
