import 'package:flutter/material.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../data/models/cart_item.dart';
import '../base/business_module_interface.dart';
import '../business_type.dart';
import 'screens/kds_screen.dart';
import 'screens/table_floor_screen.dart';

class RestaurantBusinessModule implements BusinessModuleInterface {
  @override
  BusinessType get type => BusinessType.restaurant;

  @override
  String get id => 'restaurant';

  @override
  String get name => 'Restaurant / Cafe';

  @override
  String get description => 'Table floor management, KOT & KDS views, and modifier add-ons.';

  @override
  IconData get icon => Icons.restaurant_rounded;

  @override
  List<BusinessNavigationItem> get navigationItems => [
        const BusinessNavigationItem(
          id: 'tables',
          label: 'Floor Tables',
          icon: Icons.table_restaurant_outlined,
          selectedIcon: Icons.table_restaurant_rounded,
          screen: TableFloorScreen(),
        ),
        const BusinessNavigationItem(
          id: 'kds',
          label: 'Kitchen KDS',
          icon: Icons.soup_kitchen_outlined,
          selectedIcon: Icons.soup_kitchen_rounded,
          screen: KdsScreen(),
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
                  color: const Color(0xFFE11D48).withAlpha(25),
                  borderRadius: AppTokens.borderMD,
                ),
                child: const Icon(Icons.restaurant_menu_rounded, color: Color(0xFFE11D48), size: 20),
              ),
              const SizedBox(width: AppTokens.spaceMD),
              const Expanded(
                child: Text(
                  'Dining Floor & Kitchen Status',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TableFloorScreen()),
                  );
                },
                child: const Text('Floor Plan'),
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
                    color: Colors.green.withAlpha(20),
                    borderRadius: AppTokens.borderMD,
                    border: Border.all(color: Colors.green.withAlpha(50)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('5 Free', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.green)),
                      SizedBox(height: 2),
                      Text('Tables Available', style: TextStyle(fontSize: 12, color: Colors.green)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.spaceMD),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(20),
                    borderRadius: AppTokens.borderMD,
                    border: Border.all(color: Colors.red.withAlpha(50)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('2 Seated', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.red)),
                      SizedBox(height: 2),
                      Text('Occupied Tables', style: TextStyle(fontSize: 12, color: Colors.red)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.spaceMD),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(20),
                    borderRadius: AppTokens.borderMD,
                    border: Border.all(color: Colors.orange.withAlpha(50)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('3 Active', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.deepOrange)),
                      SizedBox(height: 2),
                      Text('KDS Tickets', style: TextStyle(fontSize: 12, color: Colors.deepOrange)),
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
    if (item.selectedModifiers.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFE11D48).withAlpha(20),
          borderRadius: AppTokens.borderSM,
        ),
        child: Text(
          'Modifiers: ${item.selectedModifiers.join(", ")}',
          style: const TextStyle(fontSize: 11, color: Color(0xFFE11D48), fontWeight: FontWeight.w500),
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
        const Text('Restaurant & Kitchen Options', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: AppTokens.spaceMD),
        SwitchListTile(
          title: const Text('Vegetarian Dish'),
          value: currentMetadata['is_veg'] ?? true,
          onChanged: (val) {
            currentMetadata['is_veg'] = val;
            onChanged(currentMetadata);
          },
        ),
        SwitchListTile(
          title: const Text('Send to Kitchen Order Ticket (KOT)'),
          value: currentMetadata['is_kitchen_item'] ?? true,
          onChanged: (val) {
            currentMetadata['is_kitchen_item'] = val;
            onChanged(currentMetadata);
          },
        ),
      ],
    );
  }
}
