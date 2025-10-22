import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../expenses/model.dart';

class AddExpenseManuallyScreen extends StatefulWidget {
  const AddExpenseManuallyScreen({super.key, this.expense});

  // Allow passing an expense to edit it
  final Expense? expense;

  @override
  State<AddExpenseManuallyScreen> createState() => _AddExpenseManuallyScreenState();
}

class _AddExpenseManuallyScreenState extends State<AddExpenseManuallyScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Meals & Dining'; // Default category
  String _selectedPayment = 'Credit Card'; // Default payment

  // Mock data for dropdowns
  final List<String> _categories = [
    'Meals & Dining',
    'Travel',
    'Software',
    'Entertainment',
    'Shopping',
    'Other'
  ];
  final List<String> _paymentMethods = ['Credit Card', 'Debit Card', 'Cash', 'Bank Transfer'];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with expense data if we are editing
    _merchantController = TextEditingController(text: widget.expense?.merchant);
    _amountController = TextEditingController(text: widget.expense?.amount.toString());
    _notesController = TextEditingController(text: widget.expense?.notes);
    _selectedDate = widget.expense?.date ?? DateTime.now();
    _selectedCategory = widget.expense?.category ?? _categories.first;
    // Payment method isn't in our model, so we'll just use a default
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Function to show the date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Function to handle form submission
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Form is valid, create or update the expense
      final newExpense = Expense(
        id: widget.expense?.id ?? UniqueKey().toString(), // Use existing ID or new one
        merchant: _merchantController.text,
        amount: double.tryParse(_amountController.text) ?? 0.0,
        date: _selectedDate,
        category: _selectedCategory,
        icon: _getIconForCategory(_selectedCategory),
        notes: _notesController.text,
      );

      // Here you would save the expense to your database (Firebase, etc.)

      // For now, just pop the screen
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              widget.expense == null ? 'Expense added!' : 'Expense updated!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Helper to get an icon based on category
  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Meals & Dining': return Icons.coffee;
      case 'Travel': return Icons.directions_car;
      case 'Software': return Icons.laptop_chromebook;
      case 'Entertainment': return Icons.movie;
      case 'Shopping': return Icons.shopping_bag;
      default: return Icons.receipt_long;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.grey[800]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.expense == null ? 'Add Expense' : 'Edit Expense',
          style: TextStyle(color: Colors.grey[900], fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _submitForm,
            child: Text(
              'Save',
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Using the same "Settings Group" style for consistency
            _buildFormCard(
              children: [
                TextFormField(
                  controller: _merchantController,
                  decoration: const InputDecoration(
                    labelText: 'Merchant',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.storefront),
                  ),
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter a merchant' : null,
                ),
                _buildDivider(),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter an amount';
                    if (double.tryParse(value) == null) return 'Please enter a valid number';
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildFormCard(
              children: [
                _buildDropdownField(
                  label: 'Category',
                  icon: Icons.category,
                  value: _selectedCategory,
                  items: _categories,
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                ),
                _buildDivider(),
                _buildDateField(context),
                _buildDivider(),
                _buildDropdownField(
                  label: 'Payment',
                  icon: Icons.credit_card,
                  value: _selectedPayment,
                  items: _paymentMethods,
                  onChanged: (newValue) {
                    setState(() {
                      _selectedPayment = newValue!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildFormCard(
              children: [
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.note_alt),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Reusable card for form sections
  Widget _buildFormCard({required List<Widget> children}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: Column(children: children),
    );
  }

  // Reusable divider
  Widget _buildDivider() => Divider(height: 1, color: Colors.grey[200], indent: 56);

  // Reusable widget for dropdowns
  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 15),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: value,
                icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item, style: const TextStyle(fontSize: 16)),
                  );
                }).toList(),
                onChanged: onChanged,
                hint: Text(label),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Reusable widget for the date field
  Widget _buildDateField(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectDate(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.grey[600]),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  DateFormat('MMM dd, yyyy').format(_selectedDate),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }
}

