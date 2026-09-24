import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/analytics.dart';
import '../../../modules/medical/medical_palette.dart';

/// Sales line chart for the dashboard.
///
/// Renders an empty-state placeholder instead of a flat zero line when the
/// period has no recorded sales.
class SalesTrendChart extends StatelessWidget {
  final List<TrendPoint> points;
  final String symbol;
  final String title;
  final Color color;
  final double height;

  const SalesTrendChart({
    super.key,
    required this.points,
    required this.symbol,
    this.title = 'Sales Trend',
    this.color = MedicalPalette.primary,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasData = points.any((p) => p.value > 0);

    return SizedBox(
      height: height,
      child: hasData
          ? LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _interval,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: theme.dividerColor,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: _interval,
                      getTitlesWidget: (value, meta) => Text(
                        CurrencyFormatter.compact(value, symbol: symbol),
                        style: TextStyle(
                          fontSize: 9.5,
                          color: theme.colorScheme.onSurface.withAlpha(150),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: _labelStride,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            points[idx].shortLabel,
                            style: TextStyle(
                              fontSize: 9,
                              color: theme.colorScheme.onSurface.withAlpha(150),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                      return LineTooltipItem(
                        CurrencyFormatter.format(spot.y, symbol: symbol, decimalDigits: 0),
                        TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(points.length, (i) => FlSpot(i.toDouble(), points[i].value)),
                    isCurved: true,
                    curveSmoothness: 0.32,
                    color: color,
                    barWidth: 2.6,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withAlpha(28),
                    ),
                  ),
                ],
              ),
            )
          : _ChartEmpty(theme: theme, message: 'No sales recorded in this period'),
    );
  }

  double get _maxValue => points.fold(0.0, (a, p) => p.value > a ? p.value : a);

  double get _interval {
    final max = _maxValue;
    if (max <= 0) return 1.0;
    if (max <= 4) return 1.0;
    if (max <= 100) return (max / 4).ceilToDouble();
    if (max <= 1000) return (max / 4 / 10).ceilToDouble() * 10;
    return (max / 4 / 100).ceilToDouble() * 100;
  }

  double get _labelStride {
    if (points.length <= 7) return 1;
    if (points.length <= 15) return 2;
    return (points.length / 7).ceilToDouble();
  }
}

/// Grouped sales-vs-purchases bar chart.
class SalesPurchaseBarChart extends StatelessWidget {
  final List<TrendPoint> sales;
  final List<double> purchases;
  final String symbol;
  final double height;

  const SalesPurchaseBarChart({
    super.key,
    required this.sales,
    required this.purchases,
    required this.symbol,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasData = sales.any((p) => p.value > 0) || purchases.any((p) => p > 0);
    final count = sales.length;

    return SizedBox(
      height: height,
      child: hasData
          ? BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _interval,
                  getDrawingHorizontalLine: (v) => FlLine(color: theme.dividerColor, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: _interval,
                      getTitlesWidget: (value, meta) => Text(
                        CurrencyFormatter.compact(value, symbol: symbol),
                        style: TextStyle(
                          fontSize: 9.5,
                          color: theme.colorScheme.onSurface.withAlpha(150),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: count <= 7 ? 1.0 : (count / 7).ceilToDouble(),
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= count) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            sales[idx].shortLabel,
                            style: TextStyle(
                              fontSize: 9,
                              color: theme.colorScheme.onSurface.withAlpha(150),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(count, (i) {
                  final sale = i < sales.length ? sales[i].value : 0.0;
                  final purch = i < purchases.length ? purchases[i] : 0.0;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: sale,
                        color: MedicalPalette.primary,
                        width: 10,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(3),
                          topRight: Radius.circular(3),
                        ),
                      ),
                      BarChartRodData(
                        toY: purch,
                        color: MedicalPalette.watch,
                        width: 10,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(3),
                          topRight: Radius.circular(3),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            )
          : _ChartEmpty(theme: theme, message: 'No movement recorded in this period'),
    );
  }

  double get _maxValue {
    var max = 0.0;
    for (final p in sales) {
      if (p.value > max) max = p.value;
    }
    for (final p in purchases) {
      if (p > max) max = p;
    }
    if (max <= 0) return 1.0;
    if (max <= 4) return 1.0;
    if (max <= 100) return (max / 4).ceilToDouble();
    if (max <= 1000) return (max / 4 / 10).ceilToDouble() * 10;
    return (max / 4 / 100).ceilToDouble() * 100;
  }

  double get _interval => _maxValue / 4 <= 0 ? 1.0 : (_maxValue / 4).ceilToDouble();
}

class _ChartEmpty extends StatelessWidget {
  final ThemeData theme;
  final String message;

  const _ChartEmpty({required this.theme, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spaceLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart_rounded, size: 30, color: theme.colorScheme.onSurface.withAlpha(60)),
            const SizedBox(height: AppTokens.spaceSM),
            Text(
              message,
              style: TextStyle(
                fontSize: 12.5,
                color: theme.colorScheme.onSurface.withAlpha(150),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
