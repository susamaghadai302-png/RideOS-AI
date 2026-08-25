import 'dart:math' as math;
import 'package:flutter/material.dart';

class AaaProductionTokens {
  static const Color neonOrange = Color(0xFFFF6D00);
  static const Color electricCyan = Color(0xFF00E5FF);
  static const Color obsidianBlack = Color(0xFF05080C);
  static const Color glassBorderColor = Color(0x3300E5FF);

  static const double radiusLg = 24.0;
  static const double glassBlur = 18.0;
}

class HudGaugeCustomPainter extends CustomPainter {
  final double speedValue;
  final double maxSpeed;

  const HudGaugeCustomPainter({
    required this.speedValue,
    this.maxSpeed = 299.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width.isFinite && size.width > 0 ? size.width : 200.0;
    final height = size.height.isFinite && size.height > 0 ? size.height : 200.0;
    final center = Offset(width / 2, height / 2);
    final radius = math.max(10.0, math.min(width, height) / 2 - 12);

    final backgroundPaint = Paint()
      ..color = const Color(0x22101724)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0;

    canvas.drawCircle(center, radius, backgroundPaint);

    final sweepAngle = (speedValue / (maxSpeed > 0 ? maxSpeed : 299.0)).clamp(0.0, 1.0) * (2 * math.pi * 0.75);
    final glowArcPaint = Paint()
      ..shader = const SweepGradient(
        colors: [AaaProductionTokens.electricCyan, AaaProductionTokens.neonOrange],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 14.0;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 1.25,
      sweepAngle,
      false,
      glowArcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant HudGaugeCustomPainter oldDelegate) {
    return oldDelegate.speedValue != speedValue || oldDelegate.maxSpeed != maxSpeed;
  }
}

class GlassCardProductionWidget extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const GlassCardProductionWidget({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20.0),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: const Color(0x2A101724),
          borderRadius: BorderRadius.circular(AaaProductionTokens.radiusLg),
          border: Border.all(color: AaaProductionTokens.glassBorderColor, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 20.0,
              spreadRadius: 2.0,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class AaaDesignSystemProductionEngine {
  static final AaaDesignSystemProductionEngine instance = AaaDesignSystemProductionEngine._internal();
  AaaDesignSystemProductionEngine._internal();

  ThemeData buildProductionTheme() {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AaaProductionTokens.obsidianBlack,
      colorScheme: const ColorScheme.dark(
        primary: AaaProductionTokens.neonOrange,
        secondary: AaaProductionTokens.electricCyan,
      ),
    );
  }
}
