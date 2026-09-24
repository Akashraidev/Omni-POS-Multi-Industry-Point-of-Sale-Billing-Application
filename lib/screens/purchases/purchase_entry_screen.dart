import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/product.dart';
import '../../data/models/purchase.dart';
import '../../data/models/supplier.dart';
import '../../providers/business_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/supplier_provider.dart';
import 'widgets/purchase_detail_dialog.dart';

class PurchaseEntryScreen extends StatefulWidget {
  const PurchaseEntryScreen({super.key});

  @override
  State<PurchaseEntryScreen> createState() => _PurchaseEntryScreenState();
}

class _PurchaseEntryScreenState extends State<PurchaseEntryScreen> {
  static const Color _emerald = Color(0xFF10B981);
  static const Color _rose = Color(0xFFE11D48);

  final _uuid = const Uuid();
  final _dateFormat = DateFormat('dd/MM/yyyy');

  // Header & Meta State
  final TextEditingController _invoiceNoController = TextEditingController();
  final TextEditingController _billRefController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime _purchaseDate = DateTime.now();
  DateTime? _dueDate;
  String _status = 'Received'; // Received or Pending
  String _paymentStatus = 'Paid'; // Paid, Partial, Due
  String _paymentMethod = 'Bank/UPI'; // Cash, Bank/UPI, Cheque, Credit
  Supplier? _selectedSupplier;

  // Items State
  final List<PurchaseItem> _items = [];

  // Line Item Input Form State
  Product? _selectedProduct;
  final TextEditingController _productSearchController = TextEditingController();
  final TextEditingController _batchController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController(text: '1');
  final TextEditingController _freeQtyController = TextEditingController(text: '0');
  final TextEditingController _unitCostController = TextEditingController();
  final TextEditingController _mrpController = TextEditingController();
  final TextEditingController _taxRateController = TextEditingController(text: '12');
  final TextEditingController _discountController = TextEditingController(text: '0');

  // Summary Controllers
  final TextEditingController _paidAmountController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  Future<void> _initData() async {
    final biz = context.read<BusinessProvider>().currentBusiness;
    if (biz != null) {
      context.read<ProductProvider>().loadProducts(biz.id);
      context.read<SupplierProvider>().loadSuppliers(biz.id);
      final nextInv = await context.read<PurchaseProvider>().getNextInvoiceNumber(biz.id);
      if (mounted) {
        _invoiceNoController.text = nextInv;
      }
    }
  }

  @override
  void dispose() {
    _invoiceNoController.dispose();
    _billRefController.dispose();
    _notesController.dispose();
    _productSearchController.dispose();
    _batchController.dispose();
    _expiryController.dispose();
    _qtyController.dispose();
    _freeQtyController.dispose();
    _unitCostController.dispose();
    _mrpController.dispose();
    _taxRateController.dispose();
    _discountController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  // --- Financial Calculations ---
  double get _calculatedSubtotal {
    return _items.fold(0.0, (sum, it) => sum + (it.quantity * it.unitCost));
  }

  double get _calculatedItemDiscounts {
    return _items.fold(0.0, (sum, it) => sum + it.discountAmount);
  }

  double get _calculatedTaxAmount {
    return _items.fold(0.0, (sum, it) => sum + it.taxAmount);
  }

  double get _rawTotalAmount {
    return _calculatedSubtotal - _calculatedItemDiscounts + _calculatedTaxAmount;
  }

  double get _calculatedRoundOff {
    final rounded = _rawTotalAmount.roundToDouble();
    return double.parse((rounded - _rawTotalAmount).toStringAsFixed(2));
  }

  double get _finalTotalAmount {
    return double.parse((_rawTotalAmount + _calculatedRoundOff).toStringAsFixed(2));
  }

  double get _paidAmount {
    if (_paymentStatus == 'Paid') return _finalTotalAmount;
    if (_paymentStatus == 'Due') return 0.0;
    return double.tryParse(_paidAmountController.text) ?? 0.0;
  }

  double get _dueAmount {
    return (_finalTotalAmount - _paidAmount).clamp(0.0, 9999999.0);
  }

  double get _totalBilledUnits => _items.fold(0.0, (sum, it) => sum + it.quantity);
  double get _totalFreeUnits => _items.fold(0.0, (sum, it) => sum + it.freeQuantity);

  void _onProductSelected(Product product) {
    setState(() {
      _selectedProduct = product;
      _unitCostController.text = product.purchasePrice > 0 ? product.purchasePrice.toString() : '';
      _mrpController.text = product.mrp > 0 ? product.mrp.toString() : '';
      _taxRateController.text = product.taxRate > 0 ? product.taxRate.toString() : '12';

      // If product has existing batches, suggest the most recent batch
      final List<dynamic> batches =
          product.metadata['batches'] as List<dynamic>? ?? [];
      if (batches.isNotEmpty) {
        final lastBatch = batches.last as Map<String, dynamic>;
        _batchController.text = lastBatch['batch_no'] as String? ?? '';
        _expiryController.text = lastBatch['expiry'] as String? ?? '';
      } else {
        _batchController.clear();
        _expiryController.clear();
      }
    });
  }

  void _addItem() {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product first'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final qty = int.tryParse(_qtyController.text) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Billed quantity must be greater than 0'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final freeQty = int.tryParse(_freeQtyController.text) ?? 0;
    final unitCost = double.tryParse(_unitCostController.text) ?? 0.0;
    final mrp = double.tryParse(_mrpController.text);
    final taxRate = double.tryParse(_taxRateController.text) ?? 0.0;
    final discount = double.tryParse(_discountController.text) ?? 0.0;

    // Line tax calculation
    final taxableAmount = (qty * unitCost) - discount;
    final taxAmount = taxableAmount > 0 ? (taxableAmount * taxRate / 100) : 0.0;
    final lineTotal = (taxableAmount + taxAmount).clamp(0.0, 9999999.0);

    final item = PurchaseItem(
      id: _uuid.v4(),
      purchaseId: '', // populated on save
      productId: _selectedProduct!.id,
      productName: _selectedProduct!.name,
      quantity: qty.toDouble(),
      freeQuantity: freeQty.toDouble(),
      unitCost: unitCost,
      taxRate: taxRate,
      taxAmount: double.parse(taxAmount.toStringAsFixed(2)),
      discountAmount: discount,
      totalCost: double.parse(lineTotal.toStringAsFixed(2)),
      batchNumber: _batchController.text.trim().isNotEmpty ? _batchController.text.trim() : null,
      batchExpiry: _expiryController.text.trim().isNotEmpty ? _expiryController.text.trim() : null,
      mrp: mrp,
    );

    setState(() {
      _items.add(item);
      // Reset form
      _selectedProduct = null;
      _productSearchController.clear();
      _batchController.clear();
      _expiryController.clear();
      _qtyController.text = '1';
      _freeQtyController.text = '0';
      _unitCostController.clear();
      _mrpController.clear();
      _discountController.text = '0';
      _taxRateController.text = '12';

      if (_paymentStatus == 'Paid') {
        _paidAmountController.text = _finalTotalAmount.toStringAsFixed(2);
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      if (_paymentStatus == 'Paid') {
        _paidAmountController.text = _finalTotalAmount.toStringAsFixed(2);
      }
    });
  }

  Future<void> _showAddSupplierDialog() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addrCtrl = TextEditingController();

    final result = await showDialog<Supplier>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.person_add_alt_1_rounded, color: Colors.blue),
            SizedBox(width: 8),
            Text('Add New Supplier'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Supplier Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addrCtrl,
                decoration: const InputDecoration(
                  labelText: 'Address / City',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              final biz = context.read<BusinessProvider>().currentBusiness;
              if (biz == null) return;
              final newSupplier = Supplier(
                id: _uuid.v4(),
                businessId: biz.id,
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                address: addrCtrl.text.trim(),
              );
              Navigator.pop(ctx, newSupplier);
            },
            child: const Text('Save Supplier'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      await context.read<SupplierProvider>().saveSupplier(result);
      setState(() {
        _selectedSupplier = result;
      });
    }
  }

  Future<void> _savePurchase() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one line item to inward'),
          backgroundColor: Colors.amber,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final biz = context.read<BusinessProvider>().currentBusiness;
    if (biz == null) return;

    setState(() => _isSaving = true);

    final purchaseId = _uuid.v4();
    final invoiceNo = _invoiceNoController.text.trim().isNotEmpty
        ? _invoiceNoController.text.trim()
        : 'PUR-${DateTime.now().millisecondsSinceEpoch % 10000}';

    final purchaseItems = _items.map((it) {
      return it.copyWith(purchaseId: purchaseId);
    }).toList();

    final purchase = Purchase(
      id: purchaseId,
      businessId: biz.id,
      supplierId: _selectedSupplier?.id,
      supplierName: _selectedSupplier?.name,
      invoiceNo: invoiceNo,
      status: _status,
      subtotal: _calculatedSubtotal,
      taxAmount: _calculatedTaxAmount,
      discountAmount: _calculatedItemDiscounts,
      roundOff: _calculatedRoundOff,
      totalAmount: _finalTotalAmount,
      paymentStatus: _paymentStatus,
      paymentMethod: _paymentMethod,
      paidAmount: _paidAmount,
      dueAmount: _dueAmount,
      dueDate: _dueDate,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      createdAt: _purchaseDate,
      items: purchaseItems,
    );

    try {
      await context.read<PurchaseProvider>().createPurchase(purchase);

      // Refresh product inventory and supplier list across the application
      if (mounted) {
        context.read<ProductProvider>().loadProducts(biz.id);
        context.read<SupplierProvider>().loadSuppliers(biz.id);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase invoice $invoiceNo inwarded successfully!'),
            backgroundColor: _emerald,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Close entry and show GRN voucher dialog
        Navigator.pop(context);
        PurchaseDetailDialog.show(context, purchase);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving purchase: $e'),
            backgroundColor: _rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final symbol = context.watch<BusinessProvider>().currentBusiness?.currencySymbol ?? '₹';
    final suppliers = context.watch<SupplierProvider>().suppliers;
    final products = context.watch<ProductProvider>().allProducts;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stock Inward / New Purchase', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Record supplier invoices, FEFO batches, scheme units & stock',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _emerald,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_outline, size: 20),
              label: Text(_isSaving ? 'Inwarding...' : 'Save & Inward Stock',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _isSaving ? null : _savePurchase,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Bill & Supplier Information Card
            _buildBillInfoCard(theme, isDark, suppliers),
            const SizedBox(height: 16),

            // 2. High-Speed Product Entry Row
            _buildProductEntryCard(theme, isDark, products, symbol),
            const SizedBox(height: 16),

            // 3. Line Items Data Table
            _buildItemsTable(theme, isDark, symbol),
            const SizedBox(height: 16),

            // 4. Financial Summary & Reconciliation Bar
            _buildSummaryCard(theme, isDark, symbol),
          ],
        ),
      ),
    );
  }

  Widget _buildBillInfoCard(ThemeData theme, bool isDark, List<Supplier> suppliers) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Invoice & Supplier Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                // Status Toggle (Received vs Pending)
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Received', label: Text('Received (Inward Stock)')),
                    ButtonSegment(value: 'Pending', label: Text('Order Pending')),
                  ],
                  selected: {_status},
                  onSelectionChanged: (newVal) {
                    setState(() => _status = newVal.first);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Inward PO / GRN No
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: _invoiceNoController,
                    decoration: const InputDecoration(
                      labelText: 'GRN / PO #',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                // Supplier Dropdown + Quick Add
                SizedBox(
                  width: 280,
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<Supplier>(
                          key: ValueKey(_selectedSupplier?.id),
                          initialValue: _selectedSupplier,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Supplier / Vendor',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          hint: const Text('Select Supplier'),
                          items: suppliers.map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Text(
                                s.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedSupplier = val),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.add, size: 20),
                        tooltip: 'Add New Supplier',
                        onPressed: _showAddSupplierDialog,
                      ),
                    ],
                  ),
                ),

                // Supplier Bill Ref No
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: _billRefController,
                    decoration: const InputDecoration(
                      labelText: 'Supplier Bill #',
                      hintText: 'e.g. INV-9872',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                // Inward Date Picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _purchaseDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setState(() => _purchaseDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 8),
                        Text('Date: ${_dateFormat.format(_purchaseDate)}'),
                      ],
                    ),
                  ),
                ),

                // Payment Status
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(_paymentStatus),
                    initialValue: _paymentStatus,
                    decoration: const InputDecoration(
                      labelText: 'Payment Status',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                      DropdownMenuItem(value: 'Partial', child: Text('Partial')),
                      DropdownMenuItem(value: 'Due', child: Text('Credit / Due')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _paymentStatus = val;
                          if (val == 'Paid') {
                            _paidAmountController.text = _finalTotalAmount.toStringAsFixed(2);
                          } else if (val == 'Due') {
                            _paidAmountController.text = '0.00';
                          }
                        });
                      }
                    },
                  ),
                ),

                // Payment Method
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(_paymentMethod),
                    initialValue: _paymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'Payment Mode',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Bank/UPI', child: Text('Bank/UPI')),
                      DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                      DropdownMenuItem(value: 'Credit', child: Text('Credit Line')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _paymentMethod = val);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductEntryCard(
    ThemeData theme,
    bool isDark,
    List<Product> products,
    String symbol,
  ) {
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add_shopping_cart_rounded, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Add Medicine / Item to Inward',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                if (_selectedProduct != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Current Stock: ${_selectedProduct!.stockQty} ${_selectedProduct!.unit}',
                      style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),

            // Autocomplete Search Bar for Product
            Autocomplete<Product>(
              displayStringForOption: (p) => '${p.name} (${p.barcode.isNotEmpty ? p.barcode : p.sku})',
              optionsBuilder: (TextEditingValue textVal) {
                if (textVal.text.trim().isEmpty) return const Iterable<Product>.empty();
                final query = textVal.text.toLowerCase();
                return products.where((p) =>
                    p.name.toLowerCase().contains(query) ||
                    p.barcode.toLowerCase().contains(query) ||
                    p.sku.toLowerCase().contains(query));
              },
              onSelected: _onProductSelected,
              fieldViewBuilder: (ctx, textEditingCtrl, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: textEditingCtrl,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Search Product / Scan Barcode *',
                    hintText: 'Type medicine name, SKU or scan barcode...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: textEditingCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              textEditingCtrl.clear();
                              setState(() => _selectedProduct = null);
                            },
                          )
                        : null,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Input Fields Row: Batch, Expiry, Billed Qty, Free Qty, Unit Cost, MRP, Tax%, Discount
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Batch No
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: _batchController,
                    decoration: const InputDecoration(
                      labelText: 'Batch No',
                      hintText: 'e.g. B892',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                // Expiry Date (MM/YY)
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _expiryController,
                    decoration: const InputDecoration(
                      labelText: 'Expiry (MM/YY)',
                      hintText: '11/27',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                // Billed Qty
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Billed Qty *',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                // Free / Bonus Scheme Qty (10+2)
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: _freeQtyController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Free Qty (Bonus)',
                      hintText: '0',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                // Unit Cost Rate
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _unitCostController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Purchase Rate *',
                      prefixText: symbol,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),

                // Tax Rate % (GST)
                SizedBox(
                  width: 100,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(_taxRateController.text),
                    initialValue: ['0', '5', '12', '18', '28'].contains(_taxRateController.text)
                        ? _taxRateController.text
                        : '12',
                    decoration: const InputDecoration(
                      labelText: 'GST %',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: '0', child: Text('0%')),
                      DropdownMenuItem(value: '5', child: Text('5%')),
                      DropdownMenuItem(value: '12', child: Text('12%')),
                      DropdownMenuItem(value: '18', child: Text('18%')),
                      DropdownMenuItem(value: '28', child: Text('28%')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _taxRateController.text = val);
                    },
                  ),
                ),

                // MRP
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: _mrpController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'MRP',
                      prefixText: symbol,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),

                // Discount (₹)
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _discountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Discount',
                      prefixText: symbol,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),

                // Add Item Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Line', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _addItem,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsTable(ThemeData theme, bool isDark, String symbol) {
    if (_items.isEmpty) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add_rounded, size: 36, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'No line items added yet.',
              style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              'Search for medicine / products above and click "Add Line"',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            child: Row(
              children: [
                const SizedBox(width: 30, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                const Expanded(flex: 4, child: Text('Item & Batch Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                const Expanded(flex: 2, child: Text('Billed + Free', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
                const Expanded(flex: 2, child: Text('Cost Rate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
                const Expanded(flex: 2, child: Text('Tax %', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
                const Expanded(flex: 2, child: Text('MRP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
                const Expanded(flex: 2, child: Text('Effective Cost', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
                const Expanded(flex: 2, child: Text('Line Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
                const SizedBox(width: 48),
              ],
            ),
          ),
          // Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
            ),
            itemBuilder: (context, index) {
              final item = _items[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    SizedBox(width: 30, child: Text('${index + 1}', style: const TextStyle(fontSize: 12, color: Colors.grey))),
                    // Name & Batch
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: 6,
                            children: [
                              if (item.batchNumber != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('Batch: ${item.batchNumber}',
                                      style: const TextStyle(fontSize: 10, color: Colors.blue)),
                                ),
                              if (item.batchExpiry != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('Exp: ${item.batchExpiry}',
                                      style: const TextStyle(fontSize: 10, color: Colors.purple)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Qty + Free
                    Expanded(
                      flex: 2,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          if (item.freeQuantity > 0) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: _emerald.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '+${item.freeQuantity > 0 ? item.freeQuantity.round() : 0} Free',
                                style: const TextStyle(fontSize: 10, color: _emerald, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Cost Rate
                    Expanded(
                      flex: 2,
                      child: Text(
                        '$symbol${item.unitCost.toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    // Tax Rate
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${item.taxRate}%',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    // MRP
                    Expanded(
                      flex: 2,
                      child: Text(
                        item.mrp != null ? '$symbol${item.mrp!.toStringAsFixed(2)}' : '-',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    // Effective Cost
                    Expanded(
                      flex: 2,
                      child: Text(
                        '$symbol${item.effectiveCostPerUnit.toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.w600),
                      ),
                    ),
                    // Line Total
                    Expanded(
                      flex: 2,
                      child: Text(
                        '$symbol${item.totalCost.toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Action
                    SizedBox(
                      width: 48,
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: _rose),
                        onPressed: () => _removeItem(index),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, bool isDark, String symbol) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notes / Remarks field
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Remarks / Inward Notes',
                  hintText: 'Transporter details, consignment receipt, remarks...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: [
                  Chip(
                    avatar: const Icon(Icons.format_list_numbered, size: 16),
                    label: Text('Items: ${_items.length}'),
                  ),
                  Chip(
                    avatar: const Icon(Icons.inventory_rounded, size: 16),
                    label: Text('Total Units: $_totalBilledUnits Billed + $_totalFreeUnits Free'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),

        // Financial Calculation Box
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildAmountRow('Subtotal', '$symbol${_calculatedSubtotal.toStringAsFixed(2)}'),
                if (_calculatedItemDiscounts > 0)
                  _buildAmountRow(
                    'Line Discounts',
                    '-$symbol${_calculatedItemDiscounts.toStringAsFixed(2)}',
                    color: _emerald,
                  ),
                if (_calculatedTaxAmount > 0)
                  _buildAmountRow('GST Tax', '+$symbol${_calculatedTaxAmount.toStringAsFixed(2)}'),
                if (_calculatedRoundOff != 0)
                  _buildAmountRow('Round Off', '$symbol${_calculatedRoundOff.toStringAsFixed(2)}'),
                const Divider(height: 20),
                _buildAmountRow(
                  'Net Grand Total',
                  '$symbol${_finalTotalAmount.toStringAsFixed(2)}',
                  isBold: true,
                  fontSize: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),

                // Paid and Due Amount Inputs
                if (_paymentStatus == 'Partial') ...[
                  TextField(
                    controller: _paidAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Paid Amount Now',
                      prefixText: symbol,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                _buildAmountRow(
                  'Balance Due',
                  '$symbol${_dueAmount.toStringAsFixed(2)}',
                  isBold: true,
                  fontSize: 14,
                  color: _dueAmount > 0 ? _rose : _emerald,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 13,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
