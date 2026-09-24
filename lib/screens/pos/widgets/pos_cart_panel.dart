import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../data/models/cart_item.dart';
import '../../../modules/business_registry.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/business_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/inventory_provider.dart';
import '../checkout_dialog.dart';
import '../../estimates/widgets/create_estimate_dialog.dart';
import 'cart_line_editor_sheet.dart';
import 'customer_picker_sheet.dart';

/// Reusable cart column: customer, line items, totals, discount and checkout.
///
/// Rendered as the persistent right pane on wide screens and as the body of
/// the swipe-up cart sheet on phones — one widget, two responsive homes.
class PosCartPanel extends StatelessWidget {
  /// When true the panel is embedded in a side column (full height available);
  /// when false it is inside a bottom sheet and uses a bounded max height.
  final bool isEmbedded;

  const PosCartPanel({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartProv = context.watch<CartProvider>();
    final bizProv = context.watch<BusinessProvider>();
    final appProv = context.watch<AppProvider>();
    final currentBiz = bizProv.currentBusiness;
    final symbol = currentBiz?.currencySymbol ?? '₹';
    final bizModule = currentBiz != null ? BusinessModuleRegistry.getModule(currentBiz.type) : null;
    final canDiscount = appProv.currentUser.canDiscount;

    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PanelHeader(cartProv: cartProv, isEmbedded: isEmbedded),
        const Divider(height: 1),
        // Customer selector
        _CustomerRow(symbol: symbol),
        const Divider(height: 1),
        if (cartProv.items.isEmpty)
          const Expanded(child: _EmptyCart())
        else ...[
          Expanded(child: _CartList(cartProv: cartProv, bizModule: bizModule, symbol: symbol)),
          const Divider(height: 1),
          _TotalsBlock(
            cartProv: cartProv,
            symbol: symbol,
            canDiscount: canDiscount,
            theme: theme,
            isEmbedded: isEmbedded,
          ),
        ],
      ],
    );

    if (isEmbedded) {
      return Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          border: Border(left: BorderSide(color: theme.dividerColor)),
        ),
        child: SafeArea(child: content),
      );
    }

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.86),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(child: content),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final CartProvider cartProv;
  final bool isEmbedded;

  const _PanelHeader({required this.cartProv, required this.isEmbedded});

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text('Remove all items and reset current bill?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () {
              cartProv.clearCart();
              Navigator.pop(ctx);
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTokens.spaceLG, AppTokens.spaceMD, AppTokens.spaceSM, AppTokens.spaceSM),
      child: Row(
        children: [
          Icon(Icons.shopping_cart_rounded, color: theme.colorScheme.primary, size: 19),
          const SizedBox(width: AppTokens.spaceSM),
          Text(
            'Current Bill',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(width: AppTokens.spaceSM),
          AppBadge(label: '${cartProv.itemCount}', type: BadgeType.info),
          const Spacer(),
          if (cartProv.items.isNotEmpty)
            IconButton(
              tooltip: 'Clear Cart',
              icon: Icon(Icons.delete_sweep_outlined, size: 20, color: theme.colorScheme.error),
              onPressed: () => _confirmClear(context),
            ),
          if (!isEmbedded)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  final String symbol;

  const _CustomerRow({required this.symbol});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = context.watch<CartProvider>();
    final customer = cart.selectedCustomer;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceLG, vertical: AppTokens.spaceMD),
      child: Row(
        children: [
          InkWell(
            onTap: () async {
              final picked = await CustomerPickerSheet.show(context);
              if (context.mounted) {
                context.read<CartProvider>().setCustomer(picked);
              }
            },
            borderRadius: AppTokens.borderMD,
            child: CircleAvatar(
              radius: 15,
              backgroundColor: (customer != null
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withAlpha(40))
                  .withAlpha(22),
              child: Icon(
                customer != null ? Icons.person_rounded : Icons.person_add_alt_rounded,
                size: 16,
                color: customer != null ? theme.colorScheme.primary : theme.colorScheme.onSurface.withAlpha(160),
              ),
            ),
          ),
          const SizedBox(width: AppTokens.spaceMD),
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await CustomerPickerSheet.show(context);
                if (context.mounted) {
                  context.read<CartProvider>().setCustomer(picked);
                }
              },
              borderRadius: AppTokens.borderMD,
              child: customer != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          customer.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                        ),
                        if (customer.phone.isNotEmpty || customer.balanceDue > 0)
                          Text(
                            customer.balanceDue > 0
                                ? '${customer.phone} • Due ${CurrencyFormatter.format(customer.balanceDue, symbol: symbol, decimalDigits: 0)}'
                                : customer.phone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: customer.balanceDue > 0
                                  ? const Color(0xFFD97706)
                                  : theme.colorScheme.onSurface.withAlpha(150),
                              fontWeight: customer.balanceDue > 0 ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                      ],
                    )
                  : Text(
                      'Walk-in customer (tap or [F2])',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withAlpha(160),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          if (customer != null)
            IconButton(
              tooltip: 'Remove customer',
              icon: Icon(Icons.close_rounded, size: 18, color: theme.colorScheme.onSurface.withAlpha(140)),
              onPressed: () => cart.setCustomer(null),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            )
          else
            IconButton(
              tooltip: 'Select customer (F2)',
              icon: Icon(Icons.person_search_rounded, size: 18, color: theme.colorScheme.primary),
              onPressed: () async {
                final picked = await CustomerPickerSheet.show(context);
                if (context.mounted) {
                  context.read<CartProvider>().setCustomer(picked);
                }
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spaceXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_checkout_rounded,
              size: 46,
              color: theme.colorScheme.onSurface.withAlpha(70),
            ),
            const SizedBox(height: AppTokens.spaceMD),
            Text(
              'Cart is empty',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: theme.colorScheme.onSurface.withAlpha(180),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Search or scan a medicine above to start billing.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: theme.colorScheme.onSurface.withAlpha(150),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartList extends StatelessWidget {
  final CartProvider cartProv;
  final BusinessModuleInterface? bizModule;
  final String symbol;

  const _CartList({
    required this.cartProv,
    required this.bizModule,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: AppTokens.spaceSM),
      itemCount: cartProv.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = cartProv.items[index];
        return Dismissible(
          key: Key('${item.product.id}_${item.selectedBatch}_${item.packagingType}_$index'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withAlpha(15),
              borderRadius: AppTokens.borderMD,
            ),
            child: const Icon(Icons.delete_rounded, color: Color(0xFFDC2626)),
          ),
          onDismissed: (_) {
            final removed = cartProv.removeItem(index);
            if (removed != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Removed ${removed.product.name}'),
                  action: SnackBarAction(
                    label: 'UNDO',
                    onPressed: () => cartProv.insertItem(index, removed),
                  ),
                ),
              );
            }
          },
          child: _CartLine(
            key: ValueKey('cart_line_${item.product.id}_${item.selectedBatch}_${item.packagingType}_$index'),
            index: index,
            item: item,
            symbol: symbol,
            bizModule: bizModule,
            onEdit: () => CartLineEditorSheet.show(context, index),
            onIncrement: () => cartProv.incrementQuantityByIndex(index),
            onDecrement: () => cartProv.decrementQuantityByIndex(index),
            onDelete: () => cartProv.removeItem(index),
          ),
        );
      },
    );
  }
}

class _CartLine extends StatefulWidget {
  final int index;
  final CartItem item;
  final String symbol;
  final BusinessModuleInterface? bizModule;
  final VoidCallback onEdit;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;

  const _CartLine({
    super.key,
    required this.index,
    required this.item,
    required this.symbol,
    required this.bizModule,
    required this.onEdit,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
  });

  @override
  State<_CartLine> createState() => _CartLineState();
}

class _CartLineState extends State<_CartLine> {
  late TextEditingController _priceCtrl;
  late TextEditingController _discCtrl;

  @override
  void initState() {
    super.initState();
    _priceCtrl = TextEditingController(text: _formatNum(widget.item.unitPrice));
    _discCtrl = TextEditingController(text: _formatNum(widget.item.discountAmount));
  }

  @override
  void didUpdateWidget(covariant _CartLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentP = double.tryParse(_priceCtrl.text);
    if (currentP == null || (currentP - widget.item.unitPrice).abs() > 0.001) {
      _priceCtrl.text = _formatNum(widget.item.unitPrice);
    }
    final currentD = double.tryParse(_discCtrl.text);
    if (currentD == null || (currentD - widget.item.discountAmount).abs() > 0.001) {
      _discCtrl.text = _formatNum(widget.item.discountAmount);
    }
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _discCtrl.dispose();
    super.dispose();
  }

  static String _formatNum(double val) {
    return val % 1 == 0 ? val.toStringAsFixed(0) : val.toStringAsFixed(2);
  }

  IconData _iconForCartItem(CartItem it) {
    final form = it.dosageForm?.toLowerCase() ?? '';
    final name = it.product.name.toLowerCase();
    final unit = it.product.unit.toLowerCase();

    if (form == 'device' || name.contains('monitor') || name.contains('meter') || name.contains('bp ') || name.contains('thermometer') || unit == 'pc') {
      return Icons.health_and_safety_rounded;
    }
    if (form == 'cream' || name.contains('cream') || name.contains('betadine') || name.contains('ointment') || unit == 'tube') {
      return Icons.science_outlined;
    }
    if (form == 'syrup' || name.contains('syrup') || unit == 'bottle') {
      return Icons.liquor_rounded;
    }
    if (form == 'injection' || name.contains('injection') || name.contains('insulin') || unit == 'pen') {
      return Icons.vaccines_rounded;
    }
    if (form == 'inhaler' || name.contains('inhaler') || name.contains('respule')) {
      return Icons.air_rounded;
    }
    if (form == 'capsule' || name.contains('capsule') || name.contains('cap')) {
      return Icons.medication_liquid_rounded;
    }
    if (form == 'tablet' || name.contains('tablet') || name.contains('tab') || unit == 'strip') {
      return Icons.medication_rounded;
    }
    return Icons.medication_rounded;
  }

  Color _colorForCartItem(CartItem it) {
    final form = it.dosageForm?.toLowerCase() ?? '';
    final name = it.product.name.toLowerCase();

    if (form == 'device' || name.contains('monitor') || name.contains('meter') || name.contains('bp ')) {
      return const Color(0xFF6366F1); // Omron purple/blue in screenshot
    }
    if (form == 'cream' || name.contains('betadine') || name.contains('cream')) {
      return const Color(0xFF10B981); // Betadine green in screenshot
    }
    if (form == 'capsule') return const Color(0xFFF59E0B);
    if (form == 'syrup') return const Color(0xFF06B6D4);
    if (form == 'injection') return const Color(0xFFEF4444);
    if (form == 'inhaler') return const Color(0xFF8B5CF6);
    return const Color(0xFF0284C7);
  }

  String _buildSubtitle(CartItem it, String symbol) {
    final parts = <String>[];
    if (it.selectedBatch != null && it.selectedBatch!.isNotEmpty) {
      parts.add(it.selectedBatch!);
    }
    if (it.batchExpiry != null && it.batchExpiry!.isNotEmpty) {
      parts.add('exp ${it.batchExpiry!}');
    }
    if (it.packagingDesc != null && it.packagingDesc!.isNotEmpty) {
      parts.add(it.packagingDesc!);
    } else {
      final unitStr = it.product.unit.isNotEmpty ? '/${it.product.unit}' : '';
      parts.add('${CurrencyFormatter.format(it.unitPrice, symbol: symbol, decimalDigits: it.unitPrice % 1 == 0 ? 0 : 2)}$unitStr');
    }
    if (it.taxRate > 0) {
      parts.add('${it.taxRate.toStringAsFixed(0)}% tax');
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final it = widget.item;
    final itemColor = _colorForCartItem(it);
    final itemIcon = _iconForCartItem(it);
    final subtitle = _buildSubtitle(it, widget.symbol);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withAlpha(45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Icon + Name & Subtitle (tappable to open dialog) + Trash icon
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: widget.onEdit,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: itemColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(itemIcon, size: 18, color: itemColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: widget.onEdit,
                      borderRadius: BorderRadius.circular(4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            it.product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, height: 1.2),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withAlpha(155),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (it.freeQuantity > 0) ...[
                            const SizedBox(height: 2),
                            Text(
                              '+ ${it.freeQuantity.toStringAsFixed(0)} free units',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF059669),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove Item',
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 19,
                      color: Color(0xFFEF4444),
                    ),
                    hoverColor: const Color(0xFFEF4444).withAlpha(20),
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                    onPressed: widget.onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Bottom row: [- Qty +]  @  [ Price ]  -  [ Discount ]    ₹Total
              Row(
                children: [
                  // Stepper [- Qty +]
                  Container(
                    height: 28,
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.light
                          ? const Color(0xFFF1F5F9)
                          : theme.colorScheme.onSurface.withAlpha(12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.brightness == Brightness.light
                            ? const Color(0xFFE2E8F0)
                            : theme.colorScheme.onSurface.withAlpha(28),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: widget.onDecrement,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            child: Icon(Icons.remove, size: 13, color: theme.colorScheme.onSurface.withAlpha(190)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Text(
                            it.quantity % 1 == 0
                                ? it.quantity.toStringAsFixed(0)
                                : it.quantity.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: widget.onIncrement,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            child: Icon(Icons.add, size: 13, color: theme.colorScheme.onSurface.withAlpha(190)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),

                  // @ separator
                  Text(
                    '@',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withAlpha(140),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Price Input Box (Single border, no theme outline)
                  Container(
                    height: 28,
                    width: 54,
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.light
                          ? const Color(0xFFF1F5F9)
                          : theme.colorScheme.onSurface.withAlpha(12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.brightness == Brightness.light
                            ? const Color(0xFFCBD5E1)
                            : theme.colorScheme.onSurface.withAlpha(35),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Center(
                      child: TextField(
                        controller: _priceCtrl,
                        textAlign: TextAlign.center,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (val) {
                          final p = double.tryParse(val);
                          if (p != null && p >= 0) {
                            context.read<CartProvider>().updateItemPrice(widget.index, p);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // - separator
                  Text(
                    '-',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface.withAlpha(140),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Discount Input Box (Single border, no theme outline)
                  Container(
                    height: 28,
                    width: 48,
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.light
                          ? const Color(0xFFF1F5F9)
                          : theme.colorScheme.onSurface.withAlpha(12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.brightness == Brightness.light
                            ? const Color(0xFFCBD5E1)
                            : theme.colorScheme.onSurface.withAlpha(35),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Center(
                      child: TextField(
                        controller: _discCtrl,
                        textAlign: TextAlign.center,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (val) {
                          final d = double.tryParse(val);
                          if (d != null && d >= 0) {
                            context.read<CartProvider>().updateItemDiscount(widget.index, d);
                          }
                        },
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Line Total on the right (Expanded + FittedBox guarantees NO overflow!)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          CurrencyFormatter.format(
                            it.total,
                            symbol: widget.symbol,
                            decimalDigits: it.total % 1 == 0 ? 0 : 2,
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14.5,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalsBlock extends StatefulWidget {
  final CartProvider cartProv;
  final String symbol;
  final bool canDiscount;
  final ThemeData theme;
  final bool isEmbedded;

  const _TotalsBlock({
    required this.cartProv,
    required this.symbol,
    required this.canDiscount,
    required this.theme,
    this.isEmbedded = false,
  });

  @override
  State<_TotalsBlock> createState() => _TotalsBlockState();
}

class _TotalsBlockState extends State<_TotalsBlock> {
  final _discCtrl = TextEditingController();

  @override
  void dispose() {
    _discCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = widget.cartProv;
    final theme = widget.theme;
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTokens.spaceLG, AppTokens.spaceSM, AppTokens.spaceLG, AppTokens.spaceLG),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SummaryRow(label: 'Subtotal', value: CurrencyFormatter.format(cart.subtotal, symbol: widget.symbol)),
          if (cart.totalDiscount > 0) ...[
            const SizedBox(height: 3),
            _SummaryRow(
              label: 'Discount',
              value: '- ${CurrencyFormatter.format(cart.totalDiscount, symbol: widget.symbol)}',
              valueColor: const Color(0xFF059669),
            ),
          ],
          if (cart.totalTax > 0) ...[
            const SizedBox(height: 3),
            _SummaryRow(
              label: 'Tax (GST)',
              value: '+ ${CurrencyFormatter.format(cart.totalTax, symbol: widget.symbol)}',
            ),
          ],
          if (cart.roundOff.abs() > 0.001) ...[
            const SizedBox(height: 3),
            _SummaryRow(
              label: 'Round off',
              value: (cart.roundOff >= 0 ? '+ ' : '- ') +
                  CurrencyFormatter.format(cart.roundOff.abs(), symbol: widget.symbol),
            ),
          ],
          const Divider(height: 14),
          // Bill-level discount (permission gated)
          if (widget.canDiscount)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _discCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Bill discount %',
                      prefixIcon: Icon(Icons.local_offer_rounded),
                      isDense: true,
                    ),
                    onChanged: (val) {
                      final pct = double.tryParse(val) ?? 0.0;
                      context.read<CartProvider>().setGlobalDiscount(pct);
                    },
                  ),
                ),
                const SizedBox(width: AppTokens.spaceSM),
                ChoiceChip(
                  label: const Text('0%'),
                  selected: cart.globalDiscountPercent == 0,
                  onSelected: (_) {
                    _discCtrl.clear();
                    context.read<CartProvider>().setGlobalDiscount(0);
                  },
                ),
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: AppTokens.spaceSM),
              child: Row(
                children: [
                  Icon(Icons.lock_outline_rounded, size: 13, color: theme.colorScheme.onSurface.withAlpha(140)),
                  const SizedBox(width: 6),
                  Text(
                    'Discounts require a manager or cashier role',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withAlpha(150),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppTokens.spaceSM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Total Payable', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              Text(
                CurrencyFormatter.format(cart.finalTotal, symbol: widget.symbol),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: primary, letterSpacing: -0.5),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spaceMD),
          // Action Row: Quote + Hold + Checkout
          Row(
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
                  shape: RoundedRectangleBorder(borderRadius: AppTokens.borderMD),
                ),
                icon: const Icon(Icons.request_quote_outlined, size: 18),
                label: const Text('Quote'),
                onPressed: () {
                  if (cart.items.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Add at least one item before generating an estimate.')),
                    );
                    return;
                  }
                  CreateEstimateDialog.show(context);
                },
              ),
              const SizedBox(width: AppTokens.spaceSM),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: AppTokens.borderMD),
                  ),
                  icon: const Icon(Icons.pause_circle_outline_rounded, size: 18),
                  label: const Text('Hold'),
                  onPressed: () async {
                    final biz = context.read<BusinessProvider>().currentBusiness;
                    if (biz == null) return;
                    await cart.holdCurrentBill(biz.id, 'Bill ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}');
                    if (!context.mounted) return;
                    await context.read<InventoryProvider>().loadInventory(biz.id);
                    if (!context.mounted) return;
                    if (!widget.isEmbedded) {
                      Navigator.pop(context);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bill parked — resume anytime from Held Bills.')),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppTokens.spaceSM),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: AppTokens.borderMD),
                  ),
                  icon: const Icon(Icons.check_circle_rounded, size: 19),
                  label: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  onPressed: () {
                    if (!isCheckoutAllowed(context)) return;
                    if (!widget.isEmbedded) {
                      Navigator.pop(context);
                    }
                    CheckoutDialog.show(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool isCheckoutAllowed(BuildContext context) {
    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item before checkout.')),
      );
      return false;
    }
    return true;
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(165),
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
