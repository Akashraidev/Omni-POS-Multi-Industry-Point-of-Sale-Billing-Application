import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/estimate.dart';
import '../../../providers/business_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/estimate_provider.dart';
import '../../../providers/product_provider.dart';

class EstimateSlipDialog extends StatelessWidget {
  final Estimate estimate;
  final VoidCallback? onConverted;

  const EstimateSlipDialog({
    super.key,
    required this.estimate,
    this.onConverted,
  });

  static Future<void> show(
    BuildContext context,
    Estimate estimate, {
    VoidCallback? onConverted,
  }) {
    return showDialog(
      context: context,
      builder: (_) => EstimateSlipDialog(
        estimate: estimate,
        onConverted: onConverted,
      ),
    );
  }

  Future<void> _printEstimatePdf(BuildContext context) async {
    final biz = context.read<BusinessProvider>().currentBusiness;
    final symbol = biz?.currencySymbol ?? 'Rs.';

    final doc = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final validFormat = DateFormat('dd MMM yyyy');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                biz?.name ?? 'OMINI POS',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              if (biz?.address != null && biz!.address.isNotEmpty)
                pw.Text(biz.address, style: const pw.TextStyle(fontSize: 8)),
              if (biz?.phone != null && biz!.phone.isNotEmpty)
                pw.Text('Tel: ${biz.phone}', style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1),
                ),
                child: pw.Text(
                  'ESTIMATE / QUOTATION',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Text(
                '*** NOT A TAX INVOICE ***',
                style: pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic),
              ),
              pw.Divider(thickness: 0.5),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Estimate #: ${estimate.estimateNo}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Date: ${dateFormat.format(estimate.createdAt)}', style: const pw.TextStyle(fontSize: 7.5)),
                    if (estimate.validUntil != null)
                      pw.Text('Valid Till: ${validFormat.format(estimate.validUntil!)}', style: const pw.TextStyle(fontSize: 7.5)),
                    if (estimate.customerName != null)
                      pw.Text('Customer: ${estimate.customerName}', style: const pw.TextStyle(fontSize: 7.5)),
                    if (estimate.customerPhone != null)
                      pw.Text('Phone: ${estimate.customerPhone}', style: const pw.TextStyle(fontSize: 7.5)),
                  ],
                ),
              ),
              pw.Divider(thickness: 0.5),
              // Items
              pw.Column(
                children: estimate.items.map((it) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(it.productName, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                              if (it.packagingDesc != null && it.packagingDesc!.isNotEmpty)
                                pw.Text(it.packagingDesc!, style: const pw.TextStyle(fontSize: 6.5))
                              else if (it.batchNumber != null)
                                pw.Text('Batch: ${it.batchNumber}', style: const pw.TextStyle(fontSize: 6.5)),
                              pw.Text('${it.quantity} x $symbol${it.unitPrice.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 7)),
                            ],
                          ),
                        ),
                        pw.Text(
                          '$symbol${it.lineTotal.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              pw.Divider(thickness: 0.5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('$symbol${estimate.subtotal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              if (estimate.discountAmount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Discount:', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('-$symbol${estimate.discountAmount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              if (estimate.taxAmount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Estimated GST:', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('+$symbol${estimate.taxAmount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              pw.Divider(thickness: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL ESTIMATE:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text('$symbol${estimate.finalTotal.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 8),
              if (estimate.notes != null && estimate.notes!.isNotEmpty)
                pw.Text(
                  'Remarks: ${estimate.notes}',
                  style: const pw.TextStyle(fontSize: 7),
                  textAlign: pw.TextAlign.center,
                ),
              pw.SizedBox(height: 4),
              pw.Text('Thank You!', style: const pw.TextStyle(fontSize: 8)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'Estimate_${estimate.estimateNo}.pdf',
    );
  }

  void _shareQuotationText(BuildContext context) {
    final biz = context.read<BusinessProvider>().currentBusiness;
    final symbol = biz?.currencySymbol ?? '₹';
    final dateFormat = DateFormat('dd MMM yyyy');

    final buffer = StringBuffer();
    buffer.writeln('📋 *ESTIMATE / PRICE QUOTATION*');
    buffer.writeln('🏪 *${biz?.name ?? "Store"}*');
    if (biz?.phone != null) buffer.writeln('📞 Contact: ${biz!.phone}');
    buffer.writeln('------------------------------');
    buffer.writeln('Estimate #: *${estimate.estimateNo}*');
    buffer.writeln('Date: ${dateFormat.format(estimate.createdAt)}');
    if (estimate.validUntil != null) {
      buffer.writeln('Valid Until: *${dateFormat.format(estimate.validUntil!)}*');
    }
    if (estimate.customerName != null) {
      buffer.writeln('Customer: ${estimate.customerName}');
    }
    buffer.writeln('------------------------------');
    buffer.writeln('*ITEMS:*');

    int idx = 1;
    for (final it in estimate.items) {
      final desc = it.packagingDesc ?? '${it.quantity} units';
      buffer.writeln(
        '$idx. *${it.productName}*\n   $desc @ $symbol${it.unitPrice.toStringAsFixed(2)} = $symbol${it.lineTotal.toStringAsFixed(2)}',
      );
      idx++;
    }

    buffer.writeln('------------------------------');
    buffer.writeln('Subtotal: $symbol${estimate.subtotal.toStringAsFixed(2)}');
    if (estimate.discountAmount > 0) {
      buffer.writeln('Discount: -$symbol${estimate.discountAmount.toStringAsFixed(2)}');
    }
    if (estimate.taxAmount > 0) {
      buffer.writeln('Estimated Tax: +$symbol${estimate.taxAmount.toStringAsFixed(2)}');
    }
    buffer.writeln('*TOTAL ESTIMATE: $symbol${estimate.finalTotal.toStringAsFixed(2)}*');
    buffer.writeln('------------------------------');
    if (estimate.notes != null && estimate.notes!.isNotEmpty) {
      buffer.writeln('Remarks: ${estimate.notes}');
    }
    buffer.writeln('_Note: This is a quotation, not a tax invoice. Stock & rates subject to confirmation upon billing._');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Quotation copied to clipboard! Ready to paste into WhatsApp / SMS.'),
        backgroundColor: Color(0xFF059669),
      ),
    );
  }

  Future<void> _convertToSale(BuildContext context) async {
    final products = context.read<ProductProvider>().allProducts;
    final cart = context.read<CartProvider>();

    await context.read<EstimateProvider>().convertEstimateToCart(
          estimate: estimate,
          cart: cart,
          availableProducts: products,
        );

    if (context.mounted) {
      Navigator.pop(context);
      onConverted?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estimate ${estimate.estimateNo} loaded into POS Cart! Complete checkout to finalize sale.'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final biz = context.watch<BusinessProvider>().currentBusiness;
    final symbol = biz?.currencySymbol ?? '₹';
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final validFormat = DateFormat('dd MMM yyyy');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.dividerColor.withAlpha(60))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      estimate.estimateNo,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getStatusColor(estimate.displayStatus).withAlpha(25),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      estimate.displayStatus.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: _getStatusColor(estimate.displayStatus),
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Printable Slip Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.dividerColor.withAlpha(80)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Store Header
                      Center(
                        child: Column(
                          children: [
                            Text(
                              biz?.name ?? 'OMINI POS',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                            ),
                            if (biz?.address != null && biz!.address.isNotEmpty)
                              Text(
                                biz.address,
                                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withAlpha(140)),
                                textAlign: TextAlign.center,
                              ),
                            if (biz?.phone != null && biz!.phone.isNotEmpty)
                              Text(
                                'Tel: ${biz.phone}',
                                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withAlpha(140)),
                              ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: primary.withAlpha(60)),
                              ),
                              child: Text(
                                'ESTIMATE / QUOTATION',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: primary),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '*** NOT A TAX INVOICE ***',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontStyle: FontStyle.italic,
                                color: theme.colorScheme.onSurface.withAlpha(130),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 8),

                      // Meta details
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _metaRow('Estimate #', estimate.estimateNo, isBold: true),
                                _metaRow('Date', dateFormat.format(estimate.createdAt)),
                                if (estimate.validUntil != null)
                                  _metaRow('Valid Till', validFormat.format(estimate.validUntil!)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _metaRow('Customer', estimate.customerName ?? 'Walk-in Customer'),
                                _metaRow('Phone', estimate.customerPhone ?? '-'),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 8),

                      // Items Table Header
                      Row(
                        children: [
                          Expanded(flex: 4, child: Text('Item / Medicine', style: _tblHdrStyle)),
                          Expanded(flex: 2, child: Text('Qty / Pack', textAlign: TextAlign.center, style: _tblHdrStyle)),
                          Expanded(flex: 2, child: Text('Rate', textAlign: TextAlign.right, style: _tblHdrStyle)),
                          Expanded(flex: 2, child: Text('Total', textAlign: TextAlign.right, style: _tblHdrStyle)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Divider(height: 1),

                      // Items Rows
                      ...estimate.items.map((it) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      it.productName,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                    ),
                                    if (it.packagingDesc != null && it.packagingDesc!.isNotEmpty)
                                      Text(
                                        it.packagingDesc!,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: theme.colorScheme.onSurface.withAlpha(140),
                                        ),
                                      )
                                    else if (it.batchNumber != null)
                                      Text(
                                        'Batch: ${it.batchNumber} (exp ${it.batchExpiry ?? "-"})',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: theme.colorScheme.onSurface.withAlpha(130),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${it.quantity.round() == it.quantity ? it.quantity.toInt() : it.quantity}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  CurrencyFormatter.format(it.unitPrice, symbol: symbol),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 11.5),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  CurrencyFormatter.format(it.lineTotal, symbol: symbol),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const Divider(height: 14),

                      // Financial Summary
                      _totalRow('Subtotal', CurrencyFormatter.format(estimate.subtotal, symbol: symbol)),
                      if (estimate.discountAmount > 0)
                        _totalRow(
                          'Total Discount',
                          '- ${CurrencyFormatter.format(estimate.discountAmount, symbol: symbol)}',
                          color: const Color(0xFF059669),
                        ),
                      if (estimate.taxAmount > 0)
                        _totalRow(
                          'Estimated Tax (GST)',
                          '+ ${CurrencyFormatter.format(estimate.taxAmount, symbol: symbol)}',
                        ),
                      if (estimate.roundOff.abs() > 0.001)
                        _totalRow(
                          'Round off',
                          (estimate.roundOff >= 0 ? '+ ' : '- ') +
                              CurrencyFormatter.format(estimate.roundOff.abs(), symbol: symbol),
                        ),
                      const SizedBox(height: 6),
                      const Divider(height: 2, thickness: 1.5),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ESTIMATE TOTAL',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                          ),
                          Text(
                            CurrencyFormatter.format(estimate.finalTotal, symbol: symbol),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: primary,
                            ),
                          ),
                        ],
                      ),

                      if (estimate.notes != null && estimate.notes!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Remarks: ${estimate.notes}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurface.withAlpha(150),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.dividerColor.withAlpha(60))),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy / Share'),
                    onPressed: () => _shareQuotationText(context),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.print_rounded, size: 16),
                    label: const Text('Print Slip'),
                    onPressed: () => _printEstimatePdf(context),
                  ),
                  if (!estimate.isConverted && !estimate.isVoided)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 16, color: Colors.white),
                      label: const Text('Convert to Sale', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                      onPressed: () => _convertToSale(context),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _tblHdrStyle = TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800);

  Widget _metaRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
          Text(
            value,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF059669);
      case 'converted':
        return const Color(0xFF2563EB);
      case 'expired':
        return const Color(0xFFD97706);
      case 'voided':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }
}
