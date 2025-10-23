import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../processing_receipt/processing_receipt.dart';

// This class now has a Scaffold and AppBar
class AddExpenseManuallyScreen extends StatefulWidget {
  // The extracted data is optional
  final (String, double, String)? extractedData;

  const AddExpenseManuallyScreen({
    super.key,
    this.extractedData,
  });

  @override
  State<AddExpenseManuallyScreen> createState() =>
      _AddExpenseManuallyScreenState();
}

class _AddExpenseManuallyScreenState extends State<AddExpenseManuallyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _merchantController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _categoryController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    // Pre-fill fields if data was passed
    if (widget.extractedData != null) {
      final (merchant, amount, category) = widget.extractedData!;
      _merchantController.text = merchant;
      _amountController.text = amount.toStringAsFixed(2);
      _categoryController.text = category;
    }

    _dateController.text = DateFormat('MMM dd, yyyy').format(_selectedDate);
  }

  @override
  void dispose() {
    // Clean up controllers
    _merchantController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _categoryController.dispose();
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
        _dateController.text = DateFormat('MMM dd, yyyy').format(_selectedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // *** THE FIX IS HERE: We've added a Scaffold ***
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // An AppBar is helpful for a full screen
        title: Text(
          widget.extractedData != null
              ? 'Review Expense'
              : 'Add Expense Manually',
          style: TextStyle(
            color: Colors.grey[900],
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        // Provides a back button
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.grey[800]),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // A "Save" button
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // Handle save logic
                Navigator.pop(context); // Close the screen
              }
            },
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
      // The body is now the root Container from before
      body: Container(
        padding: const EdgeInsets.all(24.0),
        color: Colors.white,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextFormField(
                  controller: _merchantController,
                  label: 'Merchant',
                  icon: Icons.storefront_outlined,
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Enter a merchant' : null,
                ),
                const SizedBox(height: 16),
                _buildTextFormField(
                  controller: _amountController,
                  label: 'Amount',
                  icon: Icons.attach_money,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Enter an amount' : null,
                ),
                const SizedBox(height: 16),
                _buildTextFormField(
                  controller: _dateController,
                  label: 'Date',
                  icon: Icons.calendar_today_outlined,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),
                const SizedBox(height: 16),
                _buildTextFormField(
                  controller: _categoryController,
                  label: 'Category',
                  icon: Icons.category_outlined,
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Select a category' : null,
                ),
                const SizedBox(height: 16),
                _buildTextFormField(
                  controller: _notesController,
                  label: 'Notes (Optional)',
                  icon: Icons.notes_outlined,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget to build styled TextFormFields
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    TextInputType? keyboardType,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      onTap: onTap,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[700]),
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
        ),
      ),
    );
  }
}

