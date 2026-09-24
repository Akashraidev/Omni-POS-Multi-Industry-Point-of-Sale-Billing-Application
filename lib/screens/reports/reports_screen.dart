import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/stat_card.dart';
import '../../modules/business_type.dart';
import '../../providers/business_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/reports_provider.dart';
import '../../providers/sales_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repProv = context.watch<ReportsProvider>();
    final salesProv = context.watch<SalesProvider>();
    final prodProv = context.watch<ProductProvider>();
    final expProv = context.watch<ExpenseProvider>();
    final bizProv = context.watch<BusinessProvider>();
    final currentBiz = bizProv.currentBusiness;
    final symbol = currentBiz?.currencySymbol ?? '₹';

    final completedSales = salesProv.sales.where((s) => s.status == 'Completed').toList();
    final grossRevenue = completedSales.fold(0.0, (sum, s) => sum + s.finalTotal);
    final totalTax = completedSales.fold(0.0, (sum, s) => sum + s.taxAmount);
    final totalOverheads = expProv.totalExpenses;
    final estimatedNetProfit = (grossRevenue * 0.28) - totalOverheads; // 28% avg gross margin minus overheads

    final trendData = repProv.getSalesTrend(salesProv.sales);
    final topProducts = repProv.getTopProducts(salesProv.sales);
    final categoryRev = repProv.getCategoryRevenue(salesProv.sales, prodProv.allProducts);

    final isWide = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Business Analytics'),
        actions: [
          IconButton(
            tooltip: 'Export CSV Report',
            icon: const Icon(Icons.file_download_rounded),
            onPressed: () {
              final csv = repProv.generateCsvReport(salesProv.sales);
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('CSV Export Generated'),
                  content: Text('Successfully generated CSV with ${salesProv.sales.length} transactions.\n\n$csv', style: const TextStyle(fontSize: 11)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.spaceLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Summary Grid
            GridView.count(
              crossAxisCount: isWide ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: isWide ? 1.4 : 1.15,
              children: [
                StatCard(
                  title: 'Gross Revenue',
                  value: CurrencyFormatter.compact(grossRevenue, symbol: symbol),
                  subtitle: '${completedSales.length} orders',
                  icon: Icons.monetization_on_rounded,
                  color: Colors.green,
                ),
                StatCard(
                  title: 'Est. Net Profit',
                  value: CurrencyFormatter.compact(estimatedNetProfit.clamp(0.0, 9999999.0), symbol: symbol),
                  subtitle: 'After overheads',
                  icon: Icons.trending_up_rounded,
                  color: Colors.teal,
                ),
                StatCard(
                  title: 'GST / Tax Billed',
                  value: CurrencyFormatter.compact(totalTax, symbol: symbol),
                  subtitle: 'Govt. liability',
                  icon: Icons.account_balance_rounded,
                  color: Colors.indigo,
                ),
                StatCard(
                  title: 'Store Overheads',
                  value: CurrencyFormatter.compact(totalOverheads, symbol: symbol),
                  subtitle: '${expProv.expenses.length} expense items',
                  icon: Icons.receipt_long_rounded,
                  color: Colors.deepOrange,
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spaceXL),

            // Sales Trend FL Chart
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '7-Day Sales Trend (₹)',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      Text(
                        'Last 7 Days',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(140)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              interval: 1,
                              getTitlesWidget: (val, meta) {
                                const days = ['D-6', 'D-5', 'D-4', 'D-3', 'D-2', 'Yest', 'Today'];
                                final idx = val.toInt();
                                if (idx >= 0 && idx < days.length) {
                                  return Text(days[idx], style: const TextStyle(fontSize: 10, color: Colors.grey));
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(7, (i) => FlSpot(i.toDouble(), trendData[i])),
                            isCurved: true,
                            color: currentBiz?.type.primaryColor ?? const Color(0xFF4F46E5),
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: (currentBiz?.type.primaryColor ?? const Color(0xFF4F46E5)).withAlpha(30),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.spaceLG),

            // Category Share & Top Products
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 750;
                return Flex(
                  direction: isDesktop ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Share
                    Expanded(
                      flex: isDesktop ? 1 : 0,
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Category Revenue Breakdown', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            const SizedBox(height: 16),
                            if (categoryRev.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Center(child: Text('No category revenue recorded yet.')),
                              )
                            else
                              SizedBox(
                                height: 180,
                                child: PieChart(
                                  PieChartData(
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 36,
                                    sections: categoryRev.entries.map((e) {
                                      final colors = [Colors.teal, Colors.amber, Colors.purple, Colors.blue, Colors.orange];
                                      final color = colors[e.key.hashCode % colors.length];
                                      return PieChartSectionData(
                                        color: color,
                                        value: e.value,
                                        title: '${e.key}\n₹${e.value.toStringAsFixed(0)}',
                                        radius: 50,
                                        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (isDesktop) const SizedBox(width: AppTokens.spaceLG) else const SizedBox(height: AppTokens.spaceLG),
                    // Top 5 Products
                    Expanded(
                      flex: isDesktop ? 1 : 0,
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Top Selling Items', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            const SizedBox(height: 16),
                            if (topProducts.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Center(child: Text('Complete sales to view top sellers.')),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: topProducts.length,
                                separatorBuilder: (_, __) => const Divider(height: 12),
                                itemBuilder: (context, index) {
                                  final entry = topProducts.entries.toList()[index];
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: index == 0 ? Colors.amber : Colors.grey.withAlpha(50),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '#${index + 1}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 11,
                                                  color: index == 0 ? Colors.black : Colors.grey[800],
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                        ],
                                      ),
                                      Text('${entry.value} sold', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                    ],
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
