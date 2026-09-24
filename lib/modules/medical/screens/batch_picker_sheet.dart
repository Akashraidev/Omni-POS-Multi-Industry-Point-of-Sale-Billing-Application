import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/product.dart';
import '../../../providers/business_provider.dart';
import '../medical_batch_analyzer.dart';
import '../medical_palette.dart';
import '../widgets/medical_widgets.dart';

/// FEFO batch selector for pharmacy billing.
///
/// When a medicine carries multiple batches, the operator should be able to
/// pick (or confirm) which batch is being dispensed — the earliest expiry is
/// offered first, but near-expiry and expired batches are surfaced clearly so
/// they are never dispensed by accident.
class BatchPickerSheet extends StatelessWidget {
  final Product product;
  final String? selectedBatch;
  final void Function(String batchNo, String expiry) onSelected;

  const BatchPickerSheet({
    super.key,
    required this.product,
    this.selectedBatch,
    required this.onSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required Product product,
    String? selectedBatch,
    required void Function(String batchNo, String expiry) onSelected,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: AppTokens.borderLG),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: BatchPickerSheet(
            product: product,
            selectedBatch: selectedBatch,
            onSelected: onSelected,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final symbol = context.watch<BusinessProvider>().currentBusiness?.currencySymbol ?? '₹';
    final rows = MedicalBatchAnalyzer.batchesFor(product);
    final hasScheduleH = product.metadata['schedule_h'] == true;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.82),
      padding: const EdgeInsets.fromLTRB(AppTokens.spaceLG, AppTokens.spaceMD, AppTokens.spaceLG, AppTokens.spaceLG),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: MedicalSectionHeader(
                  title: 'Select Batch (FEFO)',
                  icon: Icons.medication_rounded,
                  actionLabel: rows.isEmpty ? '' : '${rows.length} batches',
                  onAction: () {},
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spaceSM),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          if (product.metadata['generic_name'] != null) ...[
            const SizedBox(height: 2),
            Text(
              'Generic: ${product.metadata['generic_name']}',
              style: TextStyle(
                fontSize: 12.5,
                color: theme.colorScheme.onSurface.withAlpha(165),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (hasScheduleH) ...[
            const SizedBox(height: AppTokens.spaceSM),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: MedicalPalette.primary.withAlpha(14),
                borderRadius: AppTokens.borderSM,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_rounded, size: 13, color: MedicalPalette.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Schedule H / Rx — doctor name required at checkout',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: MedicalPalette.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppTokens.spaceMD),
          Flexible(
            child: rows.isEmpty
                ? const EmptyBatchState()
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppTokens.spaceSM),
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      final isRecommended = index == 0;
                      final isSelected = selectedBatch == row.batchNo;
                      return _BatchTile(
                        row: row,
                        symbol: symbol,
                        unit: product.unit,
                        isRecommended: isRecommended,
                        isSelected: isSelected,
                        onTap: () {
                          onSelected(
                            row.batchNo,
                            DateFormatter.formatIsoDate(row.expiryDate),
                          );
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _BatchTile extends StatelessWidget {
  final MedicalBatchRow row;
  final String symbol;
  final String unit;
  final bool isRecommended;
  final bool isSelected;
  final VoidCallback onTap;

  const _BatchTile({
    required this.row,
    required this.symbol,
    required this.unit,
    required this.isRecommended,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = row.severity.color;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: AppTokens.borderMD,
        border: Border.all(
          color: isSelected ? MedicalPalette.primary : color.withAlpha(60),
          width: isSelected ? 1.6 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppTokens.borderMD,
        child: InkWell(
          borderRadius: AppTokens.borderMD,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: color.withAlpha(18),
                    borderRadius: AppTokens.borderSM,
                  ),
                  child: Icon(
                    row.isExpired ? Icons.block_rounded : Icons.medication_liquid_rounded,
                    color: color, size: 18,
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
                            row.batchNo,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                          if (isRecommended) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: MedicalPalette.safe.withAlpha(20),
                                borderRadius: AppTokens.borderSM,
                              ),
                              child: Text(
                                'FEFO',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: MedicalPalette.safe,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${DateFormatter.formatShort(row.expiryDate)} • ${row.daysLabel}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${row.qty.toStringAsFixed(0)} $unit',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(row.mrp, symbol: symbol, decimalDigits: 0),
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withAlpha(150),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppTokens.spaceSM),
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                  size: 20,
                  color: isSelected ? MedicalPalette.primary : theme.colorScheme.onSurface.withAlpha(120),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EmptyBatchState extends StatelessWidget {
  const EmptyBatchState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTokens.spaceXL),
      decoration: BoxDecoration(
        color: MedicalPalette.warning.withAlpha(12),
        borderRadius: AppTokens.borderMD,
      ),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 30, color: MedicalPalette.warning),
          const SizedBox(height: AppTokens.spaceSM),
          Text(
            'No batches recorded for this medicine',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withAlpha(180),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add opening-stock batches from Products to enable FEFO expiry tracking.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withAlpha(150),
            ),
          ),
        ],
      ),
    );
  }
}
