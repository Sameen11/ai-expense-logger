import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primaryBrand = Color(
    0xFF7B61FF,
  ); // Electric Violet (Common Brand)
  static const Color secondaryBrand = Color(0xFF00E676); // Success Green

  // Light Mode Palette (Soft/Friendly)
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF2D3436);
  static const Color lightTextSecondary = Color(0xFF636E72);
  static const Color lightAccent = Color(
    0xFFFFD54F,
  ); // Golden Yellow (Friendly)
  static const Color lightError = Color(0xFFFF5252);

  // Dark Mode Palette (Tech/AI)
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0BEC5);
  static const Color darkAccent = Color(0xFF7B61FF); // Neon Violet (Tech)
  static const Color darkError = Color(0xFFFF5252);

  // Gradients
  static const LinearGradient lightGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF2C2C54), Color(0xFF121212)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
