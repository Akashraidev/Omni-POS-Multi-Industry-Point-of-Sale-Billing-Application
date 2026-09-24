import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../../data/models/purchase.dart';
import '../../../providers/business_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/purchase_provider.dart';
import '../../../providers/supplier_provider.dart';

class PurchaseDetailDialog extends StatelessWidget {
  final Purchase purchase;

  const PurchaseDetailDialog({
    super.key,
    required this.purchase,
  });

  static Future<void> show(BuildContext context, Purchase purchase) {
    return showDialog(
      context: context,
      builder: (_) => PurchaseDetailDialog(purchase: purchase),
    );
  }

  static const Color _emerald = Color(0xFF10B981);
  static const Color _rose = Color(0xFFE11D48);

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'received':
        return _emerald;
      case 'pending':
        return Colors.amber.shade700;
      case 'voided':
        return _rose;
      default:
        return Colors.blueGrey;
    }
  }

  Future<void> _printGrnPdf(BuildContext context) async {
    final biz = context.read<BusinessProvider>().currentBusiness;
    final symbol = biz?.currencySymbol ?? 'Rs.';

    final doc = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        biz?.name ?? 'OMINI POS PHARMACY',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                      ),
                      if (biz?.address != null && biz!.address.isNotEmpty)
                        pw.Text(biz.address, style: const pw.TextStyle(fontSize: 9)),
                      if (biz?.phone != null && biz!.phone.isNotEmpty)
                        pw.Text('Phone: ${biz.phone}', style: const pw.TextStyle(fontSize: 9)),
                      if (biz?.email != null && biz!.email.isNotEmpty)
                        pw.Text('Email: ${biz.email}', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blueGrey50,
                          borderRadius: pw.BorderRadius.circular(4),
                          border: pw.Border.all(color: PdfColors.blueGrey),
                        ),
                        child: pw.Text(
                          'GOODS RECEIPT NOTE (GRN)',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('GRN / PO #: ${purchase.invoiceNo}',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Date: ${dateFormat.format(purchase.createdAt)}',
                          style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Status: ${purchase.status.toUpperCase()}',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 8),

              // Supplier & Payment Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('SUPPLIER / VENDOR DETAILS',
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 3),
                          pw.Text(purchase.supplierName ?? 'Cash / Direct Supplier',
                              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('PAYMENT TERMS',
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 3),
                          pw.Text('Status: ${purchase.paymentStatus} (${purchase.paymentMethod})',
                              style: const pw.TextStyle(fontSize: 9)),
                          pw.Text(
                              'Paid: $symbol${purchase.paidAmount.toStringAsFixed(2)} | Balance Due: $symbol${purchase.dueAmount.toStringAsFixed(2)}',
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 14),

              // Items Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FixedColumnWidth(24),
                  1: const pw.FlexColumnWidth(4),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(1.8),
                  4: const pw.FlexColumnWidth(1.2),
                  5: const pw.FlexColumnWidth(1.2),
                  6: const pw.FlexColumnWidth(1.8),
                  7: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('#', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Item Description', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Batch / Exp', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Qty + Free', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Rate', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Tax %', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('MRP', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Total', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                      ),
                    ],
                  ),
                  ...purchase.items.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final it = entry.value;
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('$idx', style: const pw.TextStyle(fontSize: 7.5)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(it.productName, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            '${it.batchNumber ?? '-'}\n${it.batchExpiry ?? ''}',
                            style: const pw.TextStyle(fontSize: 7),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            it.freeQuantity > 0 ? '${it.quantity} + ${it.freeQuantity}' : '${it.quantity}',
                            style: const pw.TextStyle(fontSize: 8),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('$symbol${it.unitCost.toStringAsFixed(2)}',
                              style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('${it.taxRate}%',
                              style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(it.mrp != null ? '$symbol${it.mrp!.toStringAsFixed(2)}' : '-',
                              style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('$symbol${it.totalCost.toStringAsFixed(2)}',
                              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 12),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 240,
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 8.5)),
                            pw.Text('$symbol${purchase.subtotal.toStringAsFixed(2)}',
                                style: const pw.TextStyle(fontSize: 8.5)),
                          ],
                        ),
                        if (purchase.discountAmount > 0)
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Discount:', style: const pw.TextStyle(fontSize: 8.5)),
                              pw.Text('-$symbol${purchase.discountAmount.toStringAsFixed(2)}',
                                  style: const pw.TextStyle(fontSize: 8.5)),
                            ],
                          ),
                        if (purchase.taxAmount > 0)
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Total Tax (GST):', style: const pw.TextStyle(fontSize: 8.5)),
                              pw.Text('+$symbol${purchase.taxAmount.toStringAsFixed(2)}',
                                  style: const pw.TextStyle(fontSize: 8.5)),
                            ],
                          ),
                        if (purchase.roundOff != 0)
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Round Off:', style: const pw.TextStyle(fontSize: 8.5)),
                              pw.Text('$symbol${purchase.roundOff.toStringAsFixed(2)}',
                                  style: const pw.TextStyle(fontSize: 8.5)),
                            ],
                          ),
                        pw.Divider(thickness: 0.8),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('NET INWARD VALUE:',
                                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                            pw.Text('$symbol${purchase.totalAmount.toStringAsFixed(2)}',
                                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Spacer(),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(width: 140, height: 1, color: PdfColors.grey600),
                      pw.SizedBox(height: 4),
                      pw.Text('Goods Inspected By', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(width: 140, height: 1, color: PdfColors.grey600),
                      pw.SizedBox(height: 4),
                      pw.Text('Authorized Stock Receiver', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'GRN_${purchase.invoiceNo}.pdf',
    );
  }

  void _copySummary(BuildContext context) {
    final symbol = context.read<BusinessProvider>().currentBusiness?.currencySymbol ?? 'Rs.';
    final dateStr = DateFormat('dd-MM-yyyy').format(purchase.createdAt);

    final buffer = StringBuffer();
    buffer.writeln('--- GOODS RECEIPT NOTE (GRN) ---');
    buffer.writeln('PO/GRN #: ${purchase.invoiceNo}');
    buffer.writeln('Date: $dateStr');
    buffer.writeln('Supplier: ${purchase.supplierName ?? 'Direct'}');
    buffer.writeln('Status: ${purchase.status}');
    buffer.writeln('Payment: ${purchase.paymentStatus} (${purchase.paymentMethod})');
    buffer.writeln('--------------------------------');
    for (final it in purchase.items) {
      final freeInfo = it.freeQuantity > 0 ? ' (+${it.freeQuantity} Free)' : '';
      final batchInfo = it.batchNumber != null ? ' [B: ${it.batchNumber} Exp: ${it.batchExpiry ?? ''}]' : '';
      buffer.writeln('${it.productName}$batchInfo');
      buffer.writeln('  Qty: ${it.quantity}$freeInfo @ $symbol${it.unitCost} = $symbol${it.totalCost}');
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('Total Amount: $symbol${purchase.totalAmount.toStringAsFixed(2)}');
    buffer.writeln('Paid: $symbol${purchase.paidAmount.toStringAsFixed(2)} | Due: $symbol${purchase.dueAmount.toStringAsFixed(2)}');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('GRN Summary copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmVoidPurchase(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _rose, size: 28),
            SizedBox(width: 10),
            Text('Void Purchase Order?'),
          ],
        ),
        content: const Text(
          'Voiding this purchase will:\n'
          '• Revert inward stock quantities for all items\n'
          '• Deduct registered batch stock balances\n'
          '• Deduct supplier balance due\n'
          '• Record audit entries in the stock ledger\n\n'
          'This action cannot be undone. Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _rose,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Void Purchase'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final biz = context.read<BusinessProvider>().currentBusiness;
      if (biz == null) return;

      try {
        await context.read<PurchaseProvider>().voidPurchase(purchase.id, biz.id);
        // Refresh product inventory list and supplier dues
        if (context.mounted) {
          context.read<ProductProvider>().loadProducts(biz.id);
          context.read<SupplierProvider>().loadSuppliers(biz.id);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Purchase order voided and inventory stock reverted successfully.'),
              backgroundColor: Colors.amber,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to void purchase: $e'),
              backgroundColor: _rose,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final symbol = context.watch<BusinessProvider>().currentBusiness?.currencySymbol ?? '₹';
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final statusColor = _getStatusColor(purchase.status);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 780),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.receipt_long_rounded, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Inward Slip / GRN',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                purchase.invoiceNo,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateFormat.format(purchase.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      purchase.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    splashRadius: 20,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Supplier & Payment Info Cards
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.local_shipping_outlined, size: 16, color: theme.colorScheme.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      'SUPPLIER DETAILS',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  purchase.supplierName ?? 'Direct Purchase',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                if (purchase.notes != null && purchase.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Note: ${purchase.notes}',
                                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.payments_outlined, size: 16, color: Colors.teal),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'PAYMENT & DUES',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Mode: ${purchase.paymentMethod}', style: const TextStyle(fontSize: 12)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (purchase.paymentStatus == 'Paid'
                                                ? _emerald
                                                : purchase.paymentStatus == 'Due'
                                                    ? _rose
                                                    : Colors.amber)
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        purchase.paymentStatus,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: purchase.paymentStatus == 'Paid'
                                              ? _emerald
                                              : purchase.paymentStatus == 'Due'
                                                  ? _rose
                                                  : Colors.amber.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Paid: $symbol${purchase.paidAmount.toStringAsFixed(2)} | Due: $symbol${purchase.dueAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: purchase.dueAmount > 0 ? Colors.amber.shade800 : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Items Table Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'INWARDED LINE ITEMS (${purchase.items.length})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Total Units: ${purchase.totalUnitsCount + purchase.totalFreeUnits}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Items Container Table
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          // Table Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            child: const Row(
                              children: [
                                SizedBox(width: 24, child: Text('#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                Expanded(flex: 4, child: Text('Product & Batch', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('Qty + Free', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                                Expanded(flex: 2, child: Text('Cost Rate', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                                Expanded(flex: 2, child: Text('Tax (GST)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                                Expanded(flex: 2, child: Text('Line Total', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                              ],
                            ),
                          ),
                          // Rows
                          ...purchase.items.asMap().entries.map((entry) {
                            final idx = entry.key + 1;
                            final item = entry.value;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    child: Text('$idx', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.productName,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                        ),
                                        if (item.batchNumber != null && item.batchNumber!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Wrap(
                                              spacing: 6,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    'B: ${item.batchNumber}',
                                                    style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.w500),
                                                  ),
                                                ),
                                                if (item.batchExpiry != null && item.batchExpiry!.isNotEmpty)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: Colors.purple.withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      'Exp: ${item.batchExpiry}',
                                                      style: const TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.w500),
                                                    ),
                                                  ),
                                                if (item.mrp != null && item.mrp! > 0)
                                                  Text(
                                                    'MRP: $symbol${item.mrp!.toStringAsFixed(2)}',
                                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                                  ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${item.quantity}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                        if (item.freeQuantity > 0) ...[
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: _emerald.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '+${item.freeQuantity > 0 ? item.freeQuantity.round() : 0}F',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: _emerald,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '$symbol${item.unitCost.toStringAsFixed(2)}',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '${item.taxRate}%',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '$symbol${item.totalCost.toStringAsFixed(2)}',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Summary Block
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 320,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildSummaryRow('Subtotal', '$symbol${purchase.subtotal.toStringAsFixed(2)}'),
                            if (purchase.discountAmount > 0)
                              _buildSummaryRow(
                                'Discount',
                                '-$symbol${purchase.discountAmount.toStringAsFixed(2)}',
                                color: _emerald,
                              ),
                            if (purchase.taxAmount > 0)
                              _buildSummaryRow('GST / Tax', '+$symbol${purchase.taxAmount.toStringAsFixed(2)}'),
                            if (purchase.roundOff != 0)
                              _buildSummaryRow('Round Off', '$symbol${purchase.roundOff.toStringAsFixed(2)}'),
                            const Divider(height: 16),
                            _buildSummaryRow(
                              'Grand Total',
                              '$symbol${purchase.totalAmount.toStringAsFixed(2)}',
                              isBold: true,
                              fontSize: 15,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer Actions Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (purchase.status != 'Voided')
                    TextButton.icon(
                      icon: const Icon(Icons.block_rounded, size: 18, color: _rose),
                      label: const Text(
                        'Void Purchase',
                        style: TextStyle(color: _rose, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _confirmVoidPurchase(context),
                    ),
                  const Spacer(),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy Slip'),
                    onPressed: () => _copySummary(context),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: const Text('Print GRN'),
                    onPressed: () => _printGrnPdf(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String title,
    String value, {
    bool isBold = false,
    double fontSize = 13,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
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
