import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'modules/business_registry.dart';
import 'providers/app_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/business_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/estimate_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/pos_billing_provider.dart';
import 'providers/product_provider.dart';
import 'providers/purchase_provider.dart';
import 'providers/reports_provider.dart';
import 'providers/sales_provider.dart';
import 'providers/session_provider.dart';
import 'providers/supplier_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'services/indian_medicine_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  BusinessModuleRegistry.init();
  IndianMedicineService.instance.loadIfNeeded();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()..init()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BusinessProvider()),
        ChangeNotifierProvider(create: (_) => SessionProvider()..init()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => PosBillingProvider()),
        ChangeNotifierProvider(create: (_) => EstimateProvider()),
        ChangeNotifierProvider(create: (_) => SalesProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => ReportsProvider()),
      ],
      child: const OminiPosApp(),
    ),
  );
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class OminiPosApp extends StatelessWidget {
  const OminiPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appProv = context.watch<AppProvider>();
    final bizProv = context.watch<BusinessProvider>();

    final activeType = bizProv.currentBusiness?.type ?? BusinessType.grocery;

    return MaterialApp(
      title: 'OminiPOS - Multi-Business POS & ERP',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      theme: AppTheme.getTheme(businessType: activeType, isDark: false),
      darkTheme: AppTheme.getTheme(businessType: activeType, isDark: true),
      themeMode: appProv.themeMode,
      home: const SplashScreen(),
    );
  }
}
