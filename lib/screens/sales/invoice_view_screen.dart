import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../data/models/sale.dart';
import '../../providers/business_provider.dart';

class InvoiceViewScreen extends StatelessWidget {
  final Sale sale;

  const InvoiceViewScreen({super.key, required this.sale});

  Future<Uint8List> _generatePdfReceipt(BuildContext context) async {
    final biz = context.read<BusinessProvider>().currentBusiness;
    final pdf = pw.Document();

    final storeName = biz?.name ?? 'OminiPOS Store';
    final storeAddress = biz?.address ?? 'Main Road, Commercial Complex';
    final storeTax = biz?.taxNumber.isNotEmpty == true ? 'GSTIN/VAT: ${biz!.taxNumber}' : '';
    final storePhone = biz?.phone.isNotEmpty == true ? 'Tel: ${biz!.phone}' : '';
    final curSymbol = biz?.currencySymbol == '₹' ? 'Rs. ' : (biz?.currencySymbol ?? 'Rs. ');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Thermal 80mm roll format
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(storeName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    if (storeAddress.isNotEmpty) pw.Text(storeAddress, style: const pw.TextStyle(fontSize: 8)),
                    if (storeTax.isNotEmpty) pw.Text(storeTax, style: const pw.TextStyle(fontSize: 8)),
                    if (storePhone.isNotEmpty) pw.Text(storePhone, style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ),
              pw.Divider(thickness: 0.5),
              pw.Text('Invoice: ${sale.invoiceNo}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Text('Date: ${sale.createdAt.toString().substring(0, 16)}', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('Customer: ${sale.customerName ?? 'Walk-in Guest'}', style: const pw.TextStyle(fontSize: 8)),
              if (sale.doctorName != null) pw.Text('Doctor: ${sale.doctorName}', style: const pw.TextStyle(fontSize: 8)),
              if (sale.tableNumber != null) pw.Text('Table: ${sale.tableNumber}', style: const pw.TextStyle(fontSize: 8)),
              pw.Divider(thickness: 0.5),
              // Items Table
              pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      pw.Text('Qty', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      pw.Text('Amount', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    ],
                  ),
                  ...sale.items.map((it) {
                    return pw.TableRow(
                      children: [
                        pw.Text(it.productName, style: const pw.TextStyle(fontSize: 8)),
                        pw.Text('${it.quantity.toInt()}', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
                        pw.Text('$curSymbol${it.lineTotal.toStringAsFixed(2)}', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8)),
                      ],
                    );
                  }),
                ],
              ),
              pw.Divider(thickness: 0.5),
              // Totals
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('$curSymbol${sale.subtotal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8)),
              ]),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Tax Amount:', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('$curSymbol${sale.taxAmount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8)),
              ]),
              if (sale.discountAmount > 0)
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text('Discount:', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('-$curSymbol${sale.discountAmount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8)),
                ]),
              pw.Divider(thickness: 0.5),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('FINAL TOTAL:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.Text('$curSymbol${sale.finalTotal.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              ]),
              pw.Text('Paid via: ${sale.paymentMethod}', style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  biz?.receiptFooter ?? 'Thank you for shopping with us!',
                  style: const pw.TextStyle(fontSize: 7),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final biz = context.watch<BusinessProvider>().currentBusiness;
    final symbol = biz?.currencySymbol ?? '₹';

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${sale.invoiceNo}'),
        actions: [
          IconButton(
            tooltip: 'Print Thermal Receipt',
            icon: const Icon(Icons.print_rounded),
            onPressed: () async {
              final pdfBytes = await _generatePdfReceipt(context);
              await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
            },
          ),
          IconButton(
            tooltip: 'Share Receipt',
            icon: const Icon(Icons.share_rounded),
            onPressed: () async {
              final pdfBytes = await _generatePdfReceipt(context);
              await Printing.sharePdf(bytes: pdfBytes, filename: 'Invoice_${sale.invoiceNo}.pdf');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.spaceLG),
        child: Column(
          children: [
            // Bill Header Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sale.invoiceNo, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                          Text(sale.createdAt.toString().substring(0, 16), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      AppBadge(
                        label: sale.status,
                        type: sale.status == 'Completed' ? BadgeType.success : BadgeType.error,
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Customer', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(sale.customerName ?? 'Walk-in Guest', style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (sale.customerPhone != null && sale.customerPhone!.isNotEmpty)
                            Text(sale.customerPhone!, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Payment Mode', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(sale.paymentMethod, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(sale.orderType ?? 'Counter', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  if (sale.doctorName != null) ...[
                    const SizedBox(height: 8),
                    Text('Prescribed by: ${sale.doctorName}', style: const TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                  if (sale.tableNumber != null) ...[
                    const SizedBox(height: 8),
                    Text('Table: ${sale.tableNumber}', style: const TextStyle(color: Color(0xFFE11D48), fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppTokens.spaceLG),
            // Items Table Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Items Purchased', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 12),
                  ...sale.items.map((it) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(it.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                Text('₹${it.unitPrice.toStringAsFixed(2)} × ${it.quantity.toInt()} (Tax: ${it.taxRate}%)', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                if (it.batchNumber != null)
                                  Text('Batch: ${it.batchNumber}', style: const TextStyle(fontSize: 11, color: Colors.teal)),
                                if (it.serialImei != null)
                                  Text('SN/IMEI: ${it.serialImei}', style: const TextStyle(fontSize: 11, color: Colors.indigo)),
                                if (it.variant != null)
                                  Text('Variant: ${it.variant}', style: const TextStyle(fontSize: 11, color: Colors.purple)),
                              ],
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(it.lineTotal, symbol: symbol),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 20),
                  // Bill Summary
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Subtotal:'),
                    Text(CurrencyFormatter.format(sale.subtotal, symbol: symbol)),
                  ]),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Tax:'),
                    Text('+ ${CurrencyFormatter.format(sale.taxAmount, symbol: symbol)}'),
                  ]),
                  if (sale.discountAmount > 0) ...[
                    const SizedBox(height: 4),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Discount:', style: TextStyle(color: Colors.green)),
                      Text('- ${CurrencyFormatter.format(sale.discountAmount, symbol: symbol)}', style: const TextStyle(color: Colors.green)),
                    ]),
                  ],
                  const Divider(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Final Total:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    Text(
                      CurrencyFormatter.format(sale.finalTotal, symbol: symbol),
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: theme.colorScheme.primary),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.spaceXL),
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    icon: const Icon(Icons.print_rounded),
                    label: const Text('Print Receipt'),
                    onPressed: () async {
                      final pdfBytes = await _generatePdfReceipt(context);
                      await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
                    },
                  ),
                ),
                const SizedBox(width: AppTokens.spaceMD),
                Expanded(
                  child: AppButton(
                    label: 'Back to POS',
                    icon: Icons.point_of_sale_rounded,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
