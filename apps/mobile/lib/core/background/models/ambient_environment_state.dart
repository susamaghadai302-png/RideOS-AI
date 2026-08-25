import 'package:flutter/material.dart';

/// Ambient time-of-day atmospheric mode for futuristic environmental lighting
enum AmbientTimeMode {
  night,
  sunset,
  day,
}

/// Adaptive performance tier for background rendering
enum BackgroundQualityTier {
  high,
  medium,
  low,
}

/// A microscopic floating ambient particle with depth parallax
class AmbientParticle {
  double x;
  double y;
  final double radius;
  final double speed;
  final double baseOpacity;
  final Color color;
  final double depth; // 0.0 (far) to 1.0 (near)

  AmbientParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.baseOpacity,
    required this.color,
    required this.depth,
  });
}

/// A futuristic autonomous mobility light trail moving along perspective road vectors
class MobilityLightTrail {
  final int laneIndex; // 0: leftmost, 1: mid-left, 2: mid-right, 3: rightmost
  final double speed;
  final double length;
  final Color color;
  double progress; // 0.0 (horizon) to 1.0 (near)
  final bool isIncoming; // true: toward camera (white/cyan), false: away (red/amber)

  MobilityLightTrail({
    required this.laneIndex,
    required this.speed,
    required this.length,
    required this.color,
    required this.progress,
    required this.isIncoming,
  });
}

/// Interactive background ripple pulse triggered on pointer/touch
class BackgroundTouchPulse {
  final Offset position;
  final DateTime createdAt;
  final Color color;

  BackgroundTouchPulse({
    required this.position,
    required this.createdAt,
    this.color = const Color(0xFF00F2FE),
  });

  double get progress {
    final elapsedMs = DateTime.now().difference(createdAt).inMilliseconds;
    return (elapsedMs / 1400.0).clamp(0.0, 1.0);
  }

  bool get isExpired => progress >= 1.0;
}
