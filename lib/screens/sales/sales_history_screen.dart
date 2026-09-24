import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../providers/business_provider.dart';
import '../../providers/sales_provider.dart';
import 'invoice_view_screen.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final biz = context.read<BusinessProvider>().currentBusiness;
      if (biz != null) {
        context.read<SalesProvider>().loadSales(biz.id);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final salesProv = context.watch<SalesProvider>();
    final bizProv = context.watch<BusinessProvider>();
    final currentBiz = bizProv.currentBusiness;
    final symbol = currentBiz?.currencySymbol ?? '₹';

    final filteredSales = salesProv.sales.where((s) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return s.invoiceNo.toLowerCase().contains(q) ||
          (s.customerName ?? '').toLowerCase().contains(q) ||
          (s.customerPhone ?? '').contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History & Invoices'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              if (currentBiz != null) salesProv.loadSales(currentBiz.id);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Padding(
            padding: const EdgeInsets.all(AppTokens.spaceMD),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _query = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search by Invoice No, Customer or Phone...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          // Status Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceMD),
            child: Row(
              children: ['All', 'Completed', 'Voided'].map((status) {
                final isSel = salesProv.statusFilter == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: isSel,
                    onSelected: (_) {
                      if (currentBiz != null) salesProv.setStatusFilter(currentBiz.id, status);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          // Sales List
          Expanded(
            child: salesProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredSales.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.receipt_long_outlined,
                        title: 'No Invoices Found',
                        description: 'No sales transactions match the given search query or filters.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppTokens.spaceLG),
                        itemCount: filteredSales.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppTokens.spaceMD),
                        itemBuilder: (context, index) {
                          final sale = filteredSales[index];
                          final isVoided = sale.status == 'Voided';

                          return AppCard(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => InvoiceViewScreen(sale: sale),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isVoided ? Colors.red.withAlpha(20) : theme.colorScheme.primary.withAlpha(20),
                                    borderRadius: AppTokens.borderMD,
                                  ),
                                  child: Icon(
                                    Icons.receipt_rounded,
                                    color: isVoided ? Colors.red : theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: AppTokens.spaceMD),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            sale.invoiceNo,
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                          ),
                                          const SizedBox(width: 8),
                                          AppBadge(
                                            label: sale.status,
                                            type: isVoided ? BadgeType.error : BadgeType.success,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Customer: ${sale.customerName ?? 'Walk-in'} • ${sale.paymentMethod}',
                                        style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withAlpha(150)),
                                      ),
                                      Text(
                                        'Date: ${sale.createdAt.toString().substring(0, 16)}',
                                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(120)),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      CurrencyFormatter.format(sale.finalTotal, symbol: symbol),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        decoration: isVoided ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    if (!isVoided)
                                      IconButton(
                                        icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                                        tooltip: 'Void Bill',
                                        onPressed: () async {
                                          final confirmed = await ConfirmationDialog.show(
                                            context,
                                            title: 'Void Invoice ${sale.invoiceNo}?',
                                            message:
                                                'Voiding will cancel this sale, reverse deducted inventory stock back to products, and update the stock ledger.',
                                            confirmLabel: 'Void Bill',
                                            isDestructive: true,
                                          );
                                          if (confirmed == true && currentBiz != null) {
                                            await salesProv.voidSale(currentBiz.id, sale.id, 'Customer cancellation');
                                          }
                                        },
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
