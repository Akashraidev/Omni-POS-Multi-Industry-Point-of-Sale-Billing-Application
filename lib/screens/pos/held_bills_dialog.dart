import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../providers/business_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/product_provider.dart';

class HeldBillsDialog extends StatelessWidget {
  const HeldBillsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const HeldBillsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invProv = context.watch<InventoryProvider>();
    final cartProv = context.read<CartProvider>();
    final prodProv = context.read<ProductProvider>();
    final bizProv = context.read<BusinessProvider>();
    final symbol = bizProv.currentBusiness?.currencySymbol ?? '₹';
    final heldBills = invProv.heldBills;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppTokens.borderXL),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 500),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spaceLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Held / Parked Bills',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Resume a previously paused order to complete billing.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: AppTokens.spaceMD),
              Expanded(
                child: heldBills.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.pause_circle_outline_rounded,
                        title: 'No Held Bills',
                        description: 'You can park an active checkout anytime by tapping "Hold Bill" in the cart.',
                      )
                    : ListView.separated(
                        itemCount: heldBills.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppTokens.spaceSM),
                        itemBuilder: (context, index) {
                          final bill = heldBills[index];
                          return AppCard(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withAlpha(30),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.receipt_outlined, color: Colors.amber),
                                ),
                                const SizedBox(width: AppTokens.spaceMD),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bill.title,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                      ),
                                      Text(
                                        'Customer: ${bill.customerName ?? 'Walk-in'} • ${bill.createdAt.toString().substring(11, 16)}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      CurrencyFormatter.format(bill.totalAmount, symbol: symbol),
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                          onPressed: () async {
                                            if (bizProv.currentBusiness != null) {
                                              await invProv.deleteHeldBill(bizProv.currentBusiness!.id, bill.id);
                                            }
                                          },
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          ),
                                          onPressed: () async {
                                            await cartProv.resumeHeldBill(bill, prodProv.allProducts);
                                            if (context.mounted) Navigator.pop(context);
                                          },
                                          child: const Text('Resume'),
                                        ),
                                      ],
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
      ),
    );
  }
}
