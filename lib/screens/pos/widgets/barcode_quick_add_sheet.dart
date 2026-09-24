import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/product.dart';
import '../../../providers/business_provider.dart';
import '../../../providers/product_provider.dart';

/// Barcode / SKU quick-add.
///
/// Most USB & Bluetooth barcode scanners behave as keyboards: they type the
/// code and press Enter. This sheet keeps a focused field that submits on
/// Enter, matches the code against SKU/barcode, and adds the hit directly —
/// so high-volume pharmacy billing never needs the mouse.
class BarcodeQuickAddSheet extends StatefulWidget {
  final void Function(Product product) onMatch;

  const BarcodeQuickAddSheet({super.key, required this.onMatch});

  static Future<void> show(BuildContext context, {required void Function(Product product) onMatch}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BarcodeQuickAddSheet(onMatch: onMatch),
    );
  }

  @override
  State<BarcodeQuickAddSheet> createState() => _BarcodeQuickAddSheetState();
}

class _BarcodeQuickAddSheetState extends State<BarcodeQuickAddSheet> {
  final _codeCtrl = TextEditingController();
  final _focusNode = FocusNode();
  String? _lastStatus;
  bool _lastOk = false;
  bool _autoClose = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit(String code) {
    final biz = context.read<BusinessProvider>().currentBusiness;
    if (biz == null) return;
    final prodProv = context.read<ProductProvider>();
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;

    Product? match;
    for (final p in prodProv.allProducts) {
      if (p.barcode == trimmed || p.sku.toLowerCase() == trimmed.toLowerCase()) {
        match = p;
        break;
      }
    }

    if (match == null) {
      setState(() {
        _lastStatus = 'No product matches "$trimmed"';
        _lastOk = false;
      });
      _codeCtrl.clear();
      _focusNode.requestFocus();
      return;
    }

    final product = match;
    widget.onMatch(product);
    setState(() {
      _lastStatus = 'Added ${product.name}';
      _lastOk = true;
    });
    _codeCtrl.clear();

    if (_autoClose) {
      Navigator.pop(context);
    } else {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
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
            children: [
              Icon(Icons.qr_code_scanner_rounded, color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: AppTokens.spaceSM),
              const Text('Scan / Enter Barcode', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            ],
          ),
          const SizedBox(height: AppTokens.spaceSM),
          TextField(
            controller: _codeCtrl,
            focusNode: _focusNode,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            onSubmitted: _submit,
            decoration: const InputDecoration(
              hintText: 'Scan or type barcode / SKU, then Enter',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: AppTokens.spaceSM),
          Row(
            children: [
              Switch(
                value: _autoClose,
                onChanged: (v) => setState(() => _autoClose = v),
              ),
              const SizedBox(width: AppTokens.spaceSM),
              Expanded(
                child: Text(
                  _autoClose ? 'Close after each add' : 'Keep open for rapid scanning',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: theme.colorScheme.onSurface.withAlpha(165),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (_lastStatus != null) ...[
            const SizedBox(height: AppTokens.spaceMD),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: _lastOk
                  ? const Color(0xFFD1FAE5)
                  : const Color(0xFFFEE2E2),
              borderColor: Colors.transparent,
              child: Row(
                children: [
                  Icon(
                    _lastOk ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                    size: 17,
                    color: _lastOk ? const Color(0xFF059669) : const Color(0xFFDC2626),
                  ),
                  const SizedBox(width: AppTokens.spaceSM),
                  Expanded(
                    child: Text(
                      _lastStatus!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _lastOk ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppTokens.spaceMD),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: AppTokens.borderMD),
              ),
              onPressed: () => _submit(_codeCtrl.text),
              child: const Text('Add to Cart'),
            ),
          ),
        ],
      ),
    );
  }
}
