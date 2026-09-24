import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/business.dart';
import '../data/repositories/business_repository.dart';
import '../modules/business_type.dart';

class BusinessProvider extends ChangeNotifier {
  final BusinessRepository _repository = BusinessRepository();

  List<Business> _businesses = [];
  Business? _currentBusiness;
  bool _isLoading = false;

  List<Business> get businesses => _businesses;
  Business? get currentBusiness => _currentBusiness;
  BusinessType get currentBusinessType => _currentBusiness?.type ?? BusinessType.grocery;
  bool get isLoading => _isLoading;

  Future<void> loadBusinesses() async {
    _isLoading = true;
    notifyListeners();

    try {
      _businesses = await _repository.getAllBusinesses();

      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('active_business_id');

      if (_businesses.isNotEmpty) {
        if (savedId != null) {
          _currentBusiness = _businesses.firstWhere(
            (b) => b.id == savedId,
            orElse: () => _businesses.first,
          );
        } else {
          _currentBusiness = _businesses.first;
        }
      } else {
        _currentBusiness = null;
      }
    } catch (e) {
      debugPrint('Error loading businesses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> switchBusiness(Business business) async {
    _currentBusiness = business;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_business_id', business.id);
  }

  Future<void> createBusiness(Business business) async {
    await _repository.insertBusiness(business);
    await loadBusinesses();
    await switchBusiness(business);
  }

  Future<void> updateCurrentBusiness(Business updated) async {
    await _repository.updateBusiness(updated);
    _currentBusiness = updated;
    await loadBusinesses();
  }
}
