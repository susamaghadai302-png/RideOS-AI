import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
//  PREMIUM LOGIN ANIMATIONS
//  Staggered cinematic entry, floating particles, and depth FX
// ═══════════════════════════════════════════════════════════════

/// Wraps a child with a staggered slide-up + fade-in reveal.
/// [delay]  — fraction of animation (0.0 – 0.8) where this element starts
/// [duration]— how long the element's own animation runs (fraction, 0.0–1.0)
class PremiumSlideReveal extends StatelessWidget {
  final Widget child;
  final Animation<double> parentAnimation;
  final double delay;
  final double duration;
  final double slideDistancePx;

  const PremiumSlideReveal({
    super.key,
    required this.child,
    required this.parentAnimation,
    this.delay = 0.0,
    this.duration = 0.5,
    this.slideDistancePx = 36.0,
  });

  @override
  Widget build(BuildContext context) {
    final start = delay.clamp(0.0, 1.0);
    final end = (delay + duration).clamp(0.0, 1.0);

    final curved = CurvedAnimation(
      parent: parentAnimation,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: curved,
      child: child,
      builder: (context, cachedChild) {
        final v = curved.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, slideDistancePx * (1.0 - v)),
            child: cachedChild,
          ),
        );
      },
    );
  }
}

/// Animated glassmorphic floating orb for depth background effect.
class PremiumFloatingOrb extends StatelessWidget {
  final Animation<double> animation;
  final Color color;
  final double size;
  final double startX;
  final double startY;
  final double phaseOffset;

  const PremiumFloatingOrb({
    super.key,
    required this.animation,
    required this.color,
    required this.size,
    required this.startX,
    required this.startY,
    this.phaseOffset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: startX,
      top: startY,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.28),
                color.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 3D Neumorphic glass card with deep layered shadows.
/// Combines soft inner/outer shadows with BackdropFilter for maximum depth.
class PremiumNeumorphicGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color baseColor;
  final Color accentGlow;
  final double blurSigma;

  const PremiumNeumorphicGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(28.0),
    this.borderRadius = 24.0,
    this.baseColor = const Color(0xFF0D1226),
    this.accentGlow = const Color(0xFFFF5500),
    this.blurSigma = 26.0,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(borderRadius);
    return Container(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: [
          // Outer deep drop shadow — neumorphic depth
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.70),
            blurRadius: 40,
            offset: const Offset(0, 20),
            spreadRadius: -4,
          ),
          // Accent glow halo
          BoxShadow(
            color: accentGlow.withValues(alpha: 0.14),
            blurRadius: 55,
            spreadRadius: 4,
          ),
          // Bottom-right dark shadow for concave illusion
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 22,
            offset: const Offset(8, 14),
          ),
          // Top-left light reflection
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(-4, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: Stack(
          children: [
            // Backdrop blur substrate
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        baseColor.withValues(alpha: 0.72),
                        const Color(0xFF060B18).withValues(alpha: 0.86),
                      ],
                    ),
                    borderRadius: br,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.09),
                      width: 1.3,
                    ),
                  ),
                ),
              ),
            ),
            // Top specular rim — simulates glass edge catching light
            Positioned(
              top: 0,
              left: 16,
              right: 16,
              height: 1.2,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.60),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Left edge inner highlight
            Positioned(
              top: 16,
              bottom: 16,
              left: 0,
              width: 1.2,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.30),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Inner diagonal sheen
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1.0, -0.8),
                      end: Alignment(1.0, 0.8),
                      colors: [
                        Color(0x15FFFFFF),
                        Color(0x00FFFFFF),
                        Color(0x08FFFFFF),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Actual content
            Padding(
              padding: padding,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated breathing border ring — renders a glowing animated stroke
/// around an existing widget for a premium "active system" feel.
class PremiumBreathingRing extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  final Color color;
  final double borderRadius;
  final double strokeWidth;

  const PremiumBreathingRing({
    super.key,
    required this.child,
    required this.animation,
    this.color = const Color(0xFFFF5500),
    this.borderRadius = 24.0,
    this.strokeWidth = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, cachedChild) {
        final pulse = (math.sin(animation.value * 2 * math.pi) + 1.0) / 2.0;
        final glowOpacity = 0.35 + pulse * 0.45;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: color.withValues(alpha: glowOpacity),
              width: strokeWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.18 + pulse * 0.22),
                blurRadius: 14 + pulse * 10,
                spreadRadius: pulse * 2,
              ),
            ],
          ),
          child: cachedChild,
        );
      },
    );
  }
}
