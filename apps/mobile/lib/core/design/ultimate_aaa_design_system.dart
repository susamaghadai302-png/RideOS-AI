import 'package:flutter/material.dart';

enum AuroraThemeMode {
  day,
  night,
  sunset,
  neon,
  carbon,
  ocean,
  forest,
}

class DesignTokens {
  static const Color neonOrange = Color(0xFFFF6D00);
  static const Color cyanPulse = Color(0xFF00E5FF);
  static const Color carbonBackground = Color(0xFF0A0E14);
  static const Color darkGlassSurface = Color(0x33121824);

  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;

  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationCinematic = Duration(milliseconds: 600);
}

class UltimateAaaDesignSystem {
  static final UltimateAaaDesignSystem instance = UltimateAaaDesignSystem._internal();
  UltimateAaaDesignSystem._internal();

  ThemeData getAuroraTheme(AuroraThemeMode mode) {
    switch (mode) {
      case AuroraThemeMode.neon:
        return ThemeData.dark().copyWith(
          scaffoldBackgroundColor: DesignTokens.carbonBackground,
          colorScheme: const ColorScheme.dark(
            primary: DesignTokens.neonOrange,
            secondary: DesignTokens.cyanPulse,
            surface: DesignTokens.darkGlassSurface,
          ),
        );
      case AuroraThemeMode.carbon:
      default:
        return ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
          colorScheme: const ColorScheme.dark(
            primary: DesignTokens.neonOrange,
            secondary: Colors.white,
          ),
        );
    }
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final Color glowColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 12.0,
    this.glowColor = DesignTokens.cyanPulse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.darkGlassSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glowColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.15),
            blurRadius: blur,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }
}
