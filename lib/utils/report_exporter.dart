import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/sales_reports.dart';
import 'currency_formatter.dart';

class ReportExporter {
  static Future<void> exportSalesReport({
    required List<dynamic> data,
    required String reportName,
    required List<String> headers,
    required List<String> fields,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel[reportName];

    // Add headers
    for (var i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
        ..value = headers[i]
        ..cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
        );
    }

    // Add data
    for (var i = 0; i < data.length; i++) {
      final item = data[i];
      for (var j = 0; j < fields.length; j++) {
        var value = _getFieldValue(item, fields[j]);
        if (value is double) {
          value = currencyFormatter.format(value);
        }
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1))
          ..value = value.toString();
      }
    }

    // Save and share file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${reportName}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(excel.encode()!);
    await Share.shareXFiles([XFile(file.path)], subject: reportName);
  }

  static dynamic _getFieldValue(dynamic item, String field) {
    final props = field.split('.');
    dynamic value = item;
    for (final prop in props) {
      value = value[prop];
    }
    return value;
  }
} 