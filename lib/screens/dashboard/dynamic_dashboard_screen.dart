import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/permissions.dart';
import '../../core/widgets/global_search_dialog.dart';
import '../../core/widgets/shimmer_skeleton.dart';
import '../../data/models/analytics.dart';
import '../../data/models/business.dart';
import '../../data/models/product.dart';
import '../../data/models/sale.dart';
import '../../modules/business_registry.dart';
import '../../modules/medical/medical_batch_analyzer.dart';
import '../../modules/medical/medical_palette.dart';
import '../../providers/app_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/supplier_provider.dart';
import '../expenses/expenses_screen.dart';
import '../pos/pos_screen.dart';
import '../products/product_form_screen.dart';
import '../products/product_list_screen.dart';
import '../purchases/purchases_screen.dart';
import '../sales/invoice_view_screen.dart';
import 'widgets/alert_panels.dart';
import 'widgets/kpi_cards.dart';
import 'widgets/trend_charts.dart';

class DynamicDashboardScreen extends StatefulWidget {
  final VoidCallback? onOpenPos;

  const DynamicDashboardScreen({super.key, this.onOpenPos});

  @override
  State<DynamicDashboardScreen> createState() => _DynamicDashboardScreenState();
}

class _DynamicDashboardScreenState extends State<DynamicDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Guarantee aggregates exist even if the user deep-links here directly.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final biz = context.read<BusinessProvider>().currentBusiness;
      if (biz != null) {
        context.read<DashboardProvider>().load(biz.id);
        context.read<ProductProvider>().loadProducts(biz.id);
        context.read<SalesProvider>().loadSales(biz.id);
      }
    });
  }

  Future<void> _refreshAll() async {
    final biz = context.read<BusinessProvider>().currentBusiness;
    if (biz == null) return;
    await Future.wait([
      context.read<ProductProvider>().loadProducts(biz.id),
      context.read<SalesProvider>().loadSales(biz.id),
      context.read<CustomerProvider>().loadCustomers(biz.id),
      context.read<SupplierProvider>().loadSuppliers(biz.id),
      context.read<DashboardProvider>().load(biz.id),
    ]);
  }

  void _goToPos() {
    if (widget.onOpenPos != null) {
      widget.onOpenPos!();
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PosScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bizProv = context.watch<BusinessProvider>();
    final dash = context.watch<DashboardProvider>();
    final productProv = context.watch<ProductProvider>();
    final salesProv = context.watch<SalesProvider>();
    final custProv = context.watch<CustomerProvider>();
    final suppProv = context.watch<SupplierProvider>();
    final session = context.watch<SessionProvider>();
    final appProv = context.watch<AppProvider>();

    final currentBiz = bizProv.currentBusiness;
    if (currentBiz == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final bizModule = BusinessModuleRegistry.getModule(currentBiz.type);
    final symbol = currentBiz.currencySymbol;
    final role = appProv.currentUser.role;
    final canSeeFinancials = Permissions.can(role, Capability.viewFinancials);
    final canSeeExpenses = Permissions.can(role, Capability.viewExpenses);
    final canManageProducts = Permissions.can(role, Capability.manageProducts);
    final canBill = Permissions.can(role, Capability.billing);
    final canManageShift = Permissions.can(role, Capability.manageShift);
    final isMedical = currentBiz.type == BusinessType.medical;

    final products = productProv.allProducts;
    final hasAnyData = products.isNotEmpty ||
        dash.aggregates.invoiceCount > 0 ||
        dash.todayPurchases > 0;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentBiz.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            Text(
              isMedical ? 'Pharmacy Operations' : currentBiz.type.displayName,
              style: TextStyle(fontSize: 11.5, color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Universal Search (Ctrl+K)',
            icon: const Icon(Icons.search_rounded),
            onPressed: () => GlobalSearchDialog.show(context),
          ),
          if (canBill)
            IconButton(
              tooltip: 'New Sale / POS',
              icon: const Icon(Icons.point_of_sale_rounded),
              onPressed: _goToPos,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1680),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: dash.isLoading && !hasAnyData
                  ? const _DashboardSkeleton()
                  : (dash.error != null && !hasAnyData
                      ? _ErrorState(message: dash.error!, onRetry: _refreshAll)
                      : (!hasAnyData
                          ? _EmptyState(
                              isMedical: isMedical,
                              canManageProducts: canManageProducts,
                              canBill: canBill,
                              onAddMedicine: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductFormScreen(businessId: currentBiz.id),
                                ),
                              ),
                              onStartSale: canBill ? _goToPos : null,
                              onManageStock: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ProductListScreen()),
                              ),
                            )
                          : _DashboardBody(
                              symbol: symbol,
                              theme: theme,
                              dash: dash,
                              salesProv: salesProv,
                              productProv: productProv,
                              custProv: custProv,
                              suppProv: suppProv,
                              session: session,
                              bizModule: bizModule,
                              currentBiz: currentBiz,
                              canSeeFinancials: canSeeFinancials,
                              canSeeExpenses: canSeeExpenses,
                              canManageProducts: canManageProducts,
                              canBill: canBill,
                              canManageShift: canManageShift,
                              onOpenPos: _goToPos,
                              onRetry: _refreshAll,
                            ))),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Populated dashboard
// ---------------------------------------------------------------------------

class _DashboardBody extends StatelessWidget {
  final String symbol;
  final ThemeData theme;
  final DashboardProvider dash;
  final SalesProvider salesProv;
  final ProductProvider productProv;
  final CustomerProvider custProv;
  final SupplierProvider suppProv;
  final SessionProvider session;
  final BusinessModuleInterface bizModule;
  final Business currentBiz;
  final bool canSeeFinancials;
  final bool canSeeExpenses;
  final bool canManageProducts;
  final bool canBill;
  final bool canManageShift;
  final VoidCallback onOpenPos;
  final VoidCallback onRetry;

  const _DashboardBody({
    required this.symbol,
    required this.theme,
    required this.dash,
    required this.salesProv,
    required this.productProv,
    required this.custProv,
    required this.suppProv,
    required this.session,
    required this.bizModule,
    required this.currentBiz,
    required this.canSeeFinancials,
    required this.canSeeExpenses,
    required this.canManageProducts,
    required this.canBill,
    required this.canManageShift,
    required this.onOpenPos,
    required this.onRetry,
  });

  /// Period-over-period delta derived from the trend series (never hardcoded).
  double _delta(List<TrendPoint> points) {
    if (points.length < 2) return 0.0;
    final today = points.last.value;
    final prev = points[points.length - 2].value;
    if (prev <= 0) return today > 0 ? 100.0 : 0.0;
    return ((today - prev) / prev) * 100.0;
  }

  @override
  Widget build(BuildContext context) {
    final agg = dash.aggregates;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (dash.error != null) _InlineErrorBanner(message: dash.error!, onRetry: onRetry),
        // 1. Date strip + shift status + quick actions
        _DateAndShiftStrip(
          dash: dash,
          session: session,
          canManageShift: canManageShift,
          canBill: canBill,
          onOpenPos: onOpenPos,
        ),
        const SizedBox(height: AppTokens.spaceLG),

        // 2. Primary KPI cards
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth >= 880 ? 4 : (constraints.maxWidth >= 520 ? 2 : 1);
            final spacing = AppTokens.spaceMD;
            final w = (constraints.maxWidth - spacing * (cols - 1)) / cols;
            final children = <Widget>[
              DashboardKpiCard(
                title: "Today's Sales",
                value: CurrencyFormatter.compact(agg.revenue, symbol: symbol),
                subtitle: '${agg.invoiceCount} invoices • ${agg.returnCount} returns',
                icon: Icons.payments_rounded,
                color: MedicalPalette.primary,
                deltaPercent: _delta(dash.salesTrend),
                onTap: onOpenPos,
              ),
              canSeeFinancials
                  ? DashboardKpiCard(
                      title: "Today's Profit",
                      value: CurrencyFormatter.compact(agg.profit, symbol: symbol),
                      subtitle:
                          'Margin ${agg.profitMargin.toStringAsFixed(1)}% • COGS ${CurrencyFormatter.compact(agg.cost, symbol: symbol)}',
                      icon: Icons.savings_rounded,
                      color: MedicalPalette.safe,
                      deltaPercent: _delta(dash.profitTrend),
                    )
                  : DashboardKpiCard(
                      title: "Today's Invoices",
                      value: '${agg.invoiceCount}',
                      subtitle: '${agg.returnCount} returns recorded',
                      icon: Icons.receipt_long_rounded,
                      color: MedicalPalette.watch,
                    ),
              canSeeFinancials
                  ? DashboardKpiCard(
                      title: "Today's Purchases",
                      value: CurrencyFormatter.compact(dash.todayPurchases, symbol: symbol),
                      subtitle: 'Stock inward value',
                      icon: Icons.local_shipping_rounded,
                      color: MedicalPalette.watch,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PurchasesScreen()),
                      ),
                    )
                  : DashboardKpiCard(
                      title: 'Items Sold',
                      value: '${_unitsSold(salesProv.sales)}',
                      subtitle: 'Across ${agg.invoiceCount} invoices',
                      icon: Icons.medication_rounded,
                      color: MedicalPalette.watch,
                    ),
              canSeeExpenses
                  ? DashboardKpiCard(
                      title: "Today's Expenses",
                      value: CurrencyFormatter.compact(dash.todayExpenses, symbol: symbol),
                      subtitle: 'Net flow ${CurrencyFormatter.compact(dash.netCashFlow, symbol: symbol)}',
                      icon: Icons.money_off_rounded,
                      color: MedicalPalette.warning,
                      invertDelta: true,
                    )
                  : DashboardKpiCard(
                      title: 'Catalog Size',
                      value: '${productProv.allProducts.length}',
                      subtitle: '${productProv.categories.length} categories',
                      icon: Icons.inventory_2_rounded,
                      color: MedicalPalette.primaryDark,
                    ),
            ];
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: children.map((c) => SizedBox(width: w, child: c)).toList(),
            );
          },
        ),
        const SizedBox(height: AppTokens.spaceLG),

        // 3. Operational compact tiles
        _CompactTileGrid(
          products: productProv.allProducts,
          customerDue: custProv.totalOutstandingDue,
          supplierDue: suppProv.totalSupplierPayables,
          symbol: symbol,
        ),
        const SizedBox(height: AppTokens.spaceXL),

        // 4. Charts
        LayoutBuilder(
          builder: (context, constraints) {
            final spacing = AppTokens.spaceLG;
            final isThreeCol = constraints.maxWidth >= 960;
            final isTwoCol = !isThreeCol && constraints.maxWidth >= 600;

            final salesTrendWidget = _ChartCard(
              title: 'Sales Trend',
              subtitle: 'Last ${dash.trendDays} days',
              icon: Icons.show_chart_rounded,
              child: SalesTrendChart(points: dash.salesTrend, symbol: symbol),
            );

            final salesPurchaseWidget = _ChartCard(
              title: 'Sales vs Purchases',
              subtitle: 'Daily movement',
              icon: Icons.bar_chart_rounded,
              legend: const [
                _LegendDot(color: MedicalPalette.primary, label: 'Sales'),
                _LegendDot(color: MedicalPalette.watch, label: 'Purchases'),
              ],
              child: SalesPurchaseBarChart(sales: dash.salesTrend, purchases: dash.purchaseTrend, symbol: symbol),
            );

            final profitTrendWidget = canSeeFinancials
                ? _ChartCard(
                    title: 'Profit Trend',
                    subtitle: 'Gross margin per day',
                    icon: Icons.savings_rounded,
                    child: SalesTrendChart(
                      points: dash.profitTrend,
                      symbol: symbol,
                      color: MedicalPalette.safe,
                    ),
                  )
                : null;

            if (isThreeCol && profitTrendWidget != null) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: salesTrendWidget),
                  SizedBox(width: spacing),
                  Expanded(child: salesPurchaseWidget),
                  SizedBox(width: spacing),
                  Expanded(child: profitTrendWidget),
                ],
              );
            } else if (isTwoCol && profitTrendWidget != null) {
              return Column(
                children: [
                  salesTrendWidget,
                  SizedBox(height: spacing),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: salesPurchaseWidget),
                      SizedBox(width: spacing),
                      Expanded(child: profitTrendWidget),
                    ],
                  ),
                ],
              );
            } else if (profitTrendWidget != null) {
              return Column(
                children: [
                  salesTrendWidget,
                  SizedBox(height: spacing),
                  salesPurchaseWidget,
                  SizedBox(height: spacing),
                  profitTrendWidget,
                ],
              );
            } else {
              if (constraints.maxWidth >= 600) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: salesTrendWidget),
                    SizedBox(width: spacing),
                    Expanded(child: salesPurchaseWidget),
                  ],
                );
              }
              return Column(
                children: [
                  salesTrendWidget,
                  SizedBox(height: spacing),
                  salesPurchaseWidget,
                ],
              );
            }
          },
        ),
        const SizedBox(height: AppTokens.spaceXL),

        // 5. Collections strip
        if (agg.collections.isNotEmpty) ...[
          _SectionTitle(title: 'Payment Collections', icon: Icons.account_balance_wallet_rounded),
          const SizedBox(height: AppTokens.spaceSM),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 800 ? 4 : (constraints.maxWidth >= 480 ? 2 : 1);
              final spacing = AppTokens.spaceSM;
              final w = (constraints.maxWidth - spacing * (cols - 1)) / cols;
              final tiles = ['Cash', 'UPI', 'Card', 'Credit/Due'].map((m) {
                final iconMap = {
                  'Cash': Icons.money_rounded,
                  'UPI': Icons.qr_code_rounded,
                  'Card': Icons.credit_card_rounded,
                  'Credit/Due': Icons.assignment_late_rounded,
                };
                final colorMap = {
                  'Cash': MedicalPalette.safe,
                  'UPI': MedicalPalette.watch,
                  'Card': MedicalPalette.primary,
                  'Credit/Due': MedicalPalette.warning,
                };
                return CollectionTile(
                  method: m,
                  amount: agg.collectionFor(m),
                  count: agg.collectionCountFor(m),
                  icon: iconMap[m]!,
                  color: colorMap[m]!,
                );
              }).toList();
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: tiles.map((t) => SizedBox(width: w, child: t)).toList(),
              );
            },
          ),
          const SizedBox(height: AppTokens.spaceXL),
        ],

        // 6. Alerts
        LayoutBuilder(
          builder: (context, constraints) {
            final sideBySide = constraints.maxWidth >= 820;
            if (!sideBySide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StockAlertPanel(products: productProv.allProducts),
                  const SizedBox(height: AppTokens.spaceLG),
                  ExpiryAlertPanel(products: productProv.allProducts),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: StockAlertPanel(products: productProv.allProducts)),
                const SizedBox(width: AppTokens.spaceLG),
                Expanded(child: ExpiryAlertPanel(products: productProv.allProducts)),
              ],
            );
          },
        ),
        const SizedBox(height: AppTokens.spaceXL),

        // 7. Business-specific hero widget injected by the active module
        bizModule.buildDashboardWidget(context),
        const SizedBox(height: AppTokens.spaceXL),

        // 8. Quick actions
        _SectionTitle(title: 'Quick Actions', icon: Icons.bolt_rounded),
        const SizedBox(height: AppTokens.spaceSM),
        _QuickActions(
          canBill: canBill,
          canManageProducts: canManageProducts,
          canSeeExpenses: canSeeExpenses,
          businessId: currentBiz.id,
        ),
        const SizedBox(height: AppTokens.spaceXL),

        // 9. Recent transactions
        _RecentTransactions(sales: salesProv.sales, symbol: symbol, total: salesProv.sales.length),
      ],
    );
  }

  int _unitsSold(List<Sale> sales) {
    final now = DateTime.now();
    var units = 0;
    for (final s in sales) {
      final isToday = s.createdAt.year == now.year &&
          s.createdAt.month == now.month &&
          s.createdAt.day == now.day &&
          s.status == 'Completed';
      if (isToday) {
        units += s.items.fold(0, (sum, it) => sum + it.quantity.round());
      }
    }
    return units;
  }
}

// ---------------------------------------------------------------------------
// Sections
// ---------------------------------------------------------------------------

class _DateAndShiftStrip extends StatelessWidget {
  final DashboardProvider dash;
  final SessionProvider session;
  final bool canManageShift;
  final bool canBill;
  final VoidCallback? onOpenPos;

  const _DateAndShiftStrip({
    required this.dash,
    required this.session,
    required this.canManageShift,
    this.canBill = false,
    this.onOpenPos,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = _isSameDay(dash.selectedDate, DateTime.now());
    final isYesterday =
        _isSameDay(dash.selectedDate, DateTime.now().subtract(const Duration(days: 1)));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceMD, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: AppTokens.borderLG,
        border: Border.all(color: theme.dividerColor),
        boxShadow: AppTokens.shadowSM,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 740;

          final dateSection = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                  borderRadius: AppTokens.borderMD,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 20),
                      onPressed: () => dash.stepDate(_bizId(context), -1),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Previous Day',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 13, color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            isToday
                                ? 'Today (${DateFormatter.formatShort(dash.selectedDate)})'
                                : isYesterday
                                    ? 'Yesterday (${DateFormatter.formatShort(dash.selectedDate)})'
                                    : DateFormatter.formatShort(dash.selectedDate),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 20),
                      onPressed: isToday ? null : () => dash.stepDate(_bizId(context), 1),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Next Day',
                    ),
                  ],
                ),
              ),
              if (!isToday) ...[
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('Jump to Today', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  onPressed: () => dash.jumpToToday(_bizId(context)),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          );

          final shiftSection = Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (session.isOpen ? MedicalPalette.safe : theme.colorScheme.error).withAlpha(20),
                  borderRadius: AppTokens.borderPill,
                  border: Border.all(
                    color: (session.isOpen ? MedicalPalette.safe : theme.colorScheme.error).withAlpha(70),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: session.isOpen ? MedicalPalette.safe : theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      session.isOpen
                          ? 'Shift Active • ${session.operator.isNotEmpty ? session.operator : 'Cashier'} (${session.elapsedLabel})'
                          : 'Shift Closed',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: session.isOpen ? MedicalPalette.safe : theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
              if (canManageShift)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(borderRadius: AppTokens.borderMD),
                  ),
                  icon: Icon(session.isOpen ? Icons.lock_clock_rounded : Icons.lock_open_rounded, size: 14),
                  label: Text(
                    session.isOpen ? 'Close Shift' : 'Open Shift',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  onPressed: session.isOpen ? () => _confirmClose(context) : () => _openShift(context),
                ),
              if (canBill && onOpenPos != null)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: const Size(0, 32),
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: AppTokens.borderMD),
                  ),
                  icon: const Icon(Icons.point_of_sale_rounded, size: 15),
                  label: const Text('Open POS Cart',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  onPressed: onOpenPos,
                ),
            ],
          );

          if (!isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                dateSection,
                const SizedBox(height: 10),
                shiftSection,
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              dateSection,
              shiftSection,
            ],
          );
        },
      ),
    );
  }

  String _bizId(BuildContext context) =>
      context.read<BusinessProvider>().currentBusiness!.id;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _openShift(BuildContext context) {
    final appUser = context.read<AppProvider>().currentUser;
    context.read<SessionProvider>().openShift(operator: appUser.name, role: appUser.role);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Shift opened for ${appUser.name}.')),
    );
  }

  void _confirmClose(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close Shift'),
        content: const Text(
            'This ends the current work session. A shift report can be generated from Reports.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              context.read<SessionProvider>().closeShift();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Shift closed.')),
              );
            },
            child: const Text('Close Shift'),
          ),
        ],
      ),
    );
  }
}

class _CompactTileGrid extends StatelessWidget {
  final List<Product> products;
  final double customerDue;
  final double supplierDue;
  final String symbol;

  const _CompactTileGrid({
    required this.products,
    required this.customerDue,
    required this.supplierDue,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    final lowStock = MedicalBatchAnalyzer.lowStockCount(products);
    final outStock = MedicalBatchAnalyzer.outOfStockCount(products);
    final rows = MedicalBatchAnalyzer.extractRows(products);
    final expiringSoon = rows.where((r) => r.daysLeft <= 30 && !r.isExpired).length;
    final expired = rows.where((r) => r.isExpired).length;
    final restricted = MedicalBatchAnalyzer.restrictedCount(products);

    final tiles = <CompactStatTile>[
      CompactStatTile(
        label: 'Low stock medicines',
        value: '$lowStock',
        subLabel: 'Reorder needed',
        icon: Icons.warning_amber_rounded,
        color: MedicalPalette.warning,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen())),
      ),
      CompactStatTile(
        label: 'Out of stock',
        value: '$outStock',
        subLabel: 'Blocking sales',
        icon: Icons.block_rounded,
        color: MedicalPalette.critical,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen())),
      ),
      CompactStatTile(
        label: 'Expiring ≤ 30 days',
        value: '$expiringSoon',
        subLabel: 'FEFO priority',
        icon: Icons.access_time_rounded,
        color: MedicalPalette.watch,
      ),
      CompactStatTile(
        label: 'Expired batches',
        value: '$expired',
        subLabel: expired > 0 ? 'Quarantine now' : 'None',
        icon: Icons.dangerous_rounded,
        color: expired > 0 ? MedicalPalette.critical : MedicalPalette.safe,
      ),
      CompactStatTile(
        label: 'Schedule H / Rx',
        value: '$restricted',
        subLabel: 'Controlled drugs',
        icon: Icons.shield_rounded,
        color: MedicalPalette.primary,
      ),
      CompactStatTile(
        label: 'Medicines in catalog',
        value: '${products.length}',
        subLabel: 'Active items',
        icon: Icons.medication_rounded,
        color: MedicalPalette.primaryDark,
      ),
      CompactStatTile(
        label: 'Customer outstanding',
        value: CurrencyFormatter.compact(customerDue, symbol: symbol),
        subLabel: 'Receivable',
        icon: Icons.people_alt_rounded,
        color: MedicalPalette.warning,
      ),
      CompactStatTile(
        label: 'Supplier outstanding',
        value: CurrencyFormatter.compact(supplierDue, symbol: symbol),
        subLabel: 'Payable',
        icon: Icons.local_shipping_rounded,
        color: MedicalPalette.watch,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 880
            ? 4
            : (constraints.maxWidth >= 500 ? 2 : 1);
        final spacing = AppTokens.spaceSM;
        final w = (constraints.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: tiles.map((t) => SizedBox(width: w, child: t)).toList(),
        );
      },
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final List<Widget> legend;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.legend = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: AppTokens.borderLG,
        border: Border.all(color: theme.dividerColor),
        boxShadow: AppTokens.shadowSM,
      ),
      padding: const EdgeInsets.all(AppTokens.spaceLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: theme.colorScheme.primary),
              const SizedBox(width: AppTokens.spaceSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withAlpha(150),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (legend.isNotEmpty) ...[
            const SizedBox(height: AppTokens.spaceSM),
            Wrap(spacing: 12, runSpacing: 4, children: legend),
          ],
          const SizedBox(height: AppTokens.spaceMD),
          child,
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(175),
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  final bool canBill;
  final bool canManageProducts;
  final bool canSeeExpenses;
  final String businessId;

  const _QuickActions({
    required this.canBill,
    required this.canManageProducts,
    required this.canSeeExpenses,
    required this.businessId,
  });

  @override
  Widget build(BuildContext context) {
    final actions = <_QuickAction>[
      _QuickAction(
        label: 'New Sale',
        icon: Icons.point_of_sale_rounded,
        color: MedicalPalette.primary,
        enabled: canBill,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PosScreen())),
      ),
      _QuickAction(
        label: 'Add Medicine',
        icon: Icons.medication_rounded,
        color: MedicalPalette.watch,
        enabled: canManageProducts,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductFormScreen(businessId: businessId)),
        ),
      ),
      _QuickAction(
        label: 'Manage Stock',
        icon: Icons.warehouse_rounded,
        color: MedicalPalette.safe,
        enabled: canManageProducts,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen())),
      ),
      _QuickAction(
        label: 'Stock Inward',
        icon: Icons.inventory_rounded,
        color: Colors.indigo,
        enabled: canManageProducts,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PurchasesScreen()),
        ),
      ),
      if (canSeeExpenses)
        _QuickAction(
          label: 'Record Expense',
          icon: Icons.payments_rounded,
          color: MedicalPalette.warning,
          enabled: true,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpensesScreen())),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 900 ? 4 : (constraints.maxWidth >= 500 ? 2 : 1);
        final spacing = AppTokens.spaceMD;
        final w = (constraints.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: actions.map((a) => SizedBox(width: w, child: a)).toList(),
        );
      },
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: enabled ? color.withAlpha(14) : theme.colorScheme.onSurface.withAlpha(5),
      borderRadius: AppTokens.borderMD,
      child: InkWell(
        borderRadius: AppTokens.borderMD,
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(AppTokens.spaceMD),
          decoration: BoxDecoration(
            borderRadius: AppTokens.borderMD,
            border: Border.all(color: enabled ? color.withAlpha(50) : theme.dividerColor),
          ),
          child: Row(
            children: [
              Icon(
                enabled ? icon : Icons.lock_outline_rounded,
                size: 19,
                color: enabled ? color : theme.colorScheme.onSurface.withAlpha(120),
              ),
              const SizedBox(width: AppTokens.spaceMD),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: enabled ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withAlpha(120),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  final List<Sale> sales;
  final String symbol;
  final int total;

  const _RecentTransactions({required this.sales, required this.symbol, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recent = sales.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SectionTitle(title: 'Recent Transactions', icon: Icons.history_rounded),
            Text(
              '$total total',
              style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(140), fontSize: 12.5),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.spaceMD),
        if (recent.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppTokens.spaceXL),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: AppTokens.borderLG,
              border: Border.all(color: theme.dividerColor),
            ),
            child: Center(
              child: Text(
                'No sales recorded yet. Start a bill to see it here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(140)),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: AppTokens.borderLG,
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              children: [
                for (int i = 0; i < recent.length; i++) ...[
                  _TransactionRow(sale: recent[i], symbol: symbol),
                  if (i < recent.length - 1) const Divider(height: 1, indent: 12, endIndent: 12),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final Sale sale;
  final String symbol;

  const _TransactionRow({required this.sale, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = sale.status == 'Completed';
    final statusColor = isCompleted
        ? MedicalPalette.safe
        : (sale.status == 'Voided' ? MedicalPalette.critical : MedicalPalette.warning);

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => InvoiceViewScreen(sale: sale)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceMD, vertical: 11),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(16),
                borderRadius: AppTokens.borderMD,
              ),
              child: Icon(Icons.receipt_rounded, size: 17, color: statusColor),
            ),
            const SizedBox(width: AppTokens.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sale.invoiceNo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                  ),
                  Text(
                    '${sale.customerName ?? 'Walk-in'} • ${sale.paymentMethod} • ${sale.createdAt.toString().substring(11, 16)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: theme.colorScheme.onSurface.withAlpha(150),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(sale.finalTotal,
                      symbol: symbol, decimalDigits: sale.finalTotal % 1 == 0 ? 0 : 2),
                  maxLines: 1,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(16),
                    borderRadius: AppTokens.borderPill,
                  ),
                  child: Text(
                    sale.status,
                    maxLines: 1,
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: statusColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: AppTokens.spaceSM),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final bool isMedical;
  final bool canManageProducts;
  final bool canBill;
  final VoidCallback onAddMedicine;
  final VoidCallback? onStartSale;
  final VoidCallback onManageStock;

  const _EmptyState({
    required this.isMedical,
    required this.canManageProducts,
    required this.canBill,
    required this.onAddMedicine,
    required this.onStartSale,
    required this.onManageStock,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceXXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primary.withAlpha(28), primary.withAlpha(10)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isMedical ? Icons.medication_liquid_rounded : Icons.storefront_rounded,
                size: 44,
                color: primary,
              ),
            ),
            const SizedBox(height: AppTokens.spaceXL),
            Text(
              isMedical ? 'Welcome to your pharmacy workspace' : 'Welcome to your store workspace',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppTokens.spaceSM),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                isMedical
                    ? 'There is no medicine stock or sales data yet. Add your first medicine with an opening-stock batch, and FEFO expiry tracking, billing and dashboard insights will come alive automatically.'
                    : 'There is no product or sales data yet. Add your first product to start billing.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: theme.colorScheme.onSurface.withAlpha(165),
                ),
              ),
            ),
            const SizedBox(height: AppTokens.spaceXL),
            Wrap(
              spacing: AppTokens.spaceMD,
              runSpacing: AppTokens.spaceSM,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: AppTokens.borderMD),
                  ),
                  icon: const Icon(Icons.medication_rounded),
                  label: const Text('Add Medicine'),
                  onPressed: canManageProducts ? onAddMedicine : null,
                ),
                if (canBill && onStartSale != null)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: AppTokens.borderMD),
                    ),
                    icon: const Icon(Icons.point_of_sale_rounded),
                    label: const Text('Create Sale'),
                    onPressed: onStartSale,
                  ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: AppTokens.borderMD),
                  ),
                  icon: const Icon(Icons.warehouse_rounded),
                  label: const Text('Add Stock'),
                  onPressed: onManageStock,
                ),
              ],
            ),
            if (!canManageProducts)
              Padding(
                padding: const EdgeInsets.only(top: AppTokens.spaceMD),
                child: Text(
                  'Your role can view the dashboard, but adding medicines requires a Manager or Owner.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withAlpha(150),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spaceXXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 44, color: MedicalPalette.critical),
            const SizedBox(height: AppTokens.spaceLG),
            Text(
              'Dashboard data unavailable',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: AppTokens.spaceSM),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withAlpha(165)),
              ),
            ),
            const SizedBox(height: AppTokens.spaceXL),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: AppTokens.borderMD),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.spaceLG),
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceMD, vertical: AppTokens.spaceMD),
      decoration: BoxDecoration(
        color: MedicalPalette.critical.withAlpha(12),
        borderRadius: AppTokens.borderMD,
        border: Border.all(color: MedicalPalette.critical.withAlpha(55)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 17, color: MedicalPalette.critical),
          const SizedBox(width: AppTokens.spaceMD),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: MedicalPalette.critical),
            ),
          ),
          const SizedBox(width: AppTokens.spaceSM),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(borderRadius: AppTokens.borderPill),
            ),
            onPressed: onRetry,
            child: const Text('Retry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerSkeleton(height: 48, borderRadius: AppTokens.borderLG),
        const SizedBox(height: AppTokens.spaceLG),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth >= 880 ? 4 : (constraints.maxWidth >= 520 ? 2 : 1);
            final spacing = AppTokens.spaceMD;
            final w = (constraints.maxWidth - spacing * (cols - 1)) / cols;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: List.generate(
                4,
                (_) => SizedBox(
                    width: w,
                    child: const ShimmerSkeleton(height: 118, borderRadius: BorderRadius.all(Radius.circular(14)))),
              ),
            );
          },
        ),
        const SizedBox(height: AppTokens.spaceLG),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth >= 880 ? 4 : (constraints.maxWidth >= 500 ? 2 : 1);
            final spacing = AppTokens.spaceSM;
            final w = (constraints.maxWidth - spacing * (cols - 1)) / cols;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: List.generate(
                6,
                (_) => SizedBox(
                    width: w,
                    child: const ShimmerSkeleton(height: 78, borderRadius: BorderRadius.all(Radius.circular(10)))),
              ),
            );
          },
        ),
        const SizedBox(height: AppTokens.spaceXL),
        const ShimmerSkeleton(height: 210, borderRadius: BorderRadius.all(Radius.circular(14))),
      ],
    );
  }
}
