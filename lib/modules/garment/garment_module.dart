import 'package:flutter/material.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../data/models/cart_item.dart';
import '../base/business_module_interface.dart';
import '../business_type.dart';
import 'screens/variant_matrix_screen.dart';

class GarmentBusinessModule implements BusinessModuleInterface {
  @override
  BusinessType get type => BusinessType.garment;

  @override
  String get id => 'garment';

  @override
  String get name => 'Garments & Apparel';

  @override
  String get description => 'Size × Color matrix, season collections, and fast variant chips.';

  @override
  IconData get icon => Icons.checkroom_rounded;

  @override
  List<BusinessNavigationItem> get navigationItems => [
        const BusinessNavigationItem(
          id: 'matrix',
          label: 'Variant Matrix',
          icon: Icons.grid_view_outlined,
          selectedIcon: Icons.grid_view_rounded,
          screen: VariantMatrixScreen(),
        ),
      ];

  @override
  Widget buildDashboardWidget(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF9333EA).withAlpha(25),
                  borderRadius: AppTokens.borderMD,
                ),
                child: const Icon(Icons.checkroom_rounded, color: Color(0xFF9333EA), size: 20),
              ),
              const SizedBox(width: AppTokens.spaceMD),
              const Expanded(
                child: Text(
                  'Apparel Matrix & Sizes Snapshot',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VariantMatrixScreen()),
                  );
                },
                child: const Text('Stock Matrix'),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spaceMD),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9333EA).withAlpha(20),
                    borderRadius: AppTokens.borderMD,
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Size Matrix', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF9333EA))),
                      SizedBox(height: 2),
                      Text('S / M / L / XL / XXL', style: TextStyle(fontSize: 12, color: Color(0xFF9333EA))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.spaceMD),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.pink.withAlpha(20),
                    borderRadius: AppTokens.borderMD,
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Color Variants', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.pink)),
                      SizedBox(height: 2),
                      Text('Multi-shade per SKU', style: TextStyle(fontSize: 12, color: Colors.pink)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget? buildCartItemExtra(BuildContext context, CartItem item) {
    if (item.selectedVariant != null && item.selectedVariant!.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF9333EA).withAlpha(20),
          borderRadius: AppTokens.borderSM,
        ),
        child: Text(
          'Variant: ${item.selectedVariant!}',
          style: const TextStyle(fontSize: 11, color: Color(0xFF9333EA), fontWeight: FontWeight.w500),
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
        const Text('Apparel Matrix Settings', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: AppTokens.spaceMD),
        TextFormField(
          initialValue: currentMetadata['season']?.toString() ?? '',
          decoration: const InputDecoration(labelText: 'Season / Collection (e.g. Summer 2026)'),
          onChanged: (val) {
            currentMetadata['season'] = val;
            onChanged(currentMetadata);
          },
        ),
        const SizedBox(height: AppTokens.spaceMD),
        TextFormField(
          initialValue: (currentMetadata['sizes'] as List?)?.join(', ') ?? 'S, M, L, XL',
          decoration: const InputDecoration(labelText: 'Available Sizes (comma separated)'),
          onChanged: (val) {
            currentMetadata['sizes'] = val.split(',').map((s) => s.trim()).toList();
            onChanged(currentMetadata);
          },
        ),
      ],
    );
  }
}
