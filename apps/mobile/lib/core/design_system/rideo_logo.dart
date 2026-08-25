import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'roados_tokens.dart';

/// Ultra-Luxury RIDEO PRO Precision Vector Emblem Painter
class RideoEmblemPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;
  final double progress;
  final bool showTicks;

  const RideoEmblemPainter({
    this.primaryColor = const Color(0xFF00E5FF),
    this.accentColor = const Color(0xFF0066FF),
    this.progress = 1.0,
    this.showTicks = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w * 0.46;

    // 1. Multi-Layered Radial Halo Glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withValues(alpha: 0.32 * progress),
          accentColor.withValues(alpha: 0.10 * progress),
          Colors.transparent,
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: w * 0.58));
    canvas.drawCircle(center, w * 0.58, glowPaint);

    // 2. Anodized Dark Metallic Disc Base
    final discPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF141F38),
          Color(0xFF0A1020),
          Color(0xFF04060C),
        ],
        stops: [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, discPaint);

    // 3. Precision Outer Faceted / Tachometer Tick Ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, w * 0.035)
      ..shader = LinearGradient(
        colors: [
          primaryColor.withValues(alpha: 0.9 * progress),
          const Color(0xFFFFFFFF).withValues(alpha: 0.4 * progress),
          accentColor.withValues(alpha: 0.8 * progress),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawCircle(center, radius, ringPaint);

    if (showTicks && w >= 36) {
      final tickPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.35 * progress)
        ..strokeWidth = 1.0;
      const totalTicks = 24;
      for (int i = 0; i < totalTicks; i++) {
        final angle = (i * 360 / totalTicks) * math.pi / 180;
        final innerR = radius - (i % 6 == 0 ? 4.0 : 2.5);
        final outerR = radius;
        final p1 = Offset(center.dx + innerR * math.cos(angle), center.dy + innerR * math.sin(angle));
        final p2 = Offset(center.dx + outerR * math.cos(angle), center.dy + outerR * math.sin(angle));
        canvas.drawLine(p1, p2, tickPaint);
      }
    }

    // 4. Aerodynamic Precision "R" Apex Wing Monogram
    final wingGradient = LinearGradient(
      colors: [
        const Color(0xFFFFFFFF),
        primaryColor,
        accentColor,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(w * 0.22, h * 0.22, w * 0.56, h * 0.56));

    final wingPaint = Paint()
      ..shader = wingGradient
      ..style = PaintingStyle.fill;

    // Left Vertical Aerodynamic Fin
    final leftFin = Path()
      ..moveTo(w * 0.30, h * 0.24)
      ..lineTo(w * 0.40, h * 0.24)
      ..lineTo(w * 0.40, h * 0.76)
      ..lineTo(w * 0.30, h * 0.76)
      ..close();
    canvas.drawPath(leftFin, wingPaint);

    // Upper Swept Apex Loop of "R"
    final loopPath = Path()
      ..moveTo(w * 0.40, h * 0.24)
      ..lineTo(w * 0.64, h * 0.24)
      ..cubicTo(w * 0.76, h * 0.24, w * 0.76, h * 0.50, w * 0.64, h * 0.50)
      ..lineTo(w * 0.40, h * 0.50)
      ..close();
    canvas.drawPath(loopPath, wingPaint);

    // Inner Negative Space Cutout
    final innerCutout = Paint()
      ..color = const Color(0xFF080D1A)
      ..style = PaintingStyle.fill;
    final innerPath = Path()
      ..moveTo(w * 0.40, h * 0.32)
      ..lineTo(w * 0.58, h * 0.32)
      ..cubicTo(w * 0.65, h * 0.32, w * 0.65, h * 0.42, w * 0.58, h * 0.42)
      ..lineTo(w * 0.40, h * 0.42)
      ..close();
    canvas.drawPath(innerPath, innerCutout);

    // Lower Dynamic Speed Fin of "R"
    final speedFin = Path()
      ..moveTo(w * 0.48, h * 0.48)
      ..lineTo(w * 0.72, h * 0.76)
      ..lineTo(w * 0.59, h * 0.76)
      ..lineTo(w * 0.40, h * 0.53)
      ..close();
    canvas.drawPath(speedFin, wingPaint);

    // 5. Apex Photon Sparkle Core
    final sparkPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95 * progress)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.68, h * 0.24), math.max(1.8, w * 0.035), sparkPaint);
  }

  @override
  bool shouldRepaint(covariant RideoEmblemPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.showTicks != showTicks;
  }
}

/// Unified Luxury Brand Logo & Wordmark Component
class RideoUltimateLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final bool isVertical;
  final Color primaryColor;
  final Color accentColor;

  const RideoUltimateLogo({
    super.key,
    this.size = 36.0,
    this.showWordmark = true,
    this.isVertical = false,
    this.primaryColor = RoadOSColors.roadCyan,
    this.accentColor = RoadOSColors.electricBlue,
  });

  @override
  Widget build(BuildContext context) {
    final emblem = CustomPaint(
      size: Size(size, size),
      painter: RideoEmblemPainter(
        primaryColor: primaryColor,
        accentColor: accentColor,
        showTicks: size >= 32,
      ),
    );

    if (!showWordmark) return emblem;

    final wordmark = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isVertical ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'RIDEO',
              style: GoogleFonts.spaceGrotesk(
                fontSize: math.max(14.0, size * 0.42),
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2.4,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: RoadOSGradients.anodizedCyan,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.65),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(
                'PRO',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: math.max(9.0, size * 0.22),
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        if (size >= 32)
          Text(
            'PREMIUM AI COCKPIT  |  ULTRA-LUXURY',
            style: GoogleFonts.inter(
              fontSize: math.max(7.5, size * 0.13),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF00F2FE),
              letterSpacing: 1.4,
            ),
          ),
      ],
    );

    if (isVertical) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            emblem,
            SizedBox(height: size * 0.25),
            wordmark,
          ],
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          emblem,
          SizedBox(width: size * 0.25),
          wordmark,
        ],
      ),
    );
  }
}
