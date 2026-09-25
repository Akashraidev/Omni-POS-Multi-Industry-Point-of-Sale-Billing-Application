import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../data/models/product.dart';
import '../../modules/business_type.dart';
import '../../providers/business_provider.dart';
import '../../providers/product_provider.dart';
import 'product_form_screen.dart';
import 'widgets/product_detail_dialog.dart';

enum ProductTabFilter { all, lowStock, expiring, expired, outOfStock }

enum ProductSort { nameAsc, nameDesc, stockAsc, stockDesc, priceAsc, priceDesc }

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchCtrl = TextEditingController();
  final _categoryScrollCtrl = ScrollController();

  ProductTabFilter _tabFilter = ProductTabFilter.all;
  ProductSort _sortOrder = ProductSort.nameAsc;
  bool _isTableView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final biz = context.read<BusinessProvider>().currentBusiness;
      if (biz != null) {
        context.read<ProductProvider>().loadProducts(biz.id);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _categoryScrollCtrl.dispose();
    super.dispose();
  }

  List<Product> _applyFiltersAndSort(List<Product> list) {
    var result = List<Product>.from(list);

    // Filter by tab
    switch (_tabFilter) {
      case ProductTabFilter.lowStock:
        result = result.where((p) => p.isLowStock && p.stockQty > 0).toList();
        break;
      case ProductTabFilter.outOfStock:
        result = result.where((p) => p.stockQty <= 0).toList();
        break;
      case ProductTabFilter.expiring:
        result = result.where((p) {
          final batches = p.metadata['batches'] as List<dynamic>?;
          if (batches == null || batches.isEmpty) return false;
          for (final b in batches) {
            final exp = b['expiry']?.toString();
            if (exp != null) {
              final d = DateTime.tryParse(exp);
              if (d != null) {
                final days = d.difference(DateTime.now()).inDays;
                if (days >= 0 && days <= 90) return true;
              }
            }
          }
          return false;
        }).toList();
        break;
      case ProductTabFilter.expired:
        result = result.where((p) {
          final batches = p.metadata['batches'] as List<dynamic>?;
          if (batches == null || batches.isEmpty) return false;
          for (final b in batches) {
            final exp = b['expiry']?.toString();
            if (exp != null) {
              final d = DateTime.tryParse(exp);
              if (d != null && d.difference(DateTime.now()).inDays < 0) return true;
            }
          }
          return false;
        }).toList();
        break;
      case ProductTabFilter.all:
        break;
    }

    // Sort
    switch (_sortOrder) {
      case ProductSort.nameAsc:
        result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case ProductSort.nameDesc:
        result.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case ProductSort.stockAsc:
        result.sort((a, b) => a.stockQty.compareTo(b.stockQty));
        break;
      case ProductSort.stockDesc:
        result.sort((a, b) => b.stockQty.compareTo(a.stockQty));
        break;
      case ProductSort.priceAsc:
        result.sort((a, b) => a.sellingPrice.compareTo(b.sellingPrice));
        break;
      case ProductSort.priceDesc:
        result.sort((a, b) => b.sellingPrice.compareTo(a.sellingPrice));
        break;
    }

    return result;
  }

  void _confirmDelete(Product product) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Product?',
      message: 'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
      confirmLabel: 'Delete Product',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      final biz = context.read<BusinessProvider>().currentBusiness;
      if (biz != null) {
        await context.read<ProductProvider>().deleteProduct(product.id, biz.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted ${product.name}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prodProv = context.watch<ProductProvider>();
    final bizProv = context.watch<BusinessProvider>();
    final currentBiz = bizProv.currentBusiness;
    final symbol = currentBiz?.currencySymbol ?? '₹';
    final isMedical = currentBiz?.type == BusinessType.medical;

    final all = prodProv.allProducts;
    final filtered = _applyFiltersAndSort(all);

    // Counts for tabs
    final lowStockCount = all.where((p) => p.isLowStock && p.stockQty > 0).length;
    final outOfStockCount = all.where((p) => p.stockQty <= 0).length;
    final expiringCount = all.where((p) {
      final bList = p.metadata['batches'] as List<dynamic>?;
      if (bList == null) return false;
      return bList.any((b) {
        final exp = DateTime.tryParse(b['expiry']?.toString() ?? '');
        if (exp == null) return false;
        final d = exp.difference(DateTime.now()).inDays;
        return d >= 0 && d <= 90;
      });
    }).length;
    final expiredCount = all.where((p) {
      final bList = p.metadata['batches'] as List<dynamic>?;
      if (bList == null) return false;
      return bList.any((b) {
        final exp = DateTime.tryParse(b['expiry']?.toString() ?? '');
        return exp != null && exp.difference(DateTime.now()).inDays < 0;
      });
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(isMedical ? 'Pharmacy Inventory & Medicines' : 'Product & Inventory Catalog'),
        actions: [
          IconButton(
            tooltip: _isTableView ? 'Switch to Card View' : 'Switch to Dense Table View',
            icon: Icon(_isTableView ? Icons.grid_view_rounded : Icons.table_rows_rounded),
            onPressed: () => setState(() => _isTableView = !_isTableView),
          ),
          PopupMenuButton<ProductSort>(
            tooltip: 'Sort products',
            icon: const Icon(Icons.sort_rounded),
            onSelected: (s) => setState(() => _sortOrder = s),
            itemBuilder: (_) => const [
              PopupMenuItem(value: ProductSort.nameAsc, child: Text('Name (A → Z)')),
              PopupMenuItem(value: ProductSort.nameDesc, child: Text('Name (Z → A)')),
              PopupMenuItem(value: ProductSort.stockAsc, child: Text('Stock (Lowest first)')),
              PopupMenuItem(value: ProductSort.stockDesc, child: Text('Stock (Highest first)')),
              PopupMenuItem(value: ProductSort.priceAsc, child: Text('Price (Lowest first)')),
              PopupMenuItem(value: ProductSort.priceDesc, child: Text('Price (Highest first)')),
            ],
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(isMedical ? 'Add Medicine' : 'Add Product'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (currentBiz != null) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProductFormScreen(businessId: currentBiz.id)),
                  );
                  if (mounted) prodProv.loadProducts(currentBiz.id);
                }
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Metric Filter Tabs (All, Low Stock, Expiring, Expired, Out of Stock)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              border: Border(bottom: BorderSide(color: theme.dividerColor.withAlpha(50))),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _metricTab('All Items', all.length, ProductTabFilter.all, Colors.grey),
                  const SizedBox(width: 8),
                  _metricTab('Low Stock', lowStockCount, ProductTabFilter.lowStock, const Color(0xFFF59E0B)),
                  if (isMedical) ...[
                    const SizedBox(width: 8),
                    _metricTab('Expiring Soon', expiringCount, ProductTabFilter.expiring, const Color(0xFF8B5CF6)),
                    const SizedBox(width: 8),
                    _metricTab('Expired', expiredCount, ProductTabFilter.expired, const Color(0xFFEF4444)),
                  ],
                  const SizedBox(width: 8),
                  _metricTab('Out of Stock', outOfStockCount, ProductTabFilter.outOfStock, const Color(0xFFDC2626)),
                ],
              ),
            ),
          ),

          // 2. Search Bar + Category Ribbon with Mouse Drag & Wheel Support
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: isMedical
                          ? 'Search by medicine name, salt, brand, SKU or barcode...'
                          : 'Search by product name, brand, SKU or barcode...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                if (currentBiz != null) prodProv.setSearchQuery(currentBiz.id, '');
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (q) {
                      if (currentBiz != null) prodProv.setSearchQuery(currentBiz.id, q);
                    },
                  ),
                ),
              ],
            ),
          ),

          // 3. Category Horizontal Ribbon
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 26, minHeight: 28),
                  tooltip: 'Scroll Left',
                  onPressed: () {
                    if (_categoryScrollCtrl.hasClients) {
                      _categoryScrollCtrl.animateTo(
                        (_categoryScrollCtrl.offset - 160).clamp(0.0, _categoryScrollCtrl.position.maxScrollExtent),
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                ),
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
                      height: 34,
                      child: ListView(
                        controller: _categoryScrollCtrl,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: const Text('All Categories', style: TextStyle(fontSize: 12)),
                              selected: prodProv.selectedCategoryId == 'all',
                              selectedColor: theme.colorScheme.primary,
                              backgroundColor: theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              checkmarkColor: Colors.white,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: prodProv.selectedCategoryId == 'all' ? FontWeight.w700 : FontWeight.w500,
                                color: prodProv.selectedCategoryId == 'all'
                                    ? Colors.white
                                    : (theme.brightness == Brightness.dark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A)),
                              ),
                              side: BorderSide(
                                color: prodProv.selectedCategoryId == 'all'
                                    ? theme.colorScheme.primary
                                    : (theme.brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                width: 1,
                              ),
                              onSelected: (_) {
                                if (currentBiz != null) prodProv.setCategory(currentBiz.id, 'all');
                              },
                            ),
                          ),
                          ...prodProv.categories.map((cat) {
                            final isSel = prodProv.selectedCategoryId == cat.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(cat.name, style: const TextStyle(fontSize: 12)),
                                selected: isSel,
                                selectedColor: theme.colorScheme.primary,
                                backgroundColor: theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                checkmarkColor: Colors.white,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                  color: isSel
                                      ? Colors.white
                                      : (theme.brightness == Brightness.dark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A)),
                                ),
                                side: BorderSide(
                                  color: isSel
                                      ? theme.colorScheme.primary
                                      : (theme.brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                  width: 1,
                                ),
                                onSelected: (_) {
                                  if (currentBiz != null) prodProv.setCategory(currentBiz.id, cat.id);
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 26, minHeight: 28),
                  tooltip: 'Scroll Right',
                  onPressed: () {
                    if (_categoryScrollCtrl.hasClients) {
                      _categoryScrollCtrl.animateTo(
                        (_categoryScrollCtrl.offset + 160).clamp(0.0, _categoryScrollCtrl.position.maxScrollExtent),
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 4. Products List or Dense Table
          Expanded(
            child: prodProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.inventory_2_outlined,
                        title: 'No Products Match Criteria',
                        description: 'Adjust your search query, status filters, or add a new item.',
                        actionLabel: isMedical ? 'Add Medicine' : 'Add Product',
                        onAction: () {
                          if (currentBiz != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ProductFormScreen(businessId: currentBiz.id)),
                            );
                          }
                        },
                      )
                    : _isTableView
                        ? _buildDenseTable(context, filtered, symbol, isMedical)
                        : _buildCardList(context, filtered, symbol, isMedical),
          ),
        ],
      ),
    );
  }

  Widget _metricTab(String title, int count, ProductTabFilter filter, Color accent) {
    final isSelected = _tabFilter == filter;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _tabFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? accent.withAlpha(25) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accent : Theme.of(context).dividerColor.withAlpha(60),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? accent : Theme.of(context).colorScheme.onSurface.withAlpha(170),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected ? accent : Colors.grey.withAlpha(40),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withAlpha(160),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardList(BuildContext context, List<Product> products, String symbol, bool isMedical) {
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: products.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final p = products[index];
        return _ProductCardItem(
          product: p,
          symbol: symbol,
          isMedical: isMedical,
          onTap: () => ProductDetailDialog.show(
            context,
            product: p,
            symbol: symbol,
            onUpdated: () {
              final biz = context.read<BusinessProvider>().currentBusiness;
              if (biz != null) context.read<ProductProvider>().loadProducts(biz.id);
            },
          ),
          onEdit: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProductFormScreen(businessId: p.businessId, product: p)),
            );
            if (context.mounted) {
              final biz = context.read<BusinessProvider>().currentBusiness;
              if (biz != null) context.read<ProductProvider>().loadProducts(biz.id);
            }
          },
          onDelete: () => _confirmDelete(p),
        );
      },
    );
  }

  Widget _buildDenseTable(BuildContext context, List<Product> products, String symbol, bool isMedical) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowHeight: 40,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 56,
          columns: [
            DataColumn(label: Text(isMedical ? 'Medicine Name' : 'Product Name', style: const TextStyle(fontWeight: FontWeight.w800))),
            const DataColumn(label: Text('Brand / Salt', style: TextStyle(fontWeight: FontWeight.w800))),
            const DataColumn(label: Text('SKU / Barcode', style: TextStyle(fontWeight: FontWeight.w800))),
            const DataColumn(label: Text('Stock Level', style: TextStyle(fontWeight: FontWeight.w800))),
            const DataColumn(label: Text('Cost Price', style: TextStyle(fontWeight: FontWeight.w800))),
            const DataColumn(label: Text('Selling Price', style: TextStyle(fontWeight: FontWeight.w800))),
            const DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w800))),
            const DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w800))),
          ],
          rows: products.map((p) {
            final salt = p.metadata['generic_name'] ?? p.metadata['composition'] ?? p.brand;
            return DataRow(
              cells: [
                DataCell(
                  InkWell(
                    onTap: () => ProductDetailDialog.show(context, product: p, symbol: symbol),
                    child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                DataCell(Text(salt.toString().isNotEmpty ? salt.toString() : '—', style: const TextStyle(fontSize: 12))),
                DataCell(Text(p.barcode.isNotEmpty ? p.barcode : p.sku, style: const TextStyle(fontSize: 11.5))),
                DataCell(
                  Text(
                    '${p.stockQty.toInt()} ${p.unit}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: p.stockQty <= 0
                          ? const Color(0xFFEF4444)
                          : (p.isLowStock ? const Color(0xFFF59E0B) : theme.colorScheme.onSurface),
                    ),
                  ),
                ),
                DataCell(Text(CurrencyFormatter.format(p.purchasePrice, symbol: symbol))),
                DataCell(Text(CurrencyFormatter.format(p.sellingPrice, symbol: symbol), style: const TextStyle(fontWeight: FontWeight.w700))),
                DataCell(
                  p.stockQty <= 0
                      ? const AppBadge(label: 'Out of Stock', type: BadgeType.error)
                      : (p.isLowStock
                          ? const AppBadge(label: 'Low Stock', type: BadgeType.warning)
                          : const AppBadge(label: 'In Stock', type: BadgeType.success)),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.info_outline_rounded, size: 18),
                        tooltip: 'Details',
                        onPressed: () => ProductDetailDialog.show(context, product: p, symbol: symbol),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        tooltip: 'Edit',
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ProductFormScreen(businessId: p.businessId, product: p)),
                          );
                          if (context.mounted) {
                            final biz = context.read<BusinessProvider>().currentBusiness;
                            if (biz != null) context.read<ProductProvider>().loadProducts(biz.id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ProductCardItem extends StatelessWidget {
  final Product product;
  final String symbol;
  final bool isMedical;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCardItem({
    required this.product,
    required this.symbol,
    required this.isMedical,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = product;
    final meta = p.metadata;

    final salt = meta['generic_name'] ?? meta['composition'] ?? '';
    final dosage = meta['dosage_form'] ?? '';
    final batches = (meta['batches'] as List<dynamic>?) ?? [];
    final rack = meta['rack_location'] ?? meta['shelf'] ?? '';

    final isOutOfStock = p.stockQty <= 0;
    final isLow = p.isLowStock && !isOutOfStock;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withAlpha(55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product / Medicine Icon Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isMedical ? Icons.medication_rounded : Icons.inventory_2_rounded,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // Main Info Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.name,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isOutOfStock)
                            const AppBadge(label: 'Out of Stock', type: BadgeType.error)
                          else if (isLow)
                            const AppBadge(label: 'Low Stock', type: BadgeType.warning)
                          else
                            const AppBadge(label: 'In Stock', type: BadgeType.success),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Brand / Salt / Dosage subtitle
                      Text(
                        [
                          if (p.brand.isNotEmpty) p.brand,
                          if (salt.toString().isNotEmpty) salt.toString(),
                          if (dosage.toString().isNotEmpty) dosage.toString().toUpperCase(),
                        ].join(' • '),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withAlpha(150),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Badges row: Stock, Batches, Rack
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _chip(
                            Icons.inventory_2_outlined,
                            '${p.stockQty.toInt()} ${p.unit}',
                            isOutOfStock
                                ? const Color(0xFFEF4444)
                                : (isLow ? const Color(0xFFF59E0B) : theme.colorScheme.onSurface.withAlpha(180)),
                          ),
                          if (batches.isNotEmpty)
                            _chip(Icons.qr_code_rounded, '${batches.length} batch(es)', const Color(0xFF6366F1)),
                          if (rack.toString().isNotEmpty)
                            _chip(Icons.shelves, 'Rack: $rack', Colors.teal),
                          if (p.taxRate > 0)
                            _chip(Icons.receipt_outlined, '${p.taxRate.toStringAsFixed(0)}% GST', Colors.grey),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                // Price and Menu
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(p.sellingPrice, symbol: symbol),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    Text(
                      'Cost: ${CurrencyFormatter.format(p.purchasePrice, symbol: symbol)}',
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withAlpha(130)),
                    ),
                    const SizedBox(height: 6),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey),
                      onSelected: (val) {
                        if (val == 'details') onTap();
                        if (val == 'edit') onEdit();
                        if (val == 'delete') onDelete();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'details',
                          child: Row(children: [Icon(Icons.info_outline_rounded, size: 17), SizedBox(width: 8), Text('Inspect Details')]),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [Icon(Icons.edit_rounded, size: 17), SizedBox(width: 8), Text('Edit Product')]),
                        ),
                        PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [Icon(Icons.delete_outline_rounded, size: 17, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))]),
                        ),
                      ],
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

  Widget _chip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(16),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
