import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/responsive_layout.dart';
import '../../data/models/business.dart';
import '../../modules/business_registry.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/estimate_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/supplier_provider.dart';
import 'auth/login_screen.dart';
import 'crm/customers_screen.dart';
import 'dashboard/dynamic_dashboard_screen.dart';
import 'estimates/estimates_screen.dart';
import 'expenses/expenses_screen.dart';
import 'inventory/inventory_screen.dart';
import 'pos/pos_screen.dart';
import 'products/product_list_screen.dart';
import 'purchases/purchases_screen.dart';
import 'reports/reports_screen.dart';
import 'sales/sales_history_screen.dart';
import 'settings/settings_screen.dart';
import 'suppliers/suppliers_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final biz = context.read<BusinessProvider>().currentBusiness;
      if (biz != null) {
        _loadAllStoreData(biz.id);
      }
    });
  }

  void _loadAllStoreData(String businessId) {
    context.read<ProductProvider>().loadProducts(businessId);
    context.read<SalesProvider>().loadSales(businessId);
    context.read<InventoryProvider>().loadInventory(businessId);
    context.read<CustomerProvider>().loadCustomers(businessId);
    context.read<SupplierProvider>().loadSuppliers(businessId);
    context.read<ExpenseProvider>().loadExpenses(businessId);
    context.read<PurchaseProvider>().loadPurchases(businessId);
    context.read<EstimateProvider>().loadEstimates(businessId);
    context.read<DashboardProvider>().load(businessId);
  }

  @override
  Widget build(BuildContext context) {
    final bizProv = context.watch<BusinessProvider>();
    final currentBiz = bizProv.currentBusiness;

    final authProv = context.watch<AuthProvider>();

    if (currentBiz == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bizModule = BusinessModuleRegistry.getModule(currentBiz.type);
    final isDesktop = ResponsiveLayout.isDesktop(context) || ResponsiveLayout.isTablet(context);

    // Dynamic Navigation items configuration
    final List<_NavItem> navItems = [
      _NavItem(
        title: 'Dashboard',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard_rounded,
        screen: DynamicDashboardScreen(onOpenPos: () => setState(() => _selectedIndex = 1)),
      ),
      const _NavItem(
        title: 'POS Cart',
        icon: Icons.point_of_sale_outlined,
        selectedIcon: Icons.point_of_sale_rounded,
        screen: PosScreen(),
      ),
      // Business-Specific Tab(s) injected here!
      ...bizModule.navigationItems.map((bi) => _NavItem(
            title: bi.label,
            icon: bi.icon,
            selectedIcon: bi.selectedIcon,
            screen: bi.screen,
          )),
      const _NavItem(
        title: 'Products',
        icon: Icons.inventory_2_outlined,
        selectedIcon: Icons.inventory_2_rounded,
        screen: ProductListScreen(),
      ),
      const _NavItem(
        title: 'Sales',
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long_rounded,
        screen: SalesHistoryScreen(),
      ),
      _NavItem(
        title: 'Estimates',
        icon: Icons.request_quote_outlined,
        selectedIcon: Icons.request_quote_rounded,
        screen: EstimatesScreen(onOpenPos: () => setState(() => _selectedIndex = 1)),
      ),
      const _NavItem(
        title: 'Inventory',
        icon: Icons.warehouse_outlined,
        selectedIcon: Icons.warehouse_rounded,
        screen: InventoryScreen(),
      ),
      const _NavItem(
        title: 'Customers',
        icon: Icons.people_outline_rounded,
        selectedIcon: Icons.people_rounded,
        screen: CustomersScreen(),
      ),
      const _NavItem(
        title: 'Suppliers',
        icon: Icons.local_shipping_outlined,
        selectedIcon: Icons.local_shipping_rounded,
        screen: SuppliersScreen(),
      ),
      const _NavItem(
        title: 'Purchases',
        icon: Icons.shopping_bag_outlined,
        selectedIcon: Icons.shopping_bag_rounded,
        screen: PurchasesScreen(),
      ),
      const _NavItem(
        title: 'Expenses',
        icon: Icons.payments_outlined,
        selectedIcon: Icons.payments_rounded,
        screen: ExpensesScreen(),
      ),
      const _NavItem(
        title: 'Reports',
        icon: Icons.insights_outlined,
        selectedIcon: Icons.insights_rounded,
        screen: ReportsScreen(),
      ),
      const _NavItem(
        title: 'Settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded,
        screen: SettingsScreen(),
      ),
    ];

    if (_selectedIndex >= navItems.length) {
      _selectedIndex = 0;
    }

    final currentScreen = navItems[_selectedIndex].screen;

    return Scaffold(
      body: Row(
        children: [
          // Navigation Sidebar on Tablet / Desktop
          if (isDesktop)
            _DesktopSidebar(
              selectedIndex: _selectedIndex,
              navItems: navItems,
              onItemSelected: (idx) => setState(() => _selectedIndex = idx),
              currentBiz: currentBiz,
              auth: authProv,
              onLogout: () => _confirmLogout(context),
            ),
          // Main Body
          Expanded(child: currentScreen),
        ],
      ),
      // Bottom Navigation Bar on Mobile: 4 core tabs + "More" sheet
      // so every destination (incl. Settings / Switch Sector) is reachable.
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: _selectedIndex.clamp(0, 4),
              onTap: (idx) {
                if (idx == 4) {
                  _showMoreNavSheet(context, navItems);
                  return;
                }
                setState(() => _selectedIndex = idx);
              },
              type: BottomNavigationBarType.fixed,
              items: [
                ...navItems.take(4).map((item) => BottomNavigationBarItem(
                      icon: Icon(item.icon),
                      activeIcon: Icon(item.selectedIcon),
                      label: item.title,
                    )),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.more_horiz_rounded),
                  activeIcon: Icon(Icons.more_horiz_rounded),
                  label: 'More',
                ),
              ],
            ),
    );
  }

  void _showMoreNavSheet(BuildContext context, List<_NavItem> navItems) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 8),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Text(
                  'More Screens',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(sheetCtx).colorScheme.onSurface.withAlpha(160),
                  ),
                ),
              ),
              ...navItems.skip(4).toList().asMap().entries.map((entry) {
                final actualIndex = entry.key + 4;
                final item = entry.value;
                final isSelected = _selectedIndex == actualIndex;
                return ListTile(
                  leading: Icon(
                    isSelected ? item.selectedIcon : item.icon,
                    color: isSelected
                        ? Theme.of(sheetCtx).colorScheme.primary
                        : null,
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, size: 18)
                      : const Icon(Icons.arrow_forward_ios_rounded, size: 12),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    setState(() => _selectedIndex = actualIndex);
                  },
                );
              }),
              const Divider(height: 16),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
                title: const Text(
                  'Sign Out / Close Shift',
                  style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFEF4444)),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _confirmLogout(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out & Close Shift?'),
        content: const Text('Are you sure you want to end your operator shift and return to the login screen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              Navigator.pop(ctx);
              final session = context.read<SessionProvider>();
              await context.read<AuthProvider>().logout(session);
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;

  const _NavItem({
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
  });
}

class _DesktopSidebar extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> navItems;
  final ValueChanged<int> onItemSelected;
  final Business currentBiz;
  final AuthProvider auth;
  final VoidCallback onLogout;

  const _DesktopSidebar({
    required this.selectedIndex,
    required this.navItems,
    required this.onItemSelected,
    required this.currentBiz,
    required this.auth,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = currentBiz.type.primaryColor;
    final borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final sidebarBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Container(
      width: 88,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(right: BorderSide(color: borderColor, width: 1)),
      ),
      child: Column(
        children: [
          // Store Brand Header
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Tooltip(
              message: '${currentBiz.name}\n${currentBiz.type.displayName}',
              preferBelow: false,
              waitDuration: const Duration(milliseconds: 300),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primary,
                          primary.withAlpha(200),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withAlpha(90),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        currentBiz.type.icon,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: primary.withAlpha(24),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      currentBiz.type == BusinessType.medical
                          ? 'PHARMACY'
                          : currentBiz.type.shortName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w800,
                        color: primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Divider(
              height: 1,
              thickness: 1,
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            ),
          ),

          // Nav Items (Scrollable)
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                itemCount: navItems.length,
                separatorBuilder: (_, _) => const SizedBox(height: 3),
                itemBuilder: (context, index) {
                  final item = navItems[index];
                  final isSelected = selectedIndex == index;
                  return _DesktopNavTile(
                    item: item,
                    isSelected: isSelected,
                    primaryColor: primary,
                    isDark: isDark,
                    onTap: () => onItemSelected(index),
                  );
                },
              ),
            ),
          ),

          // Footer Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Divider(
              height: 1,
              thickness: 1,
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            ),
          ),

          // Bottom Section: Shift User Badge + Logout
          Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 4, left: 8, right: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // User Shift Avatar with Live Status Dot
                Tooltip(
                  message: '${auth.currentUserName} (${auth.currentUserRole})\nShift Active',
                  waitDuration: const Duration(milliseconds: 300),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: primary.withAlpha(25),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primary.withAlpha(60),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            auth.currentUserName.isNotEmpty
                                ? auth.currentUserName[0].toUpperCase()
                                : 'A',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: primary,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: sidebarBg,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Logout Button
                Tooltip(
                  message: 'Sign Out / Close Shift',
                  waitDuration: const Duration(milliseconds: 300),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      hoverColor: const Color(0xFFEF4444).withAlpha(30),
                      splashColor: const Color(0xFFEF4444).withAlpha(50),
                      onTap: onLogout,
                      child: Container(
                        width: 38,
                        height: 34,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withAlpha(50),
                            width: 1,
                          ),
                          color: const Color(0xFFEF4444).withAlpha(15),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFFEF4444),
                          size: 17,
                        ),
                      ),
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
}

class _DesktopNavTile extends StatefulWidget {
  final _NavItem item;
  final bool isSelected;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onTap;

  const _DesktopNavTile({
    required this.item,
    required this.isSelected,
    required this.primaryColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_DesktopNavTile> createState() => _DesktopNavTileState();
}

class _DesktopNavTileState extends State<_DesktopNavTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final primary = widget.primaryColor;

    final unselectedIconColor =
        widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final unselectedTextColor =
        widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final tileBg = isSelected
        ? primary.withAlpha(25)
        : (_isHovered
            ? (widget.isDark
                ? Colors.white.withAlpha(16)
                : Colors.black.withAlpha(12))
            : Colors.transparent);

    final borderColor = isSelected
        ? primary.withAlpha(60)
        : (_isHovered
            ? (widget.isDark
                ? Colors.white.withAlpha(26)
                : Colors.black.withAlpha(20))
            : Colors.transparent);

    final iconColor = isSelected
        ? primary
        : (_isHovered
            ? (widget.isDark ? Colors.white : const Color(0xFF0F172A))
            : unselectedIconColor);

    final textColor = isSelected
        ? primary
        : (_isHovered
            ? (widget.isDark ? Colors.white : const Color(0xFF0F172A))
            : unselectedTextColor);

    return Tooltip(
      message: widget.item.title,
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            height: 64,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            decoration: BoxDecoration(
              color: tileBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Left active accent bar
                if (isSelected)
                  Positioned(
                    left: 0,
                    top: 8,
                    bottom: 8,
                    child: Container(
                      width: 3.5,
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withAlpha(100),
                            blurRadius: 4,
                            offset: const Offset(1, 0),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Center tile content with overflow protection
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AnimatedScale(
                          duration: const Duration(milliseconds: 180),
                          scale: isSelected ? 1.08 : (_isHovered ? 1.04 : 1.0),
                          child: Icon(
                            isSelected ? widget.item.selectedIcon : widget.item.icon,
                            size: 20,
                            color: iconColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 68),
                          child: Text(
                            widget.item.title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: textColor,
                              height: 1.1,
                              letterSpacing: -0.15,
                            ),
                          ),
                        ),
                      ],
                    ),
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
