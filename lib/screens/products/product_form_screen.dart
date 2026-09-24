import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/product.dart';
import '../../modules/business_type.dart';
import '../../providers/business_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/indian_medicine_service.dart';

class ProductFormScreen extends StatefulWidget {
  final String businessId;
  final Product? product;

  const ProductFormScreen({
    super.key,
    required this.businessId,
    this.product,
  });

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Uuid _uuid = const Uuid();

  late TextEditingController _nameCtrl;
  late TextEditingController _skuCtrl;
  late TextEditingController _barcodeCtrl;
  late TextEditingController _buyPriceCtrl;
  late TextEditingController _sellPriceCtrl;
  late TextEditingController _mrpCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _minStockCtrl;
  late TextEditingController _unitCtrl;
  late TextEditingController _brandCtrl;
  late TextEditingController _genericCtrl;
  late TextEditingController _hsnCtrl;
  late TextEditingController _taxRateCtrl;
  late TextEditingController _rackCtrl;
  late TextEditingController _unitsPerPackCtrl;

  // Initial Batch fields
  bool _addInitialBatch = true;
  late TextEditingController _batchNoCtrl;
  DateTime _batchExpiry = DateTime.now().add(const Duration(days: 365 * 2));

  String? _selectedCategory;
  String _dosageForm = 'tablet';
  Map<String, dynamic> _metadata = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    final meta = p?.metadata ?? {};

    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _skuCtrl = TextEditingController(text: p?.sku ?? 'SKU-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}');
    _barcodeCtrl = TextEditingController(text: p?.barcode ?? '');
    _buyPriceCtrl = TextEditingController(text: p != null ? (p.purchasePrice % 1 == 0 ? p.purchasePrice.toStringAsFixed(0) : p.purchasePrice.toStringAsFixed(2)) : '20');
    _sellPriceCtrl = TextEditingController(text: p != null ? (p.sellingPrice % 1 == 0 ? p.sellingPrice.toStringAsFixed(0) : p.sellingPrice.toStringAsFixed(2)) : '30');
    _mrpCtrl = TextEditingController(text: p != null ? (p.mrp % 1 == 0 ? p.mrp.toStringAsFixed(0) : p.mrp.toStringAsFixed(2)) : '35');
    _stockCtrl = TextEditingController(text: p?.stockQty.toString() ?? '10');
    _minStockCtrl = TextEditingController(text: p?.minStockAlert.toString() ?? '5');
    _unitCtrl = TextEditingController(text: p?.unit ?? 'strip');
    _brandCtrl = TextEditingController(text: p?.brand ?? '');
    _genericCtrl = TextEditingController(text: meta['generic_name'] ?? meta['composition'] ?? '');
    _hsnCtrl = TextEditingController(text: meta['hsn_code'] ?? '3004');
    _taxRateCtrl = TextEditingController(text: p != null ? p.taxRate.toStringAsFixed(0) : '12');
    _rackCtrl = TextEditingController(text: meta['rack_location'] ?? meta['shelf'] ?? '');
    _unitsPerPackCtrl = TextEditingController(text: meta['tablets_per_strip']?.toString() ?? meta['units_per_pack']?.toString() ?? '10');

    _batchNoCtrl = TextEditingController(text: 'B-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}');

    _dosageForm = meta['dosage_form'] ?? 'tablet';
    _selectedCategory = p?.categoryId;
    _metadata = p != null ? Map<String, dynamic>.from(p.metadata) : {};

    // Don't auto-add initial batch if editing existing product that already has batches
    if (p != null && (_metadata['batches'] as List?)?.isNotEmpty == true) {
      _addInitialBatch = false;
    }

    _buyPriceCtrl.addListener(() => setState(() {}));
    _sellPriceCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _barcodeCtrl.dispose();
    _buyPriceCtrl.dispose();
    _sellPriceCtrl.dispose();
    _mrpCtrl.dispose();
    _stockCtrl.dispose();
    _minStockCtrl.dispose();
    _unitCtrl.dispose();
    _brandCtrl.dispose();
    _genericCtrl.dispose();
    _hsnCtrl.dispose();
    _taxRateCtrl.dispose();
    _rackCtrl.dispose();
    _unitsPerPackCtrl.dispose();
    _batchNoCtrl.dispose();
    super.dispose();
  }

  void _onMedicineSuggestionSelected(Map<String, dynamic> opt) {
    setState(() {
      _nameCtrl.text = opt['name'] ?? '';
      _brandCtrl.text = opt['manufacturer_name'] ?? '';

      final comp = [
        opt['short_composition1'] ?? '',
        opt['short_composition2'] ?? '',
      ].where((s) => s.toString().trim().isNotEmpty).join(' + ');
      _genericCtrl.text = comp;

      final priceNum = (opt['price(₹)'] as num?)?.toDouble();
      if (priceNum != null && priceNum > 0) {
        _mrpCtrl.text = priceNum % 1 == 0 ? priceNum.toStringAsFixed(0) : priceNum.toStringAsFixed(2);
        final estSell = (priceNum * 0.95);
        final estCost = (priceNum * 0.70);
        _sellPriceCtrl.text = estSell % 1 == 0 ? estSell.toStringAsFixed(0) : estSell.toStringAsFixed(2);
        _buyPriceCtrl.text = estCost % 1 == 0 ? estCost.toStringAsFixed(0) : estCost.toStringAsFixed(2);
      }

      final packLabel = (opt['pack_size_label'] ?? '').toString().toLowerCase();
      if (packLabel.contains('syrup') || packLabel.contains('suspension') || packLabel.contains('liquid')) {
        _dosageForm = 'syrup';
        _unitCtrl.text = 'bottle';
      } else if (packLabel.contains('capsule')) {
        _dosageForm = 'capsule';
        _unitCtrl.text = 'strip';
      } else if (packLabel.contains('injection') || packLabel.contains('vial') || packLabel.contains('ampoule')) {
        _dosageForm = 'injection';
        _unitCtrl.text = 'vial';
      } else if (packLabel.contains('cream') || packLabel.contains('ointment') || packLabel.contains('gel')) {
        _dosageForm = 'cream';
        _unitCtrl.text = 'tube';
      } else if (packLabel.contains('inhaler') || packLabel.contains('respule')) {
        _dosageForm = 'inhaler';
        _unitCtrl.text = 'inhaler';
      } else if (packLabel.contains('drop')) {
        _dosageForm = 'drops';
        _unitCtrl.text = 'bottle';
      } else {
        _dosageForm = 'tablet';
        _unitCtrl.text = 'strip';
      }

      // Try extract pack size number
      final match = RegExp(r'(\d+)\s*(tablets|capsules|caps|tabs|ml|gm)').firstMatch(packLabel);
      if (match != null) {
        _unitsPerPackCtrl.text = match.group(1) ?? '10';
      }

      _hsnCtrl.text = '3004';
      _taxRateCtrl.text = '12';
    });
  }

  void _generateBarcode() {
    setState(() {
      _barcodeCtrl.text = '890${DateTime.now().millisecondsSinceEpoch.toString().substring(3)}';
    });
  }

  Future<void> _pickBatchExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _batchExpiry,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 6)),
    );
    if (picked != null) {
      setState(() => _batchExpiry = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final prodProv = context.read<ProductProvider>();
    final categories = prodProv.categories;
    final effectiveCatId = _selectedCategory ?? (categories.isNotEmpty ? categories.first.id : 'default');

    final stock = double.tryParse(_stockCtrl.text) ?? 0.0;
    final mrp = double.tryParse(_mrpCtrl.text) ?? (double.tryParse(_sellPriceCtrl.text) ?? 0.0);
    final tabletsPerStrip = int.tryParse(_unitsPerPackCtrl.text) ?? 10;

    // Update metadata
    _metadata['dosage_form'] = _dosageForm;
    _metadata['tablets_per_strip'] = tabletsPerStrip;
    _metadata['units_per_pack'] = tabletsPerStrip;
    _metadata['generic_name'] = _genericCtrl.text.trim();
    _metadata['composition'] = _genericCtrl.text.trim();
    _metadata['hsn_code'] = _hsnCtrl.text.trim();
    _metadata['rack_location'] = _rackCtrl.text.trim();

    // Initial batch handling
    if (_addInitialBatch && stock > 0) {
      final existingBatches = (_metadata['batches'] as List<dynamic>?)
              ?.map((b) => Map<String, dynamic>.from(b as Map))
              .toList() ??
          [];

      final newBatch = {
        'batch_number': _batchNoCtrl.text.trim(),
        'expiry': DateFormat('yyyy-MM-dd').format(_batchExpiry),
        'mrp': mrp,
        'purchase_price': double.tryParse(_buyPriceCtrl.text) ?? 0.0,
        'stock': stock.toInt(),
      };

      // Add or update
      final idx = existingBatches.indexWhere((b) => b['batch_number'] == newBatch['batch_number']);
      if (idx >= 0) {
        existingBatches[idx] = newBatch;
      } else {
        existingBatches.add(newBatch);
      }
      _metadata['batches'] = existingBatches;
    }

    final product = Product(
      id: widget.product?.id ?? _uuid.v4(),
      businessId: widget.businessId,
      categoryId: effectiveCatId,
      name: _nameCtrl.text.trim(),
      sku: _skuCtrl.text.trim(),
      barcode: _barcodeCtrl.text.trim(),
      purchasePrice: double.tryParse(_buyPriceCtrl.text) ?? 0.0,
      sellingPrice: double.tryParse(_sellPriceCtrl.text) ?? 0.0,
      mrp: mrp,
      stockQty: stock,
      minStockAlert: double.tryParse(_minStockCtrl.text) ?? 5.0,
      unit: _unitCtrl.text.trim(),
      brand: _brandCtrl.text.trim(),
      taxRate: double.tryParse(_taxRateCtrl.text) ?? 0.0,
      metadata: _metadata,
    );

    await prodProv.saveProduct(product);
    setState(() => _saving = false);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    final bizProv = context.watch<BusinessProvider>();
    final prodProv = context.watch<ProductProvider>();
    final currentBiz = bizProv.currentBusiness;
    final symbol = currentBiz?.currencySymbol ?? '₹';
    final isMedical = currentBiz?.type == BusinessType.medical;

    final categories = prodProv.categories;

    // Live Margin & Markup Math
    final cost = double.tryParse(_buyPriceCtrl.text) ?? 0.0;
    final sell = double.tryParse(_sellPriceCtrl.text) ?? 0.0;
    final profit = sell - cost;
    final marginPct = sell > 0 ? ((profit / sell) * 100) : 0.0;
    final markupPct = cost > 0 ? ((profit / cost) * 100) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? (isMedical ? 'Edit Medicine' : 'Edit Product') : (isMedical ? 'Add Medicine (Indian Dataset)' : 'Add Product')),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton.icon(
              icon: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(isEditing ? 'Update' : 'Save Item'),
              onPressed: _saving ? null : _save,
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 1. Basic Information Card (with Indian Medicine Dataset Autocomplete)
            _cardSection(
              title: isMedical ? 'Medicine Identification (Indian DB Autocomplete)' : 'Basic Information',
              icon: isMedical ? Icons.medication_rounded : Icons.info_outline_rounded,
              children: [
                if (isMedical)
                  _buildMedicineAutocomplete()
                else
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Product Name *', prefixIcon: Icon(Icons.label_outline_rounded)),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Product name is required' : null,
                  ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _brandCtrl,
                        decoration: InputDecoration(
                          labelText: isMedical ? 'Manufacturer / Brand' : 'Brand Name',
                          prefixIcon: const Icon(Icons.business_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCategory ?? (categories.isNotEmpty ? categories.first.id : null),
                        decoration: const InputDecoration(labelText: 'Category *', prefixIcon: Icon(Icons.category_outlined)),
                        items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                        onChanged: (val) => setState(() => _selectedCategory = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (isMedical) ...[
                  TextFormField(
                    controller: _genericCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Generic Name / Salt Composition',
                      prefixIcon: Icon(Icons.science_outlined),
                      helperText: 'e.g. Paracetamol (650mg) + Caffeine (50mg)',
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _barcodeCtrl,
                        decoration: InputDecoration(
                          labelText: 'Barcode / EAN',
                          prefixIcon: const Icon(Icons.qr_code_rounded),
                          suffixIcon: IconButton(
                            tooltip: 'Generate EAN Barcode',
                            icon: const Icon(Icons.auto_fix_high_rounded, size: 20),
                            onPressed: _generateBarcode,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _skuCtrl,
                        decoration: const InputDecoration(labelText: 'SKU Code *', prefixIcon: Icon(Icons.tag_rounded)),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'SKU is required' : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 2. Pricing, Margins & Tax Card
            _cardSection(
              title: 'Pricing, Taxes & Live Margin Calculator',
              icon: Icons.payments_outlined,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _buyPriceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: 'Purchase Cost ($symbol) *', prefixIcon: const Icon(Icons.arrow_downward_rounded)),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _sellPriceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: 'Selling Price ($symbol) *', prefixIcon: const Icon(Icons.arrow_upward_rounded)),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _mrpCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: 'Printed MRP ($symbol)', prefixIcon: const Icon(Icons.price_check_rounded)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _taxRateCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'GST Tax Rate (%)', prefixIcon: Icon(Icons.receipt_long_rounded)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _hsnCtrl,
                        decoration: const InputDecoration(labelText: 'HSN Code', prefixIcon: Icon(Icons.numbers_rounded)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Live Profit Margin Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: profit >= 0 ? const Color(0xFF10B981).withAlpha(16) : const Color(0xFFEF4444).withAlpha(16),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: profit >= 0 ? const Color(0xFF10B981).withAlpha(60) : const Color(0xFFEF4444).withAlpha(60),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _marginStat('Profit / Unit', CurrencyFormatter.format(profit, symbol: symbol), profit >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                      _marginStat('Profit Margin', '${marginPct.toStringAsFixed(1)}%', profit >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                      _marginStat('Markup on Cost', '${markupPct.toStringAsFixed(1)}%', const Color(0xFF0284C7)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 3. Packaging & Dispensing Configuration (Medical Specific)
            if (isMedical) ...[
              _cardSection(
                title: 'Packaging & Dispensing Options',
                icon: Icons.inventory_rounded,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _dosageForm,
                          decoration: const InputDecoration(labelText: 'Dosage Form *', prefixIcon: Icon(Icons.vaccines_rounded)),
                          items: const [
                            DropdownMenuItem(value: 'tablet', child: Text('Tablet (Tabs/Strip)')),
                            DropdownMenuItem(value: 'capsule', child: Text('Capsule (Caps/Strip)')),
                            DropdownMenuItem(value: 'syrup', child: Text('Syrup / Liquid Bottle')),
                            DropdownMenuItem(value: 'injection', child: Text('Injection / Vial / Ampoule')),
                            DropdownMenuItem(value: 'cream', child: Text('Cream / Ointment / Gel')),
                            DropdownMenuItem(value: 'inhaler', child: Text('Inhaler / Respule')),
                            DropdownMenuItem(value: 'device', child: Text('Medical Device / Monitor')),
                            DropdownMenuItem(value: 'drops', child: Text('Eye / Ear / Nasal Drops')),
                            DropdownMenuItem(value: 'other', child: Text('Other Healthcare Item')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _dosageForm = val;
                                if (val == 'syrup' || val == 'drops') {
                                  _unitCtrl.text = 'bottle';
                                } else if (val == 'cream') {
                                  _unitCtrl.text = 'tube';
                                } else if (val == 'injection') {
                                  _unitCtrl.text = 'vial';
                                } else if (val == 'device') {
                                  _unitCtrl.text = 'pc';
                                } else if (val == 'tablet' || val == 'capsule') {
                                  _unitCtrl.text = 'strip';
                                }
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _unitsPerPackCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: _dosageForm == 'tablet' || _dosageForm == 'capsule'
                                ? 'Tablets/Caps per Strip *'
                                : 'Pack Size (ml / gm / pcs)',
                            prefixIcon: const Icon(Icons.layers_outlined),
                            helperText: (_dosageForm == 'tablet' || _dosageForm == 'capsule')
                                ? 'Enables loose tablet billing in POS'
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _unitCtrl,
                          decoration: const InputDecoration(labelText: 'Billing Unit Label', prefixIcon: Icon(Icons.straighten_rounded)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _rackCtrl,
                          decoration: const InputDecoration(labelText: 'Rack / Shelf Location', prefixIcon: Icon(Icons.shelves)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
            ],

            // 4. Stock & Initial FEFO Batch Card
            _cardSection(
              title: 'Stock Inventory & Initial FEFO Batch',
              icon: Icons.inventory_2_outlined,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Opening Stock Quantity *',
                          prefixIcon: const Icon(Icons.warehouse_rounded),
                          suffixText: _unitCtrl.text,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _minStockCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Minimum Alert Level', prefixIcon: Icon(Icons.notification_important_outlined)),
                      ),
                    ),
                  ],
                ),

                if (isMedical) ...[
                  const SizedBox(height: 14),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Register Initial Batch with Expiry Date', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    subtitle: const Text('Enables immediate FEFO batch selection in POS billing', style: TextStyle(fontSize: 11.5)),
                    value: _addInitialBatch,
                    onChanged: (val) => setState(() => _addInitialBatch = val ?? false),
                  ),
                  if (_addInitialBatch) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _batchNoCtrl,
                            decoration: const InputDecoration(labelText: 'Batch Number *', prefixIcon: Icon(Icons.qr_code_2_rounded)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _pickBatchExpiry,
                            borderRadius: BorderRadius.circular(10),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Expiry Date *',
                                prefixIcon: Icon(Icons.event_rounded),
                              ),
                              child: Text(
                                DateFormat('yyyy-MM-dd').format(_batchExpiry),
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
            const SizedBox(height: 24),

            // Big Save Button
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                icon: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_rounded),
                label: Text(isEditing ? 'Update Item' : 'Save & Register Product', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                onPressed: _saving ? null : _save,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _cardSection({required String title, required IconData icon, required List<Widget> children}) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 22),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _marginStat(String title, String val, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }

  Widget _buildMedicineAutocomplete() {
    final svc = IndianMedicineService.instance;

    return Autocomplete<Map<String, dynamic>>(
      optionsBuilder: (TextEditingValue tv) {
        if (tv.text.length < 2) return const Iterable<Map<String, dynamic>>.empty();
        return svc.search(tv.text);
      },
      displayStringForOption: (opt) => opt['name']?.toString() ?? '',
      onSelected: _onMedicineSuggestionSelected,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        // Keep controller in sync with _nameCtrl
        if (controller.text != _nameCtrl.text) {
          controller.text = _nameCtrl.text;
        }
        controller.addListener(() {
          if (_nameCtrl.text != controller.text) {
            _nameCtrl.text = controller.text;
          }
        });

        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Medicine Name * (Indian Dataset Autocomplete)',
            prefixIcon: const Icon(Icons.medication_rounded),
            suffixIcon: svc.isLoaded
                ? const Tooltip(
                    message: 'Indian medicine dataset loaded',
                    child: Icon(Icons.cloud_done_rounded, color: Color(0xFF10B981), size: 20),
                  )
                : const Tooltip(
                    message: 'Dataset syncing / offline fallback active',
                    child: Icon(Icons.cloud_queue_rounded, color: Colors.grey, size: 20),
                  ),
            helperText: 'Type to auto-fill salt, manufacturer, dosage form, MRP',
          ),
          validator: (_) => _nameCtrl.text.trim().isEmpty ? 'Medicine name is required' : null,
          onFieldSubmitted: (_) => onFieldSubmitted(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480, maxHeight: 300),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final opt = options.elementAt(index);
                  final name = opt['name'] ?? '';
                  final brand = opt['manufacturer_name'] ?? '';
                  final comp = [
                    opt['short_composition1'] ?? '',
                    opt['short_composition2'] ?? '',
                  ].where((s) => s.toString().trim().isNotEmpty).join(' + ');
                  final price = opt['price(₹)'];

                  return ListTile(
                    dense: true,
                    leading: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.medication_liquid_rounded, size: 18, color: Color(0xFF0284C7)),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (brand.toString().isNotEmpty)
                          Text(brand, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        if (comp.isNotEmpty)
                          Text(comp, style: const TextStyle(fontSize: 11, color: Color(0xFF10B981)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                    trailing: price != null
                        ? Text('₹$price', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF059669)))
                        : null,
                    onTap: () => onSelected(opt),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
