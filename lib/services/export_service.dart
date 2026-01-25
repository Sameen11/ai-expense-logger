// lib/services/export_service.dart

import 'dart:async';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/expense.dart';
import '../utils/currency_utils.dart';

/// Defines the available file formats for exporting.
enum ExportFormat { pdf, csv, excel }

class ExportService {
  /// Exports the given list of expenses to the specified format.
  ///
  /// Throws an exception if the export fails.
  Future<void> exportExpenses(
      List<Expense> expenses,
      String baseFileName,
      ExportFormat format,
      ) async {
    try {
      // Get the directory to save the file
      final directory = await getApplicationDocumentsDirectory();
      String path;

      // Generate the platform-specific file path
      switch (format) {
        case ExportFormat.csv:
          path = '${directory.path}/$baseFileName-expenses.csv';
          await _exportToCsv(expenses, path);
          break;
        case ExportFormat.pdf:
          path = '${directory.path}/$baseFileName-expenses.pdf';
          await _exportToPdf(expenses, path);
          break;
        case ExportFormat.excel:
          path = '${directory.path}/$baseFileName-expenses.xlsx';
          await _exportToExcel(expenses, path);
          break;
      }

      // Verify file was created
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('Export file was not created at: $path');
      }

      // Use share_plus to share the file (more reliable than open_file)
      try {
        await Share.shareXFiles(
          [XFile(path)],
          subject: 'Expense Report - $baseFileName',
        ).timeout(
          const Duration(seconds: 10),
        );
      } on TimeoutException {
        // If sharing times out, try opening the file as fallback
        try {
          final result = await OpenFile.open(path).timeout(
            const Duration(seconds: 5),
          );
          if (result.type != ResultType.done && result.type != ResultType.noAppToOpen) {
            print('File created at: $path but could not open: ${result.message}');
          }
        } catch (e) {
          print('File created at: $path but could not open: $e');
        }
      } catch (e) {
        // If sharing fails, try opening the file as fallback
        try {
          final result = await OpenFile.open(path).timeout(
            const Duration(seconds: 5),
          );
          if (result.type != ResultType.done && result.type != ResultType.noAppToOpen) {
            print('File created at: $path but could not open: ${result.message}');
          }
        } catch (openError) {
          print('File created at: $path but could not share or open: $e, $openError');
        }
      }
    } catch (e) {
      throw Exception('Export failed: ${e.toString()}');
    }
  }

  /// Handles CSV file generation and saving.
  Future<void> _exportToCsv(List<Expense> expenses, String path) async {
    // Add headers
    List<List<dynamic>> rows = [
      ['Receipt Date', 'Added On', 'Merchant', 'Category', 'Amount', 'Currency', 
       'Subtotal', 'Tax', 'Tip', 'Discount', 'Invoice #', 'Items', 'Notes']
    ];

    // Add data rows
    for (var expense in expenses) {
      // Format items as string
      String itemsStr = '';
      if (expense.items != null && expense.items!.isNotEmpty) {
        itemsStr = expense.items!.map((item) {
          final quantity = (item['quantity'] as num?)?.toDouble() ?? 1.0;
          final itemName = item['name'] ?? 'Item';
          final displayName = quantity > 1.0 
              ? '${quantity.toStringAsFixed(0)}x $itemName'
              : itemName;
          final itemPrice = (item['total_price'] as num?)?.toDouble() ?? 0.0;
          return '$displayName: ${CurrencyUtils.formatAmount(itemPrice, expense.currency)}';
        }).join('; ');
      }
      
      rows.add([
        DateFormat('yyyy-MM-dd').format(expense.date),
        DateFormat('yyyy-MM-dd HH:mm').format(expense.createdAt.toDate()),
        expense.merchant,
        expense.category,
        expense.amount,
        expense.currency,
        expense.subtotal ?? '',
        expense.tax ?? '',
        expense.tip ?? '',
        expense.discount ?? '',
        expense.invoiceNumber ?? '',
        itemsStr,
        expense.notes ?? '',
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    final file = File(path);
    await file.writeAsString(csvData);
  }

  /// Handles Excel file generation and saving.
  Future<void> _exportToExcel(List<Expense> expenses, String path) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Expenses']; // Create a sheet

    // Add headers
    sheet.appendRow([
      TextCellValue('Receipt Date'),
      TextCellValue('Added On'),
      TextCellValue('Merchant'),
      TextCellValue('Category'),
      TextCellValue('Amount'),
      TextCellValue('Currency'),
      TextCellValue('Subtotal'),
      TextCellValue('Tax'),
      TextCellValue('Tip'),
      TextCellValue('Discount'),
      TextCellValue('Invoice #'),
      TextCellValue('Items'),
      TextCellValue('Notes'),
    ]);

    // Add data rows
    for (var expense in expenses) {
      // Format items as string
      String itemsStr = '';
      if (expense.items != null && expense.items!.isNotEmpty) {
        itemsStr = expense.items!.map((item) {
          final quantity = (item['quantity'] as num?)?.toDouble() ?? 1.0;
          final itemName = item['name'] ?? 'Item';
          final displayName = quantity > 1.0 
              ? '${quantity.toStringAsFixed(0)}x $itemName'
              : itemName;
          final itemPrice = (item['total_price'] as num?)?.toDouble() ?? 0.0;
          return '$displayName: ${CurrencyUtils.formatAmount(itemPrice, expense.currency)}';
        }).join('; ');
      }
      
      sheet.appendRow([
        TextCellValue(DateFormat('yyyy-MM-dd').format(expense.date)),
        TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(expense.createdAt.toDate())),
        TextCellValue(expense.merchant),
        TextCellValue(expense.category),
        DoubleCellValue(expense.amount),
        TextCellValue(expense.currency),
        expense.subtotal != null ? DoubleCellValue(expense.subtotal!) : TextCellValue(''),
        expense.tax != null ? DoubleCellValue(expense.tax!) : TextCellValue(''),
        expense.tip != null ? DoubleCellValue(expense.tip!) : TextCellValue(''),
        expense.discount != null ? DoubleCellValue(expense.discount!) : TextCellValue(''),
        TextCellValue(expense.invoiceNumber ?? ''),
        TextCellValue(itemsStr),
        TextCellValue(expense.notes ?? ''),
      ]);
    }

    // Save the file
    final file = File(path);
    final bytes = excel.save();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    } else {
      throw Exception('Error saving Excel file.');
    }
  }

  /// Handles PDF file generation and saving.
  Future<void> _exportToPdf(List<Expense> expenses, String path) async {
    if (expenses.isEmpty) {
      throw Exception('No expenses to export');
    }

    final doc = pw.Document();

    // Group totals by currency (optimized - single pass)
    final totals = <String, double>{};
    for (var e in expenses) {
      totals.update(e.currency, (val) => val + e.amount, ifAbsent: () => e.amount);
    }

    // Use built-in fonts (no asset setup needed)
    final baseFont = pw.Font.helvetica();
    final boldFont = pw.Font.helveticaBold();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        footer: (pw.Context context) {
          // App Watermark in footer
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 20),
            child: pw.Text(
              'AI Expense Logger',
              style: pw.TextStyle(
                fontSize: 9,
                font: baseFont,
                color: PdfColors.grey600,
              ),
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Title
            pw.Header(
              level: 0,
              child: pw.Text('Detailed Expense Report',
                  style: pw.TextStyle(fontSize: 24, font: boldFont)),
            ),
            pw.SizedBox(height: 20),

            // Detailed expense list (limit to prevent excessive memory usage)
            // For very large lists, we'll process in chunks
            ...expenses.take(1000).toList().asMap().entries.map((entry) {
              final expense = entry.value;
              final isLast = entry.key == expenses.length - 1 || entry.key == 999;
              
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 20),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 1),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Header: Merchant, Date, Amount
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                expense.merchant,
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  font: boldFont,
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                expense.category,
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  font: baseFont,
                                  color: PdfColors.grey700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              CurrencyUtils.formatAmount(expense.amount, expense.currency, forPdf: true),
                              style: pw.TextStyle(
                                fontSize: 18,
                                font: boldFont,
                                color: PdfColors.blue700,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              DateFormat('MMM dd, yyyy').format(expense.date),
                              style: pw.TextStyle(
                                fontSize: 10,
                                font: baseFont,
                                color: PdfColors.grey600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    pw.Divider(height: 12, color: PdfColors.grey300),
                    
                    // Receipt Items
                    if (expense.items != null && expense.items!.isNotEmpty) ...[
                      pw.Text(
                        'Items:',
                        style: pw.TextStyle(
                          fontSize: 12,
                          font: boldFont,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      ...expense.items!.map((item) {
                        final quantity = (item['quantity'] as num?)?.toDouble() ?? 1.0;
                        final itemName = item['name'] ?? 'Item';
                        final displayName = quantity > 1.0 
                            ? '${quantity.toStringAsFixed(0)}x $itemName'
                            : itemName;
                        final itemPrice = (item['total_price'] as num?)?.toDouble() ?? 0.0;
                        
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Expanded(
                                child: pw.Text(
                                  displayName,
                                  style: pw.TextStyle(
                                    fontSize: 11,
                                    font: baseFont,
                                  ),
                                ),
                              ),
                              pw.Text(
                                CurrencyUtils.formatAmount(itemPrice, expense.currency, forPdf: true),
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  font: baseFont,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      pw.SizedBox(height: 8),
                    ],
                    
                    // Receipt Breakdown
                    if (expense.subtotal != null || expense.tax != null || 
                        expense.tip != null || expense.discount != null) ...[
                      pw.Text(
                        'Breakdown:',
                        style: pw.TextStyle(
                          fontSize: 12,
                          font: boldFont,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      if (expense.subtotal != null && expense.subtotal! > 0)
                        _buildBreakdownRow('Subtotal', expense.subtotal!, expense.currency, baseFont),
                      if (expense.discount != null && expense.discount! > 0)
                        _buildBreakdownRow('Discount', -expense.discount!, expense.currency, baseFont, isDiscount: true),
                      if (expense.tax != null && expense.tax! > 0)
                        _buildBreakdownRow('Tax', expense.tax!, expense.currency, baseFont),
                      if (expense.tip != null && expense.tip! > 0)
                        _buildBreakdownRow('Tip', expense.tip!, expense.currency, baseFont),
                      pw.SizedBox(height: 8),
                    ],
                    
                    // Additional Details
                    pw.Row(
                      children: [
                        if (expense.invoiceNumber != null && expense.invoiceNumber!.isNotEmpty)
                          pw.Text(
                            'Invoice #: ${expense.invoiceNumber}',
                            style: pw.TextStyle(
                              fontSize: 10,
                              font: baseFont,
                              color: PdfColors.grey600,
                            ),
                          ),
                        if (expense.invoiceNumber != null && expense.invoiceNumber!.isNotEmpty && expense.notes != null)
                          pw.Text(' | ', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                        if (expense.notes != null && expense.notes!.isNotEmpty)
                          pw.Expanded(
                            child: pw.Text(
                              'Notes: ${expense.notes}',
                              style: pw.TextStyle(
                                fontSize: 10,
                                font: baseFont,
                                color: PdfColors.grey600,
                              ),
                              maxLines: 2,
                            ),
                          ),
                      ],
                    ),
                    
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Added On: ${DateFormat('MMM dd, yyyy - h:mm a').format(expense.createdAt.toDate())}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        font: baseFont,
                        color: PdfColors.grey500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            // Show warning if expenses were truncated
            if (expenses.length > 1000)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 12),
                child: pw.Text(
                  'Note: Showing first 1000 expenses. Total expenses: ${expenses.length}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    font: baseFont,
                    color: PdfColors.orange700,
                  ),
                ),
              ),

            pw.Divider(height: 20),

            // Summary Section (Totals per currency)
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Summary:',
                    style: pw.TextStyle(fontSize: 16, font: boldFont),
                  ),
                  pw.SizedBox(height: 8),
                  ...totals.entries.map((entry) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Total (${entry.key}): ',
                            style: pw.TextStyle(fontSize: 14, font: baseFont),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text(
                            CurrencyUtils.formatAmount(entry.value, entry.key, forPdf: true),
                            style: pw.TextStyle(
                              fontSize: 18,
                              font: boldFont,
                              color: PdfColors.green800,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ];
        },
      ),
    );

    // Save the file with timeout to prevent hanging
    final file = File(path);
    try {
      // Generate PDF bytes with timeout
      final pdfBytes = await doc.save().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('PDF generation timed out after 30 seconds');
        },
      );
      
      // Write bytes to file with timeout
      await file.writeAsBytes(pdfBytes).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('File write timed out after 10 seconds');
        },
      );
    } catch (e) {
      // Clean up partial file if it exists
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {
          // Ignore deletion errors
        }
      }
      rethrow;
    }
  }

  // Helper method to build breakdown rows
  pw.Widget _buildBreakdownRow(String label, double amount, String currency, pw.Font font, {bool isDiscount = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              font: font,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            CurrencyUtils.formatAmount(amount, currency, forPdf: true),
            style: pw.TextStyle(
              fontSize: 10,
              font: font,
              color: isDiscount ? PdfColors.green700 : PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }
}
