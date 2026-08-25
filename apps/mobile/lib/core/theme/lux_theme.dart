import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LuxTheme {
  // Ultra-Luxury Color Palette
  static const Color carbonBlack = Color(0xFF06080C);
  static const Color titaniumSlate = Color(0xFF10141D);
  static const Color obsidianCard = Color(0xFF161C26);
  static const Color metallicBorder = Color(0xFF2A3446);

  static const Color hyperOrange = Color(0xFFFF4500);    // Safety & Primary Accent
  static const Color quantumCyan = Color(0xFF00F2FE);    // Navigation & High-Tech Info
  static const Color apexEmerald = Color(0xFF00E676);    // Telematics Health Good
  static const Color warningAmber = Color(0xFFFFB300);   // Caution / Weather Alert
  static const Color alertCrimson = Color(0xFFFF1744);   // Crash / Danger Red
  static const Color cyberPurple = Color(0xFF8A2BE2);    // AI Jarvis Assistant
  static const Color solarGold = Color(0xFFFFD700);      // Premium Livery Accent

  static const Color platinumWhite = Color(0xFFF8FAFC);
  static const Color mutedSilver = Color(0xFF94A3B8);

  // Gradient Presets
  static const LinearGradient hyperOrangeGradient = LinearGradient(
    colors: [Color(0xFFFF4500), Color(0xFFFF7A00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient quantumCyanGradient = LinearGradient(
    colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyberPurpleGradient = LinearGradient(
    colors: [Color(0xFF8A2BE2), Color(0xFFFF0080)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient titaniumGlassGradient = LinearGradient(
    colors: [Color(0x332A3446), Color(0x1110141D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Luxury Glassmorphism Decoration
  static BoxDecoration glassCardDecoration({
    Color? borderColor,
    Color? glowColor,
    double borderRadius = 22,
    bool isElevated = true,
  }) {
    return BoxDecoration(
      color: obsidianCard.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? metallicBorder,
        width: 1.2,
      ),
      boxShadow: [
        if (glowColor != null)
          BoxShadow(
            color: glowColor.withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
        if (isElevated)
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
      ],
    );
  }

  static ThemeData get luxuryTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: carbonBlack,
      primaryColor: hyperOrange,
      colorScheme: const ColorScheme.dark(
        primary: hyperOrange,
        secondary: quantumCyan,
        surface: titaniumSlate,
        error: alertCrimson,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: const TextStyle(color: platinumWhite, fontWeight: FontWeight.bold, fontSize: 34, letterSpacing: -0.5),
        headlineMedium: const TextStyle(color: platinumWhite, fontWeight: FontWeight.w700, fontSize: 24, letterSpacing: -0.2),
        titleLarge: const TextStyle(color: platinumWhite, fontWeight: FontWeight.w600, fontSize: 18),
        bodyLarge: const TextStyle(color: platinumWhite, fontSize: 16),
        bodyMedium: const TextStyle(color: mutedSilver, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: obsidianCard,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: metallicBorder, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: hyperOrange,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 56),
          elevation: 6,
          shadowColor: hyperOrange.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: titaniumSlate,
        hintStyle: const TextStyle(color: mutedSilver),
        prefixIconColor: hyperOrange,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: metallicBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: hyperOrange, width: 2),
        ),
      ),
    );
  }
}
