import 'package:flutter/material.dart';

class AppIcons {

  // --- NEW HELPER ---
  // This maps your category string to a specific icon
  static IconData getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'meals & dining':
        return Icons.restaurant;
      case 'coffee':
        return Icons.coffee;
      case 'travel':
        return Icons.directions_car;
      case 'software':
        return Icons.laptop_chromebook;
      case 'entertainment':
        return Icons.movie;
      case 'shopping':
        return Icons.shopping_bag;
      case 'groceries':
        return Icons.local_grocery_store;
      case 'transport':
        return Icons.train;
      default:
        return Icons.receipt_long; // A good default
    }
  }
}