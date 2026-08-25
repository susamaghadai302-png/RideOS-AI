import 'dart:math' as math;
import 'package:flutter/material.dart';

class ColorTokens102 {
  static const Color darkCarbon = Color(0xFF0D1117);
  static const Color midnight = Color(0xFF05080C);
  static const Color auroraGreen = Color(0xFF00FFA3);
  static const Color oceanBlue = Color(0xFF00B2FF);
  static const Color electricBlue = Color(0xFF2979FF);
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color neonOrange = Color(0xFFFF6D00);
  static const Color glassWhite = Color(0x1FFFFFFF);
  static const Color dangerRed = Color(0xFFFF1744);
  static const Color warningAmber = Color(0xFFFFC400);
  static const Color successGreen = Color(0xFF00E676);
}

class SpacingTokens102 {
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;
}

class RadiusTokens102 {
  static const double radiusSm = 8.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0;
  static const double radiusPill = 999.0;
}

class RadarBackgroundCustomPainter extends CustomPainter {
  final double pulseValue;

  const RadarBackgroundCustomPainter({this.pulseValue = 0.5});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width.isFinite && size.width > 0 ? size.width : 200.0;
    final height = size.height.isFinite && size.height > 0 ? size.height : 200.0;
    final center = Offset(width / 2, height / 2);
    final maxRadius = math.max(10.0, math.min(width, height) / 2 - 10);

    final gridPaint = Paint()
      ..color = const Color(0x1A00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, (maxRadius / 4) * i, gridPaint);
    }

    final pulseRadius = maxRadius * pulseValue;
    final pulsePaint = Paint()
      ..color = ColorTokens102.neonCyan.withValues(alpha: (1.0 - pulseValue).clamp(0.0, 0.4))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawCircle(center, pulseRadius, pulsePaint);
  }

  @override
  bool shouldRepaint(covariant RadarBackgroundCustomPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue;
  }
}

class GlassButton102 extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  const GlassButton102({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(RadiusTokens102.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: SpacingTokens102.space24, vertical: SpacingTokens102.space16),
          decoration: BoxDecoration(
            color: ColorTokens102.glassWhite,
            borderRadius: BorderRadius.circular(RadiusTokens102.radiusMd),
            border: Border.all(color: const Color(0x3300E5FF), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: ColorTokens102.neonCyan, size: 20.0),
                const SizedBox(width: SpacingTokens102.space8),
              ],
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AaaDesignSystemV102Engine {
  static final AaaDesignSystemV102Engine instance = AaaDesignSystemV102Engine._internal();
  AaaDesignSystemV102Engine._internal();

  ThemeData buildFullTheme() {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: ColorTokens102.midnight,
      cardColor: ColorTokens102.darkCarbon,
      colorScheme: const ColorScheme.dark(
        primary: ColorTokens102.neonOrange,
        secondary: ColorTokens102.neonCyan,
        surface: ColorTokens102.darkCarbon,
        error: ColorTokens102.dangerRed,
      ),
    );
  }
}
