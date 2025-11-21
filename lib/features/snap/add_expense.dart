import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../common/colors.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/notification_bar.dart';

class AddExpenseManuallyScreen extends StatefulWidget {
  // Extended data: (merchant, amount, category, date?, paymentMethod?, confidence?)
  final (String, double, String, String?, String?, double?)? extractedData;

  const AddExpenseManuallyScreen({super.key, this.extractedData});

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

  DateTime _selectedDate = DateTime.now();
  String _paymentType = "Cash";

  // Store selected emoji/icon for category
  String? _selectedCategoryEmoji;

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

  @override
  void initState() {
    super.initState();

    // Pre-fill fields if data was passed
    if (widget.extractedData != null) {
      final (merchant, amount, category, date, paymentMethod, confidence) = widget.extractedData!;
      _merchantController.text = merchant;
      _amountController.text = amount.toStringAsFixed(2);
      _categoryController.text = category;
      
      // Set payment method if provided
      if (paymentMethod != null) {
        _paymentType = paymentMethod;
      }
      
      // Set date if provided
      if (date != null) {
        try {
          _selectedDate = DateTime.parse(date);
        } catch (e) {
          // Keep default date if parsing fails
        }
      }
      
      // try to find emoji for that category
      final match = _categories.firstWhere(
            (c) => c["label"]!.toLowerCase() == category.toLowerCase(),
        orElse: () => {},
      );
      if (match.isNotEmpty) _selectedCategoryEmoji = match["emoji"];
      
      // Show confidence if available
      if (confidence != null && confidence < 0.8) {
        // Show warning for low confidence
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SnackBarUtils.showWarning(
            context, 
            'AI confidence: ${(confidence * 100).toStringAsFixed(0)}% - Please verify the extracted data'
          );
        });
      }
    }

    _dateController.text = DateFormat('MMM dd, yyyy').format(_selectedDate);
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _categoryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('MMM dd, yyyy').format(_selectedDate);
      });
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
  // Special amount field design: $ on left + big centered amount
  Widget _amountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Amount",
          style: TextStyle(
            color: Color(0xff6B6B6B),
            fontSize: 14,
          ),
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

            // 2. Replaces the Row's "$" Text widget.
            // We use prefixIcon because your original Row had "CrossAxisAlignment.center"
            prefixIcon: Padding(
              // This padding replaces your Container's horizontal: 18
              // and the SizedBox(width: 12)
              padding: const EdgeInsets.only(left: 18, right: 12),
              child: Text(
                "\$",
                style: const TextStyle( // This is the style for the "$"
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C1C1E),
                ),
              ),
            ),
            // This ensures the prefixIcon is centered and doesn't add extra space
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),

            // 3. Replaces the Container's height/padding
            // Tweak the vertical padding to match your 85px height
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18, // Adjust this to get the exact height
              horizontal: 18, // This pads the *right* side
            ),

            // 4. Sets the border for both focused and unfocused states
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18), // Your radius
              borderSide: BorderSide.none, // No outline
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18), // Your radius
              borderSide: BorderSide.none, // No outline
            ),

            hintText: "0.00",
            hintStyle: const TextStyle( // It's good practice to style the hint too
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFFC7C7CC), // A lighter grey for the hint
            ),
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
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final expenseProvider = context.read<ExpenseProvider>();

                final String merchant = _merchantController.text;
                final double amount = double.tryParse(_amountController.text) ?? 0.0;
                final String category = _categoryController.text.trim();
                final String notes = _notesController.text;

                expenseProvider.addExpense(
                  merchant: merchant,
                  amount: amount,
                  date: _selectedDate,
                  category: category,
                  notes: notes.isNotEmpty ? notes : null, emoji: _selectedCategoryEmoji ?? "📦",
                );

                SnackBarUtils.showSuccess(context, "Expense added! 🎉");

                Navigator.pop(context);
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
                    ),
                    const SizedBox(height: 16),
                    _styledInputField(
                      label: "Date",
                      controller: _dateController,
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Select a date' : null,
                    ),
                    const SizedBox(height: 16),
                    _categoryField(),
                    const SizedBox(height: 16),
                    _styledInputField(
                      label: "Notes (Optional)",
                      controller: _notesController,
                      validator: null,
                    ),
                  ],
                ),
              ),
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
