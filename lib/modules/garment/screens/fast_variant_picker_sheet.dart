import 'package:flutter/material.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/product.dart';

class FastVariantPickerSheet extends StatefulWidget {
  final Product product;
  final Function(String selectedVariant) onSelect;

  const FastVariantPickerSheet({
    super.key,
    required this.product,
    required this.onSelect,
  });

  static Future<void> show(
    BuildContext context, {
    required Product product,
    required Function(String selectedVariant) onSelect,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => FastVariantPickerSheet(
        product: product,
        onSelect: onSelect,
      ),
    );
  }

  @override
  State<FastVariantPickerSheet> createState() => _FastVariantPickerSheetState();
}

class _FastVariantPickerSheetState extends State<FastVariantPickerSheet> {
  String? _selectedSize;
  String? _selectedColor;

  @override
  void initState() {
    super.initState();
    final sizes = List<String>.from(widget.product.metadata['sizes'] ?? []);
    final colors = List<String>.from(widget.product.metadata['colors'] ?? []);
    if (sizes.isNotEmpty) _selectedSize = sizes.first;
    if (colors.isNotEmpty) _selectedColor = colors.first;
  }

  @override
  Widget build(BuildContext context) {
    final sizes = List<String>.from(widget.product.metadata['sizes'] ?? ['S', 'M', 'L', 'XL']);
    final colors = List<String>.from(widget.product.metadata['colors'] ?? ['Standard']);
    final stockMap = Map<String, dynamic>.from(widget.product.metadata['variant_stock'] ?? {});

    final currentVariantKey = '$_selectedSize - $_selectedColor';
    final availableStock = stockMap[currentVariantKey] ?? widget.product.stockQty.toInt();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.product.name,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Text(
            '₹${widget.product.sellingPrice.toStringAsFixed(2)} • In Stock for $currentVariantKey: $availableStock pcs',
            style: const TextStyle(color: Color(0xFF9333EA), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          // Size Chips
          const Text('SELECT SIZE', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: sizes.map((s) {
              final isSel = _selectedSize == s;
              return ChoiceChip(
                label: Text(s),
                selected: isSel,
                onSelected: (_) => setState(() => _selectedSize = s),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Color Chips
          const Text('SELECT COLOR', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: colors.map((c) {
              final isSel = _selectedColor == c;
              return ChoiceChip(
                label: Text(c),
                selected: isSel,
                onSelected: (_) => setState(() => _selectedColor = c),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Add to Cart ($currentVariantKey)',
            isFullWidth: true,
            onPressed: () {
              widget.onSelect(currentVariantKey);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
