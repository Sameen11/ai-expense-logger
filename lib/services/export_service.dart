// lib/services/export_service.dart

import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/expense.dart';

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

    // Open the file after it's created
    final result = await OpenFile.open(path);
    if (result.type != ResultType.done) {
      throw Exception('Could not open the exported file: ${result.message}');
    }
  }

  /// Handles CSV file generation and saving.
  Future<void> _exportToCsv(List<Expense> expenses, String path) async {
    // Add headers
    List<List<dynamic>> rows = [
      ['Date', 'Amount', 'Category', 'Description']
    ];

    // Add data rows
    for (var expense in expenses) {
      rows.add([
        DateFormat('yyyy-MM-dd').format(expense.date),
        expense.amount,
        expense.category,
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
      TextCellValue('Date'),
      TextCellValue('Amount'),
      TextCellValue('Category'),
    ]);

    // Add data rows
    for (var expense in expenses) {
      sheet.appendRow([
        TextCellValue(DateFormat('yyyy-MM-dd').format(expense.date)),
        DoubleCellValue(expense.amount), // Use a numeric cell type
        TextCellValue(expense.category),
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
    final doc = pw.Document();

    // Calculate total
    final total = expenses.fold<double>(0, (sum, item) => sum + item.amount);

    // Use built-in fonts (no asset setup needed)
    final baseFont = pw.Font.helvetica();
    final boldFont = pw.Font.helveticaBold();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Title
            pw.Header(
              level: 0,
              child: pw.Text('Expense Report',
                  style: pw.TextStyle(fontSize: 24, font: boldFont)),
            ),
            pw.SizedBox(height: 20),

            // Table
            pw.Table.fromTextArray(
              headers: ['Date', 'Category', 'Amount'],
              data: expenses.map((e) {
                // Format data for the table
                return [
                  DateFormat('yyyy-MM-dd').format(e.date),
                  e.category,
                  e.amount.toStringAsFixed(2),
                ];
              }).toList(),

              // Styling
              headerStyle: pw.TextStyle(font: boldFont, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
              cellStyle: pw.TextStyle(font: baseFont),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                3: pw.Alignment.centerRight, // Align 'Amount' column to the right
              },
            ),

            pw.Divider(height: 20),

            // Summary Row
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'Total:',
                  style: pw.TextStyle(fontSize: 16, font: boldFont),
                ),
                pw.SizedBox(width: 10),
                pw.Text(
                  total.toStringAsFixed(2),
                  style: pw.TextStyle(
                    fontSize: 16,
                    font: boldFont,
                    color: PdfColors.green800,
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    // Save the file
    final file = File(path);
    await file.writeAsBytes(await doc.save());
  }
}