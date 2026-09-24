import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../data/models/expense.dart';
import '../../providers/business_provider.dart';
import '../../providers/expense_provider.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final biz = context.read<BusinessProvider>().currentBusiness;
      if (biz != null) {
        context.read<ExpenseProvider>().loadExpenses(biz.id);
      }
    });
  }

  void _showAddExpenseDialog(BuildContext context) {
    final biz = context.read<BusinessProvider>().currentBusiness;
    final expProv = context.read<ExpenseProvider>();
    if (biz == null) return;

    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String category = 'Utilities';
    String paymentMethod = 'Cash';

    final categories = ['Rent', 'Utilities', 'Salaries', 'Supplies', 'Marketing', 'Maintenance', 'Misc'];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              title: const Text('Record Store Expense'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Expense Description *')),
                    const SizedBox(height: 12),
                    TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (₹) *', prefixIcon: Icon(Icons.currency_rupee))),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(labelText: 'Expense Category'),
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setDlgState(() => category = v!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: paymentMethod,
                      decoration: const InputDecoration(labelText: 'Paid From'),
                      items: ['Cash', 'Bank / UPI', 'Card'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                      onChanged: (v) => setDlgState(() => paymentMethod = v!),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes / Voucher Ref')),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final amt = double.tryParse(amountCtrl.text) ?? 0.0;
                    if (titleCtrl.text.isNotEmpty && amt > 0) {
                      final exp = Expense(
                        id: _uuid.v4(),
                        businessId: biz.id,
                        title: titleCtrl.text.trim(),
                        category: category,
                        amount: amt,
                        paymentMethod: paymentMethod,
                        notes: notesCtrl.text.trim(),
                      );
                      await expProv.addExpense(exp);
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Save Expense'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final expProv = context.watch<ExpenseProvider>();
    final bizProv = context.watch<BusinessProvider>();
    final currentBiz = bizProv.currentBusiness;
    final symbol = currentBiz?.currencySymbol ?? '₹';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Expenses & Overheads'),
        actions: [
          IconButton(
            tooltip: 'Add Expense',
            icon: const Icon(Icons.add_card_rounded),
            onPressed: () => _showAddExpenseDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Total Overhead Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: Colors.deepOrange.withAlpha(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Monthly Overhead Expenses', style: TextStyle(fontSize: 12, color: Colors.deepOrange, fontWeight: FontWeight.w600)),
                    Text(
                      CurrencyFormatter.format(expProv.totalExpenses, symbol: symbol),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.deepOrange),
                    ),
                  ],
                ),
                Text('${expProv.expenses.length} records', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Expanded(
            child: expProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : expProv.expenses.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.receipt_long_outlined,
                        title: 'No Expenses Logged',
                        description: 'Record operating expenses (electricity, rent, salaries) to calculate accurate net profit.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppTokens.spaceLG),
                        itemCount: expProv.expenses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppTokens.spaceMD),
                        itemBuilder: (context, index) {
                          final e = expProv.expenses[index];
                          return AppCard(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withAlpha(25),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.outbox_rounded, color: Colors.deepOrange),
                                ),
                                const SizedBox(width: AppTokens.spaceMD),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                      Text('Category: ${e.category} • Paid via: ${e.paymentMethod}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      Text(e.date.toString().substring(0, 10), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${e.amount.toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.deepOrange),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                      onPressed: () async {
                                        if (currentBiz != null) {
                                          await expProv.deleteExpense(currentBiz.id, e.id);
                                        }
                                      },
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
