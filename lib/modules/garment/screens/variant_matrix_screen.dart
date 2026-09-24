import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../providers/product_provider.dart';

class VariantMatrixScreen extends StatelessWidget {
  const VariantMatrixScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productProv = context.watch<ProductProvider>();

    final garmentProducts = productProv.allProducts.where((p) {
      final sizes = p.metadata['sizes'] as List?;
      final colors = p.metadata['colors'] as List?;
      return sizes != null && colors != null;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Size × Color Variant Matrix'),
      ),
      body: garmentProducts.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.checkroom_rounded,
              title: 'No Apparel Matrix Items',
              description: 'Products with size and color variants configured will display their stock grid here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppTokens.spaceLG),
              itemCount: garmentProducts.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppTokens.spaceLG),
              itemBuilder: (context, index) {
                final prod = garmentProducts[index];
                final sizes = List<String>.from(prod.metadata['sizes'] ?? []);
                final colors = List<String>.from(prod.metadata['colors'] ?? []);
                final stockMap = Map<String, dynamic>.from(prod.metadata['variant_stock'] ?? {});

                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(prod.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          Text('₹${prod.sellingPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Brand: ${prod.brand} • Season: ${prod.metadata['season'] ?? 'Core'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 16),
                      // Matrix Table
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Table(
                          defaultColumnWidth: const FixedColumnWidth(90),
                          border: TableBorder.all(color: Colors.grey.withAlpha(50), borderRadius: BorderRadius.circular(8)),
                          children: [
                            // Header row: Size \ Color
                            TableRow(
                              decoration: BoxDecoration(color: Colors.grey.withAlpha(25)),
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Size / Color', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                ),
                                ...colors.map((c) => Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(c, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                    )),
                              ],
                            ),
                            // Rows per size
                            ...sizes.map((s) {
                              return TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(s, style: const TextStyle(fontWeight: FontWeight.w700)),
                                  ),
                                  ...colors.map((c) {
                                    final key = '$s - $c';
                                    final qty = stockMap[key] ?? 0;
                                    return Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Center(
                                        child: Text(
                                          '$qty pcs',
                                          style: TextStyle(
                                            color: qty <= 2 ? Colors.red : Colors.green,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
