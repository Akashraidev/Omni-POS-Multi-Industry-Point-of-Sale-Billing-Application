import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/search_bar_widget.dart';
import '../../data/models/product.dart';
import '../../modules/business_type.dart';
import '../../modules/garment/screens/fast_variant_picker_sheet.dart';
import '../../modules/grocery/screens/loose_item_weight_dialog.dart';
import '../../modules/medical/screens/medical_dispense_dialog.dart';
import '../../modules/medical/widgets/medicine_tile.dart';
import '../../providers/business_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/estimate_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/product_provider.dart';
import '../estimates/estimates_screen.dart';
import 'checkout_dialog.dart';
import 'held_bills_dialog.dart';
import '../products/product_form_screen.dart';
import 'widgets/barcode_quick_add_sheet.dart';
import 'widgets/customer_picker_sheet.dart';
import 'widgets/pos_cart_panel.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  bool _isGridView = true;
  final _searchFocus = FocusNode();
  final _categoryScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final biz = context.read<BusinessProvider>().currentBusiness;
      if (biz != null) {
        context.read<ProductProvider>().loadProducts(biz.id);
        context.read<InventoryProvider>().loadInventory(biz.id);
      }
    });
  }

  Future<void> _openCustomerPicker() async {
    final picked = await CustomerPickerSheet.show(context);
    if (!mounted) return;
    context.read<CartProvider>().setCustomer(picked);
  }

  Future<void> _holdBill() async {
    final biz = context.read<BusinessProvider>().currentBusiness;
    final cart = context.read<CartProvider>();
    if (biz == null || cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item before holding a bill.')),
      );
      return;
    }
    final now = DateTime.now();
    await cart.holdCurrentBill(biz.id, 'Bill ${now.hour}:${now.minute.toString().padLeft(2, '0')}');
    if (!mounted) return;
    await context.read<InventoryProvider>().loadInventory(biz.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bill parked — resume anytime from Held Bills (F7).')),
    );
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    _categoryScrollCtrl.dispose();
    super.dispose();
  }

  /// Sector-aware add-to-cart. Pharmacy batches are picked FEFO-first, with an
  /// explicit chooser when several batches exist.
  void _onProductTap(Product product) {
    final cartProv = context.read<CartProvider>();
    final bizType = context.read<BusinessProvider>().currentBusinessType;

    if (bizType == BusinessType.garment &&
        product.metadata['sizes'] != null &&
        product.metadata['colors'] != null) {
      FastVariantPickerSheet.show(
        context,
        product: product,
        onSelect: (variant) => cartProv.addToCart(product, variant: variant),
      );
      return;
    }

    if (bizType == BusinessType.grocery &&
        product.metadata['is_loose_weight'] == true) {
      LooseItemWeightDialog.show(
        context,
        product: product,
        onConfirm: (weightKg, _) {
          cartProv.addToCart(product, quantity: weightKg, weightGram: weightKg * 1000);
        },
      );
      return;
    }

    if (bizType == BusinessType.medical) {
      MedicalDispenseDialog.show(context, product: product);
      return;
    }

    if (bizType == BusinessType.electronics) {
      final imeis = product.metadata['imei_list'] as List?;
      cartProv.addToCart(product, imei: imeis != null && imeis.isNotEmpty ? imeis.first.toString() : null);
      return;
    }

    cartProv.addToCart(product);
  }

  void _openCartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => const PosCartPanel(),
    );
  }

  Widget _buildShortcutBadge(String keyLabel, String actionLabel, VoidCallback onTap, {bool highlight = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: highlight ? theme.colorScheme.primary.withAlpha(24) : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: highlight ? theme.colorScheme.primary : theme.dividerColor,
          width: highlight ? 1.2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  keyLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: highlight ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                actionLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: highlight ? theme.colorScheme.primary : theme.colorScheme.onSurface.withAlpha(190),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bizProv = context.watch<BusinessProvider>();
    final productProv = context.watch<ProductProvider>();
    final cartProv = context.watch<CartProvider>();
    final invProv = context.watch<InventoryProvider>();

    final currentBiz = bizProv.currentBusiness;
    if (currentBiz == null) {
      return const Scaffold(body: Center(child: Text('No active business selected.')));
    }

    final symbol = currentBiz.currencySymbol;
    final isMedical = bizProv.currentBusinessType == BusinessType.medical;
    final products = productProv.allProducts;
    final categories = productProv.categories;
    final heldCount = invProv.heldBills.length;
    final estProv = context.watch<EstimateProvider>();
    final activeEstimateCount = estProv.activeCount;
    final isScreenWidthWide = MediaQuery.sizeOf(context).width >= 768;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.f1): () => _searchFocus.requestFocus(),
        const SingleActivator(LogicalKeyboardKey.f2): _openCustomerPicker,
        const SingleActivator(LogicalKeyboardKey.f4): () {
          if (cartProv.items.isNotEmpty) CheckoutDialog.show(context);
        },
        const SingleActivator(LogicalKeyboardKey.f6): _holdBill,
        const SingleActivator(LogicalKeyboardKey.f7): () => HeldBillsDialog.show(context),
        const SingleActivator(LogicalKeyboardKey.f8): () => BarcodeQuickAddSheet.show(context, onMatch: _onProductTap),
      },
      child: FocusScope(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${currentBiz.name} — POS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                Text(
                  isMedical ? 'Pharmacy Billing' : currentBiz.type.displayName,
                  style: TextStyle(fontSize: 11.5, color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Barcode quick add (F8)',
                icon: const Icon(Icons.qr_code_scanner_rounded),
                onPressed: () => BarcodeQuickAddSheet.show(context, onMatch: _onProductTap),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    tooltip: 'Held Bills (F7)',
                    icon: const Icon(Icons.pause_circle_outline_rounded),
                    onPressed: () => HeldBillsDialog.show(context),
                  ),
                  if (heldCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                        child: Text(
                          '$heldCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                ],
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    tooltip: 'Estimates & Quotes',
                    icon: const Icon(Icons.request_quote_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EstimatesScreen(onOpenPos: () => Navigator.pop(context)),
                        ),
                      );
                    },
                  ),
                  if (activeEstimateCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Color(0xFF059669), shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                        child: Text(
                          '$activeEstimateCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                tooltip: _isGridView ? 'Switch to List View' : 'Switch to Grid View',
                icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
                onPressed: () => setState(() => _isGridView = !_isGridView),
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              final cartWidth = constraints.maxWidth >= 1400
                  ? 420.0
                  : (constraints.maxWidth >= 1050 ? 380.0 : 350.0);

              return isWide
                  ? Row(
                      children: [
                        Expanded(
                          child: _buildCatalog(
                            context,
                            currentBiz.id,
                            productProv,
                            categories,
                            products,
                            symbol,
                            isMedical,
                            isWide: true,
                          ),
                        ),
                        SizedBox(
                          width: cartWidth,
                          child: const PosCartPanel(isEmbedded: true),
                        ),
                      ],
                    )
                  : _buildCatalog(
                      context,
                      currentBiz.id,
                      productProv,
                      categories,
                      products,
                      symbol,
                      isMedical,
                      isWide: false,
                    );
            },
          ),
          bottomSheet: (isScreenWidthWide || cartProv.items.isEmpty)
              ? null
              : _buildStickyCartBar(context, cartProv, symbol),
        ),
      ),
    );
  }

  Widget _buildCatalog(
    BuildContext context,
    String businessId,
    ProductProvider productProv,
    List categories,
    List<Product> products,
    String symbol,
    bool isMedical, {
    bool isWide = false,
  }) {
    final heldCount = context.watch<InventoryProvider>().heldBills.length;
    final cartHasItems = context.watch<CartProvider>().items.isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppTokens.spaceLG, AppTokens.spaceMD, AppTokens.spaceLG, AppTokens.spaceSM),
          child: SearchBarWidget(
            focusNode: _searchFocus,
            hint: isWide ? 'Search products, SKU, barcode... [Press F1 to focus]' : 'Search products, SKU, barcode...',
            onSearchChanged: (q) => productProv.setSearchQuery(businessId, q),
            onFilterTap: () => _showFilterSheet(context, businessId),
            onScanTap: () => BarcodeQuickAddSheet.show(context, onMatch: _onProductTap),
            hasActiveFilters:
                productProv.onlyLowStock || productProv.selectedCategoryId != 'all' || productProv.searchQuery.isNotEmpty,
          ),
        ),
        if (isWide)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppTokens.spaceLG, 0, AppTokens.spaceLG, AppTokens.spaceSM),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildShortcutBadge('F1', 'Search', () => _searchFocus.requestFocus()),
                  const SizedBox(width: 8),
                  _buildShortcutBadge('F2', 'Customer', _openCustomerPicker),
                  const SizedBox(width: 8),
                  _buildShortcutBadge(
                    'F4',
                    'Checkout',
                    () {
                      if (context.read<CartProvider>().items.isNotEmpty) CheckoutDialog.show(context);
                    },
                    highlight: cartHasItems,
                  ),
                  const SizedBox(width: 8),
                  _buildShortcutBadge('F6', 'Hold Bill', _holdBill),
                  const SizedBox(width: 8),
                  _buildShortcutBadge(
                    'F7',
                    'Held Bills${heldCount > 0 ? ' ($heldCount)' : ''}',
                    () => HeldBillsDialog.show(context),
                    highlight: heldCount > 0,
                  ),
                  const SizedBox(width: 8),
                  _buildShortcutBadge('F8', 'Barcode', () => BarcodeQuickAddSheet.show(context, onMatch: _onProductTap)),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceMD),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 28),
                tooltip: 'Scroll Left',
                onPressed: () {
                  if (_categoryScrollCtrl.hasClients) {
                    _categoryScrollCtrl.animateTo(
                      (_categoryScrollCtrl.offset - 180).clamp(0.0, _categoryScrollCtrl.position.maxScrollExtent),
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Listener(
                  onPointerSignal: (pointerSignal) {
                    if (pointerSignal is PointerScrollEvent && _categoryScrollCtrl.hasClients) {
                      final delta = pointerSignal.scrollDelta.dy != 0
                          ? pointerSignal.scrollDelta.dy
                          : pointerSignal.scrollDelta.dx;
                      final target = (_categoryScrollCtrl.offset + delta)
                          .clamp(0.0, _categoryScrollCtrl.position.maxScrollExtent);
                      _categoryScrollCtrl.jumpTo(target);
                    }
                  },
                  child: SizedBox(
                    height: 38,
                    child: ListView(
                      controller: _categoryScrollCtrl,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: const Text('All Items'),
                            selected: productProv.selectedCategoryId == 'all',
                            onSelected: (_) => productProv.setCategory(businessId, 'all'),
                          ),
                        ),
                        ...categories.map((c) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(c.name),
                                selected: productProv.selectedCategoryId == c.id,
                                onSelected: (_) => productProv.setCategory(businessId, c.id),
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 28),
                tooltip: 'Scroll Right',
                onPressed: () {
                  if (_categoryScrollCtrl.hasClients) {
                    _categoryScrollCtrl.animateTo(
                      (_categoryScrollCtrl.offset + 180).clamp(0.0, _categoryScrollCtrl.position.maxScrollExtent),
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(child: _buildProductArea(context, productProv, products, symbol, isMedical, isWide: isWide)),
      ],
    );
  }

  Widget _buildProductArea(
    BuildContext context,
    ProductProvider productProv,
    List<Product> products,
    String symbol,
    bool isMedical, {
    bool isWide = false,
  }) {
    if (productProv.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (products.isEmpty) {
      final hasQuery = productProv.searchQuery.isNotEmpty ||
          productProv.selectedCategoryId != 'all' ||
          productProv.onlyLowStock;
      return EmptyStateWidget(
        icon: hasQuery ? Icons.search_off_rounded : Icons.medication_liquid_rounded,
        title: hasQuery ? 'No Matches Found' : 'No Medicines Yet',
        description: hasQuery
            ? 'Try a different name, generic, SKU or barcode.'
            : 'Add your first medicine with an opening-stock batch to begin billing.',
        actionLabel: hasQuery ? null : 'Add Medicine',
        onAction: hasQuery
            ? null
            : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductFormScreen(
                      businessId: context.read<BusinessProvider>().currentBusiness!.id,
                    ),
                  ),
                ),
      );
    }

    final bottomPadding = isWide ? 16.0 : 96.0;

    if (isMedical) {
      return _isGridView
          ? GridView.builder(
              padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.74,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) => _buildMedicalTile(products[index]),
            )
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _buildMedicalTile(products[index], list: true),
            );
    }

    return _isGridView
        ? GridView.builder(
            padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.76,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final qtyInCart = context.watch<CartProvider>().getItemQuantity(product.id);
              return _buildGenericProductCard(context, product, qtyInCart, symbol);
            },
          )
        : ListView.separated(
            padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final product = products[index];
              final qtyInCart = context.watch<CartProvider>().getItemQuantity(product.id);
              return _buildGenericProductListTile(context, product, qtyInCart, symbol);
            },
          );
  }

  Widget _buildMedicalTile(Product product, {bool list = false}) {
    final cartProv = context.watch<CartProvider>();
    final bizType = context.read<BusinessProvider>().currentBusinessType;

    return MedicineTile(
      product: product,
      layout: list ? MedicineTileLayout.list : MedicineTileLayout.grid,
      qtyInCart: cartProv.getItemQuantity(product.id),
      freeQtyInCart: cartProv.getFreeQuantity(product.id),
      onAdd: () => _onProductTap(product),
      onCardTap: () => _onProductTap(product),
      onIncrement: () {
        final batches = MedicalBatchUtils.batchesOf(product);
        if (bizType == BusinessType.medical && batches.length > 1) {
          _onProductTap(product);
          return;
        }
        context.read<CartProvider>().incrementQuantity(product.id);
      },
      onDecrement: () => context.read<CartProvider>().decrementQuantity(product.id),
      onBatchPick: () => MedicalDispenseDialog.show(
        context,
        product: product,
        initialBatch: cartProv.getItem(product.id)?.selectedBatch,
      ),
    );
  }

  // Flipkart-Style Product Card with Inline Stepper
  Widget _buildGenericProductCard(BuildContext context, Product product, double qtyInCart, String symbol) {
    final theme = Theme.of(context);
    final isLow = product.isLowStock;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: AppTokens.borderLG,
        border: Border.all(color: theme.dividerColor),
        boxShadow: AppTokens.shadowSM,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppTokens.borderLG,
        child: InkWell(
          borderRadius: AppTokens.borderLG,
          onTap: () => _onProductTap(product),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(20),
                        borderRadius: AppTokens.borderMD,
                      ),
                      child: Icon(Icons.inventory_2_rounded, size: 20, color: theme.colorScheme.primary),
                    ),
                    if (isLow)
                      const AppBadge(label: 'Low', type: BadgeType.warning)
                    else
                      Text(
                        '${product.stockQty.toInt()} ${product.unit}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      if (product.brand.isNotEmpty)
                        Text(
                          product.brand,
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withAlpha(140)),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      CurrencyFormatter.format(product.sellingPrice, symbol: symbol),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    if (product.mrp > product.sellingPrice) ...[
                      const SizedBox(width: 4),
                      Text(
                        CurrencyFormatter.format(product.mrp, symbol: symbol, decimalDigits: 0),
                        style: const TextStyle(decoration: TextDecoration.lineThrough, fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                if (qtyInCart > 0)
                  Container(
                    height: 34,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: AppTokens.borderMD,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 16, color: Colors.white),
                          onPressed: () => context.read<CartProvider>().decrementQuantity(product.id),
                          padding: EdgeInsets.zero,
                        ),
                        Text(
                          '${qtyInCart.toInt()}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 16, color: Colors.white),
                          onPressed: () => context.read<CartProvider>().incrementQuantity(product.id),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    height: 34,
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        side: BorderSide(color: theme.colorScheme.primary),
                      ),
                      onPressed: () => _onProductTap(product),
                      child: const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenericProductListTile(BuildContext context, Product product, double qtyInCart, String symbol) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: AppTokens.borderMD,
        border: Border.all(color: theme.dividerColor),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppTokens.borderMD,
        child: InkWell(
          borderRadius: AppTokens.borderMD,
          onTap: () => _onProductTap(product),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(20),
                    borderRadius: AppTokens.borderMD,
                  ),
                  child: Icon(Icons.inventory_2_rounded, size: 22, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: AppTokens.spaceMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(
                        'Stock: ${product.stockQty.toInt()} ${product.unit} • SKU: ${product.sku}',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(140)),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(product.sellingPrice, symbol: symbol),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    if (qtyInCart > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => context.read<CartProvider>().decrementQuantity(product.id),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: Colors.grey.withAlpha(50), shape: BoxShape.circle),
                              child: const Icon(Icons.remove, size: 14),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text('${qtyInCart.toInt()}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          InkWell(
                            onTap: () => context.read<CartProvider>().incrementQuantity(product.id),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                              child: const Icon(Icons.add, size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      )
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: const Size(0, 30),
                        ),
                        onPressed: () => _onProductTap(product),
                        child: const Text('Add', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStickyCartBar(BuildContext context, CartProvider cartProv, String symbol) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        border: Border(top: BorderSide(color: theme.dividerColor)),
        boxShadow: AppTokens.shadowLG,
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _openCartSheet(context),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${cartProv.itemCount} items',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.keyboard_arrow_up_rounded, size: 18, color: theme.colorScheme.primary),
                      ],
                    ),
                    Text(
                      'Total: ${CurrencyFormatter.format(cartProv.finalTotal, symbol: symbol)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Checkout'),
              onPressed: () => CheckoutDialog.show(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context, String businessId) {
    final prodProv = context.read<ProductProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filter & Sort Products', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.warning_amber_rounded),
                title: const Text('Low Stock Only'),
                trailing: Switch(
                  value: prodProv.onlyLowStock,
                  onChanged: (_) {
                    prodProv.toggleLowStock(businessId);
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.arrow_upward_rounded),
                title: const Text('Price: Low to High'),
                onTap: () {
                  prodProv.setSortBy(businessId, 'price_low');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_downward_rounded),
                title: const Text('Price: High to Low'),
                onTap: () {
                  prodProv.setSortBy(businessId, 'price_high');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.clear_all_rounded),
                title: const Text('Reset All Filters'),
                onTap: () {
                  prodProv.clearFilters(businessId);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Small accessor kept local so the medical batch metadata shape has one reader.
class MedicalBatchUtils {
  MedicalBatchUtils._();

  static List<Map<String, dynamic>> batchesOf(Product product) {
    final raw = product.metadata['batches'];
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }
}
