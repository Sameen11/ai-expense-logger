import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/category.dart';

class CategoryProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Map<String, Category> _categoryMap = {};
  bool _isLoading = false;

  Map<String, Category> get categoryMap => _categoryMap;

  CategoryProvider() {
    _fetchCategories();
  }

  final Category _defaultCategory = Category(
    name: "Default",
    codePoint: 58498, // This is Icons.receipt_long
    fontFamily: "MaterialIcons",
    color: "0xFF6C757D", // Gray
  );

  Category getCategory(String name) {
    return _categoryMap[name] ?? _defaultCategory;
  }

  Future<void> _fetchCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _db.collection('categories').get();

      // This is the key: convert the list into a Map
      final categories = snapshot.docs.map((doc) {
        return Category.fromFirestore(doc.data());
      }).toList();

      _categoryMap = {for (var cat in categories) cat.name: cat};
    } catch (e) {
      // Handle error
      print(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  //
  // --- THIS IS THE NEW METHOD ---
  //
  Future<void> addCategory(String name, IconData icon, String color) async {
    // Basic check to prevent duplicates (you can make this more robust)
    if (_categoryMap.containsKey(name)) {
      throw Exception("Category '$name' already exists.");
    }

    // Create the new category object
    final newCategory = Category(
      name: name,
      codePoint: icon.codePoint,
      fontFamily: icon.fontFamily!,
      color: color, // Color from parameter
    );

    // Create the data map for Firestore
    final data = {
      'name': name,
      'icon_codepoint': icon.codePoint,
      'icon_font_family': icon.fontFamily,
      'color': color,
    };

    try {
      // Add to Firestore
      await _db.collection('categories').add(data);

      // --- IMPORTANT ---
      // Add to our local map so the UI updates instantly
      _categoryMap[name] = newCategory;
      notifyListeners();
    } catch (e) {
      print("Error adding category: $e");
      // Re-throw to show error in the UI
      rethrow;
    }
  }

  // Default categories list (Promoted to class level for validation)
  final List<Map<String, dynamic>> _defaultCategoriesList = [
    {
      "name": "Food & Drinks",
      "emoji": "🍜",
      "icon": 57934,
      "color": "0xFFFF6B6B",
    },
    {"name": "Groceries", "emoji": "🥬", "icon": 58728, "color": "0xFF4ECDC4"},
    {"name": "Transport", "emoji": "🚖", "icon": 58673, "color": "0xFF45B7D1"},
    {"name": "Shopping", "emoji": "🛍️", "icon": 58700, "color": "0xFFFFBE0B"},
    {
      "name": "Subscriptions",
      "emoji": "💳",
      "icon": 57743,
      "color": "0xFF9B5DE5",
    },
    {
      "name": "Bills & Utilities",
      "emoji": "⚡",
      "icon": 58245,
      "color": "0xFFFB5607",
    },
    {"name": "Salary", "emoji": "💰", "icon": 57529, "color": "0xFF3A86FF"},
    {"name": "Business", "emoji": "🤝", "icon": 60237, "color": "0xFF8338EC"},
    {
      "name": "Investments",
      "emoji": "📈",
      "icon": 59511,
      "color": "0xFF00BBF9",
    },
    {"name": "Health", "emoji": "🩺", "icon": 59961, "color": "0xFFFF006E"},
    {
      "name": "Entertainment",
      "emoji": "🍿",
      "icon": 57926,
      "color": "0xFFF15BB5",
    },
    {"name": "Travel", "emoji": "🌏", "icon": 58745, "color": "0xFF00F5D4"},
    {"name": "Other", "emoji": "🧩", "icon": 59563, "color": "0xFF9E9E9E"},
  ];

  Future<void> editCategory(
    String oldName,
    String newName,
    IconData icon,
    String color,
  ) async {
    // 1. Validation for default categories
    if (_defaultCategoriesList.any((c) => c['name'] == oldName)) {
      throw Exception("Cannot edit default categories.");
    }

    try {
      // 2. Find document
      final snapshot = await _db
          .collection('categories')
          .where('name', isEqualTo: oldName)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.update({
          'name': newName,
          'icon_codepoint': icon.codePoint,
          'icon_font_family': icon.fontFamily,
          'color': color,
        });
      }

      // 3. Update local map
      _categoryMap.remove(oldName);
      _categoryMap[newName] = Category(
        name: newName,
        codePoint: icon.codePoint,
        fontFamily: icon.fontFamily!,
        color: color,
      );
      notifyListeners();
    } catch (e) {
      print("Error editing category: $e");
      rethrow;
    }
  }

  Future<void> deleteCategory(String name) async {
    // 1. Validation: Prevent deleting default categories
    if (_defaultCategoriesList.any((c) => c['name'] == name)) {
      throw Exception("Cannot delete default categories.");
    }

    try {
      // 2. Find the document in Firestore
      final snapshot = await _db
          .collection('categories')
          .where('name', isEqualTo: name)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      // 3. Update local state
      _categoryMap.remove(name);
      notifyListeners();
    } catch (e) {
      print("Error deleting category: $e");
      rethrow;
    }
  }

  // Seed default categories if none exist
  Future<void> seedDefaultCategories() async {
    try {
      final snapshot = await _db.collection('categories').get();
      if (snapshot.docs.isNotEmpty) {
        print('Categories already exist, skipping seed');
        return;
      }

      final batch = _db.batch();

      for (var cat in _defaultCategoriesList) {
        // Create a new document reference
        final docRef = _db.collection('categories').doc();

        batch.set(docRef, {
          'name': cat['name'],
          'icon_codepoint': cat['icon'],
          'icon_font_family': 'MaterialIcons',
          'color': cat['color'],
        });
      }

      await batch.commit();
      print('Default categories seeded successfully');

      // Refresh local state
      await _fetchCategories();
    } catch (e) {
      print("Error seeding categories: $e");
    }
  }

  List<Category> getAllCategories() {
    return _categoryMap.values.toList();
  }

  String getEmojiForCategory(String categoryName) {
    final match = _defaultCategoriesList.firstWhere(
      (c) => c["name"].toString().toLowerCase() == categoryName.toLowerCase(),
      orElse: () => {"emoji": "📦"},
    );
    return match["emoji"] as String;
  }
}
