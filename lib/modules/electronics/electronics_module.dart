import 'package:flutter/material.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../data/models/cart_item.dart';
import '../base/business_module_interface.dart';
import '../business_type.dart';
import 'screens/repair_service_screen.dart';
import 'screens/warranty_tracker_screen.dart';

class ElectronicsBusinessModule implements BusinessModuleInterface {
  @override
  BusinessType get type => BusinessType.electronics;

  @override
  String get id => 'electronics';

  @override
  String get name => 'Electronics & Gadgets';

  @override
  String get description => 'Serial/IMEI tracking, warranty certificates, and repair service tickets.';

  @override
  IconData get icon => Icons.devices_other_rounded;

  @override
  List<BusinessNavigationItem> get navigationItems => [
        const BusinessNavigationItem(
          id: 'warranty',
          label: 'Warranty Hub',
          icon: Icons.verified_outlined,
          selectedIcon: Icons.verified_rounded,
          screen: WarrantyTrackerScreen(),
        ),
        const BusinessNavigationItem(
          id: 'repair_jobs',
          label: 'Repair Tickets',
          icon: Icons.build_circle_outlined,
          selectedIcon: Icons.build_circle_rounded,
          screen: RepairServiceScreen(),
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
                  color: const Color(0xFF4F46E5).withAlpha(25),
                  borderRadius: AppTokens.borderMD,
                ),
                child: const Icon(Icons.devices_other_rounded, color: Color(0xFF4F46E5), size: 20),
              ),
              const SizedBox(width: AppTokens.spaceMD),
              const Expanded(
                child: Text(
                  'Electronics Service & Warranty Pulse',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WarrantyTrackerScreen()),
                  );
                },
                child: const Text('Warranty Hub'),
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
                    color: const Color(0xFF4F46E5).withAlpha(20),
                    borderRadius: AppTokens.borderMD,
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('12 Devices', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5))),
                      SizedBox(height: 2),
                      Text('Under Warranty', style: TextStyle(fontSize: 12, color: Color(0xFF4F46E5))),
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
                      Text('3 Active', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
                      SizedBox(height: 2),
                      Text('Repair Jobs', style: TextStyle(fontSize: 12, color: Color(0xFFB45309))),
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
    if (item.selectedImei != null && item.selectedImei!.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF4F46E5).withAlpha(20),
          borderRadius: AppTokens.borderSM,
        ),
        child: Text(
          'IMEI/SN: ${item.selectedImei}',
          style: const TextStyle(fontSize: 11, color: Color(0xFF4F46E5), fontWeight: FontWeight.w500),
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
        const Text('Electronics Specifications', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: AppTokens.spaceMD),
        TextFormField(
          initialValue: currentMetadata['model_name']?.toString() ?? '',
          decoration: const InputDecoration(labelText: 'Model Number / Name'),
          onChanged: (val) {
            currentMetadata['model_name'] = val;
            onChanged(currentMetadata);
          },
        ),
        const SizedBox(height: AppTokens.spaceMD),
        TextFormField(
          initialValue: (currentMetadata['warranty_months'] ?? 12).toString(),
          decoration: const InputDecoration(labelText: 'Warranty Period (Months)', suffixText: 'months'),
          keyboardType: TextInputType.number,
          onChanged: (val) {
            currentMetadata['warranty_months'] = int.tryParse(val) ?? 12;
            onChanged(currentMetadata);
          },
        ),
      ],
    );
  }
}
