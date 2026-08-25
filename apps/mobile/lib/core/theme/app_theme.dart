import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Color Tokens
  static const Color primaryOrange = Color(0xFFFF5722);  // Safety Orange / Neon Accent
  static const Color primaryAmber = Color(0xFFFF9800);   // Sunlight Accent
  static const Color neonGreen = Color(0xFF00E676);      // Optimal Health / TPMS Good
  static const Color alertRed = Color(0xFFFF5252);       // Crash / Low Fuel Warning
  static const Color infoBlue = Color(0xFF29B6F6);       // Weather / Navigation Info
  static const Color purpleAccent = Color(0xFFAB47BC);   // AI Assistant

  // Dark Theme Surfaces
  static const Color darkBackground = Color(0xFF0D0F12);
  static const Color darkSurface = Color(0xFF161A20);
  static const Color darkCard = Color(0xFF1E232B);
  static const Color darkCardBorder = Color(0xFF2E3542);

  // Light Theme Surfaces
  static const Color lightBackground = Color(0xFFF4F6F9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardBorder = Color(0xFFE2E8F0);

  // Text Colors
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);

  // Glassmorphism Container Helper
  static BoxDecoration glassDecoration({
    required bool isDark,
    Color? accentColor,
    double borderRadius = 20,
  }) {
    return BoxDecoration(
      color: isDark
          ? darkCard.withValues(alpha: 0.85)
          : lightCard.withValues(alpha: 0.90),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: accentColor?.withValues(alpha: 0.4) ??
            (isDark ? darkCardBorder : lightCardBorder),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  // Dark Theme Definition
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: primaryOrange,
      colorScheme: const ColorScheme.dark(
        primary: primaryOrange,
        secondary: neonGreen,
        surface: darkSurface,
        error: alertRed,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: const TextStyle(color: textPrimaryDark, fontWeight: FontWeight.bold, fontSize: 32),
        headlineMedium: const TextStyle(color: textPrimaryDark, fontWeight: FontWeight.w700, fontSize: 24),
        titleLarge: const TextStyle(color: textPrimaryDark, fontWeight: FontWeight.w600, fontSize: 18),
        bodyLarge: const TextStyle(color: textPrimaryDark, fontSize: 16),
        bodyMedium: const TextStyle(color: textSecondaryDark, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkCardBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 54),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        hintStyle: const TextStyle(color: textSecondaryDark),
        prefixIconColor: primaryOrange,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkCardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryOrange, width: 2),
        ),
      ),
    );
  }

  // Light Theme Definition
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      primaryColor: primaryOrange,
      colorScheme: const ColorScheme.light(
        primary: primaryOrange,
        secondary: neonGreen,
        surface: lightSurface,
        error: alertRed,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: const TextStyle(color: textPrimaryLight, fontWeight: FontWeight.bold, fontSize: 32),
        headlineMedium: const TextStyle(color: textPrimaryLight, fontWeight: FontWeight.w700, fontSize: 24),
        titleLarge: const TextStyle(color: textPrimaryLight, fontWeight: FontWeight.w600, fontSize: 18),
        bodyLarge: const TextStyle(color: textPrimaryLight, fontSize: 16),
        bodyMedium: const TextStyle(color: textSecondaryLight, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: lightCardBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 54),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        hintStyle: const TextStyle(color: textSecondaryLight),
        prefixIconColor: primaryOrange,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightCardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryOrange, width: 2),
        ),
      ),
    );
  }
}
