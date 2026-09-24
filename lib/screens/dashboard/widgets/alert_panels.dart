import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/product.dart';
import '../../../modules/medical/medical_batch_analyzer.dart';
import '../../../modules/medical/medical_palette.dart';
import '../../../modules/medical/screens/expiry_tracker_screen.dart';
import '../../../providers/business_provider.dart';
import '../../../screens/products/product_form_screen.dart';
import '../../../screens/products/product_list_screen.dart';

/// Stock alert list: out-of-stock first, then low-stock medicines.
///
/// Tapping a row jumps straight to the product editor so reorder action is
/// one tap away from the alert.
class StockAlertPanel extends StatelessWidget {
  final List<Product> products;
  final int maxRows;

  const StockAlertPanel({super.key, required this.products, this.maxRows = 5});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outOfStock = products.where((p) => p.isOutOfStock).toList();
    final lowStock = products.where((p) => p.isLowStock && !p.isOutOfStock).toList();
    final rows = [...outOfStock, ...lowStock].take(maxRows).toList();
    final totalAlerts = outOfStock.length + lowStock.length;

    return _PanelShell(
      theme: theme,
      title: 'Stock Alerts',
      icon: Icons.inventory_2_rounded,
      color: MedicalPalette.warning,
      countLabel: totalAlerts == 0 ? 'All healthy' : '$totalAlerts to review',
      onViewAll: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProductListScreen()),
      ),
      child: rows.isEmpty
          ? const _HealthyState(
              icon: Icons.check_circle_rounded,
              message: 'Every medicine is stocked above its reorder trigger.',
              color: MedicalPalette.safe,
            )
          : Column(
              children: [
                for (int i = 0; i < rows.length; i++) ...[
                  _StockRow(product: rows[i], symbol: _symbol(context)),
                  if (i < rows.length - 1) const Divider(height: 1),
                ],
              ],
            ),
    );
  }

  String _symbol(BuildContext context) =>
      context.watch<BusinessProvider>().currentBusiness?.currencySymbol ?? '₹';
}

class _StockRow extends StatelessWidget {
  final Product product;
  final String symbol;

  const _StockRow({required this.product, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final isOut = product.isOutOfStock;
    final color = isOut ? MedicalPalette.critical : MedicalPalette.warning;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductFormScreen(
            businessId: product.businessId,
            product: product,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: color.withAlpha(16),
                borderRadius: AppTokens.borderSM,
              ),
              child: Icon(
                isOut ? Icons.block_rounded : Icons.warning_amber_rounded,
                size: 15, color: color,
              ),
            ),
            const SizedBox(width: AppTokens.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  Text(
                    '${product.stockQty.toStringAsFixed(0)} ${product.unit} left • reorder at ${product.minStockAlert.toStringAsFixed(0)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 16, color: Theme.of(context).colorScheme.onSurface.withAlpha(110)),
          ],
        ),
      ),
    );
  }
}

/// FEFO expiry alert list for the dashboard.
class ExpiryAlertPanel extends StatelessWidget {
  final List<Product> products;
  final int maxRows;

  const ExpiryAlertPanel({super.key, required this.products, this.maxRows = 5});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = MedicalBatchAnalyzer.extractRows(products)
        .where((r) => r.daysLeft <= 60)
        .take(maxRows)
        .toList();
    final criticalCount = MedicalBatchAnalyzer.extractRows(products)
        .where((r) => r.severity == ExpirySeverity.critical)
        .length;

    return _PanelShell(
      theme: theme,
      title: 'Expiry Alerts (FEFO)',
      icon: Icons.access_time_rounded,
      color: MedicalPalette.critical,
      countLabel: rows.isEmpty ? 'No risk' : (criticalCount > 0 ? '$criticalCount critical' : '${rows.length} watching'),
      onViewAll: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ExpiryTrackerScreen()),
      ),
      child: rows.isEmpty
          ? const _HealthyState(
              icon: Icons.verified_user_rounded,
              message: 'No batches expiring within the next 60 days.',
              color: MedicalPalette.safe,
            )
          : Column(
              children: [
                for (int i = 0; i < rows.length; i++) ...[
                  _ExpiryRow(row: rows[i]),
                  if (i < rows.length - 1) const Divider(height: 1),
                ],
              ],
            ),
    );
  }
}

class _ExpiryRow extends StatelessWidget {
  final MedicalBatchRow row;

  const _ExpiryRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final color = row.severity.color;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ExpiryTrackerScreen()),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: color.withAlpha(16),
                borderRadius: AppTokens.borderSM,
              ),
              child: Icon(
                row.isExpired ? Icons.block_rounded : Icons.medication_liquid_rounded,
                size: 15, color: color,
              ),
            ),
            const SizedBox(width: AppTokens.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  Text(
                    '${row.batchNo} • ${row.qty.toStringAsFixed(0)} ${row.product.unit} • ${DateFormatter.formatShort(row.expiryDate)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: color.withAlpha(18),
                borderRadius: AppTokens.borderPill,
              ),
              child: Text(
                row.daysLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelShell extends StatelessWidget {
  final ThemeData theme;
  final String title;
  final IconData icon;
  final Color color;
  final String countLabel;
  final VoidCallback onViewAll;
  final Widget child;

  const _PanelShell({
    required this.theme,
    required this.title,
    required this.icon,
    required this.color,
    required this.countLabel,
    required this.onViewAll,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withAlpha(18),
                  borderRadius: AppTokens.borderSM,
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              const SizedBox(width: AppTokens.spaceSM),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                ),
              ),
              Text(
                countLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(width: AppTokens.spaceSM),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('View all', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spaceSM),
          child,
        ],
      ),
    );
  }
}

class _HealthyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;

  const _HealthyState({required this.icon, required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceLG),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppTokens.spaceMD),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(165),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Holds a currency symbol for helpers that need it without a widget tree walk.
String formatStockValue(double value, String symbol) =>
    CurrencyFormatter.format(value, symbol: symbol, decimalDigits: value % 1 == 0 ? 0 : 2);
