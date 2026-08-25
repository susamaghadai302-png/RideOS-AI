import 'package:flutter/material.dart';

enum AaaThemePreset {
  carbon,
  midnight,
  aurora,
  ocean,
  forest,
  solar,
}

class AaaDesignTokens3 {
  static const Color neonOrange = Color(0xFFFF6D00);
  static const Color cyanGlow = Color(0xFF00E5FF);
  static const Color deepSpaceBackground = Color(0xFF05080C);
  static const Color glassSurfaceColor = Color(0x2A101724);

  static const double radiusSm = 8.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0;

  static const double glassBlurX = 16.0;
  static const double glassBlurY = 16.0;
}

class AaaDesignSystem3Engine {
  static final AaaDesignSystem3Engine instance = AaaDesignSystem3Engine._internal();
  AaaDesignSystem3Engine._internal();

  ThemeData buildThemePreset(AaaThemePreset preset) {
    switch (preset) {
      case AaaThemePreset.aurora:
        return ThemeData.dark().copyWith(
          scaffoldBackgroundColor: AaaDesignTokens3.deepSpaceBackground,
          colorScheme: const ColorScheme.dark(
            primary: AaaDesignTokens3.cyanGlow,
            secondary: AaaDesignTokens3.neonOrange,
            surface: AaaDesignTokens3.glassSurfaceColor,
          ),
        );
      case AaaThemePreset.carbon:
      default:
        return ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
          colorScheme: const ColorScheme.dark(
            primary: AaaDesignTokens3.neonOrange,
            secondary: Colors.white,
          ),
        );
    }
  }
}

class GlassScaffoldWidget extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;

  const GlassScaffoldWidget({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AaaDesignTokens3.deepSpaceBackground,
      appBar: appBar,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.6),
                  radius: 1.2,
                  colors: [
                    Color(0x2200E5FF),
                    Color(0x0005080C),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(child: body),
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
