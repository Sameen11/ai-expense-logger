import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/expense.dart';


class CsvExporter {

  /// Generates a CSV string from a list of expenses.
  String generateExpenseCsv(List<Expense> expenses) {
    // 1. Create the list of rows
    List<List<dynamic>> rows = [];

    // 2. Add the header row
    rows.add([
      "Date",
      "Merchant",
      "Amount",
      "Category",
      "Notes",
    ]);

    // 3. Add data rows
    for (var expense in expenses) {
      rows.add([
        DateFormat('yyyy-MM-dd').format(expense.date),
        expense.merchant,
        expense.amount,
        expense.category,
        expense.notes ?? "", // Use empty string for null notes
      ]);
    }

    // 4. Convert to CSV string
    return const ListToCsvConverter().convert(rows);
  }

  /// Generates the CSV, saves it to a temp file, and opens the share sheet.
  Future<void> exportExpenses(List<Expense> expenses, String monthName) async {
    // 1. Generate the CSV data
    final String csvData = generateExpenseCsv(expenses);

    // 2. Get the temporary directory
    final Directory tempDir = await getTemporaryDirectory();

    // 3. Create the file
    final String fileName = 'Expenses_$monthName.csv';
    final File file = File('${tempDir.path}/$fileName');

    // 4. Write the data to the file
    await file.writeAsString(csvData);

    // 5. Share the file
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Expense Report - $monthName',
    );
  }
}