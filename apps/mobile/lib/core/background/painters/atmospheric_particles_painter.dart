import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/ambient_environment_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AtmosphericParticlesPainter — Hyper-Realistic Edition
//  Elements:
//   | Depth-layered floating particles (dust, ash, rain mist)
//   | Lens bokeh circles (out-of-focus light blobs for far particles)
//   | Camera lens flare streak on foreground bright particles
//   | Rain splash ripple rings on the ground plane
//   | Touch/tap interactive ripple pulses
// ─────────────────────────────────────────────────────────────────────────────

class AtmosphericParticlesPainter extends CustomPainter {
  final List<AmbientParticle> particles;
  final List<BackgroundTouchPulse> touchPulses;
  final double animationProgress;
  final Offset parallaxOffset;
  final BackgroundQualityTier quality;

  AtmosphericParticlesPainter({
    required this.particles,
    required this.touchPulses,
    required this.animationProgress,
    required this.parallaxOffset,
    required this.quality,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final w = size.width;
    final h = size.height;
    final t = animationProgress;

    // ── Touch ripple pulses (behind particles) ─────────────────────────────
    for (final pulse in touchPulses) {
      final p = pulse.progress;
      if (p >= 1.0) continue;

      // Outer pressure ring
      canvas.drawCircle(
        pulse.position, p * 230,
        Paint()
          ..color = pulse.color.withValues(alpha: (1 - p) * 0.40)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (1 - p) * 2.5 + 0.6,
      );

      // Mid-ring
      if (p < 0.7) {
        canvas.drawCircle(
          pulse.position, p * 140,
          Paint()
            ..color = pulse.color.withValues(alpha: (1 - p / 0.7) * 0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }

      // Inner solid glow
      if (p < 0.35) {
        canvas.drawCircle(
          pulse.position, p * 60,
          Paint()
            ..color = pulse.color.withValues(alpha: (1 - p / 0.35) * 0.15)
            ..style = PaintingStyle.fill
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }
    }

    // ── Rain splash ground ripples ─────────────────────────────────────────
    if (quality == BackgroundQualityTier.high) {
      final rng = math.Random(77);
      const numSplashes = 6;
      for (int i = 0; i < numSplashes; i++) {
        final baseX = rng.nextDouble() * w;
        final baseY = h * (0.68 + rng.nextDouble() * 0.28);
        final phase = rng.nextDouble();
        final p = (t * 0.8 + phase) % 1.0;

        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(baseX, baseY),
            width: p * 30 * (0.6 + baseX / w * 0.8),
            height: p * 8 * (0.6 + baseX / w * 0.4),
          ),
          Paint()
            ..color = const Color(0xFF9EC8E8).withValues(alpha: (1 - p) * 0.14)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8,
        );
      }
    }

    // ── Depth-layered atmospheric particles ───────────────────────────────
    for (final particle in particles) {
      final parallaxX = parallaxOffset.dx * particle.depth * 35;
      final parallaxY = parallaxOffset.dy * particle.depth * 35;

      final yPos =
          (particle.y - t * particle.speed * 1.5) % 1.0;
      final xPos = (particle.x +
              math.sin(t * 2 * math.pi + particle.y * 8) * 0.014) %
          1.0;

      final posX = (xPos * w + parallaxX) % w;
      final posY = (yPos * h + parallaxY) % h;

      final shimmer =
          0.78 + 0.22 * math.sin(t * 4 * math.pi + particle.x * 20);
      final depth = particle.depth;
      final effectiveRadius = particle.radius * (0.5 + depth * 0.9);
      final effectiveOpacity =
          (particle.baseOpacity * shimmer * (0.35 + depth * 0.65))
              .clamp(0.0, 0.9);

      if (depth < 0.35 && quality == BackgroundQualityTier.high) {
        // Far background: bokeh circles — soft blurred disc
        canvas.drawCircle(
          Offset(posX, posY),
          effectiveRadius * 3.5,
          Paint()
            ..color = particle.color.withValues(alpha: effectiveOpacity * 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        // Bokeh ring outline
        canvas.drawCircle(
          Offset(posX, posY),
          effectiveRadius * 3.5,
          Paint()
            ..color = particle.color.withValues(alpha: effectiveOpacity * 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8,
        );
      } else if (depth > 0.72 && quality == BackgroundQualityTier.high) {
        // Near foreground: bright core + glow halo + lens flare streak
        canvas.drawCircle(
          Offset(posX, posY),
          effectiveRadius * 2.4,
          Paint()
            ..color = particle.color.withValues(alpha: effectiveOpacity * 0.28)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawCircle(
          Offset(posX, posY), effectiveRadius,
          Paint()..color = particle.color.withValues(alpha: effectiveOpacity),
        );

        // Thin lens flare streak (horizontal)
        canvas.drawLine(
          Offset(posX - effectiveRadius * 5, posY),
          Offset(posX + effectiveRadius * 5, posY),
          Paint()
            ..color = particle.color.withValues(alpha: effectiveOpacity * 0.22)
            ..strokeWidth = effectiveRadius * 0.9
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
        );
      } else {
        // Mid-depth: standard solid dot
        canvas.drawCircle(
          Offset(posX, posY), effectiveRadius,
          Paint()..color = particle.color.withValues(alpha: effectiveOpacity),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant AtmosphericParticlesPainter oldDelegate) => true;
}
