import 'package:flutter/material.dart';
import 'roados_components.dart';

class ApexSpacing {
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class EnterpriseDesignSystem {
  static ThemeData get enterpriseDarkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      fontFamily: 'Inter',
      colorScheme: const ColorScheme.dark(
        primary: RoadOSColors.hyperOrange,
        secondary: RoadOSColors.cyberCyan,
        surface: Color(0xFF0F172A),
        error: RoadOSColors.errorCrimson,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}
