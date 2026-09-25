import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/estimate.dart';
import '../../../providers/business_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/customer_provider.dart';
import '../../../providers/estimate_provider.dart';
import 'estimate_slip_dialog.dart';

class CreateEstimateDialog extends StatefulWidget {
  const CreateEstimateDialog({super.key});

  static Future<Estimate?> show(BuildContext context) {
    return showDialog<Estimate>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CreateEstimateDialog(),
    );
  }

  @override
  State<CreateEstimateDialog> createState() => _CreateEstimateDialogState();
}

class _CreateEstimateDialogState extends State<CreateEstimateDialog> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  int _validityDays = 15;
  DateTime _validUntil = DateTime.now().add(const Duration(days: 15));
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final cart = context.read<CartProvider>();
    if (cart.selectedCustomer != null) {
      _nameCtrl.text = cart.selectedCustomer!.name;
      _phoneCtrl.text = cart.selectedCustomer!.phone;
    }
    _notesCtrl.text = 'Prices valid for 15 days. Subject to stock availability.';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _setValidity(int days) {
    setState(() {
      _validityDays = days;
      _validUntil = DateTime.now().add(Duration(days: days));
    });
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _validUntil,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _validUntil = picked;
        _validityDays = picked.difference(DateTime.now()).inDays;
      });
    }
  }

  Future<void> _handleSave() async {
    final cart = context.read<CartProvider>();
    final biz = context.read<BusinessProvider>().currentBusiness;
    if (biz == null || cart.items.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final estimate = await context.read<EstimateProvider>().createEstimateFromCart(
            businessId: biz.id,
            cart: cart,
            customerName: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : null,
            customerPhone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
            validUntil: _validUntil,
            notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
          );

      if (!mounted) return;

      // Clear cart AFTER saving so the estimate captures the correct totals.
      cart.clearCart();

      // Close the create-estimate dialog first.
      Navigator.pop(context, estimate);

      // Show the generated slip. Pass okOnly=true so the footer shows
      // "OK" (dismiss) + Print + Share — but NOT "Convert to Sale"
      // (user would go to Estimates screen to convert later).
      EstimateSlipDialog.show(context, estimate, okOnly: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save estimate: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final cart = context.watch<CartProvider>();
    final biz = context.watch<BusinessProvider>().currentBusiness;
    final symbol = biz?.currencySymbol ?? '₹';
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: primary.withAlpha(isDark ? 30 : 15),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: theme.dividerColor.withAlpha(60))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.request_quote_rounded, color: primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Generate Estimate / Quotation',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Creates a formal price quote without deducting inventory stock',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: theme.colorScheme.onSurface.withAlpha(150),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Customer Details',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                          icon: const Icon(Icons.person_search_rounded, size: 16),
                          label: const Text('Pick Customer', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            _showCustomerPicker(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _nameCtrl,
                            decoration: InputDecoration(
                              labelText: 'Customer Name',
                              prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Validity Period Section
                    const Text(
                      'Quotation Validity',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildValidityChip(7, '7 Days'),
                        const SizedBox(width: 8),
                        _buildValidityChip(15, '15 Days'),
                        const SizedBox(width: 8),
                        _buildValidityChip(30, '30 Days'),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.calendar_today_rounded, size: 14),
                          label: Text(
                            DateFormat('dd MMM yyyy').format(_validUntil),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          onPressed: _pickCustomDate,
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Notes / Terms
                    const Text(
                      'Terms & Remarks',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'e.g. Subject to stock availability, valid for 15 days...',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Items & Price Summary Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withAlpha(8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor.withAlpha(70)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${cart.items.length} Item(s) in Quote',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              Text(
                                'Subtotal: ${CurrencyFormatter.format(cart.subtotal, symbol: symbol)}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: theme.colorScheme.onSurface.withAlpha(160),
                                ),
                              ),
                            ],
                          ),
                          if (cart.totalDiscount > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Discount:', style: TextStyle(fontSize: 12)),
                                Text(
                                  '- ${CurrencyFormatter.format(cart.totalDiscount, symbol: symbol)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (cart.totalTax > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Estimated Tax (GST):', style: TextStyle(fontSize: 12)),
                                Text(
                                  '+ ${CurrencyFormatter.format(cart.totalTax, symbol: symbol)}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                          const Divider(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Estimate Amount',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                              Text(
                                CurrencyFormatter.format(cart.finalTotal, symbol: symbol),
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: primary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.dividerColor.withAlpha(60))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_rounded, size: 18),
                    label: Text(
                      _isSaving ? 'Generating...' : 'Generate Estimate',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    onPressed: _isSaving ? null : _handleSave,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidityChip(int days, String label) {
    final isSelected = _validityDays == days;
    final primary = Theme.of(context).colorScheme.primary;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _setValidity(days),
      selectedColor: primary.withAlpha(30),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? primary : null,
      ),
    );
  }

  void _showCustomerPicker(BuildContext context) {
    final custProv = context.read<CustomerProvider>();
    final customers = custProv.customers;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Select Customer',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (customers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('No customers registered yet.')),
              )
            else
              ...customers.map(
                (c) => ListTile(
                  leading: CircleAvatar(child: Text(c.name.isNotEmpty ? c.name[0] : 'C')),
                  title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(c.phone),
                  onTap: () {
                    _nameCtrl.text = c.name;
                    _phoneCtrl.text = c.phone;
                    Navigator.pop(ctx);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
