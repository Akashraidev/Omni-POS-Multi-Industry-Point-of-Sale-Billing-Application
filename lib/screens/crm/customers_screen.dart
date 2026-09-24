import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../data/models/customer.dart';
import '../../providers/business_provider.dart';
import '../../providers/customer_provider.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final biz = context.read<BusinessProvider>().currentBusiness;
      if (biz != null) {
        context.read<CustomerProvider>().loadCustomers(biz.id);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddCustomerDialog(BuildContext context) {
    final biz = context.read<BusinessProvider>().currentBusiness;
    final custProv = context.read<CustomerProvider>();
    if (biz == null) return;

    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add New Customer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name *')),
                const SizedBox(height: 12),
                TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number *')),
                const SizedBox(height: 12),
                TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email Address')),
                const SizedBox(height: 12),
                TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Delivery Address')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                  final customer = Customer(
                    id: _uuid.v4(),
                    businessId: biz.id,
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    address: addressCtrl.text.trim(),
                  );
                  await custProv.saveCustomer(customer);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Add Customer'),
            ),
          ],
        );
      },
    );
  }

  void _showCollectDueDialog(BuildContext context, Customer customer) {
    final biz = context.read<BusinessProvider>().currentBusiness;
    final custProv = context.read<CustomerProvider>();
    if (biz == null) return;

    final amountCtrl = TextEditingController(text: customer.balanceDue.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Collect Payment: ${customer.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Outstanding Due: ₹${customer.balanceDue.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Payment Received (₹)', prefixIcon: Icon(Icons.payments_rounded)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(amountCtrl.text) ?? 0.0;
                if (amt > 0) {
                  await custProv.collectDue(biz.id, customer.id, amt);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Record Payment'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final custProv = context.watch<CustomerProvider>();
    final bizProv = context.watch<BusinessProvider>();
    final currentBiz = bizProv.currentBusiness;
    final symbol = currentBiz?.currencySymbol ?? '₹';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Relationship (CRM)'),
        actions: [
          IconButton(
            tooltip: 'Add Customer',
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: () => _showAddCustomerDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Total Dues Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: Colors.red.withAlpha(15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Outstanding Customer Dues', style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600)),
                    Text(
                      CurrencyFormatter.format(custProv.totalOutstandingDue, symbol: symbol),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.red),
                    ),
                  ],
                ),
                Text('${custProv.customers.length} registered customers', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTokens.spaceMD),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) {
                if (currentBiz != null) custProv.loadCustomers(currentBiz.id, query: val);
              },
              decoration: const InputDecoration(
                hintText: 'Search customers by name, phone or email...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: custProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : custProv.customers.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.people_outline_rounded,
                        title: 'No Customers Found',
                        description: 'Add your regular customers to track loyalty points and dues credit.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppTokens.spaceLG),
                        itemCount: custProv.customers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppTokens.spaceMD),
                        itemBuilder: (context, index) {
                          final c = custProv.customers[index];
                          final hasDue = c.balanceDue > 0;

                          return AppCard(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withAlpha(25),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.person_rounded, color: Colors.blue),
                                ),
                                const SizedBox(width: AppTokens.spaceMD),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                      const SizedBox(height: 2),
                                      Text('Phone: ${c.phone}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                      Row(
                                        children: [
                                          Icon(Icons.stars_rounded, size: 14, color: Colors.amber[700]),
                                          const SizedBox(width: 4),
                                          Text('${c.loyaltyPoints} points', style: TextStyle(fontSize: 12, color: Colors.amber[800], fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (hasDue) ...[
                                      Text(
                                        'Due: ₹${c.balanceDue.toStringAsFixed(0)}',
                                        style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.red, fontSize: 15),
                                      ),
                                      const SizedBox(height: 6),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          minimumSize: const Size(0, 28),
                                        ),
                                        onPressed: () => _showCollectDueDialog(context, c),
                                        child: const Text('Collect', style: TextStyle(fontSize: 11)),
                                      ),
                                    ] else
                                      const AppBadge(label: 'No Dues', type: BadgeType.success),
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
    );
  }
}
