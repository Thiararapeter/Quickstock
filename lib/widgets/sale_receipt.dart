import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/cart_item.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:qr/qr.dart';
import 'package:barcode/barcode.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_database.dart';

class SaleReceipt extends StatelessWidget {
  final List<CartItem> cart;
  final String customerName;
  final String customerPhone;
  final String paymentMethod;
  final String receiptNumber;
  final DateTime saleDate;

  const SaleReceipt({
    super.key,
    required this.cart,
    required this.customerName,
    required this.customerPhone,
    required this.paymentMethod,
    required this.receiptNumber,
    required this.saleDate,
  });

  double get totalAmount =>
      cart.fold(0, (sum, item) => sum + (item.item.sellingPrice * item.quantity));

  Future<void> _printReceipt(BuildContext context) async {
    try {
      final pdf = await _generatePdf();
      
      await Printing.layoutPdf(
        onLayout: (format) => pdf.save(),
        format: const PdfPageFormat(
          58 * PdfPageFormat.mm, // Standard thermal paper width
          double.infinity,
          marginAll: 2 * PdfPageFormat.mm,
        ),
        name: 'Receipt-$receiptNumber',
      );
      
      if (context.mounted) {
        Navigator.of(context).pop(); // Close receipt dialog
        Navigator.of(context).pop(); // Return to shop
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _downloadReceipt() async {
    try {
      final pdf = await _generatePdf();
      final output = await getApplicationDocumentsDirectory();
      final file = File('${output.path}/Receipt-$receiptNumber.pdf');
      await file.writeAsBytes(await pdf.save());
    } catch (e) {
      print('Error downloading receipt: $e');
    }
  }

  Future<pw.Document> _generatePdf() async {
    final pdf = pw.Document();
    
    // Load fonts
    final regularFont = await PdfGoogleFonts.nunitoRegular();
    final boldFont = await PdfGoogleFonts.nunitoBold();

    // Get POS settings
    final settings = await SupabaseDatabase.instance.getPOSSettings();

    // Generate QR code data
    final qrData = {
      'receipt': receiptNumber,
      'date': saleDate.toIso8601String(),
      'amount': totalAmount.toString(),
      'items': cart.length.toString(),
    };

    // Create barcode
    final barcode = Barcode.code128();
    final barcodeData = await barcode.toSvg(receiptNumber, width: 200, height: 40);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          58 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 2 * PdfPageFormat.mm,
        ),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            // Store Header
            pw.Text(
              settings?.storeName ?? 'QUICK STOCK',
              style: pw.TextStyle(font: boldFont, fontSize: 10),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              settings?.tagline ?? 'Your One-Stop Shop',
              style: pw.TextStyle(font: regularFont, fontSize: 7),
            ),
            pw.Text(
              settings?.phone ?? '+254 123 456 789',
              style: pw.TextStyle(font: regularFont, fontSize: 7),
            ),
            pw.Text(
              settings?.address ?? 'Your Address Here',
              style: pw.TextStyle(font: regularFont, fontSize: 7),
            ),
            pw.SizedBox(height: 2),
            pw.Divider(thickness: 0.5),

            // Receipt Header with Barcode
            if (settings?.showBarcode ?? true) ...[
              pw.SvgImage(svg: barcodeData),
              pw.SizedBox(height: 2),
            ],
            pw.Text(
              'Receipt #: $receiptNumber',
              style: pw.TextStyle(font: regularFont, fontSize: 8),
            ),
            pw.Text(
              DateFormat('MM/dd/yyyy HH:mm').format(saleDate),
              style: pw.TextStyle(font: regularFont, fontSize: 8),
            ),
            pw.Text(
              'Sales Receipt',
              style: pw.TextStyle(font: regularFont, fontSize: 8),
            ),
            pw.Text(
              'Payment: $paymentMethod',
              style: pw.TextStyle(font: regularFont, fontSize: 8),
            ),
            pw.Divider(thickness: 0.5),

            // Customer Info (if provided)
            if (customerName.isNotEmpty) ...[
              pw.Text('Customer: $customerName', 
                style: pw.TextStyle(font: regularFont, fontSize: 8)),
              pw.Text('Phone: $customerPhone',
                style: pw.TextStyle(font: regularFont, fontSize: 8)),
              pw.Divider(thickness: 0.5),
            ],

            // Items Table
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  children: [
                    pw.Text('Item', style: pw.TextStyle(font: boldFont, fontSize: 8)),
                    pw.Text('Qty', style: pw.TextStyle(font: boldFont, fontSize: 8)),
                    pw.Text('Price', style: pw.TextStyle(font: boldFont, fontSize: 8)),
                    pw.Text('Total', style: pw.TextStyle(font: boldFont, fontSize: 8)),
                  ],
                ),
                ...cart.map(
                  (item) => pw.TableRow(
                    children: [
                      pw.Text(item.item.name,
                        style: pw.TextStyle(font: regularFont, fontSize: 8)),
                      pw.Text('${item.quantity}',
                        style: pw.TextStyle(font: regularFont, fontSize: 8)),
                      pw.Text('${item.item.sellingPrice}',
                        style: pw.TextStyle(font: regularFont, fontSize: 8)),
                      pw.Text('${item.total}',
                        style: pw.TextStyle(font: regularFont, fontSize: 8)),
                    ],
                  ),
                ),
              ],
            ),
            pw.Divider(thickness: 0.5),

            // Totals Section
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Subtotal:',
                  style: pw.TextStyle(font: regularFont, fontSize: 8)),
                pw.Text('KSH ${totalAmount.toStringAsFixed(2)}',
                  style: pw.TextStyle(font: regularFont, fontSize: 8)),
              ],
            ),
            if (settings?.showVAT ?? true) ...[
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('VAT (16%):',
                    style: pw.TextStyle(font: regularFont, fontSize: 8)),
                  pw.Text('KSH ${(totalAmount * 0.16).toStringAsFixed(2)}',
                    style: pw.TextStyle(font: regularFont, fontSize: 8)),
                ],
              ),
            ],
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total:',
                  style: pw.TextStyle(font: boldFont, fontSize: 9)),
                pw.Text(
                  'KSH ${(settings?.showVAT ?? true ? totalAmount * 1.16 : totalAmount).toStringAsFixed(2)}',
                  style: pw.TextStyle(font: boldFont, fontSize: 9)
                ),
              ],
            ),
            pw.SizedBox(height: 4),

            // QR Code
            if (settings?.showQR ?? true) ...[
              pw.BarcodeWidget(
                data: qrData.toString(),
                barcode: pw.Barcode.qrCode(),
                width: 50,
                height: 50,
              ),
              pw.SizedBox(height: 4),
            ],

            // Footer
            pw.Text(
              'Thank you for your business!',
              style: pw.TextStyle(font: regularFont, fontSize: 8),
            ),
            pw.Text(
              settings?.returnPolicy ?? 'Returns accepted within 7 days with receipt',
              style: pw.TextStyle(font: regularFont, fontSize: 7),
            ),
            pw.Text(
              settings?.website ?? 'www.quickstock.com',
              style: pw.TextStyle(font: regularFont, fontSize: 7),
            ),
          ],
        ),
      ),
    );

    return pdf;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sale Complete',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'What would you like to do with the receipt?',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _printReceipt(context),
                    icon: const Icon(Icons.print, size: 20),
                    label: const Text('Print'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                  if (!kIsWeb) // Show download button only on mobile
                    ElevatedButton.icon(
                      onPressed: _downloadReceipt,
                      icon: const Icon(Icons.download, size: 20),
                      label: const Text('Download'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close receipt dialog
                      Navigator.of(context).pop(); // Return to shop
                    },
                    child: const Text('Skip'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 