import 'package:flutter/material.dart';
import '../data/models/held_bill.dart';
import '../data/models/stock_ledger.dart';
import '../data/repositories/stock_repository.dart';

class InventoryProvider extends ChangeNotifier {
  final StockRepository _repository = StockRepository();

  List<StockLedgerEntry> _ledger = [];
  List<HeldBill> _heldBills = [];
  bool _isLoading = false;

  List<StockLedgerEntry> get ledger => _ledger;
  List<HeldBill> get heldBills => _heldBills;
  bool get isLoading => _isLoading;

  Future<void> loadInventory(String businessId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _ledger = await _repository.getLedger(businessId);
      _heldBills = await _repository.getHeldBills(businessId);
    } catch (e) {
      debugPrint('Error loading inventory ledger: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> adjustStock({
    required String businessId,
    required String productId,
    required String productName,
    required double changeQty,
    required String reason,
  }) async {
    await _repository.adjustStock(
      businessId: businessId,
      productId: productId,
      productName: productName,
      changeQty: changeQty,
      reason: reason,
    );
    await loadInventory(businessId);
  }

  Future<void> deleteHeldBill(String businessId, String id) async {
    await _repository.deleteHeldBill(id);
    await loadInventory(businessId);
  }
}
