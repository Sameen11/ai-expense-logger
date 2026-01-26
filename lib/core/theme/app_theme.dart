import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primaryBrand,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryBrand,
        secondary: AppColors.lightAccent,
        surface: AppColors.lightSurface,
        background: AppColors.lightBackground,
        error: AppColors.lightError,
        onPrimary: Colors.white,
        onSecondary: AppColors.lightTextPrimary,
        onSurface: AppColors.lightTextPrimary,
        onBackground: AppColors.lightTextPrimary,
        onError: Colors.white,
      ),
      // Use Lexend as dynamic base, but we will override headings with Syne manually in widgets or here if possible
      textTheme: GoogleFonts.lexendTextTheme(ThemeData.light().textTheme)
          .apply(
            bodyColor: AppColors.lightTextPrimary,
            displayColor: AppColors.lightTextPrimary,
          )
          .copyWith(
            displayLarge: GoogleFonts.syne(
              color: AppColors.lightTextPrimary,
              fontWeight: FontWeight.bold,
            ),
            displayMedium: GoogleFonts.syne(
              color: AppColors.lightTextPrimary,
              fontWeight: FontWeight.bold,
            ),
            displaySmall: GoogleFonts.syne(
              color: AppColors.lightTextPrimary,
              fontWeight: FontWeight.bold,
            ),
            headlineLarge: GoogleFonts.syne(
              color: AppColors.lightTextPrimary,
              fontWeight: FontWeight.bold,
            ),
            headlineMedium: GoogleFonts.syne(
              color: AppColors.lightTextPrimary,
              fontWeight: FontWeight.bold,
            ),
            headlineSmall: GoogleFonts.syne(
              color: AppColors.lightTextPrimary,
              fontWeight: FontWeight.bold,
            ),
            titleLarge: GoogleFonts.syne(
              color: AppColors.lightTextPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryBrand, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      useMaterial3: true,
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryBrand,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryBrand,
        secondary: AppColors.darkAccent,
        surface: AppColors.darkSurface,
        background: AppColors.darkBackground,
        error: AppColors.darkError,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.darkTextPrimary,
        onBackground: AppColors.darkTextPrimary,
        onError: Colors.white,
        surfaceContainerHighest: AppColors.darkSurface, // For some widgets
      ),
      textTheme: GoogleFonts.lexendTextTheme(ThemeData.dark().textTheme)
          .apply(
            bodyColor: AppColors.darkTextPrimary,
            displayColor: AppColors.darkTextPrimary,
          )
          .copyWith(
            displayLarge: GoogleFonts.syne(
              color: AppColors.darkTextPrimary,
              fontWeight: FontWeight.bold,
            ),
            displayMedium: GoogleFonts.syne(
              color: AppColors.darkTextPrimary,
              fontWeight: FontWeight.bold,
            ),
            displaySmall: GoogleFonts.syne(
              color: AppColors.darkTextPrimary,
              fontWeight: FontWeight.bold,
            ),
            headlineLarge: GoogleFonts.syne(
              color: AppColors.darkTextPrimary,
              fontWeight: FontWeight.bold,
            ),
            headlineMedium: GoogleFonts.syne(
              color: AppColors.darkTextPrimary,
              fontWeight: FontWeight.bold,
            ),
            headlineSmall: GoogleFonts.syne(
              color: AppColors.darkTextPrimary,
              fontWeight: FontWeight.bold,
            ),
            titleLarge: GoogleFonts.syne(
              color: AppColors.darkTextPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.darkAccent,
            width: 1,
          ), // Neon Glow effect
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0, // No shadow in dark mode
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white10), // Subtle border
        ),
      ),
      useMaterial3: true,
    );
  }
}
