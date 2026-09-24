import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../data/models/customer.dart';
import '../../../providers/business_provider.dart';
import '../../../providers/customer_provider.dart';

/// Customer chooser used by the POS cart panel.
///
/// Replaces walk-in billing with a loyalty customer in two taps; also supports
/// quick-adding a brand-new customer without leaving the billing flow.
class CustomerPickerSheet extends StatefulWidget {
  const CustomerPickerSheet({super.key});

  static Future<Customer?> show(BuildContext context) {
    return showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const CustomerPickerSheet(),
    );
  }

  @override
  State<CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<CustomerPickerSheet> {
  final _searchCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _showAddForm = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _applySearch(String value) {
    final biz = context.read<BusinessProvider>().currentBusiness;
    if (biz != null) {
      context.read<CustomerProvider>().loadCustomers(biz.id, query: value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final custProv = context.watch<CustomerProvider>();
    final symbol = context.watch<BusinessProvider>().currentBusiness?.currencySymbol ?? '₹';

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
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
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: AppTokens.borderPill,
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spaceMD),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Select Customer', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              TextButton.icon(
                icon: Icon(_showAddForm ? Icons.close_rounded : Icons.person_add_rounded, size: 17),
                label: Text(_showAddForm ? 'Cancel' : 'New Customer'),
                onPressed: () => setState(() => _showAddForm = !_showAddForm),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spaceSM),
          // Walk-in quick option
          _WalkInTile(
            onTap: () {
              context.read<CustomerProvider>().loadCustomers(
                    context.read<BusinessProvider>().currentBusiness!.id,
                  );
              Navigator.pop(context, null);
            },
          ),
          const SizedBox(height: AppTokens.spaceSM),
          TextField(
            controller: _searchCtrl,
            keyboardType: TextInputType.phone,
            onChanged: _applySearch,
            decoration: const InputDecoration(
              hintText: 'Search by phone or name...',
              prefixIcon: Icon(Icons.search_rounded),
              isDense: true,
            ),
          ),
          if (_showAddForm) ...[
            const SizedBox(height: AppTokens.spaceMD),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person_rounded),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.spaceSM),
                Expanded(
                  child: TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: Icon(Icons.phone_rounded),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spaceSM),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Save & Select'),
              onPressed: () async {
                if (_nameCtrl.text.trim().isEmpty) return;
                final biz = context.read<BusinessProvider>().currentBusiness!;
                final customer = Customer(
                  id: 'cust_${DateTime.now().millisecondsSinceEpoch}',
                  businessId: biz.id,
                  name: _nameCtrl.text.trim(),
                  phone: _phoneCtrl.text.trim(),
                );
                await custProv.saveCustomer(customer);
                if (mounted) Navigator.pop(context, customer);
              },
            ),
          ],
          const SizedBox(height: AppTokens.spaceMD),
          Flexible(
            child: custProv.isLoading && custProv.customers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : custProv.customers.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.person_search_rounded,
                        title: 'No Customers Found',
                        description: 'Add a new customer or adjust your search.',
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: custProv.customers.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppTokens.spaceSM),
                        itemBuilder: (context, index) {
                          final c = custProv.customers[index];
                          return AppCard(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            onTap: () => Navigator.pop(context, c),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: theme.colorScheme.primary.withAlpha(22),
                                  child: Icon(Icons.person_rounded, color: theme.colorScheme.primary, size: 18),
                                ),
                                const SizedBox(width: AppTokens.spaceMD),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                      if (c.phone.isNotEmpty)
                                        Text(
                                          c.phone,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme.colorScheme.onSurface.withAlpha(150),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (c.balanceDue > 0)
                                      Text(
                                        'Due ${CurrencyFormatter.format(c.balanceDue, symbol: symbol, decimalDigits: 0)}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFD97706),
                                        ),
                                      ),
                                    if (c.loyaltyPoints > 0)
                                      Text(
                                        '${c.loyaltyPoints} pts',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: theme.colorScheme.onSurface.withAlpha(150),
                                          fontWeight: FontWeight.w600,
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

class _WalkInTile extends StatelessWidget {
  final VoidCallback onTap;

  const _WalkInTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primary.withAlpha(10),
      borderRadius: AppTokens.borderMD,
      child: InkWell(
        borderRadius: AppTokens.borderMD,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(Icons.person_outline_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: AppTokens.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Walk-in Customer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(
                      'No loyalty points or due tracking',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: theme.colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurface.withAlpha(120)),
            ],
          ),
        ),
      ),
    );
  }
}
