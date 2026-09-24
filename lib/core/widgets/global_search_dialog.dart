import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/sales_provider.dart';
import '../theme/app_tokens.dart';

class GlobalSearchDialog extends StatefulWidget {
  const GlobalSearchDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const GlobalSearchDialog(),
    );
  }

  @override
  State<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends State<GlobalSearchDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productProv = context.watch<ProductProvider>();
    final salesProv = context.watch<SalesProvider>();
    final custProv = context.watch<CustomerProvider>();

    final matchedProducts = _query.isEmpty
        ? []
        : productProv.allProducts
            .where((p) =>
                p.name.toLowerCase().contains(_query.toLowerCase()) ||
                p.sku.toLowerCase().contains(_query.toLowerCase()) ||
                p.barcode.contains(_query))
            .take(4)
            .toList();

    final matchedCustomers = _query.isEmpty
        ? []
        : custProv.customers
            .where((c) =>
                c.name.toLowerCase().contains(_query.toLowerCase()) ||
                c.phone.contains(_query))
            .take(3)
            .toList();

    final matchedSales = _query.isEmpty
        ? []
        : salesProv.sales
            .where((s) =>
                s.invoiceNo.toLowerCase().contains(_query.toLowerCase()) ||
                (s.customerName ?? '').toLowerCase().contains(_query.toLowerCase()))
            .take(3)
            .toList();

    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: AppTokens.borderXL),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTokens.spaceMD),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: (val) => setState(() => _query = val.trim()),
                decoration: InputDecoration(
                  hintText: 'Search products, invoices, customers...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                ),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: _query.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppTokens.spaceXXL),
                      child: Text(
                        'Type to quickly jump to any product, customer or invoice.',
                        style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(140)),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        if (matchedProducts.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Text('PRODUCTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)),
                          ),
                          ...matchedProducts.map((p) => ListTile(
                                leading: const Icon(Icons.inventory_2_outlined),
                                title: Text(p.name),
                                subtitle: Text('SKU: ${p.sku} | Stock: ${p.stockQty} ${p.unit}'),
                                trailing: Text('₹${p.sellingPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                onTap: () => Navigator.pop(context),
                              )),
                        ],
                        if (matchedCustomers.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Text('CUSTOMERS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)),
                          ),
                          ...matchedCustomers.map((c) => ListTile(
                                leading: const Icon(Icons.person_outline_rounded),
                                title: Text(c.name),
                                subtitle: Text(c.phone),
                                trailing: Text('Due: ₹${c.balanceDue.toStringAsFixed(0)}'),
                                onTap: () => Navigator.pop(context),
                              )),
                        ],
                        if (matchedSales.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Text('INVOICES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)),
                          ),
                          ...matchedSales.map((s) => ListTile(
                                leading: const Icon(Icons.receipt_long_outlined),
                                title: Text(s.invoiceNo),
                                subtitle: Text(s.customerName ?? 'Walk-in Guest'),
                                trailing: Text('₹${s.finalTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                onTap: () => Navigator.pop(context),
                              )),
                        ],
                        if (matchedProducts.isEmpty && matchedCustomers.isEmpty && matchedSales.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(AppTokens.spaceXL),
                            child: Center(child: Text('No matching records found.')),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
