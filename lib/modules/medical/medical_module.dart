import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../data/models/cart_item.dart';
import '../../providers/product_provider.dart';
import '../base/business_module_interface.dart';
import '../business_type.dart';
import 'medical_batch_analyzer.dart';
import 'medical_palette.dart';
import 'screens/expiry_tracker_screen.dart';
import 'screens/narcotics_register_screen.dart';
import 'widgets/medical_widgets.dart';

class MedicalBusinessModule implements BusinessModuleInterface {
  @override
  BusinessType get type => BusinessType.medical;

  @override
  String get id => 'medical';

  @override
  String get name => 'Medical / Pharmacy';

  @override
  String get description => 'FEFO batches, Schedule H Rx tracking, and drug salt compositions.';

  @override
  IconData get icon => Icons.local_pharmacy_rounded;

  @override
  List<BusinessNavigationItem> get navigationItems => [
        const BusinessNavigationItem(
          id: 'expiry_alerts',
          label: 'Expiry Alerts',
          icon: Icons.access_time_rounded,
          selectedIcon: Icons.access_time_filled_rounded,
          screen: ExpiryTrackerScreen(),
        ),
        const BusinessNavigationItem(
          id: 'narcotics',
          label: 'Schedule H / Rx',
          icon: Icons.shield_outlined,
          selectedIcon: Icons.shield_rounded,
          screen: NarcoticsRegisterScreen(),
        ),
      ];

  @override
  Widget buildDashboardWidget(BuildContext context) {
    final theme = Theme.of(context);
    final productProv = context.watch<ProductProvider>();
    final products = productProv.allProducts;

    final rows = MedicalBatchAnalyzer.extractRows(products);
    final critical =
        rows.where((r) => r.severity == ExpirySeverity.critical).length;
    final warning =
        rows.where((r) => r.severity == ExpirySeverity.warning).length;
    final restricted = MedicalBatchAnalyzer.restrictedCount(products);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MedicalSectionHeader(
            title: 'Pharmacy Expiry & Compliance Watch',
            icon: Icons.health_and_safety_rounded,
            actionLabel: 'View All',
            onAction: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExpiryTrackerScreen()),
              );
            },
          ),
          const SizedBox(height: AppTokens.spaceMD),
          LayoutBuilder(
            builder: (context, constraints) {
              // Tiles reflow instead of squishing: 3 across on wide screens,
              // otherwise a comfortable single column.
              final perRow = constraints.maxWidth >= 560 ? 3 : 1;
              final spacing = AppTokens.spaceMD;
              final tileW =
                  (constraints.maxWidth - spacing * (perRow - 1)) / perRow;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(
                    width: tileW,
                    child: MedicalStatTile(
                      value: critical == 0 ? 'None' : '$critical',
                      label: 'Batches expiring ≤ 15 days',
                      icon: Icons.dangerous_rounded,
                      color: MedicalPalette.critical,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ExpiryTrackerScreen()),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: tileW,
                    child: MedicalStatTile(
                      value: warning == 0 ? 'None' : '$warning',
                      label: 'Batches expiring ≤ 45 days',
                      icon: Icons.warning_amber_rounded,
                      color: MedicalPalette.warning,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ExpiryTrackerScreen()),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: tileW,
                    child: MedicalStatTile(
                      value: restricted == 0 ? 'None' : '$restricted',
                      label: 'Schedule H / Rx drugs',
                      icon: Icons.shield_rounded,
                      color: MedicalPalette.primary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NarcoticsRegisterScreen()),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppTokens.spaceMD),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spaceMD, vertical: AppTokens.spaceSM),
            decoration: BoxDecoration(
              color: MedicalPalette.primary.withAlpha(12),
              borderRadius: AppTokens.borderMD,
            ),
            child: Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 15, color: MedicalPalette.primary),
                const SizedBox(width: AppTokens.spaceSM),
                Expanded(
                  child: Text(
                    rows.isEmpty
                        ? 'No batch data — add products with batch expiry to enable FEFO.'
                        : 'FEFO active • ${rows.length} batches tracked • earliest expiry picked first at billing.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withAlpha(175),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget? buildCartItemExtra(BuildContext context, CartItem item) {
    if (item.selectedBatch != null && item.selectedBatch!.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: MedicalPalette.primary.withAlpha(20),
          borderRadius: AppTokens.borderSM,
        ),
        child: Text(
          'Batch: ${item.selectedBatch!} (${item.batchExpiry ?? 'FEFO'})',
          style: const TextStyle(
            fontSize: 11,
            color: MedicalPalette.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return null;
  }

  @override
  Widget? buildProductFormFields(
    BuildContext context,
    Map<String, dynamic> currentMetadata,
    void Function(Map<String, dynamic> updated) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MedicalSectionHeader(
          title: 'Pharmacy Details',
          icon: Icons.medication_rounded,
        ),
        const SizedBox(height: AppTokens.spaceMD),
        TextFormField(
          initialValue: currentMetadata['generic_name']?.toString() ?? '',
          decoration: const InputDecoration(
            labelText: 'Generic Name (e.g. Paracetamol)',
            prefixIcon: Icon(Icons.science_rounded),
          ),
          onChanged: (val) {
            currentMetadata['generic_name'] = val;
            onChanged(currentMetadata);
          },
        ),
        const SizedBox(height: AppTokens.spaceMD),
        TextFormField(
          initialValue: currentMetadata['salt_composition']?.toString() ?? '',
          decoration: const InputDecoration(
            labelText: 'Salt Composition & Strength',
            prefixIcon: Icon(Icons.biotech_rounded),
          ),
          onChanged: (val) {
            currentMetadata['salt_composition'] = val;
            onChanged(currentMetadata);
          },
        ),
        const SizedBox(height: AppTokens.spaceMD),
        TextFormField(
          initialValue: currentMetadata['hsn_code']?.toString() ?? '',
          decoration: const InputDecoration(
            labelText: 'HSN Code',
            prefixIcon: Icon(Icons.qr_code_rounded),
          ),
          onChanged: (val) {
            currentMetadata['hsn_code'] = val;
            onChanged(currentMetadata);
          },
        ),
        const SizedBox(height: AppTokens.spaceMD),
        DropdownButtonFormField<String>(
          initialValue: currentMetadata['dosage_form']?.toString().toLowerCase(),
          decoration: const InputDecoration(
            labelText: 'Dosage Form',
            prefixIcon: Icon(Icons.medication_rounded),
          ),
          items: const [
            DropdownMenuItem(value: 'tablet', child: Text('Tablet')),
            DropdownMenuItem(value: 'capsule', child: Text('Capsule')),
            DropdownMenuItem(value: 'syrup', child: Text('Syrup / Liquid')),
            DropdownMenuItem(value: 'injection', child: Text('Injection / Vial')),
            DropdownMenuItem(value: 'cream', child: Text('Cream / Ointment / Gel')),
            DropdownMenuItem(value: 'inhaler', child: Text('Inhaler / Respule')),
            DropdownMenuItem(value: 'device', child: Text('Device / Diagnostic')),
            DropdownMenuItem(value: 'drops', child: Text('Drops (Eye / Ear)')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
          ],
          onChanged: (val) {
            if (val != null) {
              currentMetadata['dosage_form'] = val;
              onChanged(currentMetadata);
            }
          },
        ),
        const SizedBox(height: AppTokens.spaceMD),
        TextFormField(
          initialValue: currentMetadata['tablets_per_strip']?.toString() ?? '10',
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Units per Pack / Strip (for loose dispensing)',
            prefixIcon: Icon(Icons.pin_rounded),
          ),
          onChanged: (val) {
            final parsed = int.tryParse(val);
            if (parsed != null) {
              currentMetadata['tablets_per_strip'] = parsed;
              currentMetadata['pack_size'] = parsed;
              onChanged(currentMetadata);
            }
          },
        ),
        const SizedBox(height: AppTokens.spaceMD),
        SwitchListTile(
          secondary: const Icon(Icons.shield_outlined),
          title: const Text('Schedule H / Prescription Required'),
          subtitle: const Text('Prompts for Doctor Name on POS billing'),
          value: currentMetadata['schedule_h'] == true,
          onChanged: (val) {
            currentMetadata['schedule_h'] = val;
            onChanged(currentMetadata);
          },
        ),
      ],
    );
  }
}
