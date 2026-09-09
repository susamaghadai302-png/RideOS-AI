import 'dart:math' as math;
import 'package:flutter/material.dart';

enum RideOSWeatherMode { clearAurora, rain, storm, fog, snow, sunset }

class Living3dEnvironment extends StatefulWidget {
  final Widget child;
  final RideOSWeatherMode weatherMode;

  const Living3dEnvironment({
    super.key,
    required this.child,
    this.weatherMode = RideOSWeatherMode.clearAurora,
  });

  @override
  State<Living3dEnvironment> createState() => _Living3dEnvironmentState();
}

class _Living3dEnvironmentState extends State<Living3dEnvironment> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final List<WeatherParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
      value: 0.5,
    );

    _initParticles();
  }

  @override
  void didUpdateWidget(covariant Living3dEnvironment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weatherMode != widget.weatherMode) {
      _initParticles();
    }
  }

  void _initParticles() {
    _particles.clear();
    final count = widget.weatherMode == RideOSWeatherMode.rain || widget.weatherMode == RideOSWeatherMode.storm ? 70 : 40;
    for (int i = 0; i < count; i++) {
      _particles.add(WeatherParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        radius: _random.nextDouble() * 2.5 + 1.0,
        speed: _random.nextDouble() * 0.4 + 0.1,
        opacity: _random.nextDouble() * 0.7 + 0.3,
        length: _random.nextDouble() * 12 + 6,
      ));
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Atmosphere Gradient according to Weather Mode
        AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          decoration: BoxDecoration(
            gradient: _getAtmosphereGradient(widget.weatherMode),
          ),
        ),

        // Live Animated Weather Environment Layer
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              final t = _animController.value;
              return Stack(
                children: [
                  // Starfield Particles for Night/Sunset/Clear
                  if (widget.weatherMode == RideOSWeatherMode.clearAurora || widget.weatherMode == RideOSWeatherMode.sunset)
                    CustomPaint(
                      size: Size.infinite,
                      painter: StarfieldPainter(stars: _particles, progress: t),
                    ),

                  // Aurora Glow Wave
                  if (widget.weatherMode == RideOSWeatherMode.clearAurora)
                    CustomPaint(
                      size: Size.infinite,
                      painter: AuroraPainter(progress: t),
                    ),

                  // Rain / Storm / Snow Drops Painter
                  if (widget.weatherMode == RideOSWeatherMode.rain ||
                      widget.weatherMode == RideOSWeatherMode.storm ||
                      widget.weatherMode == RideOSWeatherMode.snow)
                    CustomPaint(
                      size: Size.infinite,
                      painter: WeatherPrecipitationPainter(
                        particles: _particles,
                        progress: t,
                        mode: widget.weatherMode,
                      ),
                    ),

                  // Volumetric Fog Wave Painter
                  if (widget.weatherMode == RideOSWeatherMode.fog || widget.weatherMode == RideOSWeatherMode.storm)
                    CustomPaint(
                      size: Size.infinite,
                      painter: FogPainter(progress: t),
                    ),

                  // Mountain Range Silhouettes
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 180,
                    child: CustomPaint(
                      size: const Size(double.infinity, 180),
                      painter: MountainPainter(mode: widget.weatherMode),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // Content Overlay
        widget.child,
      ],
    );
  }

  LinearGradient _getAtmosphereGradient(RideOSWeatherMode mode) {
    switch (mode) {
      case RideOSWeatherMode.sunset:
        return const LinearGradient(
          colors: [Color(0xFF2E0854), Color(0xFFC73E1D), Color(0xFF100720)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case RideOSWeatherMode.rain:
      case RideOSWeatherMode.storm:
        return const LinearGradient(
          colors: [Color(0xFF070B12), Color(0xFF0F172A), Color(0xFF05080E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case RideOSWeatherMode.fog:
        return const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A), Color(0xFF090D16)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case RideOSWeatherMode.snow:
        return const LinearGradient(
          colors: [Color(0xFF0B192C), Color(0xFF1E3E62), Color(0xFF000000)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case RideOSWeatherMode.clearAurora:
        return const LinearGradient(
          colors: [Color(0xFF04060A), Color(0xFF0D121D), Color(0xFF080A10)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
    }
  }
}

class WeatherParticle {
  final double x;
  final double y;
  final double radius;
  final double speed;
  final double opacity;
  final double length;

  WeatherParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
    required this.length,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  StarfieldPainter — depth-layered with bokeh halos for far stars
// ─────────────────────────────────────────────────────────────────────────────
class StarfieldPainter extends CustomPainter {
  final List<WeatherParticle> stars;
  final double progress;

  StarfieldPainter({required this.stars, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width.isFinite && size.width > 0 ? size.width : 1200.0;
    final h = size.height.isFinite && size.height > 0 ? size.height : 800.0;

    for (final star in stars) {
      final pulse = (math.sin(progress * 2 * math.pi + star.x * 10) + 1) / 2;
      final alpha = star.opacity * (0.35 + pulse * 0.65);
      final posX = star.x * w;
      final posY = star.y * h * 0.62;

      if (star.radius < 0.8) {
        // Far tiny star — bokeh ring
        canvas.drawCircle(Offset(posX, posY), star.radius * 3.5,
          Paint()
            ..color = Colors.white.withValues(alpha: alpha * 0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5,
        );
        canvas.drawCircle(Offset(posX, posY), star.radius * 0.8,
          Paint()..color = Colors.white.withValues(alpha: alpha),
        );
      } else if (star.radius > 1.6) {
        // Bright foreground star — soft glow + cross flare
        canvas.drawCircle(Offset(posX, posY), star.radius * 2.2,
          Paint()
            ..color = Colors.white.withValues(alpha: alpha * 0.22)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
        canvas.drawCircle(Offset(posX, posY), star.radius,
          Paint()..color = Colors.white.withValues(alpha: alpha),
        );
        // Thin cross flare
        canvas.drawLine(
          Offset(posX - star.radius * 3.5, posY),
          Offset(posX + star.radius * 3.5, posY),
          Paint()..color = Colors.white.withValues(alpha: alpha * 0.18)..strokeWidth = star.radius * 0.6,
        );
        canvas.drawLine(
          Offset(posX, posY - star.radius * 3.5),
          Offset(posX, posY + star.radius * 3.5),
          Paint()..color = Colors.white.withValues(alpha: alpha * 0.18)..strokeWidth = star.radius * 0.6,
        );
      } else {
        canvas.drawCircle(Offset(posX, posY), star.radius,
          Paint()..color = Colors.white.withValues(alpha: alpha),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant StarfieldPainter oldDelegate) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
//  AuroraPainter — 3 undulating aurora bands with emission gradient
// ─────────────────────────────────────────────────────────────────────────────
class AuroraPainter extends CustomPainter {
  final double progress;

  AuroraPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width.isFinite && size.width > 0 ? size.width : 1200.0;
    final h = size.height.isFinite && size.height > 0 ? size.height : 800.0;
    final t = progress * 2 * math.pi;

    // Band 1: Quantum Cyan
    _drawAuroraBand(
      canvas, w, h, t,
      baseY: 0.20, amplitude: 38, freq: 1.0, freqB: 1.5,
      color1: const Color(0x5200F2FE), color2: const Color(0x2200E676),
      phaseOffset: 0.0,
    );

    // Band 2: Violet/Indigo
    _drawAuroraBand(
      canvas, w, h, t,
      baseY: 0.13, amplitude: 28, freq: 0.75, freqB: 1.2,
      color1: const Color(0x3A8A2BE2), color2: const Color(0x186366F1),
      phaseOffset: 1.1,
    );

    // Band 3: Warm orange (faint)
    _drawAuroraBand(
      canvas, w, h, t,
      baseY: 0.26, amplitude: 22, freq: 1.3, freqB: 0.9,
      color1: const Color(0x28FF6B35), color2: const Color(0x0CF59E0B),
      phaseOffset: 2.3,
    );
  }

  void _drawAuroraBand(
    Canvas canvas, double w, double h, double t, {
    required double baseY,
    required double amplitude,
    required double freq,
    required double freqB,
    required Color color1,
    required Color color2,
    required double phaseOffset,
  }) {
    final bottom = baseY + 0.28;
    final path = Path();
    path.moveTo(0, h * baseY);
    for (double x = 0; x <= w; x += 18) {
      final y = h * baseY
          + math.sin(t * freq + x / 100 + phaseOffset) * amplitude
          + math.cos(t * freqB + x / 150 + phaseOffset * 0.7) * (amplitude * 0.55);
      path.lineTo(x, y);
    }
    path.lineTo(w, h * bottom);
    path.lineTo(0, h * bottom);
    path.close();

    canvas.drawPath(
      path,
      Paint()..shader = LinearGradient(
        colors: [color1, color2, Colors.transparent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h * bottom)),
    );
  }

  @override
  bool shouldRepaint(covariant AuroraPainter oldDelegate) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
//  WeatherPrecipitationPainter — realistic rain/storm/snow
// ─────────────────────────────────────────────────────────────────────────────
class WeatherPrecipitationPainter extends CustomPainter {
  final List<WeatherParticle> particles;
  final double progress;
  final RideOSWeatherMode mode;

  WeatherPrecipitationPainter({
    required this.particles,
    required this.progress,
    required this.mode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width.isFinite && size.width > 0 ? size.width : 1200.0;
    final h = size.height.isFinite && size.height > 0 ? size.height : 800.0;
    final isSnow = mode == RideOSWeatherMode.snow;
    final isStorm = mode == RideOSWeatherMode.storm;

    for (final p in particles) {
      final depth = p.opacity; // reuse opacity as depth 0..1
      final yPos = (p.y + progress * p.speed * (isStorm ? 2.8 : 1.8)) % 1.0;
      final windX = isStorm ? 0.025 : 0.008;
      final xPos = (p.x + math.sin(progress * 4 * math.pi + p.y * 5) * (isSnow ? 0.05 : windX)) % 1.0;

      final sx = xPos * w;
      final sy = yPos * h;

      if (isSnow) {
        // Snow flake — soft disc with subtle star shape
        canvas.drawCircle(
          Offset(sx, sy), p.radius * 1.6,
          Paint()..color = Colors.white.withValues(alpha: p.opacity * 0.85),
        );
        if (p.radius > 1.2) {
          // Simple 4-arm cross
          canvas.drawLine(
            Offset(sx - p.radius * 2.2, sy), Offset(sx + p.radius * 2.2, sy),
            Paint()..color = Colors.white.withValues(alpha: p.opacity * 0.45)..strokeWidth = 0.7,
          );
          canvas.drawLine(
            Offset(sx, sy - p.radius * 2.2), Offset(sx, sy + p.radius * 2.2),
            Paint()..color = Colors.white.withValues(alpha: p.opacity * 0.45)..strokeWidth = 0.7,
          );
        }
      } else {
        // Rain / Storm streak with depth perspective
        final slant = isStorm ? -6.0 - depth * 8 : -2.0 - depth * 4;
        final len = p.length * (0.5 + depth * 0.8);
        final alpha = (p.opacity * 0.5 + depth * 0.3).clamp(0.0, 0.85);
        final strokeW = (0.7 + depth * 0.9).clamp(0.5, 2.0);

        // Faint glow streak (wide, blurred)
        canvas.drawLine(
          Offset(sx, sy), Offset(sx + slant, sy + len),
          Paint()
            ..color = const Color(0xFF9EC8E8).withValues(alpha: alpha * 0.35)
            ..strokeWidth = strokeW * 2.5
            ..strokeCap = StrokeCap.round,
        );
        // Sharp core streak
        canvas.drawLine(
          Offset(sx, sy), Offset(sx + slant, sy + len),
          Paint()
            ..color = const Color(0xFFCFE8FF).withValues(alpha: alpha)
            ..strokeWidth = strokeW
            ..strokeCap = StrokeCap.round,
        );

        // Ground splash ripple for near (bottom-quarter) drops
        if (sy > h * 0.75 && depth > 0.6) {
          final splashR = (sy - h * 0.75) / (h * 0.25) * 8 * depth;
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(sx + slant, sy + len),
              width: splashR * 2.5,
              height: splashR * 0.6,
            ),
            Paint()
              ..color = const Color(0xFF9EC8E8).withValues(alpha: alpha * 0.3)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.6,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant WeatherPrecipitationPainter oldDelegate) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
//  FogPainter — multi-layer volumetric tendrils
// ─────────────────────────────────────────────────────────────────────────────
class FogPainter extends CustomPainter {
  final double progress;

  FogPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width.isFinite && size.width > 0 ? size.width : 1200.0;
    final h = size.height.isFinite && size.height > 0 ? size.height : 800.0;
    final t = progress * 2 * math.pi;

    // 3 fog layers at different heights and speeds
    final layers = [
      [0.40, 0.08, 50.0, 1.0],   // [baseY, opacity, amplitude, speed]
      [0.52, 0.11, 35.0, 0.65],
      [0.64, 0.15, 25.0, 0.42],
    ];

    for (final layer in layers) {
      final baseY = layer[0] as double;
      final opacity = layer[1] as double;
      final amplitude = layer[2] as double;
      final speed = layer[3] as double;

      final path = Path();
      path.moveTo(0, h * baseY);
      for (double x = 0; x <= w; x += 22) {
        final y = h * baseY
            + math.sin(t * speed + x / 80) * amplitude
            + math.cos(t * speed * 0.7 + x / 130) * (amplitude * 0.4);
        path.lineTo(x, y);
      }
      path.lineTo(w, h);
      path.lineTo(0, h);
      path.close();

      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            colors: [
              const Color(0xFF94A3B8).withValues(alpha: opacity),
              const Color(0xFF64748B).withValues(alpha: opacity * 0.55),
              Colors.transparent,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(0, h * baseY, w, h - h * baseY)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant FogPainter oldDelegate) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
//  MountainPainter — 3-layer parallax silhouette with snow caps & ridge detail
// ─────────────────────────────────────────────────────────────────────────────
class MountainPainter extends CustomPainter {
  final RideOSWeatherMode mode;

  MountainPainter({required this.mode});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width.isFinite && size.width > 0 ? size.width : 1200.0;
    final h = size.height.isFinite && size.height > 0 ? size.height : 800.0;

    final isSunset = mode == RideOSWeatherMode.sunset;
    final isSnow = mode == RideOSWeatherMode.snow;

    // ── Far mountain range ──────────────────────────────────────────────────
    final farColor = isSunset
        ? const Color(0xFF3D0D50).withValues(alpha: 0.42)
        : const Color(0xFF0D1522).withValues(alpha: 0.50);

    final farPath = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.52)
      ..lineTo(w * 0.10, h * 0.36)
      ..lineTo(w * 0.18, h * 0.48)
      ..lineTo(w * 0.28, h * 0.24)   // main peak
      ..lineTo(w * 0.36, h * 0.42)
      ..lineTo(w * 0.45, h * 0.30)
      ..lineTo(w * 0.52, h * 0.50)
      ..lineTo(w * 0.62, h * 0.18)   // tallest peak
      ..lineTo(w * 0.70, h * 0.38)
      ..lineTo(w * 0.80, h * 0.28)
      ..lineTo(w * 0.90, h * 0.44)
      ..lineTo(w, h * 0.32)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(farPath, Paint()..color = farColor..style = PaintingStyle.fill);

    // ── Mid mountain range ──────────────────────────────────────────────────
    final midColor = isSunset
        ? const Color(0xFF250840).withValues(alpha: 0.72)
        : const Color(0xFF090E1A).withValues(alpha: 0.78);

    final midPath = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.62)
      ..lineTo(w * 0.12, h * 0.45)
      ..lineTo(w * 0.22, h * 0.55)
      ..lineTo(w * 0.35, h * 0.33)
      ..lineTo(w * 0.44, h * 0.58)
      ..lineTo(w * 0.55, h * 0.40)
      ..lineTo(w * 0.68, h * 0.62)
      ..lineTo(w * 0.76, h * 0.38)
      ..lineTo(w * 0.88, h * 0.52)
      ..lineTo(w, h * 0.45)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(midPath, Paint()..color = midColor..style = PaintingStyle.fill);

    // Snow caps on mid range peaks
    if (isSnow || mode == RideOSWeatherMode.clearAurora) {
      _drawSnowCap(canvas, w * 0.35, h * 0.33, 28, 18, w);
      _drawSnowCap(canvas, w * 0.76, h * 0.38, 24, 16, w);
    }

    // ── Near foothills ──────────────────────────────────────────────────────
    final nearColor = isSunset
        ? const Color(0xFF140528).withValues(alpha: 0.90)
        : const Color(0xFF060911).withValues(alpha: 0.92);

    final nearPath = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.72)
      ..lineTo(w * 0.15, h * 0.60)
      ..lineTo(w * 0.28, h * 0.72)
      ..lineTo(w * 0.42, h * 0.55)
      ..lineTo(w * 0.58, h * 0.68)
      ..lineTo(w * 0.70, h * 0.60)
      ..lineTo(w * 0.84, h * 0.70)
      ..lineTo(w, h * 0.62)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(nearPath, Paint()..color = nearColor..style = PaintingStyle.fill);

    // Ridge highlight on near foothills (subtle bright edge)
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.72)
        ..lineTo(w * 0.15, h * 0.60)
        ..lineTo(w * 0.28, h * 0.72)
        ..lineTo(w * 0.42, h * 0.55)
        ..lineTo(w * 0.58, h * 0.68)
        ..lineTo(w * 0.70, h * 0.60)
        ..lineTo(w * 0.84, h * 0.70)
        ..lineTo(w, h * 0.62),
      Paint()
        ..color = (isSunset ? const Color(0xFFF59E0B) : const Color(0xFF00F2FE))
            .withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _drawSnowCap(Canvas canvas, double px, double py, double halfW, double capH, double screenW) {
    final capPath = Path()
      ..moveTo(px, py)
      ..lineTo(px - halfW, py + capH)
      ..lineTo(px + halfW, py + capH)
      ..close();
    canvas.drawPath(capPath, Paint()..color = Colors.white.withValues(alpha: 0.72)..style = PaintingStyle.fill);
    // Soft shadow under snow
    canvas.drawPath(capPath, Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant MountainPainter oldDelegate) =>
      oldDelegate.mode != mode;
}
