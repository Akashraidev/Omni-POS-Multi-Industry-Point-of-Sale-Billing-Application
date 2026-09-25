import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/product.dart';
import '../../../providers/business_provider.dart';
import '../../../providers/cart_provider.dart';
import '../medical_batch_analyzer.dart';
import '../medical_palette.dart';

enum MedicinePackagingMode {
  stripOnly,
  looseOnly,
  stripAndLoose,
  singleUnit,
}

/// A comprehensive modal dialog for dispensing medicine in a pharmacy.
///
/// Supports:
/// 1. Dosage forms: Tablet, Capsule, Syrup, Injection, Cream, Inhaler, Device, Other
/// 2. Packaging modes: Loose only, Strip only, Loose + Strip, Bottle, Tube, Vial, etc.
/// 3. FEFO Batch selection with expiry status
/// 4. Direct price and discount adjustments
/// 5. Works for both adding new items and editing existing cart lines.
class MedicalDispenseDialog extends StatefulWidget {
  final Product product;
  final int? cartIndex;
  final String? initialBatch;
  final VoidCallback? onCompleted;

  const MedicalDispenseDialog({
    super.key,
    required this.product,
    this.cartIndex,
    this.initialBatch,
    this.onCompleted,
  });

  static Future<bool?> show(
    BuildContext context, {
    required Product product,
    int? cartIndex,
    String? initialBatch,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => MedicalDispenseDialog(
        product: product,
        cartIndex: cartIndex,
        initialBatch: initialBatch,
      ),
    );
  }

  @override
  State<MedicalDispenseDialog> createState() => _MedicalDispenseDialogState();
}

class _MedicalDispenseDialogState extends State<MedicalDispenseDialog> {
  // dosage form is auto-detected from product metadata / name — never editable by cashier.
  late String _dosageForm;
  late MedicinePackagingMode _packagingMode;
  late int _packSize; // e.g. 10 tablets per strip
  late int _stripCount;
  late int _looseCount;
  late double _singleUnitQty;
  late TextEditingController _priceCtrl;
  late TextEditingController _discCtrl;
  late TextEditingController _freeCtrl;
  late TextEditingController _packSizeCtrl;

  String? _selectedBatchNo;
  String? _selectedBatchExpiry;
  List<MedicalBatchRow> _batches = [];

  bool get isEditMode => widget.cartIndex != null;

  // Convenience getter — used throughout the build tree.
  String get _selectedDosageForm => _dosageForm;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _batches = MedicalBatchAnalyzer.batchesFor(p);

    // Initial batch selection (FEFO earliest or pre-existing)
    if (widget.initialBatch != null && widget.initialBatch!.isNotEmpty) {
      _selectedBatchNo = widget.initialBatch;
      final match = _batches.where((b) => b.batchNo == widget.initialBatch).firstOrNull;
      if (match != null) {
        _selectedBatchExpiry = DateFormatter.formatIsoDate(match.expiryDate);
      }
    } else if (_batches.isNotEmpty) {
      _selectedBatchNo = _batches.first.batchNo;
      _selectedBatchExpiry = DateFormatter.formatIsoDate(_batches.first.expiryDate);
    }

    // Dosage form: always derived from product configuration, never editable at billing time.
    _dosageForm = _inferDosageForm(p);

    // Default pack size (tablets/capsules per strip)
    _packSize = (p.metadata['tablets_per_strip'] as num?)?.toInt() ??
        (p.metadata['pack_size'] as num?)?.toInt() ??
        (p.unit.toLowerCase() == 'strip' ? 10 : 1);
    if (_packSize <= 0) _packSize = 10;

    _stripCount = 1;
    _looseCount = 0;
    _singleUnitQty = 1.0;
    _packagingMode = (_dosageForm == 'tablet' || _dosageForm == 'capsule')
        ? MedicinePackagingMode.stripOnly
        : MedicinePackagingMode.singleUnit;

    double initialPrice = p.sellingPrice;
    double initialDisc = 0.0;
    double initialFree = 0.0;

    // If editing an existing cart item, restore its exact values
    if (isEditMode) {
      final cart = context.read<CartProvider>();
      if (widget.cartIndex! < cart.items.length) {
        final it = cart.items[widget.cartIndex!];
        initialPrice = it.unitPrice;
        initialDisc = it.discountAmount;
        initialFree = it.freeQuantity;
        if (it.selectedBatch != null) {
          _selectedBatchNo = it.selectedBatch;
          _selectedBatchExpiry = it.batchExpiry;
        }
        if (it.dosageForm != null) _dosageForm = it.dosageForm!;
        if (it.packSize != null && it.packSize! > 0) _packSize = it.packSize!;
        if (it.stripCount != null) _stripCount = it.stripCount!;
        if (it.looseCount != null) _looseCount = it.looseCount!;

        if (it.packagingType == 'strip') {
          _packagingMode = MedicinePackagingMode.stripOnly;
        } else if (it.packagingType == 'loose') {
          _packagingMode = MedicinePackagingMode.looseOnly;
        } else if (it.packagingType == 'strip_loose') {
          _packagingMode = MedicinePackagingMode.stripAndLoose;
        } else {
          _packagingMode = MedicinePackagingMode.singleUnit;
          _singleUnitQty = it.quantity;
        }
      }
    }

    _priceCtrl = TextEditingController(
        text: initialPrice % 1 == 0 ? initialPrice.toStringAsFixed(0) : initialPrice.toStringAsFixed(2));
    _discCtrl = TextEditingController(
        text: initialDisc % 1 == 0 ? initialDisc.toStringAsFixed(0) : initialDisc.toStringAsFixed(2));
    _freeCtrl = TextEditingController(
        text: initialFree % 1 == 0 ? initialFree.toStringAsFixed(0) : initialFree.toStringAsFixed(2));
    _packSizeCtrl = TextEditingController(text: _packSize.toString());
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _discCtrl.dispose();
    _freeCtrl.dispose();
    _packSizeCtrl.dispose();
    super.dispose();
  }

  static String _inferDosageForm(Product p) {
    if (p.metadata['dosage_form'] != null) {
      return p.metadata['dosage_form'].toString().toLowerCase();
    }
    final name = p.name.toLowerCase();
    final unit = p.unit.toLowerCase();

    if (name.contains('monitor') || name.contains('meter') || name.contains('thermometer') || unit == 'pc') {
      return 'device';
    }
    if (name.contains('cream') || name.contains('ointment') || name.contains('gel') || name.contains('betadine') || unit == 'tube') {
      return 'cream';
    }
    if (name.contains('syrup') || name.contains('suspension') || name.contains('liquid') || unit == 'bottle') {
      return 'syrup';
    }
    if (name.contains('injection') || name.contains('vial') || name.contains('ampoule') || name.contains('insulin') || unit == 'pen') {
      return 'injection';
    }
    if (name.contains('inhaler') || name.contains('respule') || name.contains('rotacap')) {
      return 'inhaler';
    }
    if (name.contains('capsule') || name.contains('cap')) {
      return 'capsule';
    }
    if (name.contains('drop')) {
      return 'drops';
    }
    if (name.contains('tablet') || name.contains('tab') || unit == 'strip') {
      return 'tablet';
    }
    return 'other';
  }

  String _dosageFormLabel(String form) {
    switch (form) {
      case 'tablet':
        return 'Tablet';
      case 'capsule':
        return 'Capsule';
      case 'syrup':
        return 'Syrup / Liquid';
      case 'injection':
        return 'Injection / Vial';
      case 'cream':
        return 'Cream / Gel';
      case 'inhaler':
        return 'Inhaler';
      case 'device':
        return 'Device / Equipment';
      case 'drops':
        return 'Drops';
      default:
        return 'Other';
    }
  }

  IconData _iconForDosageForm(String form) {
    switch (form) {
      case 'tablet':
        return Icons.medication_rounded;
      case 'capsule':
        return Icons.medication_liquid_rounded;
      case 'syrup':
        return Icons.liquor_rounded;
      case 'injection':
        return Icons.vaccines_rounded;
      case 'cream':
        return Icons.science_outlined;
      case 'inhaler':
        return Icons.air_rounded;
      case 'device':
        return Icons.medical_services_rounded;
      case 'drops':
        return Icons.water_drop_rounded;
      default:
        return Icons.health_and_safety_rounded;
    }
  }

  Color _colorForDosageForm(String form) {
    switch (form) {
      case 'device':
        return const Color(0xFF6366F1); // Purple / Indigo
      case 'cream':
        return const Color(0xFF10B981); // Emerald green
      case 'tablet':
        return const Color(0xFF0284C7); // Sky / Blue
      case 'capsule':
        return const Color(0xFFF59E0B); // Amber
      case 'syrup':
        return const Color(0xFF06B6D4); // Cyan
      case 'injection':
        return const Color(0xFFEF4444); // Rose
      case 'inhaler':
        return const Color(0xFF8B5CF6); // Violet
      default:
        return MedicalPalette.primary;
    }
  }

  /// Total tablets or units calculation
  double get _computedBilledQuantity {
    if (_selectedDosageForm == 'tablet' || _selectedDosageForm == 'capsule') {
      switch (_packagingMode) {
        case MedicinePackagingMode.stripOnly:
          return _stripCount.toDouble();
        case MedicinePackagingMode.looseOnly:
          // In loose mode, quantity is in tablets
          return _looseCount.toDouble();
        case MedicinePackagingMode.stripAndLoose:
          // Total tablets = (strips * packSize) + loose
          final totalTabs = (_stripCount * _packSize) + _looseCount;
          return totalTabs.toDouble();
        case MedicinePackagingMode.singleUnit:
          return _singleUnitQty;
      }
    }
    return _singleUnitQty;
  }

  /// Effective unit price
  double get _computedUnitPrice {
    final basePrice = double.tryParse(_priceCtrl.text) ?? widget.product.sellingPrice;
    if (_selectedDosageForm == 'tablet' || _selectedDosageForm == 'capsule') {
      if (_packagingMode == MedicinePackagingMode.stripOnly) {
        return basePrice; // price per strip
      } else {
        // Price per tablet = basePrice (strip price) / packSize
        if (_packSize > 0) {
          return basePrice / _packSize;
        }
        return basePrice;
      }
    }
    return basePrice;
  }

  String get _computedPackagingDesc {
    if (_selectedDosageForm == 'tablet' || _selectedDosageForm == 'capsule') {
      final unitLabel = _selectedDosageForm == 'tablet' ? 'tab' : 'cap';
      switch (_packagingMode) {
        case MedicinePackagingMode.stripOnly:
          return '$_stripCount Strip${_stripCount > 1 ? 's' : ''} (${_stripCount * _packSize} ${unitLabel}s)';
        case MedicinePackagingMode.looseOnly:
          return '$_looseCount Loose $unitLabel${_looseCount > 1 ? 's' : ''}';
        case MedicinePackagingMode.stripAndLoose:
          final total = (_stripCount * _packSize) + _looseCount;
          return '$_stripCount Strip + $_looseCount Loose ($total ${unitLabel}s)';
        case MedicinePackagingMode.singleUnit:
          return '$_singleUnitQty ${widget.product.unit}';
      }
    } else if (_selectedDosageForm == 'cream') {
      return '${_singleUnitQty.toStringAsFixed(0)} Tube${_singleUnitQty > 1 ? 's' : ''}';
    } else if (_selectedDosageForm == 'syrup') {
      return '${_singleUnitQty.toStringAsFixed(0)} Bottle${_singleUnitQty > 1 ? 's' : ''}';
    } else if (_selectedDosageForm == 'injection') {
      return '${_singleUnitQty.toStringAsFixed(0)} Vial${_singleUnitQty > 1 ? 's' : ''}';
    } else if (_selectedDosageForm == 'inhaler') {
      return '${_singleUnitQty.toStringAsFixed(0)} Inhaler${_singleUnitQty > 1 ? 's' : ''}';
    } else if (_selectedDosageForm == 'device') {
      return '${_singleUnitQty.toStringAsFixed(0)} pc${_singleUnitQty > 1 ? 's' : ''}';
    }
    return '${_singleUnitQty.toStringAsFixed(0)} ${widget.product.unit}';
  }

  double get _lineSubtotal {
    final qty = _computedBilledQuantity;
    final unitP = _computedUnitPrice;
    final disc = double.tryParse(_discCtrl.text) ?? 0.0;
    final free = double.tryParse(_freeCtrl.text) ?? 0.0;
    final freeVal = unitP * free;
    final sub = (qty * unitP) - disc - freeVal;
    return sub < 0 ? 0.0 : sub;
  }

  double get _lineTax {
    return (_lineSubtotal * widget.product.taxRate) / 100.0;
  }

  double get _lineTotal {
    return _lineSubtotal + _lineTax;
  }

  void _onCommit() {
    final cart = context.read<CartProvider>();
    final qty = _computedBilledQuantity;
    final unitP = _computedUnitPrice;
    final disc = double.tryParse(_discCtrl.text) ?? 0.0;
    final free = double.tryParse(_freeCtrl.text) ?? 0.0;
    final desc = _computedPackagingDesc;

    String pkgType = 'unit';
    if (_packagingMode == MedicinePackagingMode.stripOnly) pkgType = 'strip';
    if (_packagingMode == MedicinePackagingMode.looseOnly) pkgType = 'loose';
    if (_packagingMode == MedicinePackagingMode.stripAndLoose) pkgType = 'strip_loose';

    if (isEditMode) {
      cart.updateCartItem(
        widget.cartIndex!,
        quantity: qty,
        unitPrice: unitP,
        discountAmount: disc,
        freeQuantity: free,
        batch: _selectedBatchNo,
        batchExpiry: _selectedBatchExpiry,
        dosageForm: _selectedDosageForm,
        packagingType: pkgType,
        stripCount: _stripCount,
        looseCount: _looseCount,
        packSize: _packSize,
        packagingDesc: desc,
      );
    } else {
      cart.addToCart(
        widget.product,
        quantity: qty,
        unitPrice: unitP,
        discountAmount: disc,
        batch: _selectedBatchNo,
        batchExpiry: _selectedBatchExpiry,
        dosageForm: _selectedDosageForm,
        packagingType: pkgType,
        stripCount: _stripCount,
        looseCount: _looseCount,
        packSize: _packSize,
        packagingDesc: desc,
      );
      if (free > 0) {
        cart.setFreeQuantity(widget.product.id, free);
      }
    }

    Navigator.of(context).pop(true);
    widget.onCompleted?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final symbol = context.watch<BusinessProvider>().currentBusiness?.currencySymbol ?? '₹';
    final p = widget.product;
    final hasRx = p.metadata['schedule_h'] == true || p.metadata['is_narcotic'] == true;
    final generic = p.metadata['generic_name'] as String?;
    final salt = p.metadata['salt_composition'] as String?;
    final formColor = _colorForDosageForm(_selectedDosageForm);
    final formIcon = _iconForDosageForm(_selectedDosageForm);

    final isTabletOrCapsule = _selectedDosageForm == 'tablet' || _selectedDosageForm == 'capsule';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppTokens.borderLG),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 620,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
              decoration: BoxDecoration(
                color: formColor.withAlpha(14),
                border: Border(bottom: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: formColor.withAlpha(28),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(formIcon, color: formColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                p.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                            ),
                            if (hasRx) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: MedicalPalette.critical.withAlpha(25),
                                  borderRadius: AppTokens.borderSM,
                                  border: Border.all(color: MedicalPalette.critical.withAlpha(90)),
                                ),
                                child: const Text(
                                  'Rx / Sched H',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: MedicalPalette.critical,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (generic != null && generic.isNotEmpty) generic,
                            if (salt != null && salt.isNotEmpty) salt,
                            'Tax: ${p.taxRate}%',
                          ].join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: theme.colorScheme.onSurface.withAlpha(160),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dosage Form — read-only badge (auto-detected from product config)
                    Row(
                      children: [
                        const Text(
                          'Medicine Type',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: formColor.withAlpha(18),
                            borderRadius: AppTokens.borderPill,
                            border: Border.all(color: formColor.withAlpha(70)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(formIcon, size: 14, color: formColor),
                              const SizedBox(width: 5),
                              Text(
                                _dosageFormLabel(_selectedDosageForm),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: formColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Packaging / Dispense Option
                    if (isTabletOrCapsule) ...[
                      Row(
                        children: [
                          const Text(
                            'Dispense Option',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          Text(
                            'Pack size: ',
                            style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurface.withAlpha(150)),
                          ),
                          SizedBox(
                            width: 44,
                            height: 26,
                            child: TextField(
                              controller: _packSizeCtrl,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.zero,
                                border: OutlineInputBorder(borderRadius: AppTokens.borderSM),
                              ),
                              onChanged: (val) {
                                final ps = int.tryParse(val) ?? 10;
                                setState(() => _packSize = ps > 0 ? ps : 10);
                              },
                            ),
                          ),
                          Text(
                            ' ${_selectedDosageForm == 'tablet' ? 'tabs' : 'caps'}/strip',
                            style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurface.withAlpha(150)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Segmented Mode Buttons: Only Strip, Loose Only, Strip + Loose
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withAlpha(8),
                          borderRadius: AppTokens.borderMD,
                          border: Border.all(color: theme.dividerColor),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            Expanded(
                              child: _ModeSegment(
                                label: 'Only Strip',
                                icon: Icons.view_week_rounded,
                                isSelected: _packagingMode == MedicinePackagingMode.stripOnly,
                                onTap: () => setState(() => _packagingMode = MedicinePackagingMode.stripOnly),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _ModeSegment(
                                label: 'Loose Only',
                                icon: Icons.grain_rounded,
                                isSelected: _packagingMode == MedicinePackagingMode.looseOnly,
                                onTap: () => setState(() {
                                  _packagingMode = MedicinePackagingMode.looseOnly;
                                  if (_looseCount == 0) _looseCount = 2;
                                }),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _ModeSegment(
                                label: 'Strip + Loose',
                                icon: Icons.call_split_rounded,
                                isSelected: _packagingMode == MedicinePackagingMode.stripAndLoose,
                                onTap: () => setState(() {
                                  _packagingMode = MedicinePackagingMode.stripAndLoose;
                                  if (_looseCount == 0) _looseCount = 2;
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Mode-Specific Steppers
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: AppTokens.borderMD,
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Column(
                          children: [
                            if (_packagingMode == MedicinePackagingMode.stripOnly ||
                                _packagingMode == MedicinePackagingMode.stripAndLoose)
                              Row(
                                children: [
                                  const Icon(Icons.view_week_rounded, size: 18, color: Color(0xFF0284C7)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Full Strips (${_stripCount * _packSize} ${_selectedDosageForm == 'tablet' ? 'tabs' : 'caps'})',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                  ),
                                  _DialogStepper(
                                    value: _stripCount,
                                    onChanged: (val) => setState(() => _stripCount = val.clamp(1, 999)),
                                  ),
                                ],
                              ),
                            if (_packagingMode == MedicinePackagingMode.stripAndLoose) const Divider(height: 16),
                            if (_packagingMode == MedicinePackagingMode.looseOnly ||
                                _packagingMode == MedicinePackagingMode.stripAndLoose)
                              Row(
                                children: [
                                  const Icon(Icons.grain_rounded, size: 18, color: Color(0xFFF59E0B)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Loose ${_selectedDosageForm == 'tablet' ? 'Tablets' : 'Capsules'}',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                  ),
                                  _DialogStepper(
                                    value: _looseCount,
                                    onChanged: (val) => setState(() => _looseCount = val.clamp(1, 999)),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Non-tablet/capsule quantity selector
                      Row(
                        children: [
                          Icon(formIcon, size: 18, color: formColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Dispense Quantity ($_computedPackagingDesc)',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                          _DialogStepper(
                            value: _singleUnitQty.toInt(),
                            onChanged: (val) => setState(() => _singleUnitQty = val.clamp(1, 999).toDouble()),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 18),

                    // FEFO Batch Selection
                    Row(
                      children: [
                        const Icon(Icons.access_time_filled_rounded, size: 16, color: MedicalPalette.primary),
                        const SizedBox(width: 6),
                        const Text(
                          'Select Batch (FEFO - Earliest Expiry First)',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Text(
                          '${_batches.length} batches',
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withAlpha(140)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_batches.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withAlpha(6),
                          borderRadius: AppTokens.borderMD,
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 18, color: theme.colorScheme.onSurface.withAlpha(140)),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'No batches recorded. Standard stock will be billed.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: _batches.map((b) {
                          final isSelected = _selectedBatchNo == b.batchNo;
                          final expYmd = DateFormatter.formatIsoDate(b.expiryDate);
                          final color = b.isExpired
                              ? MedicalPalette.critical
                              : (b.severity == ExpirySeverity.warning ? MedicalPalette.warning : MedicalPalette.safe);

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedBatchNo = b.batchNo;
                                _selectedBatchExpiry = expYmd;
                              });
                            },
                            borderRadius: AppTokens.borderMD,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? MedicalPalette.primary.withAlpha(14) : theme.cardTheme.color,
                                borderRadius: AppTokens.borderMD,
                                border: Border.all(
                                  color: isSelected ? MedicalPalette.primary : theme.dividerColor,
                                  width: isSelected ? 1.6 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                    size: 18,
                                    color: isSelected ? MedicalPalette.primary : theme.colorScheme.onSurface.withAlpha(120),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              b.batchNo,
                                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: color.withAlpha(20),
                                                borderRadius: AppTokens.borderSM,
                                              ),
                                              child: Text(
                                                b.daysLabel,
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: color,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Exp: $expYmd • Stock: ${b.qty.toStringAsFixed(0)} ${p.unit} • MRP: $symbol${b.mrp.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: theme.colorScheme.onSurface.withAlpha(150),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 18),

                    // Price and Discount Controls
                    const Text(
                      'Price & Discount Adjustment',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _priceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: isTabletOrCapsule ? 'Strip Price ($symbol)' : 'Unit Price ($symbol)',
                              prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 16),
                              isDense: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _discCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Discount ($symbol)',
                              prefixIcon: const Icon(Icons.local_offer_rounded, size: 16),
                              isDense: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _freeCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Free Qty',
                              prefixIcon: Icon(Icons.card_giftcard_rounded, size: 16),
                              isDense: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Live Math Preview Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(8),
                        borderRadius: AppTokens.borderMD,
                        border: Border.all(color: theme.colorScheme.primary.withAlpha(30)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Packaging Summary:',
                                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(170)),
                              ),
                              Text(
                                _computedPackagingDesc,
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Effective Rate:',
                                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withAlpha(170)),
                              ),
                              Text(
                                '${CurrencyFormatter.format(_computedUnitPrice, symbol: symbol)} / ${isTabletOrCapsule && _packagingMode != MedicinePackagingMode.stripOnly ? (_selectedDosageForm == 'tablet' ? 'tab' : 'cap') : p.unit}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const Divider(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Line Total (inc. tax):', style: TextStyle(fontWeight: FontWeight.w700)),
                              Text(
                                CurrencyFormatter.format(_lineTotal, symbol: symbol),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: MedicalPalette.primaryDark,
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

            // Dialog Footer Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                children: [
                  if (isEditMode) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: AppTokens.borderMD),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Remove'),
                      onPressed: () {
                        context.read<CartProvider>().removeItem(widget.cartIndex!);
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      backgroundColor: MedicalPalette.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: AppTokens.borderMD),
                    ),
                    icon: Icon(isEditMode ? Icons.check_rounded : Icons.add_shopping_cart_rounded, size: 18),
                    label: Text(
                      isEditMode ? 'Apply Changes' : 'Add to Cart',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onPressed: _onCommit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeSegment extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeSegment({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppTokens.borderSM,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: AppTokens.borderSM,
          boxShadow: isSelected ? AppTokens.shadowSM : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : theme.colorScheme.onSurface.withAlpha(160)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : theme.colorScheme.onSurface.withAlpha(180),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _DialogStepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withAlpha(10),
        borderRadius: AppTokens.borderPill,
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_rounded, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => onChanged(value - 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$value',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}
