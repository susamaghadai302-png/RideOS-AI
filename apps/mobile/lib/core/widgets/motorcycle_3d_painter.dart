import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../design_system/roados_components.dart';
import '../services/lux_haptics_audio_service.dart';

enum SuperbikeModelType {
  yamahaR1M('Yamaha', 'YZF-R1M', 2024, '998 cc', '200 HP', Color(0xFF0033A0), Color(0xFFC0C0C0)),
  ducatiPanigaleV4('Ducati', 'Panigale V4 S', 2024, '1103 cc', '215.5 HP', Color(0xFFD60000), Color(0xFF1A1A1A)),
  bmwS1000RR('BMW', 'S 1000 RR M', 2024, '999 cc', '205 HP', Color(0xFFFFFFFF), Color(0xFF003399));

  final String make;
  final String model;
  final int year;
  final String cc;
  final String hp;
  final Color primaryColor;
  final Color secondaryColor;

  const SuperbikeModelType(this.make, this.model, this.year, this.cc, this.hp, this.primaryColor, this.secondaryColor);

  static SuperbikeModelType fromName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('ducati') || lower.contains('panigale')) {
      return SuperbikeModelType.ducatiPanigaleV4;
    } else if (lower.contains('bmw') || lower.contains('s1000rr') || lower.contains('1000')) {
      return SuperbikeModelType.bmwS1000RR;
    }
    return SuperbikeModelType.yamahaR1M;
  }
}

class Motorcycle3dWidget extends StatefulWidget {
  final String bikeName;
  final String bikeSpec;
  final double size;
  final Color primaryColor;

  const Motorcycle3dWidget({
    super.key,
    required this.bikeName,
    required this.bikeSpec,
    this.size = 320,
    this.primaryColor = RoadOSColors.hyperOrange,
  });

  @override
  State<Motorcycle3dWidget> createState() => _Motorcycle3dWidgetState();
}

class _Motorcycle3dWidgetState extends State<Motorcycle3dWidget> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  double _userAngleOffset = -0.45; // 3/4 front camera perspective
  double _scale = 1.0;
  double _baseScale = 1.0;
  bool _engineActive = true;
  bool _isAutoRotating = false;
  bool _isLoading = true;
  Timer? _loadingTimer;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    );

    // Simulate showroom studio asset initialization
    _loadingTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bikeType = SuperbikeModelType.fromName(widget.bikeName);

    return GestureDetector(
      onScaleStart: (details) {
        _baseScale = _scale;
      },
      onScaleUpdate: (details) {
        setState(() {
          _scale = (_baseScale * details.scale).clamp(0.8, 2.2);
          if (details.pointerCount == 1) {
            _userAngleOffset += details.focalPointDelta.dx * 0.012;
          }
        });
      },
      onDoubleTap: () {
        LuxAudioHapticsService.mediumImpact();
        setState(() {
          _scale = 1.0;
          _userAngleOffset = -0.45;
          _isAutoRotating = !_isAutoRotating;
          if (_isAutoRotating) {
            _rotationController.repeat();
          } else {
            _rotationController.stop();
          }
        });
      },
      child: Column(
        children: [
          Container(
            width: widget.size,
            height: widget.size * 0.78,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: widget.primaryColor.withValues(alpha: 0.3), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.8),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Studio Stage Background with Ceiling Spotlight & Dark Reflective Floor
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(0, -0.6),
                          radius: 1.1,
                          colors: [
                            Color(0xFF1E2838),
                            Color(0xFF0C101A),
                            Color(0xFF04060A),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 2. 3D Motorcycle Showroom Render
                  if (_isLoading)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: widget.primaryColor, strokeWidth: 2.5),
                        const SizedBox(height: 12),
                        const Text(
                          'LOADING 3D VEHICLE STUDIO...',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: RoadOSColors.cyberCyan,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    )
                  else
                    Transform.scale(
                      scale: _scale,
                      child: AnimatedBuilder(
                        animation: _rotationController,
                        builder: (context, child) {
                          final currentAngle = (_isAutoRotating ? (_rotationController.value * 2 * math.pi) : 0.0) + _userAngleOffset;
                          return CustomPaint(
                            size: Size(widget.size, widget.size * 0.78),
                            painter: RealisticMotorcycle3DPainter(
                              angle: currentAngle,
                              bikeType: bikeType,
                              liveryColor: widget.primaryColor,
                              engineActive: _engineActive,
                              progress: _rotationController.value,
                            ),
                          );
                        },
                      ),
                    ),

                  // 3. HUD Controls: Camera Orbit Pill
                  Positioned(
                    top: 10,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.rotate_90_degrees_cw_rounded, color: RoadOSColors.cyberCyan, size: 14),
                          const SizedBox(width: 5),
                          Text(
                            '3D CAMERA | ${(_scale * 100).toInt()}%',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: RoadOSColors.platinumWhite),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 4. Engine Ignition Power Pill
                  Positioned(
                    top: 10,
                    right: 12,
                    child: GestureDetector(
                      onTap: () {
                        LuxAudioHapticsService.lightImpact();
                        setState(() => _engineActive = !_engineActive);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _engineActive ? RoadOSColors.apexEmerald.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _engineActive ? RoadOSColors.apexEmerald : RoadOSColors.textMuted),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.power_settings_new_rounded, color: _engineActive ? RoadOSColors.apexEmerald : RoadOSColors.textMuted, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              _engineActive ? 'ENGINE RUNNING' : 'ENGINE OFF',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: _engineActive ? RoadOSColors.apexEmerald : RoadOSColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.bikeName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: RoadOSColors.platinumWhite, letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.bikeSpec} | Touch & drag to rotate 360 deg',
            style: TextStyle(fontSize: 11, color: widget.primaryColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// Photorealistic 3D PBR Custom Painter for Superbikes (Yamaha R1M, Ducati V4 S, BMW S1000RR)
class RealisticMotorcycle3DPainter extends CustomPainter {
  final double angle;
  final SuperbikeModelType bikeType;
  final Color liveryColor;
  final bool engineActive;
  final double progress;

  RealisticMotorcycle3DPainter({
    required this.angle,
    required this.bikeType,
    required this.liveryColor,
    required this.engineActive,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final center = Offset(width / 2, height * 0.55);

    final cosA = math.cos(angle);
    final sinA = math.sin(angle);

    // -------------------------------------------------------------
    // 1. Studio Reflective Floor Stage & Drop Shadow
    // -------------------------------------------------------------
    final floorCenter = Offset(center.dx, height * 0.84);
    final floorRadiusX = width * 0.44;
    const floorRadiusY = 32.0;

    final floorReflectPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          liveryColor.withValues(alpha: 0.35),
          RoadOSColors.cyberCyan.withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCenter(center: floorCenter, width: floorRadiusX * 2, height: floorRadiusY * 2));

    canvas.drawOval(
      Rect.fromCenter(center: floorCenter, width: floorRadiusX * 2, height: floorRadiusY * 2),
      floorReflectPaint,
    );

    // Ambient Occlusion Contact Shadow under tires
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, floorCenter.dy - 4), width: width * 0.65, height: 18),
      shadowPaint,
    );

    // -------------------------------------------------------------
    // 2. 3D Coordinate Projection Setup
    // -------------------------------------------------------------
    final bikeLength = width * 0.32;
    final rearPos = Offset(center.dx - (bikeLength * cosA), center.dy - (bikeLength * sinA * 0.18));
    final frontPos = Offset(center.dx + (bikeLength * cosA), center.dy + (bikeLength * sinA * 0.18));

    final wheelRadius = width * 0.145;

    // -------------------------------------------------------------
    // 3. Rear Wheel & Brake Disc & Drive Chain Assembly
    // -------------------------------------------------------------
    _drawWheel(canvas, rearPos, wheelRadius, isFront: false, accent: liveryColor, spinAngle: progress * 10 * math.pi);
    _drawSwingarmAndChain(canvas, rearPos, center, cosA, sinA);

    // -------------------------------------------------------------
    // 4. Engine Block, Frame & Exhaust System
    // -------------------------------------------------------------
    _drawEngineAndExhaust(canvas, center, rearPos, frontPos, cosA, sinA, engineActive, progress);

    // -------------------------------------------------------------
    // 5. Front Wheel, Dual Brake Discs & Upside-Down Gold Forks
    // -------------------------------------------------------------
    _drawWheel(canvas, frontPos, wheelRadius, isFront: true, accent: liveryColor, spinAngle: progress * 10 * math.pi);
    _drawFrontForksAndHandlebars(canvas, frontPos, center, cosA, sinA);

    // -------------------------------------------------------------
    // 6. Sculpted Main Fairings, Fuel Tank & Tail Section
    // -------------------------------------------------------------
    _drawBikeBodywork(canvas, center, rearPos, frontPos, cosA, sinA);

    // -------------------------------------------------------------
    // 7. LED Headlights & Tinted Aerodynamic Windscreen
    // -------------------------------------------------------------
    _drawHeadlightsAndScreen(canvas, frontPos, center, cosA, sinA);
  }

  void _drawWheel(Canvas canvas, Offset pos, double radius, {required bool isFront, required Color accent, required double spinAngle}) {
    // Tire Rubber Thread
    final tirePaint = Paint()
      ..color = const Color(0xFF12141A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15;

    final tireTreadPaint = Paint()
      ..color = const Color(0xFF222633)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(pos, radius, tirePaint);
    canvas.drawCircle(pos, radius, tireTreadPaint);

    // Black Alloy Rim
    final rimPaint = Paint()
      ..color = (bikeType == SuperbikeModelType.yamahaR1M)
          ? const Color(0xFF0033A0)
          : (bikeType == SuperbikeModelType.ducatiPanigaleV4)
              ? const Color(0xFFD60000)
              : const Color(0xFF1E2430)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(pos, radius * 0.72, rimPaint);

    // Dual Drilled Brake Disc & Caliper
    final discPaint = Paint()
      ..color = const Color(0xFF6B7280)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(pos, radius * 0.48, discPaint);

    // Caliper
    final caliperPaint = Paint()..color = (bikeType == SuperbikeModelType.bmwS1000RR) ? const Color(0xFF0055FF) : const Color(0xFFD97706);
    canvas.drawCircle(Offset(pos.dx + (isFront ? -8 : 8), pos.dy - 6), 5, caliperPaint);

    // Rim Spokes
    for (int i = 0; i < 5; i++) {
      final a = spinAngle + (i * 2 * math.pi / 5);
      final spokeEnd = Offset(pos.dx + math.cos(a) * (radius * 0.70), pos.dy + math.sin(a) * (radius * 0.70));
      canvas.drawLine(pos, spokeEnd, rimPaint);
    }
  }

  void _drawSwingarmAndChain(Canvas canvas, Offset rearPos, Offset center, double cosA, double sinA) {
    final swingarmPaint = Paint()
      ..color = const Color(0xFF374151)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    final pivotPos = Offset(center.dx - (25 * cosA), center.dy + 12);
    canvas.drawLine(pivotPos, rearPos, swingarmPaint);

    final chainPaint = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawLine(Offset(pivotPos.dx, pivotPos.dy + 4), Offset(rearPos.dx, rearPos.dy + 4), chainPaint);
  }

  void _drawEngineAndExhaust(Canvas canvas, Offset center, Offset rearPos, Offset frontPos, double cosA, double sinA, bool active, double progress) {
    // Engine Block Case
    final engineRect = Rect.fromCenter(center: Offset(center.dx - (5 * cosA), center.dy + 8), width: 55, height: 42);
    final enginePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF2C3545), Color(0xFF111827), Color(0xFF1F2937)],
      ).createShader(engineRect);

    canvas.drawRRect(RRect.fromRectAndRadius(engineRect, const Radius.circular(8)), enginePaint);

    // Titanium Exhaust Pipes & Canister
    final exhaustPath = Path();
    exhaustPath.moveTo(center.dx - (10 * cosA), center.dy + 18);
    exhaustPath.lineTo(rearPos.dx - (20 * cosA), rearPos.dy - 8);

    final exhaustPaint = Paint()
      ..color = const Color(0xFF9CA3AF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(exhaustPath, exhaustPaint);

    // Carbon Exhaust Tip
    final tipPaint = Paint()..color = const Color(0xFF1F2937);
    canvas.drawCircle(Offset(rearPos.dx - (20 * cosA), rearPos.dy - 8), 5.5, tipPaint);

    // Exhaust Backfire Flame Animation when active
    if (active) {
      final flamePos = Offset(rearPos.dx - (28 * cosA), rearPos.dy - 10);
      final flamePaint = Paint()
        ..shader = RadialGradient(
          colors: [liveryColor, RoadOSColors.cyberCyan, Colors.transparent],
        ).createShader(Rect.fromCircle(center: flamePos, radius: 18));
      canvas.drawCircle(flamePos, 12 + math.sin(progress * 30) * 4, flamePaint);
    }
  }

  void _drawFrontForksAndHandlebars(Canvas canvas, Offset frontPos, Offset center, double cosA, double sinA) {
    // Gold Öhlins USD Forks
    final forkPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round;

    final handlebarPos = Offset(center.dx + (40 * cosA), center.dy - 48);
    canvas.drawLine(frontPos, handlebarPos, forkPaint);

    // Handlebars & Rear-View Mirror
    final barPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawLine(handlebarPos, Offset(handlebarPos.dx - 12, handlebarPos.dy - 6), barPaint);
    canvas.drawCircle(Offset(handlebarPos.dx - 14, handlebarPos.dy - 12), 4, Paint()..color = Colors.black87);
  }

  void _drawBikeBodywork(Canvas canvas, Offset center, Offset rearPos, Offset frontPos, double cosA, double sinA) {
    Color bodyBaseColor;
    Color accentColor;

    switch (bikeType) {
      case SuperbikeModelType.yamahaR1M:
        bodyBaseColor = const Color(0xFF0033A0);
        accentColor = const Color(0xFFD1D5DB); // Silver / Carbon
        break;
      case SuperbikeModelType.ducatiPanigaleV4:
        bodyBaseColor = const Color(0xFFD60000);
        accentColor = const Color(0xFF1F2937);
        break;
      case SuperbikeModelType.bmwS1000RR:
        bodyBaseColor = Colors.white;
        accentColor = const Color(0xFF003399);
        break;
    }

    final bodyPath = Path();
    bodyPath.moveTo(frontPos.dx + (10 * cosA), center.dy - 35);
    bodyPath.lineTo(center.dx + (25 * cosA), center.dy - 58); // Fuel Tank Top
    bodyPath.lineTo(center.dx - (10 * cosA), center.dy - 38); // Rider Seat Dip
    bodyPath.lineTo(rearPos.dx - (10 * cosA), rearPos.dy - 34); // Tail Section
    bodyPath.lineTo(center.dx - (15 * cosA), center.dy + 8); // Lower Bellypan
    bodyPath.lineTo(frontPos.dx - (10 * cosA), center.dy - 12);
    bodyPath.close();

    final bodyGradient = LinearGradient(
      colors: [
        bodyBaseColor,
        accentColor,
        bodyBaseColor.withValues(alpha: 0.8),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromCircle(center: center, radius: 100));

    final bodyPaint = Paint()
      ..shader = bodyGradient
      ..style = PaintingStyle.fill;

    canvas.drawPath(bodyPath, bodyPaint);

    // Aerodynamic Winglets for Ducati & BMW
    if (bikeType == SuperbikeModelType.ducatiPanigaleV4 || bikeType == SuperbikeModelType.bmwS1000RR) {
      final wingletPath = Path();
      wingletPath.moveTo(center.dx + (28 * cosA), center.dy - 22);
      wingletPath.lineTo(center.dx + (42 * cosA), center.dy - 18);
      wingletPath.lineTo(center.dx + (30 * cosA), center.dy - 12);
      wingletPath.close();

      canvas.drawPath(wingletPath, Paint()..color = const Color(0xFF111827));
    }

    // Leather Rider Seat
    final seatPath = Path();
    seatPath.moveTo(center.dx - (5 * cosA), center.dy - 38);
    seatPath.quadraticBezierTo(center.dx - (20 * cosA), center.dy - 36, center.dx - (35 * cosA), center.dy - 32);
    seatPath.lineTo(center.dx - (5 * cosA), center.dy - 28);
    seatPath.close();

    canvas.drawPath(seatPath, Paint()..color = const Color(0xFF111827));
  }

  void _drawHeadlightsAndScreen(Canvas canvas, Offset frontPos, Offset center, double cosA, double sinA) {
    // Tinted Front Windscreen
    final screenPath = Path();
    final topFront = Offset(center.dx + (35 * cosA), center.dy - 65);
    screenPath.moveTo(topFront.dx, topFront.dy);
    screenPath.lineTo(topFront.dx + (14 * cosA), topFront.dy + 18);
    screenPath.lineTo(topFront.dx - (8 * cosA), topFront.dy + 20);
    screenPath.close();

    final screenPaint = Paint()
      ..color = RoadOSColors.cyberCyan.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    canvas.drawPath(screenPath, screenPaint);

    // Twin LED Projector Headlights
    final headlightPos = Offset(topFront.dx + (12 * cosA), topFront.dy + 22);
    final glowPaint = Paint()
      ..color = RoadOSColors.cyberCyan
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 8);

    canvas.drawCircle(headlightPos, 7, glowPaint);
    canvas.drawCircle(headlightPos, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant RealisticMotorcycle3DPainter oldDelegate) {
    return oldDelegate.angle != angle ||
        oldDelegate.bikeType != bikeType ||
        oldDelegate.liveryColor != liveryColor ||
        oldDelegate.engineActive != engineActive ||
        oldDelegate.progress != progress;
  }
}
