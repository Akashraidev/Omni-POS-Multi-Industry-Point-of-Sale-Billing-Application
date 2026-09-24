import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/search_bar_widget.dart';
import '../../data/models/purchase.dart';
import '../../providers/business_provider.dart';
import '../../providers/purchase_provider.dart';
import 'purchase_entry_screen.dart';
import 'widgets/purchase_detail_dialog.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final biz = context.read<BusinessProvider>().currentBusiness;
    if (biz != null) {
      context.read<PurchaseProvider>().loadPurchases(biz.id);
    }
  }

  static const Color _emerald = Color(0xFF10B981);
  static const Color _rose = Color(0xFFE11D48);

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'received':
        return _emerald;
      case 'pending':
        return Colors.amber.shade700;
      case 'voided':
        return _rose;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final symbol = context.watch<BusinessProvider>().currentBusiness?.currencySymbol ?? '₹';
    final purchaseProv = context.watch<PurchaseProvider>();
    final purchases = purchaseProv.filteredPurchases;

    return Scaffold(
      body: purchaseProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: CustomScrollView(
                slivers: [
                  // Top Header & Actions
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.inventory_rounded, color: theme.colorScheme.primary, size: 28),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Purchase & Stock Inward',
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Supplier invoices, Goods Receipt Notes (GRN), and inward batch tracking',
                                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.add, size: 20),
                                label: const Text(
                                  'New Purchase Entry',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const PurchaseEntryScreen()),
                                  );
                                  _loadData();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Metrics Bar (4 Cards)
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 700;
                              return Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  _buildMetricCard(
                                    width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                                    title: 'Total Inward Value',
                                    value: '$symbol${purchaseProv.totalPurchaseValue.toStringAsFixed(2)}',
                                    subtitle: '${purchaseProv.purchases.length} lifetime orders',
                                    icon: Icons.account_balance_wallet_rounded,
                                    color: Colors.indigo,
                                    isDark: isDark,
                                  ),
                                  _buildMetricCard(
                                    width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                                    title: 'This Month\'s Inward',
                                    value: '$symbol${purchaseProv.monthlyPurchaseValue.toStringAsFixed(2)}',
                                    subtitle: 'Current billing cycle',
                                    icon: Icons.calendar_month_rounded,
                                    color: _emerald,
                                    isDark: isDark,
                                  ),
                                  _buildMetricCard(
                                    width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                                    title: 'Supplier Dues Payable',
                                    value: '$symbol${purchaseProv.totalDueAmount.toStringAsFixed(2)}',
                                    subtitle: 'Credit balance pending',
                                    icon: Icons.pending_actions_rounded,
                                    color: purchaseProv.totalDueAmount > 0 ? Colors.amber.shade800 : Colors.teal,
                                    isDark: isDark,
                                  ),
                                  _buildMetricCard(
                                    width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                                    title: 'GRN Status Counts',
                                    value: '${purchaseProv.receivedCount} Inwarded',
                                    subtitle: '${purchaseProv.pendingCount} Pending • ${purchaseProv.voidedCount} Voided',
                                    icon: Icons.receipt_long_rounded,
                                    color: Colors.blueGrey,
                                    isDark: isDark,
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 18),

                          // Search & Filter Bar
                          Row(
                            children: [
                              Expanded(
                                child: SearchBarWidget(
                                  hint: 'Search by invoice #, supplier name, notes...',
                                  onSearchChanged: (q) => purchaseProv.setSearchQuery(q),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Filter Tabs
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip('All', 'All (${purchaseProv.purchases.length})', purchaseProv),
                                const SizedBox(width: 8),
                                _buildFilterChip('Received', 'Received (${purchaseProv.receivedCount})', purchaseProv),
                                const SizedBox(width: 8),
                                _buildFilterChip('Pending', 'Pending (${purchaseProv.pendingCount})', purchaseProv),
                                const SizedBox(width: 8),
                                _buildFilterChip('Voided', 'Voided (${purchaseProv.voidedCount})', purchaseProv),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content List / Table
                  if (purchases.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              purchaseProv.searchQuery.isNotEmpty || purchaseProv.statusFilter != 'All'
                                  ? 'No purchases match your criteria'
                                  : 'No inward purchase orders yet',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              purchaseProv.searchQuery.isNotEmpty || purchaseProv.statusFilter != 'All'
                                  ? 'Try clearing your search or filter'
                                  : 'Record supplier invoices to automatically increment stock & FEFO batches',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const SizedBox(height: 16),
                            if (purchaseProv.purchases.isEmpty)
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Record First Purchase'),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const PurchaseEntryScreen()),
                                  );
                                  _loadData();
                                },
                              ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final purchase = purchases[index];
                            return _buildPurchaseCard(context, purchase, theme, isDark, symbol);
                          },
                          childCount: purchases.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard({
    required double width,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label, PurchaseProvider provider) {
    final isSelected = provider.statusFilter.toLowerCase() == filterKey.toLowerCase();
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) => provider.setFilter(filterKey),
    );
  }

  Widget _buildPurchaseCard(
    BuildContext context,
    Purchase purchase,
    ThemeData theme,
    bool isDark,
    String symbol,
  ) {
    final statusColor = _getStatusColor(purchase.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => PurchaseDetailDialog.show(context, purchase),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // GRN Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.receipt_rounded, color: statusColor, size: 24),
              ),
              const SizedBox(width: 14),

              // Invoice & Supplier Info
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          purchase.invoiceNo,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            purchase.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Supplier: ${purchase.supplierName ?? 'Direct Purchase'}',
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _dateFormat.format(purchase.createdAt),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Units & Items Summary
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${purchase.items.length} items (${purchase.totalUnitsCount} Billed'
                      '${purchase.totalFreeUnits > 0 ? ' + ${purchase.totalFreeUnits} Free' : ''})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: (purchase.paymentStatus == 'Paid'
                                    ? _emerald
                                    : purchase.paymentStatus == 'Due'
                                        ? _rose
                                        : Colors.amber)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${purchase.paymentStatus} (${purchase.paymentMethod})',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: purchase.paymentStatus == 'Paid'
                                  ? _emerald
                                  : purchase.paymentStatus == 'Due'
                                      ? _rose
                                      : Colors.amber.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Financial Values
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$symbol${purchase.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    if (purchase.dueAmount > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Due: $symbol${purchase.dueAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Chevron Action
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
