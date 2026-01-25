

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

      _categoryMap = { for (var cat in categories) cat.name : cat };

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
  Future<void> addCategory(String name, IconData icon) async {
    // Basic check to prevent duplicates (you can make this more robust)
    if (_categoryMap.containsKey(name)) {
      throw Exception("Category '$name' already exists.");
    }

    // Create the new category object
    final newCategory = Category(
      name: name,
      codePoint: icon.codePoint,
      fontFamily: icon.fontFamily!,
    );

    // Create the data map for Firestore
    final data = {
      'name': name,
      'icon_codepoint': icon.codePoint,
      'icon_font_family': icon.fontFamily,
      // You could add 'default_color' here too
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
}