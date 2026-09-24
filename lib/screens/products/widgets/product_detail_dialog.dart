import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../data/models/product.dart';
import '../product_form_screen.dart';

class ProductDetailDialog extends StatelessWidget {
  final Product product;
  final String symbol;
  final VoidCallback? onUpdated;

  const ProductDetailDialog({
    super.key,
    required this.product,
    required this.symbol,
    this.onUpdated,
  });

  static Future<void> show(BuildContext context, {required Product product, required String symbol, VoidCallback? onUpdated}) {
    return showDialog(
      context: context,
      builder: (_) => ProductDetailDialog(
        product: product,
        symbol: symbol,
        onUpdated: onUpdated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = product;
    final meta = p.metadata;

    final batches = (meta['batches'] as List<dynamic>?)
            ?.map((b) => Map<String, dynamic>.from(b as Map))
            .toList() ??
        [];

    final genericName = meta['generic_name'] ?? meta['composition'] ?? '';
    final manufacturer = meta['manufacturer'] ?? p.brand;
    final dosageForm = meta['dosage_form'] ?? '';
    final rack = meta['rack_location'] ?? meta['shelf'] ?? '';
    final tabletsPerStrip = meta['tablets_per_strip'] ?? meta['units_per_pack'] ?? '';

    final cost = p.purchasePrice;
    final sell = p.sellingPrice;
    final margin = sell > 0 ? (((sell - cost) / sell) * 100).toStringAsFixed(1) : '0';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.medication_rounded, color: theme.colorScheme.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                        ),
                        if (genericName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            genericName,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: theme.colorScheme.onSurface.withAlpha(160),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Body content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // KPI Grid
                  Row(
                    children: [
                      _kpiCard(
                        theme,
                        'Selling Price',
                        CurrencyFormatter.format(p.sellingPrice, symbol: symbol),
                        'MRP: ${CurrencyFormatter.format(p.mrp, symbol: symbol)}',
                        theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      _kpiCard(
                        theme,
                        'Stock Available',
                        '${p.stockQty.toInt()} ${p.unit}',
                        p.isLowStock ? 'Low Stock Alert' : 'Healthy Stock',
                        p.isLowStock ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 12),
                      _kpiCard(
                        theme,
                        'Profit Margin',
                        '$margin%',
                        'Cost: ${CurrencyFormatter.format(p.purchasePrice, symbol: symbol)}',
                        const Color(0xFF06B6D4),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Specification details
                  _sectionTitle('Specifications & Packaging'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withAlpha(6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor.withAlpha(80)),
                    ),
                    child: Column(
                      children: [
                        _specRow('Brand / Manufacturer', manufacturer.isNotEmpty ? manufacturer : '—'),
                        _specRow('SKU Code', p.sku),
                        _specRow('Barcode', p.barcode.isNotEmpty ? p.barcode : '—'),
                        if (dosageForm.isNotEmpty) _specRow('Dosage Form', dosageForm.toUpperCase()),
                        if (tabletsPerStrip.toString().isNotEmpty) _specRow('Units / Pack Size', '$tabletsPerStrip units/pack'),
                        if (rack.toString().isNotEmpty) _specRow('Rack / Shelf Location', rack.toString()),
                        _specRow('Tax Rate (GST)', '${p.taxRate.toStringAsFixed(0)}%'),
                        _specRow('Minimum Stock Alert', '${p.minStockAlert.toInt()} ${p.unit}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Active Batches Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionTitle('Active FEFO Batches (${batches.length})'),
                      if (batches.isNotEmpty)
                        const Text(
                          'Sorted by earliest expiry',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (batches.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withAlpha(6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor.withAlpha(80)),
                      ),
                      child: const Text(
                        'No specific batches registered. Stock tracked as general inventory.',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey),
                      ),
                    )
                  else
                    ...batches.map((b) {
                      final exp = b['expiry']?.toString() ?? '—';
                      final bNo = b['batch_number']?.toString() ?? '—';
                      final bStock = b['stock'] ?? 0;
                      final bMrp = (b['mrp'] as num?)?.toDouble() ?? p.mrp;

                      DateTime? expDate;
                      try {
                        expDate = DateTime.tryParse(exp);
                      } catch (_) {}

                      final daysLeft = expDate != null ? expDate.difference(DateTime.now()).inDays : 999;
                      final isExpired = daysLeft < 0;
                      final isNear = daysLeft >= 0 && daysLeft <= 90;

                      final statusText = isExpired
                          ? 'Expired'
                          : (isNear ? 'Expiring ($daysLeft d)' : 'Safe ($daysLeft d)');
                      final statusType = isExpired
                          ? BadgeType.error
                          : (isNear ? BadgeType.warning : BadgeType.success);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isExpired
                                ? const Color(0xFFEF4444).withAlpha(120)
                                : theme.dividerColor.withAlpha(80),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.qr_code_rounded, size: 18, color: Colors.grey),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bNo,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                  ),
                                  Text(
                                    'Expiry: $exp',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isExpired ? const Color(0xFFEF4444) : theme.colorScheme.onSurface.withAlpha(140),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$bStock ${p.unit}',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                ),
                                Text(
                                  'MRP: ${CurrencyFormatter.format(bMrp, symbol: symbol)}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            AppBadge(label: statusText, type: statusType),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
            const Divider(height: 1),

            // Footer actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Close'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Edit Product'),
                    onPressed: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductFormScreen(
                            businessId: p.businessId,
                            product: p,
                          ),
                        ),
                      );
                      onUpdated?.call();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard(ThemeData theme, String label, String value, String sub, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: accent.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withAlpha(60)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: accent)),
            ),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(fontSize: 10.5, color: theme.colorScheme.onSurface.withAlpha(140))),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, letterSpacing: -0.2),
    );
  }

  Widget _specRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
