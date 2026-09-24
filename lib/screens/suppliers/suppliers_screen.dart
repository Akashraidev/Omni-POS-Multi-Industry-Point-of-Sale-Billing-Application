import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../data/models/supplier.dart';
import '../../providers/business_provider.dart';
import '../../providers/supplier_provider.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final biz = context.read<BusinessProvider>().currentBusiness;
      if (biz != null) {
        context.read<SupplierProvider>().loadSuppliers(biz.id);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddSupplierDialog(BuildContext context) {
    final biz = context.read<BusinessProvider>().currentBusiness;
    final suppProv = context.read<SupplierProvider>();
    if (biz == null) return;

    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add New Supplier'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Supplier / Company Name *')),
                const SizedBox(height: 12),
                TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Contact Phone *')),
                const SizedBox(height: 12),
                TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email Address')),
                const SizedBox(height: 12),
                TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Warehouse Address')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                  final supplier = Supplier(
                    id: _uuid.v4(),
                    businessId: biz.id,
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    address: addressCtrl.text.trim(),
                  );
                  await suppProv.saveSupplier(supplier);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Save Supplier'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final suppProv = context.watch<SupplierProvider>();
    final bizProv = context.watch<BusinessProvider>();
    final currentBiz = bizProv.currentBusiness;
    final symbol = currentBiz?.currencySymbol ?? '₹';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier & Vendor Directory'),
        actions: [
          IconButton(
            tooltip: 'Add Supplier',
            icon: const Icon(Icons.add_business_rounded),
            onPressed: () => _showAddSupplierDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: Colors.amber.withAlpha(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Outstanding Supplier Payables', style: TextStyle(fontSize: 12, color: Colors.brown, fontWeight: FontWeight.w600)),
                    Text(
                      CurrencyFormatter.format(suppProv.totalSupplierPayables, symbol: symbol),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.brown),
                    ),
                  ],
                ),
                Text('${suppProv.suppliers.length} vendors', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTokens.spaceMD),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) {
                if (currentBiz != null) suppProv.loadSuppliers(currentBiz.id, query: val);
              },
              decoration: const InputDecoration(
                hintText: 'Search suppliers by company or contact...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: suppProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : suppProv.suppliers.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.local_shipping_outlined,
                        title: 'No Suppliers Found',
                        description: 'Register wholesale distributors and vendors to manage supply orders.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppTokens.spaceLG),
                        itemCount: suppProv.suppliers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppTokens.spaceMD),
                        itemBuilder: (context, index) {
                          final s = suppProv.suppliers[index];
                          return AppCard(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withAlpha(20),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.store_rounded, color: Colors.purple),
                                ),
                                const SizedBox(width: AppTokens.spaceMD),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                      const SizedBox(height: 2),
                                      Text('Phone: ${s.phone} • Rating: ${s.rating} ★', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      if (s.address.isNotEmpty) Text(s.address, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Payable Due', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    Text(
                                      '₹${s.balanceDue.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: s.balanceDue > 0 ? Colors.red : Colors.green,
                                      ),
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
    );
  }
}
