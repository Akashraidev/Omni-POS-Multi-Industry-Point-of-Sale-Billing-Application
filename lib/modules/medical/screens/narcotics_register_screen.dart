import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/sales_provider.dart';
import '../medical_palette.dart';
import '../widgets/medical_widgets.dart';

class NarcoticsRegisterScreen extends StatelessWidget {
  const NarcoticsRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= AppTokens.breakpointTablet;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Schedule H & Narcotic Register'),
          bottom: TabBar(
            tabs: const [
              Tab(
                icon: Icon(Icons.medication_rounded),
                text: 'Restricted Drugs',
              ),
              Tab(
                icon: Icon(Icons.receipt_long_rounded),
                text: 'Prescription Sales',
              ),
            ],
            labelColor: MedicalPalette.primary,
            unselectedLabelColor:
                theme.colorScheme.onSurface.withAlpha(150),
            indicatorColor: MedicalPalette.primary,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _RestrictedDrugsTab(isWide: isWide),
            _PrescriptionSalesTab(isWide: isWide),
          ],
        ),
      ),
    );
  }
}

class _RestrictedDrugsTab extends StatelessWidget {
  final bool isWide;

  const _RestrictedDrugsTab({required this.isWide});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productProv = context.watch<ProductProvider>();

    final restricted = productProv.allProducts.where((p) {
      return p.metadata['schedule_h'] == true ||
          p.metadata['is_narcotic'] == true;
    }).toList();

    if (restricted.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.shield_outlined,
        title: 'No Schedule H Drugs',
        description:
            'No controlled substances are currently flagged in your product inventory.',
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(isWide ? AppTokens.spaceXXL : AppTokens.spaceLG),
      itemCount: restricted.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTokens.spaceMD),
      itemBuilder: (context, index) {
        final p = restricted[index];
        final isNarcotic = p.metadata['is_narcotic'] == true;

        return Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: AppTokens.borderLG,
            border: Border.all(
              color: (isNarcotic
                      ? MedicalPalette.critical
                      : MedicalPalette.primary)
                  .withAlpha(100),
            ),
            boxShadow: AppTokens.shadowSM,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: AppTokens.borderLG,
            child: InkWell(
              borderRadius: AppTokens.borderLG,
              onTap: () {
                // Reserved for a future drug-master detail view.
              },
              child: Padding(
                padding: EdgeInsets.all(
                    isWide ? AppTokens.spaceLG : AppTokens.spaceMD),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: isWide ? 44 : 38,
                      height: isWide ? 44 : 38,
                      decoration: BoxDecoration(
                        color: (isNarcotic
                                ? MedicalPalette.critical
                                : MedicalPalette.primary)
                            .withAlpha(20),
                        borderRadius: AppTokens.borderMD,
                      ),
                      child: Icon(
                        isNarcotic
                            ? Icons.dangerous_rounded
                            : Icons.shield_rounded,
                        color: isNarcotic
                            ? MedicalPalette.critical
                            : MedicalPalette.primary,
                        size: isWide ? 21 : 18,
                      ),
                    ),
                    SizedBox(width: isWide ? AppTokens.spaceLG : AppTokens.spaceMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  p.name,
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
                              _ComplianceBadge(
                                label: isNarcotic ? 'Narcotic' : 'Schedule H / Rx',
                                color: isNarcotic
                                    ? MedicalPalette.critical
                                    : MedicalPalette.primary,
                                bg: isNarcotic
                                    ? MedicalPalette.criticalBg
                                    : MedicalPalette.primaryLight,
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          if ((p.metadata['generic_name'] as String?)
                                  ?.isNotEmpty ??
                              false)
                            Text(
                              'Generic: ${p.metadata['generic_name']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: theme.colorScheme.onSurface.withAlpha(165),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              MedicalInfoChip(
                                label: 'Salt',
                                value:
                                    '${p.metadata['salt_composition'] ?? 'N/A'}',
                                icon: Icons.science_rounded,
                              ),
                              MedicalInfoChip(
                                label: 'HSN',
                                value: '${p.metadata['hsn_code'] ?? '3004'}',
                                icon: Icons.qr_code_rounded,
                              ),
                              MedicalInfoChip(
                                label: 'Stock',
                                value:
                                    '${p.stockQty.toStringAsFixed(0)} ${p.unit}',
                                icon: Icons.inventory_2_rounded,
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
      },
    );
  }
}

class _PrescriptionSalesTab extends StatelessWidget {
  final bool isWide;

  const _PrescriptionSalesTab({required this.isWide});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final salesProv = context.watch<SalesProvider>();

    final restrictedSales = salesProv.sales
        .where((s) => (s.doctorName ?? '').isNotEmpty)
        .toList();

    if (restrictedSales.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.description_outlined,
        title: 'No Prescription Sales',
        description:
            'Sales recorded with a registered doctor name will automatically appear here.',
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(isWide ? AppTokens.spaceXXL : AppTokens.spaceLG),
      itemCount: restrictedSales.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTokens.spaceMD),
      itemBuilder: (context, index) {
        final s = restrictedSales[index];

        return Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: AppTokens.borderLG,
            border: Border.all(color: theme.dividerColor),
            boxShadow: AppTokens.shadowSM,
          ),
          child: Padding(
            padding: EdgeInsets.all(
                isWide ? AppTokens.spaceLG : AppTokens.spaceMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: isWide ? 44 : 38,
                      height: isWide ? 44 : 38,
                      decoration: BoxDecoration(
                        color: MedicalPalette.primary.withAlpha(20),
                        borderRadius: AppTokens.borderMD,
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: MedicalPalette.primary,
                        size: isWide ? 21 : 18,
                      ),
                    ),
                    SizedBox(width: isWide ? AppTokens.spaceLG : AppTokens.spaceMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s.invoiceNo,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppTokens.spaceSM),
                              _ComplianceBadge(
                                label: s.status,
                                color: MedicalPalette.safe,
                                bg: MedicalPalette.safeBg,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              MedicalInfoChip(
                                label: 'Doctor',
                                value: s.doctorName!,
                                icon: Icons.person_rounded,
                                color: MedicalPalette.primary,
                              ),
                              MedicalInfoChip(
                                label: 'Patient',
                                value:
                                    '${s.customerName ?? 'Walk-in'} (${s.customerPhone ?? 'N/A'})',
                                icon: Icons.person_outline_rounded,
                              ),
                              MedicalInfoChip(
                                label: 'Date',
                                value: DateFormatter.formatShort(s.createdAt),
                                icon: Icons.event_rounded,
                              ),
                              MedicalInfoChip(
                                label: 'Items',
                                value: '${s.items.length}',
                                icon: Icons.shopping_bag_rounded,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ComplianceBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _ComplianceBadge({
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppTokens.borderPill,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
