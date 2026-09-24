import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/cart_item.dart';
import '../../../modules/business_type.dart';
import '../../../modules/medical/screens/batch_picker_sheet.dart';
import '../../../modules/medical/screens/medical_dispense_dialog.dart';
import '../../../providers/app_provider.dart';
import '../../../providers/business_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../core/utils/permissions.dart';

/// Inline editor dialog for a single cart line: quantity, free-scheme units, line
/// discount and (for pharmacy) batch selection.
///
/// Everything here flows through [CartProvider], which remains the only place
/// that mutates cart state.
class CartLineEditorSheet extends StatefulWidget {
  final int index;

  const CartLineEditorSheet({super.key, required this.index});

  static Future<void> show(BuildContext context, int index) {
    final bizType = context.read<BusinessProvider>().currentBusinessType;
    final cart = context.read<CartProvider>();
    if (index < cart.items.length && bizType == BusinessType.medical) {
      final it = cart.items[index];
      return MedicalDispenseDialog.show(
        context,
        product: it.product,
        cartIndex: index,
        initialBatch: it.selectedBatch,
      );
    }

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: AppTokens.borderLG),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: CartLineEditorSheet(index: index),
        ),
      ),
    );
  }

  @override
  State<CartLineEditorSheet> createState() => _CartLineEditorSheetState();
}

class _CartLineEditorSheetState extends State<CartLineEditorSheet> {
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _freeCtrl;
  late final TextEditingController _discCtrl;

  @override
  void initState() {
    super.initState();
    final item = context.read<CartProvider>().items[widget.index];
    _qtyCtrl = TextEditingController(text: item.quantity.toStringAsFixed(0));
    _freeCtrl = TextEditingController(text: item.freeQuantity.toStringAsFixed(0));
    _discCtrl = TextEditingController(text: item.discountAmount.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _freeCtrl.dispose();
    _discCtrl.dispose();
    super.dispose();
  }

  void _commitAndClose() {
    final cart = context.read<CartProvider>();
    final qty = double.tryParse(_qtyCtrl.text) ?? 1.0;
    final free = double.tryParse(_freeCtrl.text) ?? 0.0;
    final disc = double.tryParse(_discCtrl.text) ?? 0.0;

    cart.setItemQuantity(item.product.id, qty);
    cart.setFreeQuantity(item.product.id, free);
    cart.updateItemDiscount(widget.index, disc);
    Navigator.pop(context);
  }

  CartItem get item => context.read<CartProvider>().items[widget.index];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = context.watch<CartProvider>();
    final symbol = context.read<BusinessProvider>().currentBusiness?.currencySymbol ?? '₹';
    final bizType = context.read<BusinessProvider>().currentBusinessType;
    final user = context.read<AppProvider>().currentUser;
    final canDiscount = Permissions.userCan(user, Capability.billing) &&
        (user.isManager || user.canDiscount);

    if (widget.index >= cart.items.length) {
      return const SizedBox.shrink();
    }
    final it = cart.items[widget.index];
    final lineValue = it.unitPrice * it.quantity;
    final savings = it.discountAmount + it.freeValue;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
      padding: EdgeInsets.fromLTRB(
        AppTokens.spaceLG,
        AppTokens.spaceMD,
        AppTokens.spaceLG,
        MediaQuery.viewInsetsOf(context).bottom + AppTokens.spaceLG,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  it.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${it.unitPrice.toStringAsFixed(2)} / ${it.product.unit} • Tax ${it.taxRate}%',
            style: TextStyle(
              fontSize: 12.5,
              color: theme.colorScheme.onSurface.withAlpha(160),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (it.selectedBatch != null) ...[
            const SizedBox(height: 4),
            Text(
              'Batch: ${it.selectedBatch}${it.batchExpiry != null ? ' • Exp ${it.batchExpiry}' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: AppTokens.spaceLG),

          // Quantity + free quantity row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantity (${it.product.unit})',
                    prefixIcon: const Icon(Icons.add_shopping_cart_rounded),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.spaceSM),
              Expanded(
                child: TextField(
                  controller: _freeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Free Qty (scheme)',
                    prefixIcon: Icon(Icons.card_giftcard_rounded),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spaceMD),

          // Line discount (permission gated)
          TextField(
            controller: _discCtrl,
            keyboardType: TextInputType.number,
            enabled: canDiscount,
            decoration: InputDecoration(
              labelText: 'Line Discount ($symbol)',
              prefixIcon: const Icon(Icons.local_offer_rounded),
              isDense: true,
              helperText: canDiscount ? null : 'Managers & cashiers may apply discounts',
            ),
          ),
          const SizedBox(height: AppTokens.spaceMD),

          // Batch re-pick (pharmacy only)
          if (bizType == BusinessType.medical)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: AppTokens.borderMD),
                ),
                icon: const Icon(Icons.swap_horiz_rounded),
                label: Text(it.selectedBatch != null
                    ? 'Change Batch (${it.selectedBatch})'
                    : 'Choose Batch (FEFO)'),
                onPressed: () async {
                  await BatchPickerSheet.show(
                    context,
                    product: it.product,
                    selectedBatch: it.selectedBatch,
                    onSelected: (batchNo, expiry) {
                      context.read<CartProvider>().setItemBatch(it.product.id, batchNo, expiry);
                    },
                  );
                },
              ),
            ),

          const SizedBox(height: AppTokens.spaceMD),
          // Live preview of the line math
          Container(
            padding: const EdgeInsets.all(AppTokens.spaceMD),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(8),
              borderRadius: AppTokens.borderMD,
            ),
            child: Column(
              children: [
                _PreviewRow(
                  label: 'Line value',
                  value: CurrencyFormatter.format(lineValue, symbol: symbol),
                ),
                if (savings > 0) ...[
                  const SizedBox(height: 4),
                  _PreviewRow(
                    label: 'You save',
                    value: '- ${CurrencyFormatter.format(savings, symbol: symbol)}',
                    valueColor: const Color(0xFF059669),
                  ),
                ],
                const Divider(height: 12),
                _PreviewRow(
                  label: 'Line total',
                  value: CurrencyFormatter.format(it.total, symbol: symbol),
                  bold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.spaceLG),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: AppTokens.borderMD),
                  ),
                  onPressed: () {
                    context.read<CartProvider>().removeItem(widget.index);
                    Navigator.pop(context);
                  },
                  child: const Text('Remove Item', style: TextStyle(color: Color(0xFFDC2626))),
                ),
              ),
              const SizedBox(width: AppTokens.spaceSM),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: AppTokens.borderMD),
                  ),
                  onPressed: _commitAndClose,
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _PreviewRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(bold ? 220 : 160),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 15 : 13,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
