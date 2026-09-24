import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../providers/business_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/product_provider.dart';
import 'stock_transfer_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final biz = context.read<BusinessProvider>().currentBusiness;
      if (biz != null) {
        context.read<InventoryProvider>().loadInventory(biz.id);
        context.read<ProductProvider>().loadProducts(biz.id);
      }
    });
  }

  void _showAdjustStockDialog(BuildContext context) {
    final prodProv = context.read<ProductProvider>();
    final invProv = context.read<InventoryProvider>();
    final biz = context.read<BusinessProvider>().currentBusiness;
    if (biz == null || prodProv.allProducts.isEmpty) return;

    String selectedProdId = prodProv.allProducts.first.id;
    final qtyCtrl = TextEditingController(text: '1');
    String reason = 'Adjustment / Audit';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              title: const Text('Manual Stock Adjustment'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedProdId,
                    decoration: const InputDecoration(labelText: 'Select Product'),
                    items: prodProv.allProducts.map((p) {
                      return DropdownMenuItem(value: p.id, child: Text(p.name));
                    }).toList(),
                    onChanged: (v) => setDlgState(() => selectedProdId = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: qtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Quantity Change (+/-)',
                      hintText: 'e.g. +10 or -5',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: reason,
                    decoration: const InputDecoration(labelText: 'Reason'),
                    items: ['Adjustment / Audit', 'Damage / Spoilage', 'Return to Stock', 'Initial Opening']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => setDlgState(() => reason = v!),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final change = double.tryParse(qtyCtrl.text) ?? 0.0;
                    final prod = prodProv.allProducts.firstWhere((p) => p.id == selectedProdId);
                    await invProv.adjustStock(
                      businessId: biz.id,
                      productId: prod.id,
                      productName: prod.name,
                      changeQty: change,
                      reason: reason,
                    );
                    await prodProv.loadProducts(biz.id);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save Adjustment'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final invProv = context.watch<InventoryProvider>();
    final prodProv = context.watch<ProductProvider>();

    final lowStockItems = prodProv.allProducts.where((p) => p.isLowStock).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inventory & Stock Audit'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Real-time Stock Ledger'),
              Tab(text: 'Low Stock Reorder Alerts'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Stock Transfer Between Locations',
              icon: const Icon(Icons.swap_horiz_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StockTransferScreen()),
                );
              },
            ),
            IconButton(
              tooltip: 'Adjust Stock',
              icon: const Icon(Icons.tune_rounded),
              onPressed: () => _showAdjustStockDialog(context),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Real-time Stock Ledger
            invProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : invProv.ledger.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.history_rounded,
                        title: 'Stock Ledger Empty',
                        description: 'All product inventory movements (sales, purchases, adjustments) will appear here in chronological order.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppTokens.spaceLG),
                        itemCount: invProv.ledger.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppTokens.spaceMD),
                        itemBuilder: (context, index) {
                          final log = invProv.ledger[index];
                          final isPositive = log.changeQty > 0;

                          return AppCard(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isPositive ? Colors.green.withAlpha(25) : Colors.red.withAlpha(25),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isPositive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                    color: isPositive ? Colors.green : Colors.red,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: AppTokens.spaceMD),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        log.productName,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Reason: ${log.reason} ${log.referenceId != null ? "• Ref: ${log.referenceId}" : ""}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      Text(
                                        log.createdAt.toString().substring(0, 16),
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${isPositive ? "+" : ""}${log.changeQty.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: isPositive ? Colors.green : Colors.red,
                                      ),
                                    ),
                                    Text(
                                      'Bal: ${log.balanceQty.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            // Tab 2: Low Stock Alerts
            lowStockItems.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'Healthy Stock Levels',
                    description: 'No products currently fall below their minimum reorder point threshold.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppTokens.spaceLG),
                    itemCount: lowStockItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppTokens.spaceMD),
                    itemBuilder: (context, index) {
                      final p = lowStockItems[index];
                      return AppCard(
                        borderColor: Colors.orange.withAlpha(80),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.orange.withAlpha(25),
                                borderRadius: AppTokens.borderMD,
                              ),
                              child: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                            ),
                            const SizedBox(width: AppTokens.spaceMD),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                  const SizedBox(height: 2),
                                  Text('SKU: ${p.sku} | Min Alert: ${p.minStockAlert.toInt()} ${p.unit}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                AppBadge(label: '${p.stockQty.toInt()} left', type: BadgeType.warning),
                                const SizedBox(height: 4),
                                const Text('Reorder', style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
