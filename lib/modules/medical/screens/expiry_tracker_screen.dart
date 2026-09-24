import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../providers/product_provider.dart';
import '../medical_batch_analyzer.dart';
import '../medical_palette.dart';
import '../widgets/medical_widgets.dart';

class ExpiryTrackerScreen extends StatefulWidget {
  const ExpiryTrackerScreen({super.key});

  @override
  State<ExpiryTrackerScreen> createState() => _ExpiryTrackerScreenState();
}

class _ExpiryTrackerScreenState extends State<ExpiryTrackerScreen> {
  int _selectedBucket = 60; // 30, 60, 90 days

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productProv = context.watch<ProductProvider>();
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= AppTokens.breakpointTablet;

    final allRows = MedicalBatchAnalyzer.extractRows(productProv.allProducts);
    final visibleRows =
        allRows.where((r) => r.daysLeft <= _selectedBucket).toList();

    final critical = allRows.where((r) => r.severity == ExpirySeverity.critical).length;
    final warning = allRows.where((r) => r.severity == ExpirySeverity.warning).length;
    final watch = allRows.where((r) => r.severity == ExpirySeverity.watch).length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('FEFO Expiry Tracker'),
            Text(
              '${allRows.length} batches monitored',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withAlpha(150),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Summary strip
          Container(
            padding: EdgeInsets.fromLTRB(
              isWide ? width * 0.03 : AppTokens.spaceLG,
              AppTokens.spaceMD,
              isWide ? width * 0.03 : AppTokens.spaceLG,
              AppTokens.spaceMD,
            ),
            color: theme.cardTheme.color,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (allRows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppTokens.spaceSM),
                    child: MedicalSectionHeader(
                      title: 'No batch data yet',
                      icon: Icons.inventory_2_outlined,
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Stat tiles wrap instead of overflowing on narrow phones.
                      final tilesPerRow = constraints.maxWidth >= 720 ? 4 : 2;
                      final spacing = AppTokens.spaceSM;
                      final tileWidth = (constraints.maxWidth -
                              spacing * (tilesPerRow - 1)) /
                          tilesPerRow;

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          SizedBox(
                            width: tileWidth,
                            child: MedicalStatTile(
                              value: '$critical',
                              label: 'Critical ≤ 15 days',
                              icon: Icons.dangerous_rounded,
                              color: MedicalPalette.critical,
                              onTap: () => setState(() => _selectedBucket = 15),
                            ),
                          ),
                          SizedBox(
                            width: tileWidth,
                            child: MedicalStatTile(
                              value: '$warning',
                              label: 'Warning ≤ 45 days',
                              icon: Icons.warning_amber_rounded,
                              color: MedicalPalette.warning,
                              onTap: () => setState(() => _selectedBucket = 45),
                            ),
                          ),
                          SizedBox(
                            width: tileWidth,
                            child: MedicalStatTile(
                              value: '$watch',
                              label: 'Watch ≤ 90 days',
                              icon: Icons.visibility_rounded,
                              color: MedicalPalette.watch,
                              onTap: () => setState(() => _selectedBucket = 90),
                            ),
                          ),
                          SizedBox(
                            width: tileWidth,
                            child: MedicalStatTile(
                              value: '${MedicalBatchAnalyzer.expiredCount(
                                  productProv.allProducts)}',
                              label: 'Already Expired',
                              icon: Icons.block_rounded,
                              color: MedicalPalette.primary,
                              background: MedicalPalette.primaryLight,
                              onTap: () => setState(() => _selectedBucket = 90),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                if (allRows.isNotEmpty) ...[
                  const SizedBox(height: AppTokens.spaceMD),
                  const Divider(height: 1),
                  const SizedBox(height: AppTokens.spaceMD),
                  // Filter buckets
                  Wrap(
                    spacing: AppTokens.spaceSM,
                    runSpacing: AppTokens.spaceSM,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Expiry Range:',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: isWide ? 14 : 13,
                          color: theme.colorScheme.onSurface.withAlpha(180),
                        ),
                      ),
                      _bucketChip(30, '< 30 Days', MedicalPalette.critical),
                      _bucketChip(60, '< 60 Days', MedicalPalette.warning),
                      _bucketChip(90, '< 90 Days', MedicalPalette.watch),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          // Batch list
          Expanded(
            child: visibleRows.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.verified_user_rounded,
                    title: 'No Near-Expiry Medicines',
                    description:
                        'All medicine stock batches are well within safe shelf-life limits.',
                  )
                : ListView.separated(
                    padding: EdgeInsets.all(isWide ? width * 0.03 : AppTokens.spaceLG),
                    itemCount: visibleRows.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppTokens.spaceMD),
                    itemBuilder: (context, index) {
                      final row = visibleRows[index];
                      final severity = row.severity;

                      return _BatchCard(row: row, severity: severity);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _bucketChip(int days, String label, Color color) {
    final selected = _selectedBucket == days;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: color.withAlpha(45),
      labelStyle: TextStyle(
        color: selected ? color : null,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        fontSize: 12.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppTokens.borderPill,
        side: BorderSide(
          color: selected ? color.withAlpha(120) : Colors.transparent,
        ),
      ),
      onSelected: (_) => setState(() => _selectedBucket = days),
    );
  }
}

class _BatchCard extends StatelessWidget {
  final MedicalBatchRow row;
  final ExpirySeverity severity;

  const _BatchCard({required this.row, required this.severity});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= AppTokens.breakpointTablet;
    final color = severity.color;
    final prod = row.product;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: AppTokens.borderLG,
        border: Border.all(
          color: severity == ExpirySeverity.critical
              ? color.withAlpha(110)
              : theme.dividerColor,
          width: severity == ExpirySeverity.critical ? 1.5 : 1,
        ),
        boxShadow: AppTokens.shadowSM,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppTokens.borderLG,
        child: InkWell(
          borderRadius: AppTokens.borderLG,
          onTap: () {
            // Reserved for a future batch-detail view.
          },
          child: Padding(
            padding: EdgeInsets.all(isWide ? AppTokens.spaceLG : AppTokens.spaceMD),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Severity icon tile
                Container(
                  width: isWide ? 46 : 40,
                  height: isWide ? 46 : 40,
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: AppTokens.borderMD,
                  ),
                  child: Icon(
                    row.isExpired
                        ? Icons.block_rounded
                        : Icons.medication_liquid_rounded,
                    color: color,
                    size: isWide ? 22 : 19,
                  ),
                ),
                SizedBox(width: isWide ? AppTokens.spaceLG : AppTokens.spaceMD),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + days badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              prod.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTokens.spaceSM),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withAlpha(22),
                              borderRadius: AppTokens.borderPill,
                            ),
                            child: Text(
                              row.daysLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Generic: ${prod.metadata['generic_name'] ?? 'N/A'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: theme.colorScheme.onSurface.withAlpha(165),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Metadata chips wrap so they never overflow.
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          MedicalInfoChip(
                            label: 'Batch',
                            value: row.batchNo,
                            icon: Icons.tag_rounded,
                            color: color,
                          ),
                          MedicalInfoChip(
                            label: 'Stock',
                            value: '${row.qty.toStringAsFixed(0)} ${prod.unit}',
                            icon: Icons.inventory_2_rounded,
                          ),
                          MedicalInfoChip(
                            label: 'MRP',
                            value:
                                '₹${row.mrp.toStringAsFixed(row.mrp % 1 == 0 ? 0 : 2)}',
                            icon: Icons.currency_rupee_rounded,
                          ),
                          MedicalInfoChip(
                            label: 'Expiry',
                            value: DateFormatter.formatShort(row.expiryDate),
                            icon: Icons.event_rounded,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
