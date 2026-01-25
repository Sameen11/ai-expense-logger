import 'package:flutter/material.dart';

class Category {
  final String name;
  final int codePoint;
  final String fontFamily;
  // final String color; // You can add this later

  Category({
    required this.name,
    required this.codePoint,
    required this.fontFamily,
  });

  // Helper to create the IconData object on the fly
  IconData get iconData {
    return IconData(
      codePoint,
      fontFamily: fontFamily,
    );
  }

  factory Category.fromFirestore(Map<String, dynamic> data) {
    return Category(
      name: data['name'] as String,
      codePoint: data['icon_codepoint'] as int,
      fontFamily: data['icon_font_family'] as String,
    );
  }
}