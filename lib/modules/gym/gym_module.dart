import 'package:flutter/material.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../data/models/cart_item.dart';
import '../base/business_module_interface.dart';
import '../business_type.dart';
import 'screens/gym_memberships_screen.dart';
import 'screens/gym_trainer_schedule_screen.dart';

class GymBusinessModule implements BusinessModuleInterface {
  @override
  BusinessType get type => BusinessType.gym;

  @override
  String get id => 'gym';

  @override
  String get name => 'Gym & Fitness Center';

  @override
  String get description => 'Memberships, trainer plans, workout passes, attendance & supplements.';

  @override
  IconData get icon => Icons.fitness_center_rounded;

  @override
  List<BusinessNavigationItem> get navigationItems => [
        const BusinessNavigationItem(
          id: 'gym_memberships',
          label: 'Memberships',
          icon: Icons.card_membership_outlined,
          selectedIcon: Icons.card_membership_rounded,
          screen: GymMembershipsScreen(),
        ),
        const BusinessNavigationItem(
          id: 'gym_trainers',
          label: 'Trainers & Slots',
          icon: Icons.sports_gymnastics_rounded,
          selectedIcon: Icons.sports_gymnastics_rounded,
          screen: GymTrainerScheduleScreen(),
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
                  color: const Color(0xFFFF5722).withAlpha(25),
                  borderRadius: AppTokens.borderMD,
                ),
                child: const Icon(Icons.fitness_center_rounded, color: Color(0xFFFF5722), size: 20),
              ),
              const SizedBox(width: AppTokens.spaceMD),
              const Expanded(
                child: Text(
                  'Gym & Fitness Operations',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.people_alt_outlined, size: 16),
                label: const Text('Member Directory'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GymMembershipsScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spaceMD),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GymMembershipsScreen()),
                    );
                  },
                  borderRadius: AppTokens.borderMD,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5722).withAlpha(18),
                      borderRadius: AppTokens.borderMD,
                      border: Border.all(color: const Color(0xFFFF5722).withAlpha(40)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('142 Active Members', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFFF5722))),
                        SizedBox(height: 2),
                        Text('38 Checked-in Today • 5 Expiring Soon', style: TextStyle(fontSize: 12, color: Color(0xFFFF5722))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.spaceMD),
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GymTrainerScheduleScreen()),
                    );
                  },
                  borderRadius: AppTokens.borderMD,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withAlpha(20),
                      borderRadius: AppTokens.borderMD,
                      border: Border.all(color: const Color(0xFFF59E0B).withAlpha(50)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('4 Active Batches', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
                        SizedBox(height: 2),
                        Text('Next: CrossFit @ 05:00 PM (24 booked)', style: TextStyle(fontSize: 12, color: Color(0xFFB45309))),
                      ],
                    ),
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
    final meta = item.product.metadata;
    if (meta['is_gym_plan'] == true || meta['plan_days'] != null) {
      final days = meta['plan_days'] ?? 30;
      final pt = meta['has_trainer'] == true ? ' • Includes PT' : '';
      return Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFF5722).withAlpha(20),
          borderRadius: AppTokens.borderSM,
        ),
        child: Text(
          'Gym Pass: $days Days$pt',
          style: const TextStyle(fontSize: 11, color: Color(0xFFFF5722), fontWeight: FontWeight.w600),
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
        const Text('Gym & Fitness Configuration', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: AppTokens.spaceMD),
        SwitchListTile(
          title: const Text('Is Membership Plan / Workout Pass'),
          subtitle: const Text('Marks this product as a time-bound member subscription'),
          value: currentMetadata['is_gym_plan'] ?? false,
          activeThumbColor: const Color(0xFFFF5722),
          onChanged: (val) {
            currentMetadata['is_gym_plan'] = val;
            onChanged(currentMetadata);
          },
        ),
        if (currentMetadata['is_gym_plan'] == true) ...[
          const SizedBox(height: AppTokens.spaceSM),
          TextFormField(
            initialValue: currentMetadata['plan_days']?.toString() ?? '30',
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Validity Duration (Days)',
              helperText: 'e.g. 30 for Monthly, 90 for 3-Months, 365 for Annual',
              prefixIcon: Icon(Icons.calendar_today_rounded),
            ),
            onChanged: (val) {
              currentMetadata['plan_days'] = int.tryParse(val) ?? 30;
              onChanged(currentMetadata);
            },
          ),
          const SizedBox(height: AppTokens.spaceMD),
          SwitchListTile(
            title: const Text('Includes Personal Trainer'),
            subtitle: const Text('Allows allocating assigned trainer for client'),
            value: currentMetadata['has_trainer'] ?? false,
            activeThumbColor: const Color(0xFFFF5722),
            onChanged: (val) {
              currentMetadata['has_trainer'] = val;
              onChanged(currentMetadata);
            },
          ),
        ],
      ],
    );
  }
}
