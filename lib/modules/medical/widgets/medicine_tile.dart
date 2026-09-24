import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/product.dart';
import '../../../providers/business_provider.dart';
import '../../../providers/cart_provider.dart';
import '../medical_batch_analyzer.dart';
import '../medical_palette.dart';

/// Layout variant for the medicine catalog tile.
enum MedicineTileLayout { grid, list }

/// Pharmacy-flavoured catalogue tile used inside the POS grid/list.
///
/// Surfaces the details a dispenser actually scans for — generic name, batch,
/// expiry status, Rx flag and live stock — instead of a plain product name.
class MedicineTile extends StatelessWidget {
  final Product product;
  final MedicineTileLayout layout;
  final double qtyInCart;
  final double freeQtyInCart;
  final VoidCallback onAdd;
  final VoidCallback onCardTap;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback? onBatchPick;

  const MedicineTile({
    super.key,
    required this.product,
    required this.layout,
    required this.qtyInCart,
    this.freeQtyInCart = 0,
    required this.onAdd,
    required this.onCardTap,
    required this.onIncrement,
    required this.onDecrement,
    this.onBatchPick,
  });

  @override
  Widget build(BuildContext context) {
    if (layout == MedicineTileLayout.list) {
      return _buildList(context);
    }
    return _buildGrid(context);
  }

  Widget _buildGrid(BuildContext context) {
    final theme = Theme.of(context);
    final symbol = context.watch<BusinessProvider>().currentBusiness?.currencySymbol ?? '₹';
    final info = MedicalBatchAnalyzer.expiryInfo(product);
    final isRx = product.metadata['schedule_h'] == true || product.metadata['is_narcotic'] == true;
    final status = _StockStatus.of(product);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: AppTokens.borderLG,
        border: Border.all(
          color: status.isOut ? MedicalPalette.critical.withAlpha(90) : theme.dividerColor,
          width: status.isOut ? 1.4 : 1,
        ),
        boxShadow: AppTokens.shadowSM,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppTokens.borderLG,
        child: InkWell(
          borderRadius: AppTokens.borderLG,
          onTap: onCardTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: status chip + Rx badge
                Row(
                  children: [
                    Expanded(child: _StatusChip(status: status, unit: product.unit)),
                    if (isRx) ...[
                      const SizedBox(width: 4),
                      const _RxBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                // Name + generic
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, height: 1.2),
                ),
                const SizedBox(height: 2),
                Text(
                  (product.metadata['generic_name'] as String?) ?? product.brand,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withAlpha(150),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                // Batch / expiry chip
                if (info != null)
                  _ExpiryChip(info: info, onPick: onBatchPick)
                else
                  _NoBatchChip(onPick: onBatchPick),
                const Spacer(),
                const SizedBox(height: 8),
                // Price row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(product.sellingPrice, symbol: symbol, decimalDigits: 0),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: MedicalPalette.primaryDark,
                      ),
                    ),
                    if (product.mrp > product.sellingPrice) ...[
                      const SizedBox(width: 4),
                      Text(
                        CurrencyFormatter.format(product.mrp, symbol: symbol, decimalDigits: 0),
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          fontSize: 10.5,
                          color: theme.colorScheme.onSurface.withAlpha(140),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                _AddOrStepper(
                  qtyInCart: qtyInCart,
                  freeQtyInCart: freeQtyInCart,
                  disabled: status.isOut,
                  onAdd: onAdd,
                  onIncrement: onIncrement,
                  onDecrement: onDecrement,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final theme = Theme.of(context);
    final symbol = context.watch<BusinessProvider>().currentBusiness?.currencySymbol ?? '₹';
    final info = MedicalBatchAnalyzer.expiryInfo(product);
    final isRx = product.metadata['schedule_h'] == true || product.metadata['is_narcotic'] == true;
    final status = _StockStatus.of(product);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: AppTokens.borderMD,
        border: Border.all(
          color: status.isOut ? MedicalPalette.critical.withAlpha(90) : theme.dividerColor,
          width: status.isOut ? 1.4 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppTokens.borderMD,
        child: InkWell(
          borderRadius: AppTokens.borderMD,
          onTap: onCardTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: MedicalPalette.primary.withAlpha(16),
                    borderRadius: AppTokens.borderSM,
                  ),
                  child: Icon(
                    isRx ? Icons.shield_rounded : Icons.medication_rounded,
                    color: MedicalPalette.primary, size: 19,
                  ),
                ),
                const SizedBox(width: AppTokens.spaceMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                            ),
                          ),
                          if (isRx) ...[
                            const SizedBox(width: 6),
                            const _RxBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (info != null)
                            _MiniExpiryLabel(info: info)
                          else
                            Text(
                              'No batch',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withAlpha(140),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          Text(
                            'Stock: ${product.stockQty.toStringAsFixed(0)} ${product.unit}',
                            style: TextStyle(
                              fontSize: 11,
                              color: status.color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTokens.spaceSM),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(product.sellingPrice, symbol: symbol, decimalDigits: 0),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                        color: MedicalPalette.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _AddOrStepper(
                      qtyInCart: qtyInCart,
                      freeQtyInCart: freeQtyInCart,
                      compact: true,
                      disabled: status.isOut,
                      onAdd: onAdd,
                      onIncrement: onIncrement,
                      onDecrement: onDecrement,
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
}

/// Derived stock condition for a medicine.
class _StockStatus {
  final bool isOut;
  final bool isLow;
  final double qty;

  const _StockStatus._({required this.isOut, required this.isLow, required this.qty});

  static _StockStatus of(Product p) {
    if (p.isOutOfStock) return _StockStatus._(isOut: true, isLow: true, qty: p.stockQty);
    if (p.isLowStock) return _StockStatus._(isOut: false, isLow: true, qty: p.stockQty);
    return _StockStatus._(isOut: false, isLow: false, qty: p.stockQty);
  }

  Color get color {
    if (isOut) return MedicalPalette.critical;
    if (isLow) return MedicalPalette.warning;
    return MedicalPalette.safe;
  }

  String get label {
    if (isOut) return 'Out of stock';
    if (isLow) return 'Low stock';
    return 'In stock';
  }
}

class _StatusChip extends StatelessWidget {
  final _StockStatus status;
  final String unit;

  const _StatusChip({required this.status, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withAlpha(18),
        borderRadius: AppTokens.borderSM,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.isOut ? Icons.block_rounded : (status.isLow ? Icons.warning_amber_rounded : Icons.check_circle_rounded),
            size: 11,
            color: status.color,
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              status.isOut ? status.label : '${status.qty.toStringAsFixed(0)} $unit',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: status.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RxBadge extends StatelessWidget {
  const _RxBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: MedicalPalette.primary,
        borderRadius: AppTokens.borderSM,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_rounded, size: 9.5, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            'Rx',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpiryChip extends StatelessWidget {
  final ProductExpiryInfo info;
  final VoidCallback? onPick;

  const _ExpiryChip({required this.info, this.onPick});

  @override
  Widget build(BuildContext context) {
    final color = info.severity.color;

    return InkWell(
      onTap: onPick,
      borderRadius: AppTokens.borderSM,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(14),
          borderRadius: AppTokens.borderSM,
          border: Border.all(color: color.withAlpha(45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time_rounded, size: 10, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                info.batchCount > 1
                    ? '${info.nearestBatch} • ${info.daysLabel} • +${info.batchCount - 1}'
                    : '${info.nearestBatch} • ${info.daysLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniExpiryLabel extends StatelessWidget {
  final ProductExpiryInfo info;

  const _MiniExpiryLabel({required this.info});

  @override
  Widget build(BuildContext context) {
    final color = info.severity.color;
    return Text(
      '${info.nearestBatch} • ${DateFormatter.formatShort(info.nearestExpiry)}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: info.isCritical ? color : Theme.of(context).colorScheme.onSurface.withAlpha(160),
      ),
    );
  }
}

class _NoBatchChip extends StatelessWidget {
  final VoidCallback? onPick;

  const _NoBatchChip({this.onPick});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      borderRadius: AppTokens.borderSM,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: MedicalPalette.warning.withAlpha(14),
          borderRadius: AppTokens.borderSM,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle_outline_rounded, size: 10, color: MedicalPalette.warning),
            const SizedBox(width: 4),
            Text(
              'Add batch',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: MedicalPalette.warning,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddOrStepper extends StatelessWidget {
  final double qtyInCart;
  final double freeQtyInCart;
  final bool compact;
  final bool disabled;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _AddOrStepper({
    required this.qtyInCart,
    this.freeQtyInCart = 0,
    this.compact = false,
    this.disabled = false,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (qtyInCart <= 0) {
      return SizedBox(
        height: compact ? 30 : 32,
        width: double.infinity,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            foregroundColor: disabled ? theme.colorScheme.onSurface.withAlpha(110) : MedicalPalette.primary,
            side: BorderSide(
              color: disabled ? theme.dividerColor : MedicalPalette.primary,
            ),
            shape: RoundedRectangleBorder(borderRadius: AppTokens.borderMD),
          ),
          onPressed: disabled ? null : onAdd,
          icon: Icon(disabled ? Icons.remove_shopping_cart_rounded : Icons.add_rounded, size: 15),
          label: Text(
            disabled ? 'Unavailable' : 'Add',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ),
      );
    }

    return Container(
      height: compact ? 30 : 32,
      decoration: BoxDecoration(
        color: MedicalPalette.primary,
        borderRadius: AppTokens.borderMD,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_rounded, size: 15, color: Colors.white),
            onPressed: onDecrement,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
          Text(
            freeQtyInCart > 0
                ? '${qtyInCart.toStringAsFixed(0)}+${freeQtyInCart.toStringAsFixed(0)}f'
                : qtyInCart.toStringAsFixed(0),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 15, color: Colors.white),
            onPressed: onIncrement,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

/// Reads the live cart quantity for a product id (helper for callers).
double cartQtyOf(BuildContext context, String productId) {
  return context.read<CartProvider>().getItemQuantity(productId);
}
