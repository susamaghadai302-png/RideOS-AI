import 'package:flutter/material.dart';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'design_tokens.dart';
import 'roados_tokens.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LUX THEME ENGINE — Singleton ChangeNotifier with SharedPreferences persistence
//  Provides true OLED Dark, Premium Light, and System-follow modes.
// ─────────────────────────────────────────────────────────────────────────────

class LuxThemeEngine extends ChangeNotifier {
  static final LuxThemeEngine _instance = LuxThemeEngine._internal();
  factory LuxThemeEngine() => _instance;
  LuxThemeEngine._internal();

  static const String _prefKey = 'rideOS_theme_mode';

  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _effectiveBrightness == Brightness.dark;

  /// Initialize from SharedPreferences (call once in main()).
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved == 'light') {
        _themeMode = ThemeMode.light;
      } else if (saved == 'system') {
        _themeMode = ThemeMode.system;
      } else {
        _themeMode = ThemeMode.dark;
      }
    } catch (_) {
      _themeMode = ThemeMode.dark;
    }
  }

  Brightness get _effectiveBrightness {
    if (_themeMode == ThemeMode.system) {
      return SchedulerBinding.instance.platformDispatcher.platformBrightness;
    }
    return _themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light;
  }

  void toggleTheme() => setThemeMode(
    _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
  );

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    _updateSystemUI(mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, mode == ThemeMode.light ? 'light' : mode == ThemeMode.system ? 'system' : 'dark');
    } catch (_) {}
  }

  void _updateSystemUI(ThemeMode mode) {
    final isDark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);
    SystemChrome.setSystemUIOverlayStyle(
      isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.black,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: const Color(0xFFF1F5F9),
            ),
    );
  }

  // ── DARK THEME: True OLED Blacks + Neon Accent Glows ─────────────────────

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF000000), // true OLED black
      primaryColor: RoadOSColors.hyperOrange,
      colorScheme: const ColorScheme.dark(
        primary: RoadOSColors.hyperOrange,
        onPrimary: Colors.white,
        secondary: RoadOSColors.cyberCyan,
        onSecondary: Colors.black,
        surface: Color(0xFF0A0D1A),      // near-black surface
        onSurface: RoadOSColors.platinumWhite,
        surfaceContainerHighest: Color(0xFF0D1226),
        error: RoadOSColors.errorCrimson,
        onError: Colors.white,
        outline: Color(0xFF2B3654),
        outlineVariant: Color(0xFF1A2240),
        shadow: Colors.black,
        scrim: Colors.black87,
      ),
      textTheme: _darkTextTheme,
      cardTheme: CardThemeData(
        color: const Color(0xFF0D1226),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuxRadius.lg),
          side: const BorderSide(color: Color(0xFF2B3654), width: 1.1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RoadOSColors.hyperOrange,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 54),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LuxRadius.md)),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0D1226),
        hintStyle: TextStyle(color: RoadOSColors.textMuted.withValues(alpha: 0.6)),
        prefixIconColor: RoadOSColors.hyperOrange,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2B3654), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2B3654), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: RoadOSColors.hyperOrange, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: RoadOSColors.errorCrimson, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF1A2240), thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF0D1226),
        contentTextStyle: GoogleFonts.inter(color: RoadOSColors.platinumWhite, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF0A0D1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF2B3654), width: 1.1),
        ),
        elevation: 0,
      ),
      iconTheme: const IconThemeData(color: RoadOSColors.platinumWhite),
    );
  }

  // ── LIGHT THEME: Pearl Ivory + Deep Navy + Orange Accents ────────────────

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF4F6FA),
      primaryColor: RoadOSColors.hyperOrange,
      colorScheme: const ColorScheme.light(
        primary: RoadOSColors.hyperOrange,
        onPrimary: Colors.white,
        secondary: Color(0xFF005FCC),       // deep navy blue
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: Color(0xFF0F172A),        // near-black text
        surfaceContainerHighest: Color(0xFFECF0F9),
        error: RoadOSColors.errorCrimson,
        onError: Colors.white,
        outline: Color(0xFFCBD5E1),
        outlineVariant: Color(0xFFE2E8F0),
        shadow: Color(0xFF000000),
        scrim: Color(0x80000000),
      ),
      textTheme: _lightTextTheme,
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shadowColor: const Color(0x14000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuxRadius.lg),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RoadOSColors.hyperOrange,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 54),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LuxRadius.md)),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        prefixIconColor: RoadOSColors.hyperOrange,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: RoadOSColors.hyperOrange, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: RoadOSColors.errorCrimson, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE2E8F0), thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF0F172A),
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
        elevation: 0,
      ),
      iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
    );
  }

  // ── TEXT THEMES ───────────────────────────────────────────────────────────

  static TextTheme get _darkTextTheme => TextTheme(
    displayLarge: LuxTypography.displayHeader(color: RoadOSColors.platinumWhite),
    headlineMedium: LuxTypography.titleLarge(color: RoadOSColors.platinumWhite),
    titleLarge: LuxTypography.titleMedium(color: RoadOSColors.platinumWhite),
    bodyLarge: LuxTypography.bodyLarge(color: RoadOSColors.platinumWhite),
    bodyMedium: LuxTypography.bodyMedium(color: RoadOSColors.textMuted),
    labelSmall: GoogleFonts.robotoMono(color: RoadOSColors.textMuted, fontSize: 10, letterSpacing: 0.8),
  );

  static TextTheme get _lightTextTheme => TextTheme(
    displayLarge: LuxTypography.displayHeader(color: const Color(0xFF0F172A)),
    headlineMedium: LuxTypography.titleLarge(color: const Color(0xFF0F172A)),
    titleLarge: LuxTypography.titleMedium(color: const Color(0xFF0F172A)),
    bodyLarge: LuxTypography.bodyLarge(color: const Color(0xFF0F172A)),
    bodyMedium: LuxTypography.bodyMedium(color: const Color(0xFF64748B)),
    labelSmall: GoogleFonts.robotoMono(color: const Color(0xFF94A3B8), fontSize: 10, letterSpacing: 0.8),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  THEME-AWARE GLASS DECORATION HELPER
//  Call ThemeAwareGlass.cardDecoration(context, accentColor: ...) from any
//  widget to get a BackdropFilter-ready BoxDecoration that adapts to dark/light.
// ─────────────────────────────────────────────────────────────────────────────

class ThemeAwareGlass {
  static BoxDecoration cardDecoration(
    BuildContext context, {
    Color? accentColor,
    double borderRadius = 16,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = accentColor ?? RoadOSColors.hyperOrange;
    if (isDark) {
      return BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x700D1226), Color(0x85060B18)],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07), width: 1.1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 24, offset: const Offset(0, 10), spreadRadius: -4),
          BoxShadow(color: accent.withValues(alpha: 0.06), blurRadius: 20),
        ],
      );
    } else {
      // Light: subtle white glass with a warm orange tint
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withValues(alpha: 0.92), Colors.white.withValues(alpha: 0.78)],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(color: const Color(0xFF000000).withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 8), spreadRadius: -2),
          BoxShadow(color: accent.withValues(alpha: 0.08), blurRadius: 12),
        ],
      );
    }
  }

  /// Sigma for BackdropFilter — lower on light (content is clearer) to save GPU.
  static double blurSigma(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? 20.0 : 12.0;
}
