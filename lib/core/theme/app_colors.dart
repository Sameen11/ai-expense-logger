import 'package:flutter/material.dart';

class AppColors {
  // Common
  static const Color white = Colors.white;
  static const Color scaffoldBackground = Color(
    0xFF0A0320,
  ); // Deep Navy matching darkBackground

  // Brand Colors
  static const Color primaryBrand = Color(0xFF247CFF); // Electric Blue
  static const Color secondaryBrand = Color(0xFF5856D6); // Deep Purple

  // Light Mode Palette (Kept for compatibility, can be updated later)
  static const Color lightBackground = Color(0xFFF2F2F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF000000);
  static const Color lightTextSecondary = Color(0xFF8E8E93);
  static const Color lightAccent = Color(0xFF247CFF);
  static const Color lightError = Color(0xFFFF3B30);

  // Dark Mode Palette (Premium Dark)
  static const Color darkBackground = Color(0xFF0A0320); // Deep Navy
  static const Color darkSurface = Color(
    0xFF1E1E2C,
  ); // Slightly lighter navy/grey for cards if needed, but we often use glass
  static const Color cardColorDark = Color(0xFF1E1E2C);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF82878F); // Grey from design
  static const Color darkAccent = Color(0xFF247CFF); // Electric Blue
  static const Color darkError = Color(0xFFFF453A);

  // New Gradients & Specials
  static const Color premiumCardGradientStart = Color(0xFF247CFF);
  static const Color premiumCardGradientEnd = Color(0xFF5856D6);
  static const Color glassBorder = Color(0xFFFFFFFF); // with opacity

  // Gradients
  static const LinearGradient lightGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF2F2F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0A0320), Color(0xFF1E1E2C)], // Deep Navy to Lighter
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
