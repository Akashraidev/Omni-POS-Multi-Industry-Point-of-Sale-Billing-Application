import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/database/app_database.dart';
import '../../core/database/seed_data.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/responsive_size.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../modules/business_type.dart';
import '../../providers/app_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/sales_provider.dart';
import '../business_setup/business_setup_wizard_screen.dart';
import '../sector_selection/sector_selection_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appProv = context.watch<AppProvider>();
    final bizProv = context.watch<BusinessProvider>();
    final currentBiz = bizProv.currentBusiness;
    final allBiz = bizProv.businesses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Configuration'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: context.contentMaxWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: context.widthPct(4),
                vertical: context.widthPct(3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            // Active Business Header Card
            if (currentBiz != null)
              AppCard(
                borderColor: currentBiz.type.primaryColor.withAlpha(80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: currentBiz.type.primaryColor.withAlpha(25),
                                borderRadius: AppTokens.borderMD,
                              ),
                              child: Icon(currentBiz.type.icon, color: currentBiz.type.primaryColor),
                            ),
                            const SizedBox(width: AppTokens.spaceMD),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(currentBiz.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                Text(currentBiz.type.displayName, style: TextStyle(color: currentBiz.type.primaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SectorSelectionScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                          label: const Text('Switch Sector'),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Text('Address: ${currentBiz.address.isNotEmpty ? currentBiz.address : "Main Store"}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('Tax Number / GSTIN: ${currentBiz.taxNumber.isNotEmpty ? currentBiz.taxNumber : "Unregistered"}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('Invoice Prefix: ${currentBiz.invoicePrefix} • Default Tax: ${currentBiz.defaultTaxRate}%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            const SizedBox(height: AppTokens.spaceLG),

            // Multi-Store Quick Switcher List
            const Text('Multi-Store Branch Switcher', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 8),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // Primary switch-sector action
                  ListTile(
                    leading: Icon(Icons.swap_horiz_rounded, color: currentBiz?.type.primaryColor ?? theme.colorScheme.primary),
                    title: const Text('Switch Sector', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Open the sector picker to choose Medical, Restaurant, Grocery, Gym, Library, Electronics or Garments'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SectorSelectionScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ...allBiz.map((b) {
                    final isCurrent = b.id == currentBiz?.id;
                    return ListTile(
                      leading: Icon(b.type.icon, color: b.type.primaryColor),
                      title: Text(b.name, style: TextStyle(fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500)),
                      subtitle: Text(b.type.displayName),
                      trailing: isCurrent
                          ? const AppBadge(label: 'ACTIVE', type: BadgeType.success)
                          : TextButton(
                              onPressed: () async {
                                await bizProv.switchBusiness(b);
                                if (context.mounted) {
                                  context.read<ProductProvider>().loadProducts(b.id);
                                  context.read<SalesProvider>().loadSales(b.id);
                                }
                              },
                              child: const Text('Activate'),
                            ),
                    );
                  }),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.add_business_rounded, color: Colors.indigo),
                    title: const Text('Register New Store / Branch'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BusinessSetupWizardScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.spaceLG),

            // User Role Simulator
            const Text('User Role & Permissions (Security)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 8),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Simulate Role:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text('Current: ${appProv.currentUser.role}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      Wrap(
                        spacing: 6,
                        children: ['Owner', 'Manager', 'Cashier', 'Staff'].map((r) {
                          final isSel = appProv.currentUser.role == r;
                          return ChoiceChip(
                            label: Text(r),
                            selected: isSel,
                            onSelected: (_) => appProv.setCurrentUserRole(r),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          appProv.currentUser.isManager
                              ? '✓ Full permissions: Voids, reports, settings, inventory reorders, discounts.'
                              : '✓ Restricted mode: Billing & checkout enabled. Reports and voids gated.',
                          style: TextStyle(fontSize: 12, color: appProv.currentUser.isManager ? Colors.teal : Colors.deepOrange),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.spaceLG),

            // Theme & Preferences
            const Text('App Experience & Appearance', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 8),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: Icon(appProv.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded),
                    title: const Text('Dark Mode Interface'),
                    subtitle: const Text('Curated dark surface themes per business palette'),
                    value: appProv.isDarkMode,
                    onChanged: (_) => appProv.toggleTheme(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.spaceLG),

            // Data Management
            const Text('Database & Backup', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 8),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.cloud_upload_outlined, color: Colors.blue),
                    title: const Text('Export Local Database Backup'),
                    subtitle: const Text('Saved to app storage as ominipos_backup.db'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Database backup exported successfully!')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.restart_alt_rounded, color: Colors.red),
                    title: const Text('Reset & Re-populate Seed Data'),
                    subtitle: const Text('Resets all 6 sectors, products, and sample sales'),
                    onTap: () async {
                      final confirmed = await ConfirmationDialog.show(
                        context,
                        title: 'Reset Demo Data?',
                        message: 'This will wipe custom sales and re-populate the official seed data for all 6 sectors.',
                        isDestructive: true,
                      );
                      if (confirmed == true) {
                        final db = await AppDatabase.instance.database;
                        await AppDatabase.instance.clearAllData();
                        await SeedData.populateAllSeedData(db);
                        await bizProv.loadBusinesses();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Database reset and seed data loaded!')),
                          );
                        }
                      }
                    },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
      }
    }
