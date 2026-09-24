import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/models/business.dart';
import '../data/models/cart_item.dart';
import '../data/models/sale.dart';
import '../data/repositories/sale_repository.dart';

class PosBillingProvider extends ChangeNotifier {
  final SaleRepository _saleRepository = SaleRepository();
  final Uuid _uuid = const Uuid();

  bool _isProcessing = false;
  Sale? _lastCompletedSale;

  bool get isProcessing => _isProcessing;
  Sale? get lastCompletedSale => _lastCompletedSale;

  Future<Sale?> completeCheckout({
    required Business business,
    required List<CartItem> items,
    required double subtotal,
    required double taxAmount,
    required double discountAmount,
    required double roundOff,
    required double finalTotal,
    required String paymentMethod,
    required Map<String, double> splitBreakup,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? orderType,
    String? tableNumber,
    String? doctorName,
    String? notes,
  }) async {
    _isProcessing = true;
    notifyListeners();

    try {
      final invoiceNo = await _saleRepository.generateNextInvoiceNo(
        business.id,
        business.invoicePrefix,
      );

      final saleId = _uuid.v4();

      final List<SaleItem> saleItems = items.map((it) {
        // Free-scheme units are folded into the line discount so the invoice
        // stays arithmetically consistent without needing a new DB column.
        final freeValue = it.freeValue;
        final lineDiscount = it.discountAmount + freeValue;
        final lineSub = (it.unitPrice * it.quantity) - lineDiscount;
        final lineTax = (lineSub * it.taxRate) / 100.0;
        final modifiers = <String>[...it.selectedModifiers];
        if (it.freeQuantity > 0) {
          modifiers.add('Free: ${it.freeQuantity.toStringAsFixed(0)}');
        }
        return SaleItem(
          id: _uuid.v4(),
          saleId: saleId,
          productId: it.product.id,
          productName: it.product.name,
          sku: it.product.sku,
          quantity: it.quantity,
          unitPrice: it.unitPrice,
          discountAmount: lineDiscount,
          taxRate: it.taxRate,
          taxAmount: lineTax,
          lineTotal: lineSub + lineTax,
          batchNumber: it.selectedBatch,
          batchExpiry: it.batchExpiry,
          serialImei: it.selectedImei,
          variant: it.selectedVariant,
          modifiers: modifiers.join(', '),
        );
      }).toList();

      final sale = Sale(
        id: saleId,
        businessId: business.id,
        invoiceNo: invoiceNo,
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        subtotal: subtotal,
        taxAmount: taxAmount,
        discountAmount: discountAmount,
        roundOff: roundOff,
        finalTotal: finalTotal,
        paymentMethod: paymentMethod,
        splitBreakup: splitBreakup,
        status: 'Completed',
        orderType: orderType ?? 'Counter',
        tableNumber: tableNumber,
        doctorName: doctorName,
        notes: notes,
        createdAt: DateTime.now(),
        items: saleItems,
      );

      await _saleRepository.createSale(sale);
      _lastCompletedSale = sale;
      return sale;
    } catch (e) {
      debugPrint('Error during checkout: $e');
      rethrow;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
}
