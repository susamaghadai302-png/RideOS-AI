import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'roados_tokens.dart';

/// Single active liquid water ripple instance
class _WaterRippleWave {
  final Offset position;
  final DateTime startTime;
  final double maxRadius;
  final Color tintColor;

  _WaterRippleWave({
    required this.position,
    required this.startTime,
    this.maxRadius = 140.0,
    this.tintColor = const Color(0xFF00F2FE),
  });
}

/// Interactive Touch & Click Liquid Water Ripple Container
/// Wraps any glass surface, button, or card with realistic fluid touch ripples.
class LiquidWaterRipple extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final Color? rippleColor;
  final VoidCallback? onTap;
  final bool enableHoverLight;
  final double blurSigma;

  const LiquidWaterRipple({
    super.key,
    required this.child,
    this.borderRadius = 18.0,
    this.rippleColor,
    this.onTap,
    this.enableHoverLight = false,
    this.blurSigma = 0.0,
  });

  @override
  State<LiquidWaterRipple> createState() => _LiquidWaterRippleState();
}

class _LiquidWaterRippleState extends State<LiquidWaterRipple>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final List<_WaterRippleWave> _ripples = [];
  Offset? _hoverPosition;
  bool _isHovering = false;
  static const Duration _rippleLifetime = Duration(milliseconds: 480);

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onTick);
  }

  @override
  void dispose() {
    _ticker.removeListener(_onTick);
    _ticker.dispose();
    super.dispose();
  }

  void _onTick() {
    final now = DateTime.now();
    _ripples.removeWhere((r) => now.difference(r.startTime) > _rippleLifetime);
    if (_ripples.isEmpty && !_isHovering && _ticker.isAnimating) {
      _ticker.stop();
    }
    setState(() {});
  }

  void _addRipple(Offset localPos, {double maxRadius = 160.0}) {
    final effectiveColor = widget.rippleColor ?? const Color(0xFF00F2FE);
    setState(() {
      _ripples.add(_WaterRippleWave(
        position: localPos,
        startTime: DateTime.now(),
        maxRadius: maxRadius,
        tintColor: effectiveColor,
      ));
    });
    if (!_ticker.isAnimating) {
      _ticker.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) {
          _addRipple(details.localPosition);
        },
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              widget.child,
              // Water Ripple & Specular Glow Canvas
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _LiquidWaterRipplePainter(
                      ripples: _ripples,
                      hoverPos: _hoverPosition,
                      isHovering: _isHovering,
                      lifetime: _rippleLifetime,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

/// Custom Painter for expanding liquid water rings and caustic refractions
class _LiquidWaterRipplePainter extends CustomPainter {
  final List<_WaterRippleWave> ripples;
  final Offset? hoverPos;
  final bool isHovering;
  final Duration lifetime;

  _LiquidWaterRipplePainter({
    required this.ripples,
    required this.hoverPos,
    required this.isHovering,
    required this.lifetime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();

    // 1. Subtle Mouse Hover Ambient Fluid Highlight
    if (isHovering && hoverPos != null) {
      final hoverPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF00F2FE).withValues(alpha: 0.12),
            const Color(0xFF6366F1).withValues(alpha: 0.04),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: hoverPos!, radius: 90.0));

      canvas.drawCircle(hoverPos!, 90.0, hoverPaint);
    }

    // 2. Active Liquid Water Expanding Rings
    for (final ripple in ripples) {
      final elapsed = now.difference(ripple.startTime).inMilliseconds;
      final progress = (elapsed / lifetime.inMilliseconds).clamp(0.0, 1.0);
      if (progress >= 1.0) continue;

      final easeOut = Curves.easeOutCubic.transform(progress);
      final currentRadius = ripple.maxRadius * easeOut;
      final alpha = (1.0 - easeOut) * 0.75;

      // Primary Outer Water Crest
      final outerRingPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (2.5 * (1.0 - easeOut)).clamp(0.5, 3.0)
        ..color = ripple.tintColor.withValues(alpha: alpha * 0.85);
      canvas.drawCircle(ripple.position, currentRadius, outerRingPaint);

      // Inner Refraction Secondary Crest
      if (currentRadius > 8.0) {
        final innerRingPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = Colors.white.withValues(alpha: alpha * 0.95);
        canvas.drawCircle(ripple.position, currentRadius * 0.75, innerRingPaint);
      }

      // Center Fluid Flash Sheen
      final fluidFlashPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: (alpha * 0.5).clamp(0.0, 1.0)),
            ripple.tintColor.withValues(alpha: (alpha * 0.25).clamp(0.0, 1.0)),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: ripple.position, radius: currentRadius));

      canvas.drawCircle(ripple.position, currentRadius, fluidFlashPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidWaterRipplePainter oldDelegate) {
    return ripples.isNotEmpty || isHovering != oldDelegate.isHovering || hoverPos != oldDelegate.hoverPos;
  }
}
