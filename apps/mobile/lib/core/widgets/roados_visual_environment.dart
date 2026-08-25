import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../design_system/roados_tokens.dart';

/// Available environment profiles across RoadOS AI
enum RoadOSEnvironmentType {
  dashboard,
  garage,
  voiceAi,
  radar,
  trips,
  safety,
  notifications,
  settings,
  profileVault,
}

/// Unified, High-Performance Page Visual Environment
class RoadOSVisualEnvironment extends StatefulWidget {
  final Widget child;
  final RoadOSEnvironmentType environmentType;
  final bool animate;
  final double intensity;

  const RoadOSVisualEnvironment({
    super.key,
    required this.child,
    this.environmentType = RoadOSEnvironmentType.dashboard,
    this.animate = true,
    this.intensity = 1.0,
  });

  @override
  State<RoadOSVisualEnvironment> createState() => _RoadOSVisualEnvironmentState();
}

class _RoadOSVisualEnvironmentState extends State<RoadOSVisualEnvironment> with SingleTickerProviderStateMixin {
  late AnimationController _ambientController;
  final List<_EnvParticle> _particles = [];
  final math.Random _random = math.Random(42);

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
    if (widget.animate) {
      _ambientController.repeat();
    }
    _initEnvironmentParticles();
  }

  @override
  void didUpdateWidget(covariant RoadOSVisualEnvironment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.environmentType != widget.environmentType) {
      _initEnvironmentParticles();
    }
    if (widget.animate && !_ambientController.isAnimating) {
      _ambientController.repeat();
    } else if (!widget.animate && _ambientController.isAnimating) {
      _ambientController.stop();
    }
  }

  void _initEnvironmentParticles() {
    _particles.clear();
    final count = switch (widget.environmentType) {
      RoadOSEnvironmentType.dashboard => 28,
      RoadOSEnvironmentType.garage => 16,
      RoadOSEnvironmentType.voiceAi => 36,
      RoadOSEnvironmentType.radar => 24,
      RoadOSEnvironmentType.trips => 20,
      RoadOSEnvironmentType.safety => 14,
      RoadOSEnvironmentType.notifications => 18,
      RoadOSEnvironmentType.settings => 8,
      RoadOSEnvironmentType.profileVault => 10,
    };

    final particleColor = switch (widget.environmentType) {
      RoadOSEnvironmentType.dashboard => RoadOSColors.roadCyan,
      RoadOSEnvironmentType.garage => RoadOSColors.hyperOrange,
      RoadOSEnvironmentType.voiceAi => const Color(0xFFB388FF),
      RoadOSEnvironmentType.radar => RoadOSColors.apexEmerald,
      RoadOSEnvironmentType.trips => const Color(0xFF00E5FF),
      RoadOSEnvironmentType.safety => const Color(0xFF448AFF),
      RoadOSEnvironmentType.notifications => const Color(0xFF80D8FF),
      RoadOSEnvironmentType.settings => const Color(0xFF64B5F6),
      RoadOSEnvironmentType.profileVault => const Color(0xFF00E5FF),
    };

    for (int i = 0; i < count; i++) {
      _particles.add(_EnvParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        radius: _random.nextDouble() * 2.2 + 0.8,
        speed: (_random.nextDouble() * 0.05 + 0.015) * widget.intensity,
        opacity: _random.nextDouble() * 0.45 + 0.15,
        color: particleColor,
      ));
    }
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Procedural Environment Background Canvas — isolated GPU layer
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _ambientController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _RoadOSEnvironmentPainter(
                  environmentType: widget.environmentType,
                  progress: _ambientController.value,
                  particles: _particles,
                  intensity: widget.intensity,
                ),
              );
            },
          ),
        ),

        // 2. Main Page Content
        widget.child,
      ],
    );
  }
}

class _EnvParticle {
  double x;
  double y;
  final double radius;
  final double speed;
  final double opacity;
  final Color color;

  _EnvParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
    required this.color,
  });
}

class _RoadOSEnvironmentPainter extends CustomPainter {
  final RoadOSEnvironmentType environmentType;
  final double progress;
  final List<_EnvParticle> particles;
  final double intensity;

  _RoadOSEnvironmentPainter({
    required this.environmentType,
    required this.progress,
    required this.particles,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width.isFinite && size.width > 0 ? size.width : 1200.0;
    final height = size.height.isFinite && size.height > 0 ? size.height : 800.0;
    final rect = Rect.fromLTWH(0, 0, width, height);

    switch (environmentType) {
      case RoadOSEnvironmentType.dashboard:
        _paintDashboardEnvironment(canvas, rect, width, height);
        break;
      case RoadOSEnvironmentType.garage:
        _paintGarageEnvironment(canvas, rect, width, height);
        break;
      case RoadOSEnvironmentType.voiceAi:
        _paintVoiceAiEnvironment(canvas, rect, width, height);
        break;
      case RoadOSEnvironmentType.radar:
        _paintRadarEnvironment(canvas, rect, width, height);
        break;
      case RoadOSEnvironmentType.trips:
        _paintTripsEnvironment(canvas, rect, width, height);
        break;
      case RoadOSEnvironmentType.safety:
        _paintSafetyEnvironment(canvas, rect, width, height);
        break;
      case RoadOSEnvironmentType.notifications:
        _paintNotificationsEnvironment(canvas, rect, width, height);
        break;
      case RoadOSEnvironmentType.settings:
      case RoadOSEnvironmentType.profileVault:
        _paintSettingsEnvironment(canvas, rect, width, height);
        break;
    }

    _paintParticles(canvas, width, height);
  }

  /// 1. Dashboard: Smart Mobility City Horizon & Faint Road Grid
  void _paintDashboardEnvironment(Canvas canvas, Rect rect, double w, double h) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF04060C), Color(0xFF060B18), Color(0xFF091226)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // Horizon Glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, 0.4),
        radius: 0.9,
        colors: [
          RoadOSColors.roadCyan.withValues(alpha: 0.08 * intensity),
          RoadOSColors.electricBlue.withValues(alpha: 0.03 * intensity),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, glowPaint);

    // Faint perspective road network grid
    final gridPaint = Paint()
      ..color = RoadOSColors.roadCyan.withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    final horizonY = h * 0.55;
    for (double i = -w * 0.4; i <= w * 1.4; i += 70) {
      canvas.drawLine(Offset(w * 0.5, horizonY), Offset(i, h), gridPaint);
    }
    for (double y = horizonY; y <= h; y += 32) {
      final yProgress = (y - horizonY) / (h - horizonY);
      final dynamicY = horizonY + math.pow(yProgress, 1.8) * (h - horizonY);
      canvas.drawLine(Offset(0, dynamicY), Offset(w, dynamicY), gridPaint);
    }
  }

  /// 2. Garage: Automotive Virtual Studio with Reflective Showroom Floor
  void _paintGarageEnvironment(Canvas canvas, Rect rect, double w, double h) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF06080E), Color(0xFF0D111A), Color(0xFF141924)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // Studio Overhead Keylight Spotlight
    final spotPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.6),
        radius: 0.85,
        colors: [
          RoadOSColors.hyperOrange.withValues(alpha: 0.12 * intensity),
          const Color(0x1100E5FF),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, spotPaint);

    // Showroom Floor Grid & Specular Reflection Plane
    final floorY = h * 0.48;
    final floorPaint = Paint()
      ..color = const Color(0x15FF5500)
      ..strokeWidth = 1.0;

    for (double x = 0; x <= w; x += 55) {
      canvas.drawLine(Offset(x, floorY), Offset(x * 1.3 - w * 0.15, h), floorPaint);
    }
    for (double y = floorY; y <= h; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(w, y), floorPaint);
    }
  }

  /// 3. Voice AI: Neural Intelligence Chamber with Energy Radial Nodes
  void _paintVoiceAiEnvironment(Canvas canvas, Rect rect, double w, double h) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF060614), Color(0xFF0C0A24), Color(0xFF140E36)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // Pulsating Neural Center Field
    final pulse = 0.5 + 0.5 * math.sin(progress * 2 * math.pi);
    final neuralPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.1),
        radius: 0.8 + 0.2 * pulse,
        colors: [
          const Color(0xFF9C27B0).withValues(alpha: 0.15 * intensity),
          const Color(0xFF00E5FF).withValues(alpha: 0.08 * intensity),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, neuralPaint);

    // Neural Ring Waveforms
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int r = 1; r <= 4; r++) {
      final radius = r * 80.0 + pulse * 18.0;
      ringPaint.color = const Color(0xFFB388FF).withValues(alpha: (0.12 - r * 0.02) * intensity);
      canvas.drawCircle(Offset(w * 0.5, h * 0.38), radius, ringPaint);
    }
  }

  /// 4. Radar: Live Mobility Network Concentric Sweep Canvas
  void _paintRadarEnvironment(Canvas canvas, Rect rect, double w, double h) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF030814), Color(0xFF061026), Color(0xFF0B1B3D)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    final center = Offset(w * 0.5, h * 0.42);
    final maxR = math.min(w, h) * 0.45;

    // Concentric Range Rings
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = RoadOSColors.roadCyan.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;

    for (double r = 60; r <= maxR; r += 70) {
      canvas.drawCircle(center, r, ringPaint);
    }

    // Rotating Radar Sweep Vector
    final angle = progress * 2 * math.pi;
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment(
          (center.dx / w) * 2 - 1,
          (center.dy / h) * 2 - 1,
        ),
        startAngle: angle - math.pi * 0.25,
        endAngle: angle,
        colors: [
          Colors.transparent,
          RoadOSColors.apexEmerald.withValues(alpha: 0.12 * intensity),
        ],
      ).createShader(rect);
    canvas.drawCircle(center, maxR, sweepPaint);
  }

  /// 5. Trips: Abstract Journey Topography & Illuminated Waypoint Network
  void _paintTripsEnvironment(Canvas canvas, Rect rect, double w, double h) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF040810), Color(0xFF09121E), Color(0xFF0F1E2E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // Topographical Route Elevation Curves
    final pathPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0x1400E5FF);

    for (int line = 0; line < 5; line++) {
      final path = Path();
      final baseY = h * 0.3 + line * 70.0;
      path.moveTo(0, baseY);
      for (double x = 0; x <= w; x += 40) {
        final y = baseY + math.sin((x / w) * 4 * math.pi + progress * math.pi + line) * 24.0;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, pathPaint);
    }
  }

  /// 6. Safety: Protective Command Center with Sapphire Aura
  void _paintSafetyEnvironment(Canvas canvas, Rect rect, double w, double h) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF05070E), Color(0xFF0A0F1D), Color(0xFF10182D)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // Protective Safety Shield Glow
    final shieldPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, 0.0),
        radius: 0.75,
        colors: [
          const Color(0xFF2979FF).withValues(alpha: 0.10 * intensity),
          const Color(0xFF00E5FF).withValues(alpha: 0.04 * intensity),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, shieldPaint);
  }

  /// 7. Notifications: Layered Slate Telematics Center
  void _paintNotificationsEnvironment(Canvas canvas, Rect rect, double w, double h) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF050810), Color(0xFF0B101E), Color(0xFF121B2E)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);
  }

  /// 8. Settings & Profile Vault: Minimal Clean Studio
  void _paintSettingsEnvironment(Canvas canvas, Rect rect, double w, double h) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF04060A), Color(0xFF080D16), Color(0xFF0E1422)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);
  }

  void _paintParticles(Canvas canvas, double w, double h) {
    final particlePaint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final dynamicY = (p.y - progress * p.speed) % 1.0;
      final px = p.x * w;
      final py = dynamicY * h;

      particlePaint.color = p.color.withValues(alpha: p.opacity * intensity);
      canvas.drawCircle(Offset(px, py), p.radius, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoadOSEnvironmentPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.environmentType != environmentType ||
        oldDelegate.intensity != intensity;
  }
}
