import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/product_provider.dart';
import 'loose_item_weight_dialog.dart';

class FastCheckoutScreen extends StatefulWidget {
  const FastCheckoutScreen({super.key});

  @override
  State<FastCheckoutScreen> createState() => _FastCheckoutScreenState();
}

class _FastCheckoutScreenState extends State<FastCheckoutScreen> {
  final TextEditingController _barcodeCtrl = TextEditingController();

  void _handleBarcodeSubmit(String barcode) {
    if (barcode.trim().isEmpty) return;
    final productProv = context.read<ProductProvider>();
    final cartProv = context.read<CartProvider>();

    final matched = productProv.allProducts.firstWhere(
      (p) => p.barcode == barcode.trim() || p.sku == barcode.trim(),
      orElse: () => productProv.allProducts.first,
    );

    cartProv.addToCart(matched);
    _barcodeCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${matched.name} to cart!'),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productProv = context.watch<ProductProvider>();
    final cartProv = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grocery Quick Touch POS'),
      ),
      body: Row(
        children: [
          // Left: Touch Grid
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppTokens.spaceMD),
                  child: TextField(
                    controller: _barcodeCtrl,
                    autofocus: true,
                    onSubmitted: _handleBarcodeSubmit,
                    decoration: InputDecoration(
                      hintText: 'Barcode scanner active (Scan or enter barcode & press Enter)',
                      prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add_shopping_cart_rounded),
                        onPressed: () => _handleBarcodeSubmit(_barcodeCtrl.text),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(AppTokens.spaceMD),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 180,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: productProv.allProducts.length,
                    itemBuilder: (context, index) {
                      final product = productProv.allProducts[index];
                      final isLoose = product.metadata['is_loose_weight'] == true;
                      final inCart = cartProv.getItemQuantity(product.id);

                      return AppCard(
                        padding: const EdgeInsets.all(10),
                        onTap: () {
                          if (isLoose) {
                            LooseItemWeightDialog.show(
                              context,
                              product: product,
                              onConfirm: (weightKg, _) {
                                cartProv.addToCart(product, quantity: weightKg);
                              },
                            );
                          } else {
                            cartProv.addToCart(product);
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(
                                  isLoose ? Icons.scale_rounded : Icons.shopping_bag_outlined,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                                if (inCart > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      borderRadius: AppTokens.borderPill,
                                    ),
                                    child: Text(
                                      '${inCart.toStringAsFixed(inCart == inCart.roundToDouble() ? 0 : 2)}',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${product.sellingPrice.toStringAsFixed(2)} / ${product.unit}',
                                  style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.primary, fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Right: Fast Cart Sidebar
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              border: Border(left: BorderSide(color: theme.dividerColor)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTokens.spaceMD),
                  color: theme.colorScheme.primary.withAlpha(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quick Cart', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      Text('${cartProv.itemCount} items', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Expanded(
                  child: cartProv.items.isEmpty
                      ? const Center(child: Text('Scan or tap item to add'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(8),
                          itemCount: cartProv.items.length,
                          separatorBuilder: (_, __) => const Divider(height: 8),
                          itemBuilder: (context, i) {
                            final item = cartProv.items[i];
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(item.product.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              subtitle: Text('${item.quantity} ${item.product.unit} × ₹${item.unitPrice}'),
                              trailing: Text('₹${item.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(AppTokens.spaceLG),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: theme.dividerColor)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Payable:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          Text('₹${cartProv.finalTotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: cartProv.items.isEmpty ? null : () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                        child: const Text('Proceed to Checkout'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
