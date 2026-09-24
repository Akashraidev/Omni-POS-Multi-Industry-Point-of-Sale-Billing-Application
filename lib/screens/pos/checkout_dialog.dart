import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/business.dart';
import '../../data/models/customer.dart';
import '../../data/models/sale.dart';
import '../../modules/business_type.dart';
import '../../providers/business_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/pos_billing_provider.dart';
import '../sales/invoice_view_screen.dart';

class CheckoutDialog extends StatefulWidget {
  const CheckoutDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CheckoutDialog(),
    );
  }

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog> {
  String _selectedPaymentMethod = 'Cash'; // Cash, Card, UPI, Credit/Due, Split
  final TextEditingController _cashTenderedCtrl = TextEditingController();
  final TextEditingController _custPhoneCtrl = TextEditingController();
  final TextEditingController _custNameCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _doctorCtrl = TextEditingController();

  // Split payment amounts
  final TextEditingController _splitCashCtrl = TextEditingController();
  final TextEditingController _splitUpiCtrl = TextEditingController();
  final TextEditingController _splitCardCtrl = TextEditingController();

  Customer? _matchedCustomer;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    final cartProv = context.read<CartProvider>();
    _cashTenderedCtrl.text = cartProv.finalTotal.toStringAsFixed(0);

    if (cartProv.selectedCustomer != null) {
      _matchedCustomer = cartProv.selectedCustomer;
      _custPhoneCtrl.text = _matchedCustomer!.phone;
      _custNameCtrl.text = _matchedCustomer!.name;
    }

    if (cartProv.doctorName != null) {
      _doctorCtrl.text = cartProv.doctorName!;
    }
  }

  @override
  void dispose() {
    _cashTenderedCtrl.dispose();
    _custPhoneCtrl.dispose();
    _custNameCtrl.dispose();
    _notesCtrl.dispose();
    _doctorCtrl.dispose();
    _splitCashCtrl.dispose();
    _splitUpiCtrl.dispose();
    _splitCardCtrl.dispose();
    super.dispose();
  }

  void _lookupCustomer(String phone) async {
    if (phone.length >= 4) {
      final bizProv = context.read<BusinessProvider>();
      final custProv = context.read<CustomerProvider>();
      if (bizProv.currentBusiness != null) {
        final cust = await custProv.findByPhone(bizProv.currentBusiness!.id, phone);
        if (cust != null && mounted) {
          setState(() {
            _matchedCustomer = cust;
            _custNameCtrl.text = cust.name;
          });
        }
      }
    }
  }

  double get _totalPayable => context.read<CartProvider>().finalTotal;

  double get _splitTotal =>
      (double.tryParse(_splitCashCtrl.text) ?? 0.0) +
      (double.tryParse(_splitUpiCtrl.text) ?? 0.0) +
      (double.tryParse(_splitCardCtrl.text) ?? 0.0);

  /// Validates the payment inputs before allowing the sale to be committed.
  bool _validate() {
    final cart = context.read<CartProvider>();
    final biz = context.read<BusinessProvider>().currentBusiness;

    if (_selectedPaymentMethod == 'Cash') {
      final tendered = double.tryParse(_cashTenderedCtrl.text) ?? 0.0;
      if (tendered < _totalPayable) {
        setState(() => _validationError = 'Cash received is less than the total payable.');
        return false;
      }
    }

    if (_selectedPaymentMethod == 'Split') {
      if ((_splitTotal - _totalPayable).abs() > 0.01) {
        setState(() => _validationError =
            'Split amounts must add up to ${CurrencyFormatter.format(_totalPayable, symbol: biz?.currencySymbol ?? '₹')}.');
        return false;
      }
    }

    // Pharmacy Schedule H compliance: record the prescriber.
    final needsRx = cart.items.any((it) =>
        it.product.metadata['schedule_h'] == true || it.product.metadata['is_narcotic'] == true);
    if (needsRx &&
        biz != null &&
        biz.settings['require_doctor_for_schedule_h'] == true &&
        _doctorCtrl.text.trim().isEmpty) {
      setState(() => _validationError = 'A prescribing doctor name is required for Schedule H / Rx medicines.');
      return false;
    }

    setState(() => _validationError = null);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final cartProv = context.watch<CartProvider>();
    final bizProv = context.watch<BusinessProvider>();
    final billingProv = context.watch<PosBillingProvider>();

    final currentBiz = bizProv.currentBusiness;
    if (currentBiz == null) return const SizedBox.shrink();

    final symbol = currentBiz.currencySymbol;
    final totalPayable = cartProv.finalTotal;
    final tendered = double.tryParse(_cashTenderedCtrl.text) ?? totalPayable;
    final changeDue = (tendered - totalPayable).clamp(0.0, 999999.0);
    final isWide = MediaQuery.sizeOf(context).width >= 640;

    final paymentMethods = ['Cash', 'UPI', 'Card', 'Credit/Due', 'Split'];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppTokens.borderXL),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 760, maxHeight: MediaQuery.sizeOf(context).height * 0.9),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spaceLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Checkout & Payment', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                      Text(
                        '${cartProv.itemCount} items • ${cartProv.orderType}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Flexible(
                child: SingleChildScrollView(
                  child: isWide
                      ? IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: _buildSummaryColumn(context, cartProv, currentBiz, symbol, paymentMethods, totalPayable, changeDue)),
                              const SizedBox(width: AppTokens.spaceLG),
                              Expanded(child: _buildPaymentColumn(context, cartProv, currentBiz, symbol, totalPayable, paymentMethods, changeDue)),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ..._buildSummaryChildren(context, cartProv, currentBiz, symbol),
                            const SizedBox(height: AppTokens.spaceLG),
                            ..._buildPaymentChildren(context, cartProv, currentBiz, symbol, totalPayable, paymentMethods, changeDue),
                          ],
                        ),
                ),
              ),
              if (_validationError != null) ...[
                const SizedBox(height: AppTokens.spaceSM),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: AppTokens.borderMD,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 17, color: Color(0xFFDC2626)),
                      const SizedBox(width: AppTokens.spaceSM),
                      Expanded(
                        child: Text(
                          _validationError!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppTokens.spaceMD),
              // Complete Button
              AppButton(
                label: 'Complete Sale & Generate Invoice',
                icon: Icons.check_circle_rounded,
                isFullWidth: true,
                isLoading: billingProv.isProcessing,
                height: 48,
                onPressed: () async {
                  if (!_validate()) return;

                  final splitMap = <String, double>{};
                  if (_selectedPaymentMethod == 'Split') {
                    splitMap['Cash'] = double.tryParse(_splitCashCtrl.text) ?? 0.0;
                    splitMap['UPI'] = double.tryParse(_splitUpiCtrl.text) ?? 0.0;
                    splitMap['Card'] = double.tryParse(_splitCardCtrl.text) ?? 0.0;
                  } else {
                    splitMap[_selectedPaymentMethod] = totalPayable;
                  }

                  Sale? sale;
                  try {
                    sale = await billingProv.completeCheckout(
                      business: currentBiz,
                      items: cartProv.items,
                      subtotal: cartProv.subtotal,
                      taxAmount: cartProv.totalTax,
                      discountAmount: cartProv.totalDiscount,
                      roundOff: cartProv.roundOff,
                      finalTotal: totalPayable,
                      paymentMethod: _selectedPaymentMethod,
                      splitBreakup: splitMap,
                      customerId: _matchedCustomer?.id,
                      customerName: _custNameCtrl.text.isNotEmpty ? _custNameCtrl.text : 'Walk-in Guest',
                      customerPhone: _custPhoneCtrl.text,
                      orderType: cartProv.orderType,
                      tableNumber: cartProv.tableNumber,
                      doctorName: _doctorCtrl.text.isNotEmpty ? _doctorCtrl.text : null,
                      notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
                    );
                  } catch (e) {
                    if (!mounted) return;
                    setState(() => _validationError = 'Could not complete the sale. Please try again.');
                    return;
                  }

                  if (!mounted) return;
                  if (sale != null) {
                    cartProv.clearCart();
                    Navigator.pop(context); // close dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InvoiceViewScreen(sale: sale!),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Summary column (order + customer) ---------------------------------

  Widget _buildSummaryColumn(
    BuildContext context,
    CartProvider cartProv,
    Business currentBiz,
    String symbol,
    List<String> paymentMethods,
    double totalPayable,
    double changeDue,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildSummaryChildren(context, cartProv, currentBiz, symbol),
    );
  }

  List<Widget> _buildSummaryChildren(BuildContext context, CartProvider cartProv, Business currentBiz, String symbol) {
    return [
      // Total Payable Hero Banner
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              currentBiz.type.primaryColor,
              currentBiz.type.primaryColor.withBlue((currentBiz.type.primaryColor.blue + 40).clamp(0, 255)),
            ],
          ),
          borderRadius: AppTokens.borderLG,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Total Payable', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 2),
            Text(
              CurrencyFormatter.format(cartProv.finalTotal, symbol: symbol),
              style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              runSpacing: 2,
              children: [
                _HeroPill(label: 'Subtotal', value: CurrencyFormatter.format(cartProv.subtotal, symbol: symbol)),
                _HeroPill(label: 'Tax', value: CurrencyFormatter.format(cartProv.totalTax, symbol: symbol)),
                if (cartProv.totalDiscount > 0)
                  _HeroPill(label: 'Discount', value: '- ${CurrencyFormatter.format(cartProv.totalDiscount, symbol: symbol)}'),
                if (cartProv.freeUnitCount > 0)
                  _HeroPill(label: 'Free units', value: '${cartProv.freeUnitCount}'),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: AppTokens.spaceLG),
      // Customer Details
      const Text('Customer Information (Optional)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _custPhoneCtrl,
              keyboardType: TextInputType.phone,
              onChanged: _lookupCustomer,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_rounded),
              ),
            ),
          ),
          const SizedBox(width: AppTokens.spaceMD),
          Expanded(
            child: TextField(
              controller: _custNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Customer Name',
                prefixIcon: Icon(Icons.person_rounded),
              ),
            ),
          ),
        ],
      ),
      if (_matchedCustomer != null) ...[
        const SizedBox(height: 6),
        Text(
          'Loyalty Points: ${_matchedCustomer!.loyaltyPoints} pts | Existing Due: ${CurrencyFormatter.format(_matchedCustomer!.balanceDue, symbol: symbol, decimalDigits: 0)}',
          style: const TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.w600),
        ),
      ],
      const SizedBox(height: AppTokens.spaceLG),
      TextField(
        controller: _notesCtrl,
        decoration: const InputDecoration(
          labelText: 'Order Notes / Bill Reference (Optional)',
          prefixIcon: Icon(Icons.note_alt_outlined),
        ),
      ),
    ];
  }

  // ---- Payment column ----------------------------------------------------

  Widget _buildPaymentColumn(
    BuildContext context,
    CartProvider cartProv,
    Business currentBiz,
    String symbol,
    double totalPayable,
    List<String> paymentMethods,
    double changeDue,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildPaymentChildren(context, cartProv, currentBiz, symbol, totalPayable, paymentMethods, changeDue),
    );
  }

  List<Widget> _buildPaymentChildren(
    BuildContext context,
    CartProvider cartProv,
    Business currentBiz,
    String symbol,
    double totalPayable,
    List<String> paymentMethods,
    double changeDue,
  ) {
    return [
      // Medical doctor capture
      if (currentBiz.type == BusinessType.medical) ...[
        TextField(
          controller: _doctorCtrl,
          decoration: const InputDecoration(
            labelText: 'Prescribing Doctor Name (Schedule H / Rx)',
            prefixIcon: Icon(Icons.medical_services_rounded),
          ),
        ),
        const SizedBox(height: AppTokens.spaceLG),
      ],

      const Text('Select Payment Method', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: paymentMethods.map((method) {
          final isSel = _selectedPaymentMethod == method;
          return ChoiceChip(
            label: Text(method),
            selected: isSel,
            selectedColor: currentBiz.type.primaryColor,
            labelStyle: TextStyle(
              color: isSel ? Colors.white : Colors.black87,
              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
            ),
            onSelected: (_) => setState(() {
              _selectedPaymentMethod = method;
              _validationError = null;
            }),
          );
        }).toList(),
      ),
      const SizedBox(height: AppTokens.spaceLG),

      // Cash tender / change calculator
      if (_selectedPaymentMethod == 'Cash') ...[
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cashTenderedCtrl,
                keyboardType: TextInputType.number,
                onChanged: (val) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Cash Received',
                  prefixIcon: Icon(Icons.money_rounded),
                ),
              ),
            ),
            const SizedBox(width: AppTokens.spaceMD),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(20),
                  borderRadius: AppTokens.borderMD,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Change to Return', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600)),
                    Text(
                      CurrencyFormatter.format(changeDue, symbol: symbol),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.green),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Quick cash denominations
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ActionChip(label: const Text('Exact'), onPressed: () => setState(() => _cashTenderedCtrl.text = totalPayable.toStringAsFixed(0))),
            ActionChip(label: const Text('₹500'), onPressed: () => setState(() => _cashTenderedCtrl.text = '500')),
            ActionChip(label: const Text('₹1000'), onPressed: () => setState(() => _cashTenderedCtrl.text = '1000')),
            ActionChip(label: const Text('₹2000'), onPressed: () => setState(() => _cashTenderedCtrl.text = '2000')),
          ],
        ),
      ],

      // Split payment inputs
      if (_selectedPaymentMethod == 'Split') ...[
        const Text('Enter Split Amounts', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _splitCashCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Cash',
                  prefixText: symbol,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _splitUpiCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'UPI',
                  prefixText: symbol,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _splitCardCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Card',
                  prefixText: symbol,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _SplitMeter(total: totalPayable, entered: _splitTotal, symbol: symbol),
      ],
    ];
  }
}

class _HeroPill extends StatelessWidget {
  final String label;
  final String value;

  const _HeroPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(35),
        borderRadius: AppTokens.borderSM,
      ),
      child: RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
          children: [
            TextSpan(text: '$label ', style: const TextStyle(color: Colors.white70)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _SplitMeter extends StatelessWidget {
  final double total;
  final double entered;
  final String symbol;

  const _SplitMeter({required this.total, required this.entered, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final diff = total - entered;
    final isComplete = diff.abs() <= 0.01;
    final over = entered > total + 0.01;

    final color = isComplete ? const Color(0xFF059669) : (over ? const Color(0xFFDC2626) : const Color(0xFFD97706));
    final msg = isComplete
        ? 'Amounts match the total payable'
        : over
            ? 'Over by ${CurrencyFormatter.format(entered - total, symbol: symbol)}'
            : 'Short by ${CurrencyFormatter.format(diff, symbol: symbol)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: AppTokens.borderMD,
      ),
      child: Row(
        children: [
          Icon(isComplete ? Icons.check_circle_rounded : Icons.info_outline_rounded, size: 15, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
            ),
          ),
          Text(
            '${CurrencyFormatter.format(entered, symbol: symbol)} / ${CurrencyFormatter.format(total, symbol: symbol)}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}
