import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../common/colors.dart';
import '../../providers/expense_provider.dart';
import '../../services/gemini_service.dart';
import '../../widgets/notification_bar.dart';

class AddExpenseManuallyScreen extends StatefulWidget {
  // Full ReceiptData object with all extracted fields
  final ReceiptData? receiptData;
  // Backward compatibility - old tuple format
  final (String, double, String, String?, String?, double?)? extractedData;

  const AddExpenseManuallyScreen({
    super.key, 
    this.receiptData,
    this.extractedData,
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
  String _paymentType = ""; // Empty by default - user must select if not in receipt
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

  // Category set B (Finance App Standard) with emoji icons
  final List<Map<String, String>> _categories = [
    {"label": "Food & Drinks", "emoji": "🍔"},
    {"label": "Groceries", "emoji": "🛒"},
    {"label": "Transport", "emoji": "🚌"},
    {"label": "Shopping", "emoji": "🛍"},
    {"label": "Subscriptions", "emoji": "📺"},
    {"label": "Bills & Utilities", "emoji": "💡"},
    {"label": "Salary", "emoji": "💼"},
    {"label": "Business", "emoji": "🏢"},
    {"label": "Investments", "emoji": "📈"},
    {"label": "Health", "emoji": "❤️"},
    {"label": "Entertainment", "emoji": "🎬"},
    {"label": "Travel", "emoji": "✈️"},
    {"label": "Other", "emoji": "📦"},
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
      if (receiptData.paymentMethod != null && receiptData.paymentMethod!.isNotEmpty) {
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
      
      // Set category emoji
      final match = _categories.firstWhere(
        (c) => c["label"]!.toLowerCase() == receiptData.category.toLowerCase(),
        orElse: () => {},
      );
      if (match.isNotEmpty) _selectedCategoryEmoji = match["emoji"];
      
      // Show confidence warning
      if (receiptData.confidence < 0.8) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SnackBarUtils.showWarning(
            context, 
            'AI confidence: ${(receiptData.confidence * 100).toStringAsFixed(0)}% - Please verify'
          );
        });
      }
      
      // Show split receipt notification if applicable
      if (receiptData.hasSplitReceipts) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SnackBarUtils.showInfo(
            context, 
            'Multiple receipts detected. Swipe to view split receipts.'
          );
        });
      }
    }
    // Handle old tuple format (backward compatibility)
    else if (widget.extractedData != null) {
      final (merchant, amount, category, date, paymentMethod, confidence) = widget.extractedData!;
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
      
      final match = _categories.firstWhere(
            (c) => c["label"]!.toLowerCase() == category.toLowerCase(),
        orElse: () => {},
      );
      if (match.isNotEmpty) _selectedCategoryEmoji = match["emoji"];
      
      if (confidence != null && confidence < 0.8) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SnackBarUtils.showWarning(
            context, 
            'AI confidence: ${(confidence * 100).toStringAsFixed(0)}% - Please verify'
          );
        });
      }
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

    final categoryTag = trimLabel(receiptData.category.split(' ').first.replaceAll('&', ''), 8);
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
      addPart('Disc $currencySymbol${receiptData.discount!.toStringAsFixed(0)}');
    } else if (receiptData.taxAmount != null && receiptData.taxAmount! > 0) {
      addPart('Tax $currencySymbol${receiptData.taxAmount!.toStringAsFixed(0)}');
    }

    if (receiptData.paymentMethod != null) {
      final payment = receiptData.paymentMethod!
          .replaceAll('Credit Card', 'Card')
          .replaceAll('Debit Card', 'Card')
          .replaceAll('Digital Payment', 'Digital');
      addPart(trimLabel(payment, 8));
    }

    if (receiptData.invoiceNumber == null || receiptData.invoiceNumber!.isEmpty) {
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
      final amountText = '$currencySymbol${receiptData.totalAmount.toStringAsFixed(0)}';
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
    // First show date picker
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4A90E2),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1D1D1F),
            ),
            dialogBackgroundColor: Colors.white,
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4A90E2),
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
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF4A90E2),
                onPrimary: Colors.white,
                onSurface: Color(0xFF1D1D1F),
              ),
              dialogBackgroundColor: Colors.white,
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Select category",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    itemCount: _categories.length,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 3 / 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _categoryController.text = cat["label"]!;
                            _selectedCategoryEmoji = cat["emoji"];
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F7F7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                cat["emoji"]!,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                cat["label"]!,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Select currency",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1C1E),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryColor.withOpacity(0.1) : const Color(0xFFF7F7F7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryColor : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primaryColor : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    currency['symbol']!,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? Colors.white : Colors.grey[700],
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
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? AppColors.primaryColor : const Color(0xFF1C1C1E),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      currency['code']!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primaryColor,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
            color: Colors.black.withOpacity(0.05),
          )
        ],
      ),
      child: child,
    );
  }

  // Styled input used for merchant, date, notes etc.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              color: Color(0xff6B6B6B),
              fontSize: 14,
            )),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType:
          isNumber ? TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          readOnly: readOnly,
          onTap: onTap,
          validator: validator,
          decoration: InputDecoration(
            // 1. This tells the field to be filled with a color
            filled: true,
            fillColor: const Color(0xFFF7F7F7),

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
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1C1C1E),
          ),
        ),
      ],
    );
  }
  // Special amount field design: currency selector + big centered amount
  Widget _amountField() {
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
        const Text(
          "Amount",
          style: TextStyle(
            color: Color(0xff6B6B6B),
            fontSize: 14,
          ),
            ),
            // Currency dropdown
            InkWell(
              onTap: _openCurrencySheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$currencySymbol $_selectedCurrency',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.primaryColor),
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
          style: const TextStyle( // This is the style for the input text "0.00"
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1C1C1E),
          ),
          decoration: InputDecoration(
            // 1. Replaces the Container's color
            filled: true,
            fillColor: const Color(0xFFF7F7F7),

            // 2. Currency symbol prefix
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 18, right: 12),
              child: Text(
                currencySymbol,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C1C1E),
                ),
              ),
            ),
            // This ensures the prefixIcon is centered and doesn't add extra space
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),

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
            hintStyle: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFFC7C7CC),
            ),
          ),
        ),
      ],
    );
  }

  // Notes field with multiline support (editable)
  Widget _notesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Notes (Optional)",
          style: TextStyle(
            color: Color(0xff6B6B6B),
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
            fillColor: const Color(0xFFF7F7F7),
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
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1C1C1E),
            height: 1.4, // Line height for better readability
          ),
        ),
      ],
    );
  }

  Widget _categoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Category",
          style: TextStyle(
            color: Color(0xff6B6B6B),
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
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                // icon emoji box
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E9),
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 26, color: Color(0xFF1C1C1E)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _emojiForCategory(String category) {
    final match = _categories.firstWhere(
      (c) => c["label"]!.toLowerCase() == category.toLowerCase(),
      orElse: () => {"emoji": "📦"},
    );
    return match["emoji"] ?? "📦";
  }

  // Get currency symbol from currency code
  String _getCurrencySymbol() {
    final currency = _currencies.firstWhere(
      (c) => c['code'] == _selectedCurrency,
      orElse: () => _currencies[0],
    );
    return currency['symbol'] ?? '\$';
  }

  // --- Your updated widget ---
  Widget _paymentChip(String label) {
    final isSelected = _paymentType == label;

    // Look up the icon from the map, using a default if not found
    final IconData endIcon = _paymentIcons[label] ?? Icons.payment; // Default icon

    return InkWell(
      onTap: () {
        setState(() => _paymentType = label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor.withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primaryColor : Colors.grey,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xff1C1C1E) : Colors.grey[600],
              ),
            ),

            // --- NEW WIDGETS ---
            const Spacer(), // This pushes the icon to the end
            Icon(
              endIcon, // Use the icon we looked up
              color: isSelected ? AppColors.primaryColor : Colors.grey[600],
            ),
            // --- END NEW WIDGETS ---
          ],
        ),
      ),
    );
  }

  // Items list section - left name, right price
  Widget _itemsListSection() {
    final currencySymbol = _getCurrencySymbol();
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Items",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xff1C1C1E),
            ),
          ),
          const SizedBox(height: 12),
          ..._receiptItems.map((item) => Padding(
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff1C1C1E),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$currencySymbol${item.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1C1C1E),
                  ),
                ),
              ],
            ),
          )),
          const Divider(height: 24),
          Builder(
            builder: (context) {
              // Calculate total - use subtotal if available, otherwise sum all items
              final double calculatedTotal = _subtotal ?? 
                (_receiptItems.isEmpty 
                  ? 0.0 
                  : _receiptItems.fold<double>(0.0, (sum, item) => sum + item.totalPrice));
              
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Items Total",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff1C1C1E),
                    ),
                  ),
                  Text(
                    '$currencySymbol${calculatedTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
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
    final currencySymbol = _getCurrencySymbol();
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Receipt Details",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xff1C1C1E),
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
            _receiptDetailRow("Service Charge", '$currencySymbol${_serviceCharge!.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
          ],
          if (_tip != null && _tip! > 0) ...[
            _receiptDetailRow("Tip", '$currencySymbol${_tip!.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
          ],
          _receiptDetailRow(
            "Invoice #",
            (_invoiceNumber != null && _invoiceNumber!.isNotEmpty) ? _invoiceNumber! : 'Not Available',
          ),
        ],
      ),
    );
  }

  // Receipt detail row helper
  Widget _receiptDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xff1C1C1E),
          ),
        ),
      ],
    );
  }

  // Split receipts section
  Widget _splitReceiptsSection() {
    final currencySymbol = _getCurrencySymbol();
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, size: 18, color: AppColors.primaryColor),
              const SizedBox(width: 8),
              const Text(
                "Split Receipts",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff1C1C1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._splitReceipts!.asMap().entries.map((entry) {
            final index = entry.key;
            final splitReceipt = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: index < _splitReceipts!.length - 1 ? 16 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    splitReceipt.merchantName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...splitReceipt.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.quantity > 1.0 
                                ? '${item.quantity.toStringAsFixed(0)}x ${item.name}'
                                : item.name,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        Text(
                          '$currencySymbol${item.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )),
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        splitReceipt.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '$currencySymbol${splitReceipt.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColor,
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
      final splitNotes = '${_notesController.text} • ${split.merchantName}'.trim();
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
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              // Draft action - simply pop for now or save as draft
              Navigator.pop(context);
            },
            child: const Text(
              "Cancel",
              style: TextStyle(
                color: Color(0xFF1C1C1E),
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
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      SnackBarUtils.showSuccess(context, "Split expenses added! 🎉");
                    }
                  } else {
                final String merchant = _merchantController.text;
                final double amount = double.tryParse(_amountController.text) ?? 0.0;
                final String category = _categoryController.text.trim();
                final String notes = _notesController.text;

                    // Ensure emoji is always set - use category-based fallback if needed
                    final emoji = _selectedCategoryEmoji?.trim().isNotEmpty == true 
                        ? _selectedCategoryEmoji! 
                        : _emojiForCategory(category);
                    
                    await expenseProvider.addExpense(
                  merchant: merchant,
                  amount: amount,
                  date: _selectedDate,
                  category: category,
                      notes: notes.isNotEmpty ? notes : null,
                      emoji: emoji,
                      currency: _selectedCurrency, // Pass selected currency
                      items: _receiptItems.map((item) => item.toJson()).toList(),
                      subtotal: _subtotal,
                      tax: _taxAmount,
                      tip: _tip,
                      discount: _discount,
                      invoiceNumber: _invoiceNumber,
                    );

                    // Navigate to Dashboard with Expenses tab selected
                    if (mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                SnackBarUtils.showSuccess(context, "Expense added! 🎉");
                    }
                  }
                } catch (e) {
                  // Show error message to user
                  if (mounted) {
                    SnackBarUtils.showError(
                      context, 
                      "Failed to save expense: ${e.toString()}\nPlease check your internet connection."
                    );
                  }
                }
              }
            },
            child: const Text(
              "Add",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _circleBackButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              blurRadius: 6,
              offset: const Offset(0, 3),
              color: Colors.black.withOpacity(0.1),
            )
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }
  // (A map to store the icon for each payment type)
  final Map<String, IconData> _paymentIcons = {
    'Cash': Icons.money_rounded,
    'Card': Icons.credit_card_rounded,
    'Online': Icons.public_rounded,
    // Add other labels and their icons here
  };

  // --- BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F8F8),
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: _circleBackButton(),
        title: const Text(
          "Add transaction",
          style: TextStyle(
            color: Color(0xff1C1C1E),
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
              _sectionCard(
                child: _amountField(),
              ),
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
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Select a date' : null,
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
              const Text(
                "Payment Type",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xff1C1C1E),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _paymentChip("Cash"),
              const SizedBox(height: 10),
              _paymentChip("Credit/Debit Card"),
              const SizedBox(height: 10),
              _paymentChip("Check"),
              const SizedBox(height: 30),
              _saveButton(context),
            ],
          ),
        ),
      ),
    );
  }
}
