import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ominipos_app/core/theme/app_theme.dart';
import 'package:ominipos_app/data/models/customer.dart';
import 'package:ominipos_app/data/models/product.dart';
import 'package:ominipos_app/modules/business_registry.dart';
import 'package:ominipos_app/modules/medical/medical_batch_analyzer.dart';
import 'package:ominipos_app/modules/medical/screens/expiry_tracker_screen.dart';
import 'package:ominipos_app/modules/medical/screens/narcotics_register_screen.dart';
import 'package:ominipos_app/providers/business_provider.dart';
import 'package:ominipos_app/providers/cart_provider.dart';
import 'package:ominipos_app/providers/product_provider.dart';
import 'package:ominipos_app/providers/sales_provider.dart';
import 'package:ominipos_app/providers/auth_provider.dart';
import 'package:ominipos_app/screens/sector_selection/sector_selection_screen.dart';
import 'package:ominipos_app/screens/splash/splash_screen.dart';
import 'package:provider/provider.dart';

void main() {
  setUp(() {
    BusinessModuleRegistry.init();
  });

  group('BusinessModuleRegistry Tests', () {
    test('All 7 business modules are registered and accessible', () {
      final modules = BusinessModuleRegistry.getAllModules();
      expect(modules.length, equals(7));

      final medical = BusinessModuleRegistry.getModule(BusinessType.medical);
      expect(medical.name, contains('Medical'));
      expect(medical.navigationItems.length, greaterThanOrEqualTo(1));

      final restaurant = BusinessModuleRegistry.getModule(BusinessType.restaurant);
      expect(restaurant.name, contains('Restaurant'));
      expect(restaurant.navigationItems.length, greaterThanOrEqualTo(1));

      final grocery = BusinessModuleRegistry.getModule(BusinessType.grocery);
      expect(grocery.name, contains('Grocery'));

      final gym = BusinessModuleRegistry.getModule(BusinessType.gym);
      expect(gym.name, contains('Gym'));
      expect(gym.navigationItems.length, greaterThanOrEqualTo(1));

      final library = BusinessModuleRegistry.getModule(BusinessType.library);
      expect(library.name, contains('Library'));
      expect(library.navigationItems.length, greaterThanOrEqualTo(1));

      final electronics = BusinessModuleRegistry.getModule(BusinessType.electronics);
      expect(electronics.name, contains('Electronics'));

      final garment = BusinessModuleRegistry.getModule(BusinessType.garment);
      expect(garment.name, contains('Garment'));
    });
  });

  group('Cart Calculation & Logic Tests', () {
    test('Cart accurately calculates subtotal, tax, discounts, and roundoff', () {
      final cart = CartProvider();

      final p1 = Product(
        id: 'p1',
        businessId: 'b1',
        categoryId: 'c1',
        name: 'Organic Milk 1L',
        sku: 'MLK-01',
        purchasePrice: 40,
        sellingPrice: 60,
        mrp: 65,
        taxRate: 5.0,
      );

      final p2 = Product(
        id: 'p2',
        businessId: 'b1',
        categoryId: 'c1',
        name: 'Whole Wheat Bread',
        sku: 'BRD-01',
        purchasePrice: 25,
        sellingPrice: 40,
        mrp: 45,
        taxRate: 0.0,
      );

      // Add 2x milk + 1x bread
      cart.addToCart(p1, quantity: 2);
      cart.addToCart(p2, quantity: 1);

      expect(cart.items.length, equals(2));
      expect(cart.itemCount, equals(3));

      // Subtotal = (60 * 2) + (40 * 1) = 160
      expect(cart.subtotal, equals(160.0));

      // Tax = 5% on 120 (milk) = 6.0
      expect(cart.totalTax, equals(6.0));

      // Total = 160 + 6 = 166
      expect(cart.finalTotal, equals(166.0));

      // Test inline steppers
      cart.incrementQuantity(p1.id);
      expect(cart.getItemQuantity(p1.id), equals(3.0));

      cart.decrementQuantity(p1.id);
      expect(cart.getItemQuantity(p1.id), equals(2.0));
    });
  });

  group('Theming & Colors Tests', () {
    test('AppTheme generates custom color schemes per business type', () {
      final medTheme = AppTheme.getTheme(businessType: BusinessType.medical, isDark: false);
      expect(medTheme.colorScheme.primary, equals(const Color(0xFF0D9488)));

      final restTheme = AppTheme.getTheme(businessType: BusinessType.restaurant, isDark: false);
      expect(restTheme.colorScheme.primary, equals(const Color(0xFFE11D48)));

      final elecTheme = AppTheme.getTheme(businessType: BusinessType.electronics, isDark: true);
      expect(elecTheme.colorScheme.primary, equals(const Color(0xFF4F46E5)));
      expect(elecTheme.brightness, equals(Brightness.dark));
    });
  });

  group('Model Serialization Tests', () {
    test('Product and Customer serialize and deserialize properly', () {
      final cust = Customer(
        id: 'cust_01',
        businessId: 'biz_01',
        name: 'John Doe',
        phone: '9876543210',
        loyaltyPoints: 120,
        balanceDue: 450.0,
      );

      final map = cust.toMap();
      final restored = Customer.fromMap(map);

      expect(restored.id, equals('cust_01'));
      expect(restored.name, equals('John Doe'));
      expect(restored.phone, equals('9876543210'));
      expect(restored.loyaltyPoints, equals(120));
      expect(restored.balanceDue, equals(450.0));
    });
  });

  group('NavigationRail Responsive Tests', () {
    testWidgets('NavigationRail with 12 destinations renders without overflow on 500px height', (tester) async {
      tester.view.physicalSize = const Size(800, 500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: IntrinsicHeight(
                          child: NavigationRail(
                            selectedIndex: 0,
                            onDestinationSelected: (_) {},
                            labelType: NavigationRailLabelType.all,
                            destinations: List.generate(
                              12,
                              (index) => NavigationRailDestination(
                                icon: const Icon(Icons.star),
                                label: Text('Item $index'),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const Expanded(child: Center(child: Text('Content'))),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Responsive Sector Selection Screen Tests', () {
    Widget _wrapApp() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => BusinessProvider()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getTheme(
              businessType: BusinessType.grocery, isDark: false),
          home: const SectorSelectionScreen(),
        ),
      );
    }

    testWidgets('renders 6 sector cards without overflow on phone', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrapApp());
      await tester.pumpAndSettle();

      expect(find.text('Choose Your Sector'), findsOneWidget);
      // 7 sector cards, one per BusinessType.
      expect(find.text('Medical'), findsOneWidget);
      expect(find.text('Gym'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on tablet portrait', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrapApp());
      await tester.pumpAndSettle();

      expect(find.text('Choose Your Sector'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on desktop', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrapApp());
      await tester.pumpAndSettle();

      expect(find.text('Choose Your Sector'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('BusinessType Sector Coverage Tests', () {
    test('All 7 expected sectors exist with unique ids', () {
      expect(BusinessType.values.length, equals(7));
      final ids = BusinessType.values.map((t) => t.id).toSet();
      expect(ids.length, equals(7));
      expect(ids, containsAll(const [
        'medical',
        'restaurant',
        'grocery',
        'gym',
        'library',
        'electronics',
        'garment',
      ]));
    });

    test('fromString round-trips every sector', () {
      for (final type in BusinessType.values) {
        expect(BusinessTypeExtension.fromString(type.id), equals(type));
      }
    });
  });

  group('Medical Sector UI Tests', () {
    // A small synthetic catalog with two batches and one Schedule H drug so
    // the screens have real rows to render.
    List<Product> _sampleProducts() {
      return [
        Product(
          id: 'p1',
          businessId: 'b1',
          categoryId: 'c1',
          name: 'Dolo 650mg Tablet',
          sku: 'MED-DOL-650',
          purchasePrice: 22.5,
          sellingPrice: 30.5,
          mrp: 33.0,
          stockQty: 150,
          unit: 'strip',
          metadata: {
            'generic_name': 'Paracetamol 650mg',
            'salt_composition': 'Paracetamol IP 650 mg',
            'hsn_code': '30049060',
            'schedule_h': false,
            'batches': [
              {
                'batch_no': 'B-DL01',
                'expiry': DateTime.now()
                    .add(const Duration(days: 10))
                    .toIso8601String()
                    .substring(0, 10),
                'qty': 50,
                'mrp': 33.0,
              },
              {
                'batch_no': 'B-DL02',
                'expiry': DateTime.now()
                    .add(const Duration(days: 300))
                    .toIso8601String()
                    .substring(0, 10),
                'qty': 100,
                'mrp': 33.0,
              },
            ],
          },
        ),
        Product(
          id: 'p2',
          businessId: 'b1',
          categoryId: 'c1',
          name: 'Augmentin 625 Duo Tablet',
          sku: 'MED-AUG-625',
          purchasePrice: 160,
          sellingPrice: 201.5,
          mrp: 223,
          stockQty: 45,
          unit: 'strip',
          metadata: {
            'generic_name': 'Amoxycillin + Potassium Clavulanate',
            'salt_composition': 'Amoxycillin 500mg',
            'hsn_code': '30041010',
            'schedule_h': true,
          },
        ),
      ];
    }

    Widget _wrapApp({required List<Product> products}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SalesProvider()),
          ChangeNotifierProvider.value(value: ProductProvider()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme:
              AppTheme.getTheme(businessType: BusinessType.medical, isDark: false),
          home: const ExpiryTrackerScreen(),
        ),
      );
    }

    test('batch analyzer parses batches and severity', () {
      final rows = MedicalBatchAnalyzer.extractRows(_sampleProducts());
      // 2 batches from p1, none from p2.
      expect(rows.length, equals(2));
      expect(rows.first.daysLeft, lessThanOrEqualTo(10));
      expect(rows.first.severity.toString(),
          contains('ExpirySeverity.critical'));

      expect(MedicalBatchAnalyzer.restrictedCount(_sampleProducts()), equals(1));
    });

    testWidgets('ExpiryTracker renders without overflow on phone',
        (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrapApp(products: _sampleProducts()));
      await tester.pumpAndSettle();

      expect(find.text('FEFO Expiry Tracker'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ExpiryTracker renders without overflow on desktop',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrapApp(products: _sampleProducts()));
      await tester.pumpAndSettle();

      expect(find.text('FEFO Expiry Tracker'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('NarcoticsRegister renders both tabs without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final productProv = ProductProvider();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SalesProvider()),
            ChangeNotifierProvider.value(value: productProv),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getTheme(
                businessType: BusinessType.medical, isDark: false),
            home: const NarcoticsRegisterScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Schedule H & Narcotic Register'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('SplashScreen Responsive Tests', () {
    Widget wrapSplash() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => BusinessProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: SplashScreen(),
        ),
      );
    }

    testWidgets('renders without overflow on desktop window (1280x683)',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 683);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapSplash());
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('OminiPOS'), findsOneWidget);
      expect(find.text('ONE PLATFORM. EVERY SECTOR.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on tablet (1024x768)',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapSplash());
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('OminiPOS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on phone (360x640)',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapSplash());
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('OminiPOS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}


