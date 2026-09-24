import 'package:flutter/material.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../data/models/cart_item.dart';
import '../base/business_module_interface.dart';
import '../business_type.dart';
import 'screens/fast_checkout_screen.dart';

class GroceryBusinessModule implements BusinessModuleInterface {
  @override
  BusinessType get type => BusinessType.grocery;

  @override
  String get id => 'grocery';

  @override
  String get name => 'Grocery / Supermarket';

  @override
  String get description => 'Weight-based pricing, unit conversion, and fast touch checkout mode.';

  @override
  IconData get icon => Icons.shopping_basket_rounded;

  @override
  List<BusinessNavigationItem> get navigationItems => [
        const BusinessNavigationItem(
          id: 'fast_checkout',
          label: 'Touch Checkout',
          icon: Icons.flash_on_outlined,
          selectedIcon: Icons.flash_on_rounded,
          screen: FastCheckoutScreen(),
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
                  color: const Color(0xFF16A34A).withAlpha(25),
                  borderRadius: AppTokens.borderMD,
                ),
                child: const Icon(Icons.scale_rounded, color: Color(0xFF16A34A), size: 20),
              ),
              const SizedBox(width: AppTokens.spaceMD),
              const Expanded(
                child: Text(
                  'Supermarket Quick Tools',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FastCheckoutScreen()),
                  );
                },
                child: const Text('Touch POS'),
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
                    color: const Color(0xFF16A34A).withAlpha(20),
                    borderRadius: AppTokens.borderMD,
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Weight Scale', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                      SizedBox(height: 2),
                      Text('Kg / Gram Calculator', style: TextStyle(fontSize: 12, color: Color(0xFF16A34A))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.spaceMD),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(20),
                    borderRadius: AppTokens.borderMD,
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Barcode Ready', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
                      SizedBox(height: 2),
                      Text('High-Speed Scanning', style: TextStyle(fontSize: 12, color: Color(0xFFB45309))),
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
    if (item.selectedWeightGram != null) {
      return Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF16A34A).withAlpha(20),
          borderRadius: AppTokens.borderSM,
        ),
        child: Text(
          'Weight: ${item.selectedWeightGram!.toStringAsFixed(0)} g',
          style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w500),
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
        const Text('Grocery & Supermarket Options', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: AppTokens.spaceMD),
        SwitchListTile(
          title: const Text('Sold by Loose Weight (Scale)'),
          subtitle: const Text('Triggers gram/kg weight dialog on POS tap'),
          value: currentMetadata['is_loose_weight'] ?? false,
          onChanged: (val) {
            currentMetadata['is_loose_weight'] = val;
            onChanged(currentMetadata);
          },
        ),
        const SizedBox(height: AppTokens.spaceMD),
        TextFormField(
          initialValue: currentMetadata['rack_location']?.toString() ?? '',
          decoration: const InputDecoration(labelText: 'Aisle / Rack Location (e.g. Aisle 2 - Bay 4)'),
          onChanged: (val) {
            currentMetadata['rack_location'] = val;
            onChanged(currentMetadata);
          },
        ),
      ],
    );
  }
}
