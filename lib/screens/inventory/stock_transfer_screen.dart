import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../providers/business_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/product_provider.dart';

class StockTransferScreen extends StatefulWidget {
  const StockTransferScreen({super.key});

  @override
  State<StockTransferScreen> createState() => _StockTransferScreenState();
}

class _StockTransferScreenState extends State<StockTransferScreen> {
  String _sourceLocation = 'Main Store Warehouse';
  String _destinationLocation = 'Branch Store #2 (Downtown)';
  String? _selectedProductId;
  final TextEditingController _qtyCtrl = TextEditingController(text: '10');
  final TextEditingController _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prodProv = context.watch<ProductProvider>();
    final invProv = context.watch<InventoryProvider>();
    final bizProv = context.watch<BusinessProvider>();
    final currentBiz = bizProv.currentBusiness;

    final products = prodProv.allProducts;
    if (_selectedProductId == null && products.isNotEmpty) {
      _selectedProductId = products.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Transfer Between Locations'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.spaceLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inter-Warehouse & Branch Stock Dispatch',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Move product inventory between main warehouse and satellite branches with automated ledger audit.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: AppTokens.spaceLG),
            AppCard(
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _sourceLocation,
                    decoration: const InputDecoration(
                      labelText: 'Source Location',
                      prefixIcon: Icon(Icons.warehouse_rounded),
                    ),
                    items: ['Main Store Warehouse', 'Storage Depo A']
                        .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                        .toList(),
                    onChanged: (v) => setState(() => _sourceLocation = v!),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_downward_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _destinationLocation,
                    decoration: const InputDecoration(
                      labelText: 'Destination Location',
                      prefixIcon: Icon(Icons.store_mall_directory_rounded),
                    ),
                    items: ['Branch Store #2 (Downtown)', 'Airport Kiosk', 'Sub-branch B']
                        .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                        .toList(),
                    onChanged: (v) => setState(() => _destinationLocation = v!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.spaceLG),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Items to Transfer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 12),
                  if (products.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: _selectedProductId,
                      decoration: const InputDecoration(
                        labelText: 'Select Product',
                        prefixIcon: Icon(Icons.inventory_2_rounded),
                      ),
                      items: products
                          .map((p) => DropdownMenuItem(
                                value: p.id,
                                child: Text('${p.name} (${p.stockQty.toInt()} available)'),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedProductId = v),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Transfer Quantity',
                      prefixIcon: Icon(Icons.numbers_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Transfer Reference / Gate Pass Note',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.spaceXL),
            AppButton(
              label: 'Dispatch & Confirm Transfer',
              icon: Icons.local_shipping_rounded,
              isFullWidth: true,
              height: 48,
              onPressed: () async {
                final qty = double.tryParse(_qtyCtrl.text) ?? 0.0;
                if (qty > 0 && _selectedProductId != null && currentBiz != null) {
                  final prod = products.firstWhere((p) => p.id == _selectedProductId);
                  await invProv.adjustStock(
                    businessId: currentBiz.id,
                    productId: prod.id,
                    productName: prod.name,
                    changeQty: -qty,
                    reason: 'Transfer to $_destinationLocation',
                  );
                  await prodProv.loadProducts(currentBiz.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Dispatched $qty units of ${prod.name} to $_destinationLocation')),
                    );
                    Navigator.pop(context);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
