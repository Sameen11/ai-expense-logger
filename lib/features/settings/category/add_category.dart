import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/category_provider.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  IconData? _selectedIcon;
  bool _isLoading = false;

  // --- This is our curated list of icons for the user to pick ---
  final List<IconData> _iconList = [
    Icons.restaurant, Icons.local_cafe, Icons.local_bar, Icons.local_pizza,
    Icons.shopping_bag, Icons.local_grocery_store, Icons.store, Icons.shopping_cart,
    Icons.directions_car, Icons.train, Icons.flight, Icons.local_taxi, Icons.local_gas_station,
    Icons.movie, Icons.music_note, Icons.sports_esports, Icons.book,
    Icons.house, Icons.lightbulb, Icons.phone_android, Icons.laptop_mac,
    Icons.receipt_long, Icons.credit_card, Icons.attach_money, Icons.savings,
    Icons.pets, Icons.grass, Icons.fitness_center, Icons.school, Icons.health_and_safety,
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
        // Show an error if no icon is selected
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an icon.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() { _isLoading = true; });

      try {
        final provider = context.read<CategoryProvider>();
        await provider.addCategory(
          _nameController.text.trim().toLowerCase(),
          _selectedIcon!,
        );

        // If successful, close the screen
        Navigator.pop(context);

      } catch (e) {
        // Show any errors (like "category already exists")
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Category'),
        actions: [
          // The Save button
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator()),
            )
          else
            TextButton(
              onPressed: _saveCategory,
              child: const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            )
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. CATEGORY NAME ---
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g., Groceries',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                validator: (value) =>
                (value == null || value.isEmpty) ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 32.0),

              // --- 2. ICON PICKER ---
              Text(
                'Select Icon',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 16.0),
              InkWell(
                onTap: _showIconPicker,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Center(
                    child: _selectedIcon == null
                        ? Icon(Icons.add_a_photo_outlined, color: Colors.grey[600], size: 32)
                        : Icon(_selectedIcon, color: Colors.blue[700], size: 40),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}