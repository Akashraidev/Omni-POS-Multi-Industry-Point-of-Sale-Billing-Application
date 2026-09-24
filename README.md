# OminiPOS — Enterprise Multi-Business POS & ERP Application

A complete, production-grade, responsive Flutter multi-business management system built with **SQLite** (`sqflite` + `sqflite_common_ffi`) for local offline-first database management and **Provider** for reactive state management.

The app dynamically adapts its entire UI, navigation, business logic, workflows, and color themes based on the business type selected.

---

## 1. Supported Business Types (Fully Implemented)

1. **Medical Shop (Pharmacy)**
   - Medicine master with generic salt compositions, manufacturer, and HSN codes.
   - Batch-wise & expiry-wise stock management (**FEFO — First-Expiry-First-Out** billing logic).
   - Expiry alert dashboard with color-coded buckets (< 30 days, < 60 days, < 90 days).
   - Schedule H / H1 prescription flag with prescribing doctor name capture.
   - Schedule H & Narcotic regulatory register.

2. **Restaurant / Cafe**
   - Dining floor plan view with interactive table occupancy statuses (**Free**, **Occupied**, **Reserved**, **Billing**).
   - Kitchen Order Ticket (KOT) and Kitchen Display System (**KDS**) view with live preparation timer stages (*Placed → Preparing → Ready → Served*).
   - Menu modifiers & add-ons (Milk choices, Pizza crusts, Spice levels).

3. **Grocery Shop / Supermarket**
   - Weight-based & loose item calculator (per kg / gram pricing with tare presets: 250g, 500g, 1kg, etc.).
   - Supermarket high-throughput **Fast Touch POS mode** with barcode scanner integration.
   - Aisle and rack/shelf location mapping.

4. **Electronics Shop**
   - Serial & IMEI tracking captured upon checkout.
   - Warranty tracker hub with validity countdowns and claim records.
   - Repair and service job card management (*Intake → Diagnosing → Repairing → Ready for Delivery*).

5. **Garment / Apparel Shop**
   - Size (S / M / L / XL / XXL) × Color multi-shade variant matrix.
   - Live visual stock matrix table view per SKU.
   - Fast variant picker sheet in POS cart for tapping size and color chips.
   - Hassle-free size exchange support without full return overhead.

---

## 2. Architecture & Extensibility

The codebase follows a clean layered and modular plugin architecture:

```
lib/
├── core/
│   ├── database/        # SQLite setup, ffi init, table creation, migrations, seed data
│   ├── theme/           # AppColors, AppTokens, AppTypography, AppTheme (5 dynamic palettes)
│   ├── utils/           # Currency, Date, and Responsive Layout helpers
│   └── widgets/         # Shared component library (AppButton, AppCard, AppChip, etc.)
├── data/
│   ├── models/          # Business, Product, CartItem, Sale, Customer, Supplier, Expense, etc.
│   └── repositories/    # Layered data access with atomic SQLite transactions
├── modules/
│   ├── base/            # BusinessModuleInterface contract
│   ├── business_registry.dart # Central extensible registry
│   ├── medical/         # Pharmacy module (FEFO, batches, expiry alerts, narcotics)
│   ├── restaurant/      # Cafe module (table floor plan, KDS, modifiers)
│   ├── grocery/         # Supermarket module (weight scales, fast touch checkout)
│   ├── electronics/     # Electronics module (IMEI tracker, warranty, repair jobs)
│   └── garment/         # Apparel module (variant matrix, fast variant picker)
├── providers/           # State management with MultiProvider
└── screens/             # Responsive UI screens (Splash, Onboarding, POS, Reports, etc.)
```

---

## 3. How to Add a 6th Business Type (e.g., Bakery, Salon, Hardware)

Adding a new business domain requires **zero modifications** to core billing engines, database transactions, reporting, or user authentication:

1. **Add an enum value** in `lib/modules/business_type.dart`:
   ```dart
   enum BusinessType { medical, restaurant, grocery, electronics, garment, bakery }
   ```
2. **Implement `BusinessModuleInterface`**:
   ```dart
   class BakeryBusinessModule implements BusinessModuleInterface {
     @override
     BusinessType get type => BusinessType.bakery;
     
     @override
     String get name => 'Bakery & Confectionery';
     
     @override
     List<BusinessNavigationItem> get navigationItems => [
       BusinessNavigationItem(
         id: 'custom_cakes',
         label: 'Custom Cakes',
         icon: Icons.cake_outlined,
         selectedIcon: Icons.cake_rounded,
         screen: CustomCakesScreen(),
       ),
     ];
     
     @override
     Widget buildDashboardWidget(BuildContext context) => CakeOrdersSummaryCard();
     ...
   }
   ```
3. **Register in `BusinessModuleRegistry`**:
   ```dart
   BusinessModuleRegistry.register(BakeryBusinessModule());
   ```

---

## 4. Key Cross-Business Features

- **Flipkart-Style Cart**: Sticky debounced search, one-tap add, inline quantity steppers (+/-) on product cards, swipe-to-remove with undo snackbars, persistent bottom cart bar, held/parked bills.
- **Advanced Billing**: Split payments (Cash + UPI + Card + Credit/Due), quick cash denomination calculator, round-off handling.
- **Thermal Invoice Printing**: High-density 80mm/58mm thermal receipt layout with printable PDF generation and sharing via the `printing` and `pdf` packages.
- **Reports & Analytics**: Interactive sales trends (LineChart), category revenue breakdown (PieChart), top-selling items, and CSV export.
- **Multi-Store Management**: Switch seamlessly between stores with different business domains under one app instance.
- **Role-Based Security**: Owner, Manager, Cashier, and Staff privilege simulator.
- **Dark & Light Mode**: Curated HSL dark surfaces and contrasting accents for all 5 business domains.

---

## 5. Running the Application

### Windows Desktop:
```bash
flutter run -d windows
```

### Web (Chrome):
```bash
flutter run -d chrome
```

### Android:
```bash
flutter run -d android
```

### Run Automated Tests:
```bash
flutter test
```
