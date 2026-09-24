import 'package:flutter/material.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/product.dart';

class LooseItemWeightDialog extends StatefulWidget {
  final Product product;
  final Function(double quantityInKg, double calculatedTotal) onConfirm;

  const LooseItemWeightDialog({
    super.key,
    required this.product,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required Product product,
    required Function(double quantityInKg, double calculatedTotal) onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (context) => LooseItemWeightDialog(
        product: product,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<LooseItemWeightDialog> createState() => _LooseItemWeightDialogState();
}

class _LooseItemWeightDialogState extends State<LooseItemWeightDialog> {
  double _weightInKg = 1.0;
  final TextEditingController _ctrl = TextEditingController(text: '1.0');

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _setWeight(double val) {
    setState(() {
      _weightInKg = val;
      _ctrl.text = val.toStringAsFixed( val == val.roundToDouble() ? 1 : 3);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unitPrice = widget.product.sellingPrice;
    final total = _weightInKg * unitPrice;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppTokens.borderXL),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spaceXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withAlpha(25),
                    borderRadius: AppTokens.borderMD,
                  ),
                  child: const Icon(Icons.scale_rounded, color: Color(0xFF16A34A)),
                ),
                const SizedBox(width: AppTokens.spaceMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.product.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      Text('Rate: ₹${unitPrice.toStringAsFixed(2)} / ${widget.product.unit}', style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(150), fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spaceLG),
            // Presets
            Wrap(
              spacing: 8,
              children: [
                ActionChip(label: const Text('250 g'), onPressed: () => _setWeight(0.25)),
                ActionChip(label: const Text('500 g'), onPressed: () => _setWeight(0.50)),
                ActionChip(label: const Text('1.0 kg'), onPressed: () => _setWeight(1.0)),
                ActionChip(label: const Text('2.0 kg'), onPressed: () => _setWeight(2.0)),
                ActionChip(label: const Text('5.0 kg'), onPressed: () => _setWeight(5.0)),
              ],
            ),
            const SizedBox(height: AppTokens.spaceMD),
            TextField(
              controller: _ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (val) {
                final parsed = double.tryParse(val) ?? 0.0;
                setState(() => _weightInKg = parsed);
              },
              decoration: const InputDecoration(
                labelText: 'Enter Exact Weight (kg)',
                suffixText: 'kg',
              ),
            ),
            const SizedBox(height: AppTokens.spaceLG),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withAlpha(15),
                borderRadius: AppTokens.borderMD,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Calculated Price:', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '₹${total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF16A34A)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.spaceLG),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: AppTokens.spaceMD),
                AppButton(
                  label: 'Add to Cart',
                  onPressed: () {
                    if (_weightInKg > 0) {
                      widget.onConfirm(_weightInKg, total);
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
