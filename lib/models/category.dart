import 'package:flutter/material.dart';

class Category {
  final String name;
  final int codePoint;
  final String fontFamily;
  final String color; // Color as hex string (e.g., "0xFFFF6B6B")

  Category({
    required this.name,
    required this.codePoint,
    required this.fontFamily,
    required this.color,
  });

  // Helper to create the IconData object on the fly
  IconData get iconData {
    return IconData(codePoint, fontFamily: fontFamily);
  }

  // Helper to get Color object from hex string
  Color get colorValue {
    return Color(int.parse(color));
  }

  factory Category.fromFirestore(Map<String, dynamic> data) {
    return Category(
      name: data['name'] as String,
      codePoint: data['icon_codepoint'] as int,
      fontFamily: data['icon_font_family'] as String,
      color: data['color'] as String? ?? '0xFF6C757D', // Default gray
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'icon_codepoint': codePoint,
      'icon_font_family': fontFamily,
      'color': color,
    };
  }
}
