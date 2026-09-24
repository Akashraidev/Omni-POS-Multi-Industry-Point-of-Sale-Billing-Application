import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../providers/sales_provider.dart';

class WarrantyTrackerScreen extends StatelessWidget {
  const WarrantyTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final salesProv = context.watch<SalesProvider>();

    // Collect sold items with serial/IMEI
    final List<Map<String, dynamic>> warrantyUnits = [];

    for (final sale in salesProv.sales) {
      for (final item in sale.items) {
        if (item.serialImei != null && item.serialImei!.isNotEmpty) {
          final saleDate = sale.createdAt;
          final warrantyEnd = saleDate.add(const Duration(days: 365));
          final isUnderWarranty = DateTime.now().isBefore(warrantyEnd);

          warrantyUnits.add({
            'sale': sale,
            'item': item,
            'serial': item.serialImei!,
            'customer': sale.customerName ?? 'Customer',
            'phone': sale.customerPhone ?? '',
            'warranty_end': warrantyEnd,
            'is_valid': isUnderWarranty,
          });
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Serial & Warranty Tracker'),
      ),
      body: warrantyUnits.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.verified_rounded,
              title: 'No Registered Devices',
              description: 'When electronics are sold with an IMEI or Serial number, their warranty records show up here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppTokens.spaceLG),
              itemCount: warrantyUnits.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppTokens.spaceMD),
              itemBuilder: (context, index) {
                final record = warrantyUnits[index];
                final item = record['item'];
                final sale = record['sale'];
                final isValid = record['is_valid'] as bool;
                final endDate = record['warranty_end'] as DateTime;

                return AppCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withAlpha(20),
                          borderRadius: AppTokens.borderMD,
                        ),
                        child: const Icon(Icons.devices_other_rounded, color: Color(0xFF4F46E5)),
                      ),
                      const SizedBox(width: AppTokens.spaceLG),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.productName,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                  ),
                                ),
                                AppBadge(
                                  label: isValid ? 'In Warranty' : 'Expired',
                                  type: isValid ? BadgeType.success : BadgeType.error,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Serial / IMEI: ${record['serial']}', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4F46E5), fontSize: 13)),
                            const SizedBox(height: 4),
                            Text('Customer: ${record['customer']} (${record['phone']})', style: const TextStyle(fontSize: 13)),
                            Text('Invoice: ${sale.invoiceNo} • Coverage until: ${endDate.toString().substring(0, 10)}', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(140))),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
