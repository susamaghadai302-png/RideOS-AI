import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/ambient_environment_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MobilityHorizonPainter — Hyper-Realistic Edition
//  Layers:
//   1. Far city skyline with window glow grid
//   2. Mid city silhouette + spire beacons
//   3. Volumetric ground fog band
//   4. Wet asphalt road with live specular reflections
//   5. Perspective lane markings (animated dashes)
//   6. Rain streak layer
//   7. Autonomous light trails with glow bloom + puddle reflection
// ─────────────────────────────────────────────────────────────────────────────

class MobilityHorizonPainter extends CustomPainter {
  final double animationProgress;
  final Offset parallaxOffset;
  final AmbientTimeMode timeMode;
  final List<MobilityLightTrail> lightTrails;
  final BackgroundQualityTier quality;

  MobilityHorizonPainter({
    required this.animationProgress,
    required this.parallaxOffset,
    required this.timeMode,
    required this.lightTrails,
    required this.quality,
  });

  Color get _accentCyan => timeMode == AmbientTimeMode.sunset
      ? const Color(0xFFF59E0B)
      : const Color(0xFF00F2FE);

  Color get _roadColor => timeMode == AmbientTimeMode.day
      ? const Color(0xFF1A1F2E)
      : const Color(0xFF0C0E18);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final w = size.width;
    final h = size.height;
    final horizonY = h * 0.54 + parallaxOffset.dy * 18;
    final vx = w * 0.5 + parallaxOffset.dx * 28;

    _drawFarCityLayer(canvas, w, h, horizonY, vx);
    _drawMidCityLayer(canvas, w, h, horizonY, vx);
    _drawGroundFog(canvas, w, h, horizonY);
    _drawWetRoad(canvas, w, h, horizonY, vx);
    _drawLaneMarkings(canvas, w, h, horizonY, vx);
    if (quality != BackgroundQualityTier.low) {
      _drawRainStreaks(canvas, w, h);
      _drawMobilityLightTrails(canvas, w, h, horizonY, vx);
    }
  }

  // ── 1. Far city — tiny lit-window grid ─────────────────────────────────────
  void _drawFarCityLayer(
      Canvas canvas, double w, double h, double horizonY, double vx) {
    final rng = math.Random(7);
    const numBuildings = 22;
    final buildingColor = timeMode == AmbientTimeMode.day
        ? const Color(0x10385170)
        : const Color(0x14102030);

    double cx = w * 0.05;
    for (int i = 0; i < numBuildings; i++) {
      final bw = w * (0.03 + rng.nextDouble() * 0.05);
      final bh = 25.0 + rng.nextDouble() * 60.0;
      final rect = Rect.fromLTWH(cx, horizonY - bh, bw - 1, bh);
      canvas.drawRect(rect, Paint()..color = buildingColor);

      if (quality == BackgroundQualityTier.high) {
        final cols = (bw / 5).floor().clamp(1, 8);
        final rows = (bh / 7).floor().clamp(1, 12);
        final rng2 = math.Random(i * 31 + 7);
        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < cols; c++) {
            if (rng2.nextDouble() < 0.55) continue;
            final flicker = 0.7 +
                0.3 *
                    math.sin(animationProgress * math.pi * 2 +
                        r * 1.3 +
                        c * 2.1 +
                        i);
            final wx = rect.left + c * (bw / cols) + 1.5;
            final wy = rect.top + r * (bh / rows) + 1.5;
            canvas.drawRect(
              Rect.fromLTWH(wx, wy, 2.5, 3.0),
              Paint()
                ..color = Color.lerp(
                  const Color(0xFFFFF9C4),
                  _accentCyan,
                  rng2.nextDouble(),
                )!
                    .withValues(alpha: 0.35 * flicker),
            );
          }
        }
      }
      cx += bw + rng.nextDouble() * 3;
      if (cx > w * 0.98) break;
    }
  }

  // ── 2. Mid city — prominent silhouette + glowing spires ────────────────────
  void _drawMidCityLayer(
      Canvas canvas, double w, double h, double horizonY, double vx) {
    final fillPaint = Paint()
      ..color = timeMode == AmbientTimeMode.day
          ? const Color(0x1E2A4A6B)
          : const Color(0x221C2840);

    final beaconOpacity =
        0.5 + 0.5 * math.sin(animationProgress * math.pi * 3.5);

    final specs = [
      [0.05, 48.0, 0.07], [0.12, 22.0, 0.05], [0.18, 72.0, 0.09],
      [0.27, 35.0, 0.06], [0.33, 90.0, 0.08], [0.42, 55.0, 0.07],
      [0.50, 110.0, 0.06], [0.57, 68.0, 0.08], [0.65, 40.0, 0.05],
      [0.71, 85.0, 0.09], [0.80, 30.0, 0.06], [0.87, 65.0, 0.07],
      [0.93, 50.0, 0.06],
    ];

    final path = Path();
    path.moveTo(0, horizonY);

    for (final s in specs) {
      final bx = (s[0] as double) * w;
      final bh = s[1] as double;
      final bw = (s[2] as double) * w;
      final topY = horizonY - bh;

      path.lineTo(bx, horizonY);
      path.lineTo(bx, topY);
      if (bh > 70) {
        path.lineTo(bx + bw * 0.5, topY - 12);
        path.lineTo(bx + bw, topY);
      } else {
        path.lineTo(bx + bw, topY);
      }
      path.lineTo(bx + bw, horizonY);

      if (bh > 70 && quality == BackgroundQualityTier.high) {
        final spireX = bx + bw * 0.5;
        final spireY = horizonY - bh - 13;
        canvas.drawCircle(
          Offset(spireX, spireY),
          2.5,
          Paint()
            ..color = _accentCyan.withValues(alpha: beaconOpacity * 0.8)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawCircle(
          Offset(spireX, spireY), 1.5,
          Paint()..color = Colors.white.withValues(alpha: beaconOpacity * 0.9),
        );
      }
    }
    path.lineTo(w, horizonY);
    path.close();
    canvas.drawPath(path, fillPaint);

    // Horizon glow line
    final glowShader = LinearGradient(
      colors: [
        Colors.transparent,
        _accentCyan.withValues(alpha: 0.28),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(0, horizonY - 1, w, 3));
    canvas.drawRect(
      Rect.fromLTWH(0, horizonY - 1, w, 2),
      Paint()..shader = glowShader,
    );
  }

  // ── 3. Volumetric ground fog ──────────────────────────────────────────────
  void _drawGroundFog(
      Canvas canvas, double w, double h, double horizonY) {
    final fogTop = horizonY - 8;
    final fogHeight = h * 0.12;
    final t = animationProgress * 2 * math.pi;

    for (int i = 0; i < 3; i++) {
      final phase = i * math.pi * 0.66;
      final fogX = w * (0.2 + i * 0.3) +
          math.sin(t * 0.4 + phase) * w * 0.08;
      final shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          _accentCyan.withValues(alpha: 0.07),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCenter(
        center: Offset(fogX, fogTop + fogHeight * 0.3),
        width: w * 0.6,
        height: fogHeight,
      ));
      canvas.drawRect(
        Rect.fromLTWH(0, fogTop, w, fogHeight * 0.8),
        Paint()
          ..shader = shader
          ..blendMode = BlendMode.screen,
      );
    }

    final denseFogShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.black.withValues(alpha: 0.0),
        _roadColor.withValues(alpha: 0.7),
        _roadColor,
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromLTWH(0, fogTop, w, fogHeight));
    canvas.drawRect(
      Rect.fromLTWH(0, fogTop, w, fogHeight),
      Paint()..shader = denseFogShader,
    );
  }

  // ── 4. Wet asphalt road with specular puddle reflections ──────────────────
  void _drawWetRoad(
      Canvas canvas, double w, double h, double horizonY, double vx) {
    final roadShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [_roadColor, const Color(0xFF080B12)],
    ).createShader(Rect.fromLTWH(0, horizonY, w, h - horizonY));
    canvas.drawRect(
      Rect.fromLTWH(0, horizonY, w, h - horizonY),
      Paint()..shader = roadShader,
    );

    // Wet specular sheen band
    final sheenY = horizonY + (h - horizonY) * 0.28;
    final sheenShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        _accentCyan.withValues(alpha: 0.04),
        _accentCyan.withValues(alpha: 0.09),
        _accentCyan.withValues(alpha: 0.04),
        Colors.transparent,
      ],
      stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
    ).createShader(Rect.fromLTWH(0, sheenY - 20, w, 55));
    canvas.drawRect(
      Rect.fromLTWH(0, sheenY - 20, w, 55),
      Paint()..shader = sheenShader,
    );

    if (quality == BackgroundQualityTier.high) {
      final t = animationProgress * 2 * math.pi;
      final puddles = [
        [w * 0.22, h * 0.72, w * 0.08, 4.0],
        [w * 0.55, h * 0.80, w * 0.12, 5.0],
        [w * 0.78, h * 0.68, w * 0.06, 3.5],
        [w * 0.38, h * 0.90, w * 0.10, 4.5],
      ];
      for (final p in puddles) {
        final shimmer = 0.6 + 0.4 * math.sin(t * 0.7 + (p[0] as double) / w * 5);
        final puddlePaint = Paint()
          ..shader = RadialGradient(
            colors: [
              _accentCyan.withValues(alpha: 0.14 * shimmer),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCenter(
            center: Offset(p[0] as double, p[1] as double),
            width: p[2] as double,
            height: p[3] as double,
          ));
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(p[0] as double, p[1] as double),
            width: p[2] as double,
            height: p[3] as double,
          ),
          puddlePaint,
        );
      }
    }
  }

  // ── 5. Lane markings with animated perspective dashes ─────────────────────
  void _drawLaneMarkings(
      Canvas canvas, double w, double h, double horizonY, double vx) {
    Color lineColor;
    switch (timeMode) {
      case AmbientTimeMode.sunset:
        lineColor = const Color(0x30EC4899);
        break;
      case AmbientTimeMode.day:
        lineColor = const Color(0x282563EB);
        break;
      default:
        lineColor = const Color(0x3200F2FE);
    }

    final bottomSpread = w * 1.45;
    final startX = (w - bottomSpread) / 2;
    const numLanes = 7;

    final edgePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.22)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(vx - w * 0.03, horizonY), Offset(startX, h + 20), edgePaint);
    canvas.drawLine(Offset(vx + w * 0.03, horizonY),
        Offset(startX + bottomSpread, h + 20), edgePaint);

    for (int i = 1; i < numLanes; i++) {
      final t = i / numLanes;
      final botX = startX + bottomSpread * t;
      final isMid = i == numLanes ~/ 2;
      if (isMid) {
        _drawPerspectiveDash(
            canvas, w, h, horizonY, vx, botX, lineColor.withValues(alpha: 0.38));
      } else {
        canvas.drawLine(
          Offset(vx + (botX - vx) * 0.05, horizonY),
          Offset(botX, h + 20),
          Paint()
            ..color = lineColor.withValues(alpha: 0.10)
            ..strokeWidth = 0.7
            ..style = PaintingStyle.stroke,
        );
      }
    }
  }

  void _drawPerspectiveDash(Canvas canvas, double w, double h, double horizonY,
      double vx, double botX, Color color) {
    const numDashes = 14;
    for (int d = 0; d < numDashes; d++) {
      final t0 = math.pow(
              (d + animationProgress % 1.0) / numDashes, 1.8)
          .toDouble();
      final t1 = math.pow(
              (d + 0.5 + animationProgress % 1.0) / numDashes, 1.8)
          .toDouble();
      if (t0 >= 1.0 || t1 >= 1.0) continue;

      final y0 = horizonY + (h - horizonY + 20) * t0;
      final y1 = horizonY + (h - horizonY + 20) * t1;
      final x0 = vx + (botX - vx) * math.pow(t0, 0.65).toDouble();
      final x1 = vx + (botX - vx) * math.pow(t1, 0.65).toDouble();

      canvas.drawLine(
        Offset(x0, y0), Offset(x1, y1),
        Paint()
          ..color = color.withValues(alpha: (0.2 + t0 * 0.5).clamp(0.0, 0.7))
          ..strokeWidth = (0.8 + t0 * 2.2).clamp(0.5, 4.0)
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }
  }

  // ── 6. Rain streaks with perspective depth ─────────────────────────────────
  void _drawRainStreaks(Canvas canvas, double w, double h) {
    if (timeMode == AmbientTimeMode.day) return;
    final rng = math.Random(99);
    final t = animationProgress;
    const numStreaks = 45;

    for (int i = 0; i < numStreaks; i++) {
      final x = rng.nextDouble() * w;
      final depthFactor = rng.nextDouble();
      final yStart =
          ((rng.nextDouble() + t * (1.5 + depthFactor)) % 1.0) * h;
      final length = 8.0 + depthFactor * 24.0;
      final slant = 4.0 + depthFactor * 9.0;
      final opacity = 0.04 + depthFactor * 0.09;

      canvas.drawLine(
        Offset(x, yStart),
        Offset(x + slant, yStart + length),
        Paint()
          ..color = const Color(0xFF9EC8E8).withValues(alpha: opacity)
          ..strokeWidth = (0.5 + depthFactor * 0.8).clamp(0.3, 1.5)
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  // ── 7. Autonomous mobility light trails with glow bloom + puddle reflection ─
  void _drawMobilityLightTrails(
      Canvas canvas, double w, double h, double horizonY, double vx) {
    final bottomSpread = w * 1.45;
    final startX = (w - bottomSpread) / 2;

    for (var trail in lightTrails) {
      final p = trail.progress;
      final pTail = (p - trail.length).clamp(0.0, 1.0);

      final yHead =
          horizonY + (h - horizonY + 40) * math.pow(p, 2.2).toDouble();
      final yTail = horizonY +
          (h - horizonY + 40) * math.pow(pTail, 2.2).toDouble();
      final laneFactor = (trail.laneIndex + 1) / 8.0;
      final botX = startX + bottomSpread * laneFactor;
      final xHead =
          vx + (botX - vx) * math.pow(p, 1.6).toDouble();
      final xTail =
          vx + (botX - vx) * math.pow(pTail, 1.6).toDouble();

      final opacity = (math.sin(p * math.pi) * 0.65).clamp(0.0, 0.80);
      final strokeW = 1.0 + p * 2.8;

      // Glow halo
      canvas.drawLine(
        Offset(xTail, yTail), Offset(xHead, yHead),
        Paint()
          ..color = trail.color.withValues(alpha: opacity * 0.35)
          ..strokeWidth = strokeW * 3.5
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      // Core trail
      canvas.drawLine(
        Offset(xTail, yTail), Offset(xHead, yHead),
        Paint()
          ..color = trail.color.withValues(alpha: opacity)
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );
      // Photon head bloom
      canvas.drawCircle(
        Offset(xHead, yHead), 3.5 + p * 2.5,
        Paint()
          ..color = Colors.white.withValues(alpha: opacity * 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawCircle(
        Offset(xHead, yHead), 1.5,
        Paint()..color = Colors.white.withValues(alpha: (opacity * 1.3).clamp(0, 1)),
      );
      // Puddle reflection
      if (yHead > horizonY + (h - horizonY) * 0.25) {
        final reflY = yHead + (yHead - horizonY) * 0.12;
        canvas.drawLine(
          Offset(xHead, yHead), Offset(xTail, reflY),
          Paint()
            ..color = trail.color.withValues(alpha: opacity * 0.18)
            ..strokeWidth = strokeW * 1.5
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant MobilityHorizonPainter oldDelegate) => true;
}
