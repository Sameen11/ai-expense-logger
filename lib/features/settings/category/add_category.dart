import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/expense_provider.dart';
import '../../../models/category.dart';

class AddCategoryScreen extends StatefulWidget {
  final Category? categoryToEdit;
  const AddCategoryScreen({super.key, this.categoryToEdit});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  IconData? _selectedIcon;
  Color _selectedColor = const Color(0xFF6C757D); // Default gray
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.categoryToEdit != null) {
      _nameController.text = widget.categoryToEdit!.name;
      _selectedIcon = widget.categoryToEdit!.iconData;
      _selectedColor = widget.categoryToEdit!.colorValue;
    }
  }

  // Curated list of icons for the user to pick
  final List<IconData> _iconList = [
    Icons.restaurant,
    Icons.local_cafe,
    Icons.local_bar,
    Icons.local_pizza,
    Icons.shopping_bag,
    Icons.local_grocery_store,
    Icons.store,
    Icons.shopping_cart,
    Icons.directions_car,
    Icons.train,
    Icons.flight,
    Icons.local_taxi,
    Icons.local_gas_station,
    Icons.movie,
    Icons.music_note,
    Icons.sports_esports,
    Icons.book,
    Icons.house,
    Icons.lightbulb,
    Icons.phone_android,
    Icons.laptop_mac,
    Icons.receipt_long,
    Icons.credit_card,
    Icons.attach_money,
    Icons.savings,
    Icons.pets,
    Icons.grass,
    Icons.fitness_center,
    Icons.school,
    Icons.health_and_safety,
    Icons.business_center,
    Icons.trending_up,
    Icons.local_hospital,
    Icons.category,
  ];

  // Predefined color palette
  final List<Color> _colorPalette = [
    const Color(0xFFFF6B6B),
    const Color(0xFF4ECDC4),
    const Color(0xFF95E1D3),
    const Color(0xFFFFBE0B),
    const Color(0xFF8338EC),
    const Color(0xFFFF006E),
    const Color(0xFF06FFA5),
    const Color(0xFF3A86FF),
    const Color(0xFF06D6A0),
    const Color(0xFFEF476F),
    const Color(0xFFFB5607),
    const Color(0xFF118AB2),
    const Color(0xFF6C757D),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _showIconPicker() async {
    final IconData? pickedIcon = await showModalBottomSheet(
      context: context,
      builder: (context) {
        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
          ),
          itemCount: _iconList.length,
          itemBuilder: (context, index) {
            final icon = _iconList[index];
            return InkWell(
              onTap: () => Navigator.pop(context, icon),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(icon, size: 30.0, color: Colors.grey[700]),
              ),
            );
          },
        );
      },
    );

    if (pickedIcon != null) {
      setState(() {
        _selectedIcon = pickedIcon;
      });
    }
  }

  Future<void> _saveCategory() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedIcon == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an icon.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final categoryProvider = context.read<CategoryProvider>();
        final expenseProvider = context.read<ExpenseProvider>();

        final newName = _nameController.text.trim();
        final colorHex =
            '0x${_selectedColor.value.toRadixString(16).padLeft(8, '0')}';

        if (widget.categoryToEdit != null) {
          // EDIT MODE
          final oldName = widget.categoryToEdit!.name;

          await categoryProvider.editCategory(
            oldName,
            newName,
            _selectedIcon!,
            colorHex,
          );

          // If name changed, update batch expenses
          if (oldName != newName) {
            await expenseProvider.updateCategoryForExpenses(oldName, newName);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Category updated successfully!')),
            );
          }
        } else {
          // ADD MODE
          await categoryProvider.addCategory(newName, _selectedIcon!, colorHex);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Category created successfully!')),
            );
          }
        }

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.categoryToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Category' : 'Add New Category'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveCategory,
              child: Text(
                isEditing ? 'Update' : 'Save',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // Category Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g., Groceries',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Please enter a name'
                  : null,
            ),
            const SizedBox(height: 32.0),

            // Icon Picker
            Text(
              'Select Icon',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            InkWell(
              onTap: _showIconPicker,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Center(
                  child: _selectedIcon == null
                      ? Icon(
                          Icons.add_a_photo_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 32,
                        )
                      : Icon(_selectedIcon, color: _selectedColor, size: 40),
                ),
              ),
            ),
            const SizedBox(height: 32.0),

            // Color Picker
            Text(
              'Select Color',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colorPalette.map((color) {
                final isSelected = _selectedColor == color;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
