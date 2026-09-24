import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/search_bar_widget.dart';
import '../../data/models/estimate.dart';
import '../../providers/business_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/estimate_provider.dart';
import '../../providers/product_provider.dart';
import 'widgets/estimate_slip_dialog.dart';

class EstimatesScreen extends StatefulWidget {
  final VoidCallback? onOpenPos;

  const EstimatesScreen({super.key, this.onOpenPos});

  @override
  State<EstimatesScreen> createState() => _EstimatesScreenState();
}

class _EstimatesScreenState extends State<EstimatesScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final biz = context.read<BusinessProvider>().currentBusiness;
      if (biz != null) {
        context.read<EstimateProvider>().loadEstimates(biz.id);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleConvertToSale(Estimate estimate) async {
    final products = context.read<ProductProvider>().allProducts;
    final cart = context.read<CartProvider>();

    await context.read<EstimateProvider>().convertEstimateToCart(
          estimate: estimate,
          cart: cart,
          availableProducts: products,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estimate ${estimate.estimateNo} loaded into POS Cart! Complete checkout to finalize sale.'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
      widget.onOpenPos?.call();
    }
  }

  Future<void> _confirmVoid(Estimate estimate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Void Estimate ${estimate.estimateNo}?'),
        content: const Text('This will mark the quotation as voided. It cannot be converted to a sale.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Void', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<EstimateProvider>().voidEstimate(estimate.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Estimate ${estimate.estimateNo} voided.')),
        );
      }
    }
  }

  Future<void> _confirmDelete(Estimate estimate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Estimate ${estimate.estimateNo}?'),
        content: const Text('This will permanently delete this estimate record and its item details.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<EstimateProvider>().deleteEstimate(estimate.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Estimate ${estimate.estimateNo} deleted.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final estProv = context.watch<EstimateProvider>();
    final bizProv = context.watch<BusinessProvider>();
    final currentBiz = bizProv.currentBusiness;
    final symbol = currentBiz?.currencySymbol ?? '₹';
    final isDark = theme.brightness == Brightness.dark;

    final estimates = estProv.filteredEstimates;

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              border: Border(bottom: BorderSide(color: theme.dividerColor.withAlpha(60))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estimates & Quotations',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Generate price quotes, print formal slips, and convert directly to sales',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withAlpha(150),
                          ),
                        ),
                      ],
                    ),
                    // Quick Action to POS
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.point_of_sale_rounded, size: 18),
                      label: const Text('Open POS Cart', style: TextStyle(fontWeight: FontWeight.w700)),
                      onPressed: () => widget.onOpenPos?.call(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Metrics summary bar
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _buildMetricCard(
                      label: 'Active Quotes',
                      value: '${estProv.activeCount}',
                      subvalue: CurrencyFormatter.format(estProv.activeTotalValue, symbol: symbol),
                      color: const Color(0xFF059669),
                      isDark: isDark,
                    ),
                    _buildMetricCard(
                      label: 'Converted to Sale',
                      value: '${estProv.convertedCount}',
                      subvalue: 'Billed',
                      color: const Color(0xFF2563EB),
                      isDark: isDark,
                    ),
                    _buildMetricCard(
                      label: 'Expired',
                      value: '${estProv.expiredCount}',
                      subvalue: 'Past validity',
                      color: const Color(0xFFD97706),
                      isDark: isDark,
                    ),
                    _buildMetricCard(
                      label: 'Total Quotes',
                      value: '${estProv.totalCount}',
                      subvalue: 'Lifetime',
                      color: const Color(0xFF6366F1),
                      isDark: isDark,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Search & Filter Tabs
                Row(
                  children: [
                    Expanded(
                      child: SearchBarWidget(
                        hint: 'Search by estimate #, customer name, phone, or items...',
                        onSearchChanged: (val) => estProv.setSearchQuery(val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'All (${estProv.totalCount})', estProv),
                      const SizedBox(width: 8),
                      _buildFilterChip('Active', 'Active / Valid (${estProv.activeCount})', estProv),
                      const SizedBox(width: 8),
                      _buildFilterChip('Converted', 'Converted (${estProv.convertedCount})', estProv),
                      const SizedBox(width: 8),
                      _buildFilterChip('Expired', 'Expired (${estProv.expiredCount})', estProv),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content List
          Expanded(
            child: estProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : estimates.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.request_quote_outlined,
                        title: 'No Estimates Found',
                        description: estProv.searchQuery.isNotEmpty
                            ? 'No quotation matches "${estProv.searchQuery}"'
                            : 'Create quotations from the POS Cart panel by clicking "Quote".',
                        actionLabel: 'Open POS Cart',
                        onAction: () => widget.onOpenPos?.call(),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: estimates.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final est = estimates[index];
                          return _buildEstimateCard(context, est, symbol, theme, isDark);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, EstimateProvider prov) {
    final isSelected = prov.selectedFilter == key;
    final primary = Theme.of(context).colorScheme.primary;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => prov.setFilter(key),
      selectedColor: primary.withAlpha(25),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
        color: isSelected ? primary : null,
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required String subvalue,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 25 : 15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
              Text(
                subvalue,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color.withAlpha(200),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstimateCard(
    BuildContext context,
    Estimate est,
    String symbol,
    ThemeData theme,
    bool isDark,
  ) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final validFormat = DateFormat('dd MMM yyyy');
    final statusColor = _getStatusColor(est.displayStatus);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: est.isActive ? theme.dividerColor.withAlpha(100) : theme.dividerColor.withAlpha(50),
          width: est.isActive ? 1.2 : 1,
        ),
        boxShadow: est.isActive
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 30 : 8),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => EstimateSlipDialog.show(context, est, onConverted: widget.onOpenPos),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Estimate No, Status, Date
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        est.estimateNo,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        est.displayStatus.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      dateFormat.format(est.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withAlpha(140),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, size: 18),
                      onSelected: (action) {
                        if (action == 'view') {
                          EstimateSlipDialog.show(context, est, onConverted: widget.onOpenPos);
                        } else if (action == 'convert') {
                          _handleConvertToSale(est);
                        } else if (action == 'void') {
                          _confirmVoid(est);
                        } else if (action == 'delete') {
                          _confirmDelete(est);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.receipt_long_rounded, size: 16),
                              SizedBox(width: 8),
                              Text('View / Print Slip'),
                            ],
                          ),
                        ),
                        if (est.isActive)
                          const PopupMenuItem(
                            value: 'convert',
                            child: Row(
                              children: [
                                Icon(Icons.shopping_cart_checkout_rounded, size: 16, color: Color(0xFF059669)),
                                SizedBox(width: 8),
                                Text('Convert to Sale', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        if (!est.isVoided && !est.isConverted)
                          const PopupMenuItem(
                            value: 'void',
                            child: Row(
                              children: [
                                Icon(Icons.block_rounded, size: 16, color: Color(0xFFDC2626)),
                                SizedBox(width: 8),
                                Text('Void Estimate', style: TextStyle(color: Color(0xFFDC2626))),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Color(0xFFDC2626))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Customer & Items summary
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person_outline_rounded, size: 14, color: theme.colorScheme.onSurface.withAlpha(140)),
                              const SizedBox(width: 4),
                              Text(
                                est.customerName ?? 'Walk-in Customer',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              if (est.customerPhone != null && est.customerPhone!.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '(${est.customerPhone})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface.withAlpha(140),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            est.items.map((it) => it.productName).join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: theme.colorScheme.onSurface.withAlpha(150),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Final Total
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(est.finalTotal, symbol: symbol),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          '${est.items.length} item(s)',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withAlpha(140),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Bottom row: Validity & Convert Button
                Row(
                  children: [
                    if (est.validUntil != null) ...[
                      Icon(Icons.schedule_rounded, size: 13, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        est.isExpired
                            ? 'Expired on ${validFormat.format(est.validUntil!)}'
                            : (est.daysRemaining != null
                                ? 'Valid till ${validFormat.format(est.validUntil!)} (${est.daysRemaining} days left)'
                                : 'Valid till ${validFormat.format(est.validUntil!)}'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                    const Spacer(),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.receipt_long_rounded, size: 14),
                      label: const Text('View Slip', style: TextStyle(fontSize: 11.5)),
                      onPressed: () => EstimateSlipDialog.show(context, est, onConverted: widget.onOpenPos),
                    ),
                    if (est.isActive) ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 14, color: Colors.white),
                        label: const Text('Bill Now', style: TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w800)),
                        onPressed: () => _handleConvertToSale(est),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF059669);
      case 'converted':
        return const Color(0xFF2563EB);
      case 'expired':
        return const Color(0xFFD97706);
      case 'voided':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }
}
