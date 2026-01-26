import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// import '../../common/colors.dart';
import '../../models/expense.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import '../settings/category/add_category.dart';
import '../../services/gemini_service.dart';
import '../../widgets/notification_bar.dart';

class AddExpenseManuallyScreen extends StatefulWidget {
  // Full ReceiptData object with all extracted fields
  final ReceiptData? receiptData;
  // Backward compatibility - old tuple format
  final (String, double, String, String?, String?, double?)? extractedData;
  final Expense? expenseToEdit;

  const AddExpenseManuallyScreen({
    super.key,
    this.receiptData,
    this.extractedData,
    this.expenseToEdit,
  });

  @override
  State<AddExpenseManuallyScreen> createState() =>
      _AddExpenseManuallyScreenState();
}

class _AddExpenseManuallyScreenState extends State<AddExpenseManuallyScreen> {
  // --- STATE & CONTROLLERS ---
  final _formKey = GlobalKey<FormState>();
  final _merchantController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _categoryController = TextEditingController();
  final _notesController = TextEditingController();
  final _titleController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _paymentType =
      ""; // Empty by default - user must select if not in receipt
  String _selectedCurrency = 'USD'; // Default currency

  // Store selected emoji/icon for category
  String? _selectedCategoryEmoji;

  // Currency list with codes and symbols - Comprehensive list
  final List<Map<String, String>> _currencies = [
    // Major Currencies
    {"code": "USD", "symbol": "\$", "name": "US Dollar"},
    {"code": "EUR", "symbol": "€", "name": "Euro"},
    {"code": "GBP", "symbol": "£", "name": "British Pound"},
    {"code": "JPY", "symbol": "¥", "name": "Japanese Yen"},
    {"code": "CNY", "symbol": "¥", "name": "Chinese Yuan"},

    // South Asian
    {"code": "PKR", "symbol": "Rs", "name": "Pakistani Rupee"},
    {"code": "INR", "symbol": "₹", "name": "Indian Rupee"},
    {"code": "BDT", "symbol": "৳", "name": "Bangladeshi Taka"},
    {"code": "LKR", "symbol": "Rs", "name": "Sri Lankan Rupee"},
    {"code": "NPR", "symbol": "Rs", "name": "Nepalese Rupee"},
    {"code": "AFN", "symbol": "؋", "name": "Afghan Afghani"},

    // Middle East & Gulf
    {"code": "AED", "symbol": "د.إ", "name": "UAE Dirham"},
    {"code": "SAR", "symbol": "﷼", "name": "Saudi Riyal"},
    {"code": "QAR", "symbol": "﷼", "name": "Qatari Riyal"},
    {"code": "KWD", "symbol": "د.ك", "name": "Kuwaiti Dinar"},
    {"code": "OMR", "symbol": "﷼", "name": "Omani Rial"},
    {"code": "BHD", "symbol": "د.ب", "name": "Bahraini Dinar"},
    {"code": "JOD", "symbol": "د.ا", "name": "Jordanian Dinar"},
    {"code": "ILS", "symbol": "₪", "name": "Israeli Shekel"},
    {"code": "EGP", "symbol": "£", "name": "Egyptian Pound"},
    {"code": "IRR", "symbol": "﷼", "name": "Iranian Rial"},
    {"code": "IQD", "symbol": "ع.د", "name": "Iraqi Dinar"},

    // Turkish & Central Asian
    {"code": "TRY", "symbol": "₺", "name": "Turkish Lira"},
    {"code": "KZT", "symbol": "₸", "name": "Kazakhstani Tenge"},
    {"code": "UZS", "symbol": "сум", "name": "Uzbekistani Som"},
    {"code": "TJS", "symbol": "ЅМ", "name": "Tajikistani Somoni"},
    {"code": "TMT", "symbol": "m", "name": "Turkmenistani Manat"},
    {"code": "AZN", "symbol": "₼", "name": "Azerbaijani Manat"},
    {"code": "AMD", "symbol": "֏", "name": "Armenian Dram"},
    {"code": "GEL", "symbol": "₾", "name": "Georgian Lari"},

    // Southeast Asian
    {"code": "SGD", "symbol": "S\$", "name": "Singapore Dollar"},
    {"code": "MYR", "symbol": "RM", "name": "Malaysian Ringgit"},
    {"code": "THB", "symbol": "฿", "name": "Thai Baht"},
    {"code": "IDR", "symbol": "Rp", "name": "Indonesian Rupiah"},
    {"code": "PHP", "symbol": "₱", "name": "Philippine Peso"},
    {"code": "VND", "symbol": "₫", "name": "Vietnamese Dong"},
    {"code": "MMK", "symbol": "K", "name": "Myanmar Kyat"},
    {"code": "LAK", "symbol": "₭", "name": "Lao Kip"},
    {"code": "KHR", "symbol": "៛", "name": "Cambodian Riel"},

    // East Asian
    {"code": "KRW", "symbol": "₩", "name": "South Korean Won"},
    {"code": "TWD", "symbol": "NT\$", "name": "Taiwan Dollar"},
    {"code": "HKD", "symbol": "HK\$", "name": "Hong Kong Dollar"},
    {"code": "MOP", "symbol": "MOP\$", "name": "Macanese Pataca"},

    // European
    {"code": "CHF", "symbol": "CHF", "name": "Swiss Franc"},
    {"code": "SEK", "symbol": "kr", "name": "Swedish Krona"},
    {"code": "NOK", "symbol": "kr", "name": "Norwegian Krone"},
    {"code": "DKK", "symbol": "kr", "name": "Danish Krone"},
    {"code": "PLN", "symbol": "zł", "name": "Polish Zloty"},
    {"code": "CZK", "symbol": "Kč", "name": "Czech Koruna"},
    {"code": "HUF", "symbol": "Ft", "name": "Hungarian Forint"},
    {"code": "RON", "symbol": "lei", "name": "Romanian Leu"},
    {"code": "BGN", "symbol": "лв", "name": "Bulgarian Lev"},
    {"code": "HRK", "symbol": "kn", "name": "Croatian Kuna"},
    {"code": "RUB", "symbol": "₽", "name": "Russian Ruble"},
    {"code": "UAH", "symbol": "₴", "name": "Ukrainian Hryvnia"},

    // Americas
    {"code": "CAD", "symbol": "C\$", "name": "Canadian Dollar"},
    {"code": "MXN", "symbol": "\$", "name": "Mexican Peso"},
    {"code": "BRL", "symbol": "R\$", "name": "Brazilian Real"},
    {"code": "ARS", "symbol": "\$", "name": "Argentine Peso"},
    {"code": "CLP", "symbol": "\$", "name": "Chilean Peso"},
    {"code": "COP", "symbol": "\$", "name": "Colombian Peso"},
    {"code": "PEN", "symbol": "S/", "name": "Peruvian Sol"},

    // Oceania
    {"code": "AUD", "symbol": "A\$", "name": "Australian Dollar"},
    {"code": "NZD", "symbol": "NZ\$", "name": "New Zealand Dollar"},
    {"code": "FJD", "symbol": "FJ\$", "name": "Fijian Dollar"},

    // African
    {"code": "ZAR", "symbol": "R", "name": "South African Rand"},
    {"code": "NGN", "symbol": "₦", "name": "Nigerian Naira"},
    {"code": "KES", "symbol": "KSh", "name": "Kenyan Shilling"},
    {"code": "ETB", "symbol": "Br", "name": "Ethiopian Birr"},
    {"code": "GHS", "symbol": "₵", "name": "Ghanaian Cedi"},
    {"code": "MAD", "symbol": "د.م.", "name": "Moroccan Dirham"},
    {"code": "TND", "symbol": "د.ت", "name": "Tunisian Dinar"},
    {"code": "DZD", "symbol": "د.ج", "name": "Algerian Dinar"},
  ];

  // Store receipt items and split receipts
  List<ReceiptItem> _receiptItems = [];
  List<SplitReceipt>? _splitReceipts;
  String? _title;
  double? _subtotal;
  double? _discount;
  double? _discountPercentage;
  double? _taxAmount;
  double? _taxRate;
  double? _serviceCharge;
  double? _tip;
  String? _invoiceNumber;

  @override
  void initState() {
    super.initState();

    // Handle new ReceiptData format (preferred)
    if (widget.receiptData != null) {
      final receiptData = widget.receiptData!;
      _merchantController.text = receiptData.merchantName;
      _amountController.text = receiptData.totalAmount.toStringAsFixed(2);
      _categoryController.text = receiptData.category;

      // Store comprehensive data
      _title = receiptData.title;
      _titleController.text = receiptData.title ?? '';
      _receiptItems = receiptData.items;
      _subtotal = receiptData.subtotal;
      _discount = receiptData.discount ?? 0;
      _discountPercentage = receiptData.discountPercentage;
      _taxAmount = receiptData.taxAmount ?? 0;
      _taxRate = receiptData.taxRate;
      _serviceCharge = receiptData.serviceCharge ?? 0;
      _tip = receiptData.tip ?? 0;
      _splitReceipts = receiptData.splitReceipts;
      _invoiceNumber = receiptData.invoiceNumber;

      // Set currency from receipt
      if (receiptData.currency != null) {
        _selectedCurrency = receiptData.currency!;
      }

      // Set payment method from receipt (auto-select if available)
      if (receiptData.paymentMethod != null &&
          receiptData.paymentMethod!.isNotEmpty) {
        final receiptPayment = receiptData.paymentMethod!.trim();
        // Map receipt payment methods to UI payment types
        if (receiptPayment.toLowerCase().contains('cash')) {
          _paymentType = "Cash";
        } else if (receiptPayment.toLowerCase().contains('credit') ||
            receiptPayment.toLowerCase().contains('debit') ||
            receiptPayment.toLowerCase().contains('card')) {
          _paymentType = "Credit/Debit Card";
        } else if (receiptPayment.toLowerCase().contains('check') ||
            receiptPayment.toLowerCase().contains('cheque')) {
          _paymentType = "Check";
        } else {
          // For other payment methods (UPI, Digital Payment, etc.), default to Cash or leave empty
          // You can customize this based on your needs
          _paymentType = ""; // Leave empty for user to select
        }
      } else {
        // No payment method in receipt - leave empty for user to select
        _paymentType = "";
      }

      // Set date and time
      if (receiptData.date != null) {
        try {
          _selectedDate = DateTime.parse(receiptData.date!);
          // If time is available, add it to the date
          if (receiptData.time != null) {
            final timeParts = receiptData.time!.split(':');
            if (timeParts.length >= 2) {
              final hour = int.tryParse(timeParts[0]) ?? 0;
              final minute = int.tryParse(timeParts[1]) ?? 0;
              _selectedDate = DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                hour,
                minute,
              );
            }
          }
        } catch (e) {
          // Keep default date if parsing fails
        }
      }

      // Auto-generate notes from receipt data (editable)
      _generateNotesFromReceipt(receiptData);

      // Show confidence warning
      if (receiptData.confidence < 0.8) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SnackBarUtils.showWarning(
            context,
            'AI confidence: ${(receiptData.confidence * 100).toStringAsFixed(0)}% - Please verify',
          );
        });
      }

      // Show split receipt notification if applicable
      if (receiptData.hasSplitReceipts) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SnackBarUtils.showInfo(
            context,
            'Multiple receipts detected. Swipe to view split receipts.',
          );
        });
      }
    }
    // Handle old tuple format (backward compatibility)
    else if (widget.extractedData != null) {
      final (merchant, amount, category, date, paymentMethod, confidence) =
          widget.extractedData!;
      _merchantController.text = merchant;
      _amountController.text = amount.toStringAsFixed(2);
      _categoryController.text = category;

      // Set payment method from old format (auto-select if available)
      if (paymentMethod != null && paymentMethod!.isNotEmpty) {
        final receiptPayment = paymentMethod!.trim();
        // Map receipt payment methods to UI payment types
        if (receiptPayment.toLowerCase().contains('cash')) {
          _paymentType = "Cash";
        } else if (receiptPayment.toLowerCase().contains('credit') ||
            receiptPayment.toLowerCase().contains('debit') ||
            receiptPayment.toLowerCase().contains('card')) {
          _paymentType = "Credit/Debit Card";
        } else if (receiptPayment.toLowerCase().contains('check') ||
            receiptPayment.toLowerCase().contains('cheque')) {
          _paymentType = "Check";
        } else {
          _paymentType = ""; // Leave empty for user to select
        }
      } else {
        // No payment method - leave empty for user to select
        _paymentType = "";
      }

      if (date != null) {
        try {
          _selectedDate = DateTime.parse(date);
        } catch (e) {}
      }

      if (confidence != null && confidence < 0.8) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SnackBarUtils.showWarning(
            context,
            'AI confidence: ${(confidence * 100).toStringAsFixed(0)}% - Please verify',
          );
        });
      }
    }

    // HANDLE EDIT MODE
    if (widget.expenseToEdit != null) {
      final e = widget.expenseToEdit!;
      _merchantController.text = e.merchant;
      _amountController.text = e.amount.toString(); // or toStringAsFixed(2)
      _dateController.text = DateFormat('MMM dd, yyyy').format(e.date);
      _categoryController.text = e.category;

      _notesController.text = e.notes ?? "";
      _selectedDate = e.date;
      _selectedCurrency = e.currency;
      _selectedCategoryEmoji = e.emoji;

      // Optional: Load advanced fields if they exist
      if (e.items != null) {
        _receiptItems = e.items!
            .map(
              (item) => ReceiptItem(
                name: item['name'] ?? 'Item',
                quantity: (item['quantity'] as num).toDouble(),
                totalPrice: (item['total_price'] as num).toDouble(),
              ),
            )
            .toList();
      }
      _subtotal = e.subtotal;
      _taxAmount = e.tax;
      _tip = e.tip;
      _discount = e.discount;
      _invoiceNumber = e.invoiceNumber;
    }

    // Format date with time if available
    _updateDateDisplay();
  }

  // Generate concise notes from receipt data (30–50 characters)
  void _generateNotesFromReceipt(ReceiptData receiptData) {
    final List<String> parts = [];
    int totalLength = 0;
    const int minChars = 30;
    const int maxChars = 50;

    String trimLabel(String text, int maxLength) {
      final trimmed = text.trim();
      if (trimmed.length <= maxLength) return trimmed;
      return '${trimmed.substring(0, maxLength - 3)}...';
    }

    void addPart(String text) {
      final candidate = text.trim();
      if (candidate.isEmpty) return;
      final additional = candidate.length + (parts.isNotEmpty ? 2 : 0);
      if (totalLength + additional <= maxChars) {
        parts.add(candidate);
        totalLength += additional;
      }
    }

    final categoryTag = trimLabel(
      receiptData.category.split(' ').first.replaceAll('&', ''),
      8,
    );
    addPart(categoryTag);

    addPart(trimLabel(receiptData.merchantName, 15));

    if (receiptData.items.isNotEmpty) {
      final firstItem = receiptData.items.first.name;
      String itemLabel = trimLabel(firstItem, 14);
      if (receiptData.items.length > 1) {
        itemLabel = '$itemLabel +${receiptData.items.length - 1}';
      }
      addPart(itemLabel);
    }

    final currencySymbol = _getCurrencySymbol();
    if (receiptData.discount != null && receiptData.discount! > 0) {
      addPart(
        'Disc $currencySymbol${receiptData.discount!.toStringAsFixed(0)}',
      );
    } else if (receiptData.taxAmount != null && receiptData.taxAmount! > 0) {
      addPart(
        'Tax $currencySymbol${receiptData.taxAmount!.toStringAsFixed(0)}',
      );
    }

    if (receiptData.paymentMethod != null) {
      final payment = receiptData.paymentMethod!
          .replaceAll('Credit Card', 'Card')
          .replaceAll('Debit Card', 'Card')
          .replaceAll('Digital Payment', 'Digital');
      addPart(trimLabel(payment, 8));
    }

    if (receiptData.invoiceNumber == null ||
        receiptData.invoiceNumber!.isEmpty) {
      addPart('INV N/A');
    } else {
      addPart(trimLabel('INV ${receiptData.invoiceNumber!}', 12));
    }

    var finalNotes = parts.join(', ');

    if (finalNotes.length < minChars && receiptData.items.length > 1) {
      final moreText = ' +${receiptData.items.length - 1}';
      if (finalNotes.length + moreText.length <= maxChars) {
        finalNotes += moreText;
      }
    }

    if (finalNotes.length < minChars) {
      final currencySymbol = _getCurrencySymbol();
      final amountText =
          '$currencySymbol${receiptData.totalAmount.toStringAsFixed(0)}';
      if (finalNotes.isEmpty) {
        finalNotes = amountText;
      } else if (finalNotes.length + amountText.length + 2 <= maxChars) {
        finalNotes += ', $amountText';
      }
    }

    if (finalNotes.length < minChars) {
      final filler = ' receipt';
      if (finalNotes.length + filler.length <= maxChars) {
        finalNotes += filler;
      }
    }

    if (finalNotes.length > maxChars) {
      finalNotes = '${finalNotes.substring(0, maxChars - 3)}...';
    }

    _notesController.text = finalNotes;
  }

  // Update date display with time if available
  void _updateDateDisplay() {
    String dateFormat = 'MMM dd, yyyy';

    // Check if time is set (hour and minute are not both 0)
    if (_selectedDate.hour != 0 || _selectedDate.minute != 0) {
      dateFormat = 'MMM dd, yyyy • h:mm a';
    }

    _dateController.text = DateFormat(dateFormat).format(_selectedDate);
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _categoryController.dispose();
    _notesController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final theme = Theme.of(context);
    // First show date picker
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
              onPrimary: theme.colorScheme.onPrimary,
              onSurface: theme.colorScheme.onSurface,
            ),
            dialogBackgroundColor: theme.brightness == Brightness.dark
                ? theme.cardColor
                : Colors.white,
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      // Then show time picker
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
        builder: (context, child) {
          return Theme(
            data: theme.copyWith(
              colorScheme: theme.colorScheme.copyWith(
                primary: theme.colorScheme.primary,
                onPrimary: theme.colorScheme.onPrimary,
                onSurface: theme.colorScheme.onSurface,
              ),
              dialogBackgroundColor: theme.brightness == Brightness.dark
                  ? theme.cardColor
                  : Colors.white,
            ),
            child: child!,
          );
        },
      );

      if (mounted) {
        setState(() {
          if (pickedTime != null) {
            _selectedDate = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
          } else {
            _selectedDate = pickedDate;
          }
          _updateDateDisplay();
        });
      }
    }
  }

  // Open bottom sheet for category selection
  void _openCategorySheet() {
    final theme = Theme.of(context);

    // We don't fetch here anymore, we use Consumer inside the sheet

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Select category",
                    style: theme.textTheme.titleMedium?.copyWith(
                      // fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Wrap in Consumer to be reactive to deletes/additions
                Flexible(
                  child: Consumer<CategoryProvider>(
                    builder: (context, catProvider, child) {
                      final categories = catProvider.getAllCategories();

                      return GridView.builder(
                        shrinkWrap: true,
                        // Add 1 for the "Add New" button
                        itemCount: categories.length + 1,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 3 / 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemBuilder: (context, index) {
                          // Logic for "Add New Category" button (last item)
                          if (index == categories.length) {
                            return InkWell(
                              onTap: () async {
                                Navigator.pop(context); // Close sheet first

                                // Navigate to Add Category Screen
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AddCategoryScreen(),
                                  ),
                                );

                                // Re-open sheet to show new category
                                if (mounted) {
                                  _openCategorySheet();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer
                                      .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.5),
                                    style: BorderStyle.solid,
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_circle_outline_rounded,
                                      size: 24,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Add New",
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // Logic for existing categories
                          final cat = categories[index];
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _categoryController.text = cat.name;
                                _selectedCategoryEmoji = null;
                              });
                              Navigator.pop(context);
                            },
                            // Add Long Press to Manage (Edit/Delete)
                            onLongPress: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: theme.scaffoldBackgroundColor,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                builder: (ctx) {
                                  return SafeArea(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16.0,
                                          ),
                                          child: Container(
                                            height: 4,
                                            width: 40,
                                            decoration: BoxDecoration(
                                              color: theme.dividerColor
                                                  .withOpacity(0.4),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 16.0,
                                          ),
                                          child: Text(
                                            "Manage '${cat.name}'",
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                        ListTile(
                                          leading: Icon(
                                            Icons.edit_rounded,
                                            color: theme.colorScheme.primary,
                                          ),
                                          title: const Text("Edit Category"),
                                          onTap: () async {
                                            Navigator.pop(
                                              ctx,
                                            ); // Close Manage sheet
                                            Navigator.pop(
                                              context,
                                            ); // Close Category Picker

                                            // Navigate to Edit
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    AddCategoryScreen(
                                                      categoryToEdit: cat,
                                                    ),
                                              ),
                                            );

                                            // Re-open category sheet to show changes
                                            if (mounted) _openCategorySheet();
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(
                                            Icons.delete_rounded,
                                            color: Colors.red,
                                          ),
                                          title: const Text(
                                            "Delete Category",
                                            style: TextStyle(color: Colors.red),
                                          ),
                                          onTap: () {
                                            Navigator.pop(
                                              ctx,
                                            ); // Close Manage sheet

                                            // Show Delete Confirmation
                                            showDialog(
                                              context: context,
                                              builder: (dialogCtx) => AlertDialog(
                                                backgroundColor:
                                                    theme.cardColor,
                                                title: Text(
                                                  "Delete '${cat.name}'?",
                                                  style: theme
                                                      .textTheme
                                                      .titleMedium,
                                                ),
                                                content: Text(
                                                  "You are about to delete this category. This cannot be undone.",
                                                  style: theme
                                                      .textTheme
                                                      .bodyMedium,
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          dialogCtx,
                                                        ),
                                                    child: Text(
                                                      "Cancel",
                                                      style: TextStyle(
                                                        color: theme
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () async {
                                                      Navigator.pop(
                                                        dialogCtx,
                                                      ); // Close dialog
                                                      try {
                                                        await catProvider
                                                            .deleteCategory(
                                                              cat.name,
                                                            );
                                                        if (mounted) {
                                                          SnackBarUtils.showSuccess(
                                                            context,
                                                            "Category deleted",
                                                          );
                                                        }
                                                      } catch (e) {
                                                        if (mounted) {
                                                          String errorMsg = e
                                                              .toString()
                                                              .replaceAll(
                                                                "Exception: ",
                                                                "",
                                                              );
                                                          SnackBarUtils.showError(
                                                            context,
                                                            errorMsg,
                                                          );
                                                        }
                                                      }
                                                    },
                                                    child: const Text(
                                                      "Delete",
                                                      style: TextStyle(
                                                        color: Colors.redAccent,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.dividerColor.withOpacity(0.1),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    cat.iconData,
                                    size: 24,
                                    color: cat.colorValue,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    cat.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                // sss
              ],
            ),
          ),
        );
      },
    );
  }

  // Open bottom sheet for currency selection
  void _openCurrencySheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Select currency",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _currencies.length,
                    itemBuilder: (context, index) {
                      final currency = _currencies[index];
                      final isSelected = _selectedCurrency == currency['code'];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCurrency = currency['code']!;
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary.withOpacity(0.1)
                                : theme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.disabledColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    currency['symbol']!,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currency['name']!,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.onSurface,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      currency['code']!,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            // fontSize: 13,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: theme.colorScheme.primary,
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Card container wrapper
  Widget _sectionCard({required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: child,
    );
  }

  // Styled input used for merchant, date, notes etc.
  Widget _styledInputField({
    required String label,
    required TextEditingController controller,
    bool isNumber = false,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
    Widget? trailing,
    double height = 65, // Note: height is handled differently now
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber
              ? TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          readOnly: readOnly,
          onTap: onTap,
          validator: validator,
          decoration: InputDecoration(
            // 1. This tells the field to be filled with a color
            filled: true,
            fillColor: theme.brightness == Brightness.dark
                ? theme.scaffoldBackgroundColor
                : const Color(0xFFF7F7F7),

            // 2. This is the border when the field is NOT focused
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), // Your border radius
              borderSide: BorderSide.none, // No outline
            ),

            // 3. This is the border when the field IS focused
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), // Same border radius
              borderSide: BorderSide.none, // No outline
            ),

            // These make it look like your original
            hintText: '',
            isDense: true, // This helps control the height
            // This adds the padding that your Container had
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: (height - 20) / 2, // Simple way to center vertically
            ),
            suffixIcon: trailing, // Use suffixIcon for the trailing widget
          ),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  // Special amount field design: currency selector + big centered amount
  Widget _amountField() {
    final theme = Theme.of(context);
    // Get current currency symbol
    final currentCurrency = _currencies.firstWhere(
      (c) => c['code'] == _selectedCurrency,
      orElse: () => _currencies[0],
    );
    final currencySymbol = currentCurrency['symbol'] ?? '\$';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Amount",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            // Currency dropdown
            InkWell(
              onTap: _openCurrencySheet,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$currencySymbol $_selectedCurrency',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) =>
              value == null || value.isEmpty ? 'Enter an amount' : null,
          style: theme.textTheme.headlineLarge?.copyWith(
            // This is the style for the input text "0.00"
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            // 1. Replaces the Container's color
            filled: true,
            fillColor: theme.brightness == Brightness.dark
                ? theme.scaffoldBackgroundColor
                : const Color(0xFFF7F7F7),

            // 2. Currency symbol prefix
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 18, right: 12),
              child: Text(
                currencySymbol,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            // This ensures the prefixIcon is centered and doesn't add extra space
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),

            // 3. Replaces the Container's height/padding
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 18,
            ),

            // 4. Sets the border for both focused and unfocused states
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),

            hintText: "0.00",
            hintStyle: theme.textTheme.headlineLarge?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
          ),
        ),
      ],
    );
  }

  // Notes field with multiline support (editable)
  Widget _notesField() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Notes (Optional)",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          maxLines: 6, // Multiline support
          minLines: 3, // Minimum 3 lines
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.brightness == Brightness.dark
                ? theme.scaffoldBackgroundColor
                : const Color(0xFFF7F7F7),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
            hintText: 'Receipt details will be auto-filled here...',
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
            height: 1.4, // Line height for better readability
          ),
        ),
      ],
    );
  }

  Widget _categoryField() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Category",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _openCategorySheet,
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? theme.scaffoldBackgroundColor
                  : const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                // icon emoji box
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? theme.colorScheme.primary.withOpacity(0.2)
                        : const Color(0xFFFFF3E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _selectedCategoryEmoji ?? "📦",
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _categoryController.text.isEmpty
                        ? "Select Category"
                        : _categoryController.text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 26,
                  color: theme.colorScheme.onSurface,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _emojiForCategory(String category) {
    return context.read<CategoryProvider>().getEmojiForCategory(category);
  }

  // Get currency symbol from currency code
  String _getCurrencySymbol() {
    final currency = _currencies.firstWhere(
      (c) => c['code'] == _selectedCurrency,
      orElse: () => _currencies[0],
    );
    return currency['symbol'] ?? '\$';
  }

  // Items list section - left name, right price
  Widget _itemsListSection() {
    final theme = Theme.of(context);
    final currencySymbol = _getCurrencySymbol();
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Items",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ..._receiptItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.quantity > 1.0
                          ? '${item.quantity.toStringAsFixed(0)}x ${item.name}'
                          : item.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$currencySymbol${item.totalPrice.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 24, color: theme.dividerColor.withOpacity(0.1)),
          Builder(
            builder: (context) {
              // Calculate total - use subtotal if available, otherwise sum all items
              final double calculatedTotal =
                  _subtotal ??
                  (_receiptItems.isEmpty
                      ? 0.0
                      : _receiptItems.fold<double>(
                          0.0,
                          (sum, item) => sum + item.totalPrice,
                        ));

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Items Total",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '$currencySymbol${calculatedTotal.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Receipt details section - discount, tax, service charge, tip, invoice number
  Widget _receiptDetailsSection() {
    final theme = Theme.of(context);
    final currencySymbol = _getCurrencySymbol();
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Receipt Details",
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          if (_discount != null && _discount! > 0) ...[
            _receiptDetailRow(
              "Discount",
              '-$currencySymbol${_discount!.toStringAsFixed(2)}${_discountPercentage != null ? ' (${_discountPercentage!.toStringAsFixed(1)}%)' : ''}',
            ),
            const SizedBox(height: 8),
          ],
          if (_taxAmount != null && _taxAmount! > 0) ...[
            _receiptDetailRow(
              "Tax",
              '$currencySymbol${_taxAmount!.toStringAsFixed(2)}${_taxRate != null ? ' (${_taxRate!.toStringAsFixed(1)}%)' : ''}',
            ),
            const SizedBox(height: 8),
          ],
          if (_serviceCharge != null && _serviceCharge! > 0) ...[
            _receiptDetailRow(
              "Service Charge",
              '$currencySymbol${_serviceCharge!.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
          ],
          if (_tip != null && _tip! > 0) ...[
            _receiptDetailRow(
              "Tip",
              '$currencySymbol${_tip!.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
          ],
          _receiptDetailRow(
            "Invoice #",
            (_invoiceNumber != null && _invoiceNumber!.isNotEmpty)
                ? _invoiceNumber!
                : 'Not Available',
          ),
        ],
      ),
    );
  }

  // Receipt detail row helper
  Widget _receiptDetailRow(String label, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  // Split receipts section
  Widget _splitReceiptsSection() {
    final theme = Theme.of(context);
    final currencySymbol = _getCurrencySymbol();
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                "Split Receipts",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._splitReceipts!.asMap().entries.map((entry) {
            final index = entry.key;
            final splitReceipt = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < _splitReceipts!.length - 1 ? 16 : 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    splitReceipt.merchantName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...splitReceipt.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.quantity > 1.0
                                  ? '${item.quantity.toStringAsFixed(0)}x ${item.name}'
                                  : item.name,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Text(
                            '$currencySymbol${item.totalPrice.toStringAsFixed(2)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(
                    height: 12,
                    color: theme.dividerColor.withOpacity(0.1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        splitReceipt.category,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '$currencySymbol${splitReceipt.totalAmount.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _addSplitExpenses(ExpenseProvider expenseProvider) async {
    if (_splitReceipts == null || _splitReceipts!.isEmpty) return;
    for (final split in _splitReceipts!) {
      final splitNotes = '${_notesController.text} • ${split.merchantName}'
          .trim();
      await expenseProvider.addExpense(
        merchant: split.merchantName,
        amount: split.totalAmount, // Use totalAmount (including tax/tip share)
        date: _selectedDate,
        category: split.category,
        emoji: _emojiForCategory(split.category),
        notes: splitNotes.isNotEmpty ? splitNotes : null,
        currency: _selectedCurrency, // Pass selected currency
        items: split.items.map((item) => item.toJson()).toList(),
        subtotal: split.subtotal,
      );
    }
  }

  Widget _saveButton(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: theme.cardColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
            ),
            onPressed: () {
              // Draft action - simply pop for now or save as draft
              Navigator.pop(context);
            },
            child: Text(
              "Cancel",
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final expenseProvider = context.read<ExpenseProvider>();

                try {
                  if (_splitReceipts != null && _splitReceipts!.isNotEmpty) {
                    await _addSplitExpenses(expenseProvider);

                    // Navigate to Dashboard with Expenses tab selected
                    if (mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      SnackBarUtils.showSuccess(
                        context,
                        "Split expenses added! 🎉",
                      );
                    }
                  } else {
                    final String merchant = _merchantController.text;
                    final double amount =
                        double.tryParse(_amountController.text) ?? 0.0;
                    final String category = _categoryController.text.trim();
                    final String notes = _notesController.text;

                    // Ensure emoji is always set - use category-based fallback if needed
                    final emoji =
                        _selectedCategoryEmoji?.trim().isNotEmpty == true
                        ? _selectedCategoryEmoji!
                        : _emojiForCategory(category);

                    if (widget.expenseToEdit != null) {
                      final updatedExpense = Expense(
                        id: widget.expenseToEdit!.id, // Keep original ID
                        merchant: merchant,
                        amount: amount,
                        date: _selectedDate,
                        category: category,
                        notes: notes,
                        emoji: emoji,
                        currency: _selectedCurrency,
                        createdAt: widget
                            .expenseToEdit!
                            .createdAt, // Keep original timestamp
                        items: _receiptItems
                            .map((item) => item.toJson())
                            .toList(),
                        subtotal: _subtotal,
                        tax: _taxAmount,
                        tip: _tip,
                        discount: _discount,
                        invoiceNumber: _invoiceNumber,
                      );

                      await expenseProvider.updateExpense(
                        widget.expenseToEdit!.id,
                        updatedExpense,
                      );
                      if (mounted) {
                        Navigator.pop(context); // Close Add Screen
                        Navigator.pop(
                          context,
                        ); // Close Detail Screen (return to list)
                        SnackBarUtils.showSuccess(context, "Expense updated!");
                      }
                    } else {
                      await expenseProvider.addExpense(
                        merchant: merchant,
                        amount: amount,
                        date: _selectedDate,
                        category: category,
                        notes: notes.isNotEmpty ? notes : null,
                        emoji: emoji,
                        currency: _selectedCurrency,
                        // Pass selected currency
                        items: _receiptItems
                            .map((item) => item.toJson())
                            .toList(),
                        subtotal: _subtotal,
                        tax: _taxAmount,
                        tip: _tip,
                        discount: _discount,
                        invoiceNumber: _invoiceNumber,
                      );

                      // Navigate to Dashboard with Expenses tab selected
                      if (mounted) {
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                        SnackBarUtils.showSuccess(context, "Expense added! 🎉");
                      }
                    }
                  }
                } catch (e) {
                  // Show error message to user
                  if (mounted) {
                    SnackBarUtils.showError(
                      context,
                      "Failed to save expense: ${e.toString()}\nPlease check your internet connection.",
                    );
                  }
                }
              }
            },
            child: const Text(
              "Add",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _circleBackButton() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: theme.cardColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              blurRadius: 6,
              offset: const Offset(0, 3),
              color: Colors.black.withOpacity(0.1),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  // --- BUILD ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: theme.scaffoldBackgroundColor,
        centerTitle: true,
        leading: _circleBackButton(),
        title: Text(
          "Add transaction",
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionCard(child: _amountField()),
              const SizedBox(height: 16),
              _sectionCard(
                child: Column(
                  children: [
                    _styledInputField(
                      label: "Merchant",
                      controller: _merchantController,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter a merchant'
                          : null,
                      height: 50, // Smaller merchant field
                    ),
                    const SizedBox(height: 16),
                    _styledInputField(
                      label: "Receipt Date",
                      controller: _dateController,
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Select a date'
                          : null,
                      height: 50, // Smaller date field
                    ),
                    const SizedBox(height: 16),
                    _categoryField(),
                    const SizedBox(height: 16),
                    _notesField(),
                  ],
                ),
              ),
              // Title field (normal size) - if extracted from receipt
              if (_title != null && _title!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _sectionCard(
                  child: _styledInputField(
                    label: "Title",
                    controller: _titleController,
                    height: 55, // Normal size for title
                  ),
                ),
              ],

              // Items list with left name, right price
              if (_receiptItems.isNotEmpty) ...[
                const SizedBox(height: 16),
                _itemsListSection(),
              ],

              // Discount, Tax, Service Charge, Tip, Invoice Number (smaller fields)
              if (_discount != null && _discount! > 0 ||
                  _taxAmount != null && _taxAmount! > 0 ||
                  _serviceCharge != null && _serviceCharge! > 0 ||
                  _tip != null && _tip! > 0 ||
                  _invoiceNumber != null && _invoiceNumber!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _receiptDetailsSection(),
              ],

              // Split Receipts Support
              if (_splitReceipts != null && _splitReceipts!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _splitReceiptsSection(),
              ],

              const SizedBox(height: 24),
              const SizedBox(height: 24),
              Text(
                "Payment Method",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              // Horizontal Scrollable Row for Payment Options
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _PaymentOption(
                      icon: Icons.money_rounded,
                      label: "Cash",
                      isSelected: _paymentType == "Cash",
                      onTap: () => setState(() => _paymentType = "Cash"),
                    ),
                    const SizedBox(width: 12),
                    _PaymentOption(
                      icon: Icons.credit_card_rounded,
                      label: "Card",
                      isSelected: _paymentType == "Credit/Debit Card",
                      onTap: () =>
                          setState(() => _paymentType = "Credit/Debit Card"),
                    ),
                    const SizedBox(width: 12),
                    _PaymentOption(
                      icon: Icons.account_balance_rounded,
                      label: "Check",
                      isSelected: _paymentType == "Check",
                      onTap: () => setState(() => _paymentType = "Check"),
                    ),
                    const SizedBox(width: 12),
                    _PaymentOption(
                      icon: Icons.account_balance_wallet_rounded,
                      label: "Other",
                      isSelected: _paymentType == "Other",
                      onTap: () => setState(() => _paymentType = "Other"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _saveButton(context),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// --- NEW WIDGETS (Outside of State Class) ---
// ----------------------------------------------------

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor.withOpacity(0.2),
            width: isSelected ? 0 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
