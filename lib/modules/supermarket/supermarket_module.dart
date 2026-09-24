import 'package:flutter/material.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../data/models/cart_item.dart';
import '../base/business_module_interface.dart';
import '../business_type.dart';
import '../grocery/screens/fast_checkout_screen.dart';

class SupermarketBusinessModule implements BusinessModuleInterface {
  @override
  BusinessType get type => BusinessType.supermarket;

  @override
  String get id => 'supermarket';

  @override
  String get name => 'Supermarket / Hypermarket';

  @override
  String get description => 'High-volume multi-aisle billing, shelf labels, and loyalty points.';

  @override
  IconData get icon => Icons.local_grocery_store_rounded;

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
                  color: const Color(0xFFEA580C).withAlpha(25),
                  borderRadius: AppTokens.borderMD,
                ),
                child: const Icon(Icons.storefront_rounded, color: Color(0xFFEA580C), size: 20),
              ),
              const SizedBox(width: AppTokens.spaceMD),
              const Expanded(
                child: Text(
                  'Hypermarket Quick Tools',
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
                    color: const Color(0xFFEA580C).withAlpha(20),
                    borderRadius: AppTokens.borderMD,
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Shelf Labels', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFEA580C))),
                      SizedBox(height: 2),
                      Text('Print Aisle Price Tags', style: TextStyle(fontSize: 12, color: Color(0xFFEA580C))),
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
                      Text('Loyalty Points', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
                      SizedBox(height: 2),
                      Text('Repeat Customer Rewards', style: TextStyle(fontSize: 12, color: Color(0xFFB45309))),
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
          color: const Color(0xFFEA580C).withAlpha(20),
          borderRadius: AppTokens.borderSM,
        ),
        child: Text(
          'Weight: ${item.selectedWeightGram!.toStringAsFixed(0)} g',
          style: const TextStyle(fontSize: 11, color: Color(0xFFEA580C), fontWeight: FontWeight.w500),
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
        const Text('Supermarket Options', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
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
          decoration: const InputDecoration(labelText: 'Shelf / Aisle Location (e.g. Aisle 5 - Shelf B)'),
          onChanged: (val) {
            currentMetadata['rack_location'] = val;
            onChanged(currentMetadata);
          },
        ),
        const SizedBox(height: AppTokens.spaceMD),
        TextFormField(
          initialValue: currentMetadata['shelf_label']?.toString() ?? '',
          decoration: const InputDecoration(labelText: 'Shelf Label / Tagline'),
          onChanged: (val) {
            currentMetadata['shelf_label'] = val;
            onChanged(currentMetadata);
          },
        ),
      ],
    );
  }
}
