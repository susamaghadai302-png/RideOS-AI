import 'dart:math' as math;
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard;

import 'package:flutter/material.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../../../navigation/presentation/screens/navigation_hud_screen.dart';
import '../../../../core/design_system/premium_navigation.dart';

class CockpitCommandCenterScreen extends StatefulWidget {
  const CockpitCommandCenterScreen({super.key});

  @override
  State<CockpitCommandCenterScreen> createState() => _CockpitCommandCenterScreenState();
}

class _CockpitCommandCenterScreenState extends State<CockpitCommandCenterScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final double _speed = 124.0;
  final double _rpm = 9800.0;
  final double _leanAngle = 24.5;
  final double _throttlePercent = 78.0;
  final double _gForce = 1.42;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Background 1: Animated Aurora Liquid Background
          Positioned.fill(
            child: LuxAuroraBackground(
              child: Container(),
            ),
          ),

          // Background 2: Fighter Jet HUD Overlay Grid & Crosshairs
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: FighterJetHudOverlayPainter(pulse: _animController.value),
                  );
                },
              ),
            ),
          ),

          // Main Cockpit HUD Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Column(
                children: [
                  // Top Navigation Header Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: RoadOSColors.platinumWhite, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.6)),
                          boxShadow: LuxShadows.glassGlow(RoadOSColors.cyberCyan),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.flight_takeoff_rounded, color: RoadOSColors.cyberCyan, size: 14),
                            SizedBox(width: 6),
                            Text(
                              'FIGHTER JET AI COCKPIT V2.0',
                              style: TextStyle(color: RoadOSColors.cyberCyan, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_suggest_rounded, color: RoadOSColors.cyberCyan, size: 22),
                        onPressed: () {
                          LuxAudioHapticsService.lightImpact();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Center Hero: Iron Man / Fighter Jet Speedometer & Tachometer Gauge
                  Expanded(
                    flex: 5,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // RPM Radial Arc Painter
                        AnimatedBuilder(
                          animation: _animController,
                          builder: (context, _) {
                            return CustomPaint(
                              size: const Size(280, 280),
                              painter: IronManTachometerPainter(
                                speed: _speed,
                                rpm: _rpm,
                                pulse: _animController.value,
                              ),
                            );
                          },
                        ),

                        // Center Digital Speedometer Display
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _speed.toInt().toString(),
                              style: const TextStyle(
                                fontSize: 76,
                                fontWeight: FontWeight.w900,
                                color: RoadOSColors.platinumWhite,
                                height: 0.9,
                                letterSpacing: -2,
                              ),
                            ),
                            const Text(
                              'KM / H',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: RoadOSColors.cyberCyan,
                                letterSpacing: 3.0,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: RoadOSColors.hyperOrange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: RoadOSColors.hyperOrange, width: 1),
                              ),
                              child: Text(
                                '${_rpm.toInt()} RPM | THROTTLE ${_throttlePercent.toInt()}%',
                                style: const TextStyle(color: RoadOSColors.hyperOrange, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Middle Row: Lean Angle Tilt Gauge & Jarvis Glowing AI Orb
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        // Left: 45 deg Lean Angle Visualizer Card
                        Expanded(
                          child: RoadOSCard(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('LEAN ANGLE TILT', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Transform.rotate(
                                  angle: _leanAngle * (math.pi / 180),
                                  child: const Icon(Icons.two_wheeler_rounded, color: RoadOSColors.cyberCyan, size: 36),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$_leanAngle deg RIGHT',
                                  style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.w900, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Center: Pulsing Jarvis AI Assistant Orb Button
                        GestureDetector(
                          onTap: () {
                            LuxAudioHapticsService.heavyImpact();
                            Navigator.push(context, premiumRoute(const AiAssistantScreen()));
                          },
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LuxGradients.quantumCyan,
                              boxShadow: [
                                BoxShadow(
                                  color: RoadOSColors.cyberCyan.withValues(alpha: 0.6),
                                  blurRadius: 24,
                                  spreadRadius: 6,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.auto_awesome_rounded, color: Colors.black, size: 36),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Right: G-Force & Accelerometer Card
                        Expanded(
                          child: RoadOSCard(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('LATERAL G-FORCE', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                const Icon(Icons.speed_rounded, color: RoadOSColors.hyperOrange, size: 36),
                                const SizedBox(height: 6),
                                Text(
                                  '$_gForce G',
                                  style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.w900, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Bottom Dock Row: Floating Mini Navigation Map Card & Controls
                  RoadOSCard(
                    padding: const EdgeInsets.all(12),
                    onTap: () {
                      LuxAudioHapticsService.mediumImpact();
                      Navigator.push(context, premiumRoute(const NavigationHudScreen()));
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: RoadOSColors.cyberCyan,
                          ),
                          child: const Icon(Icons.turn_right_rounded, color: Colors.black, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('MINI NAVIGATION HUD', style: TextStyle(color: RoadOSColors.cyberCyan, fontSize: 10, fontWeight: FontWeight.bold)),
                              SizedBox(height: 2),
                              Text('In 350m | Turn Right onto Canyon Pass Trail', style: TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                        const Icon(Icons.open_in_full_rounded, color: RoadOSColors.platinumWhite, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FighterJetHudOverlayPainter extends CustomPainter {
  final double pulse;
  FighterJetHudOverlayPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width.isFinite && size.width > 0 ? size.width : 400.0;
    final height = size.height.isFinite && size.height > 0 ? size.height : 400.0;

    final paint = Paint()
      ..color = RoadOSColors.cyberCyan.withValues(alpha: 0.15)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final center = Offset(width / 2, height / 2.4);

    // Crosshair Lines
    canvas.drawLine(Offset(center.dx - 100, center.dy), Offset(center.dx - 20, center.dy), paint);
    canvas.drawLine(Offset(center.dx + 20, center.dy), Offset(center.dx + 100, center.dy), paint);
    canvas.drawLine(Offset(center.dx, center.dy - 100), Offset(center.dx, center.dy - 20), paint);
    canvas.drawLine(Offset(center.dx, center.dy + 20), Offset(center.dx, center.dy + 100), paint);

    // Outer Target Reticle
    canvas.drawCircle(center, 120 + (pulse * 6), paint);
  }

  @override
  bool shouldRepaint(covariant FighterJetHudOverlayPainter oldDelegate) => oldDelegate.pulse != pulse;
}

class IronManTachometerPainter extends CustomPainter {
  final double speed;
  final double rpm;
  final double pulse;

  IronManTachometerPainter({required this.speed, required this.rpm, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width.isFinite && size.width > 0 ? size.width : 280.0;
    final height = size.height.isFinite && size.height > 0 ? size.height : 280.0;
    final center = Offset(width / 2, height / 2);
    final radius = math.max(10.0, width / 2 - 12);

    final trackPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rpmPaint = Paint()
      ..shader = const SweepGradient(
        colors: [RoadOSColors.cyberCyan, RoadOSColors.hyperOrange, Colors.redAccent],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw Background Radial Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      trackPaint,
    );

    // Draw Active RPM Arc
    final rpmRatio = (rpm / 12000.0).clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5 * rpmRatio,
      false,
      rpmPaint,
    );
  }

  @override
  bool shouldRepaint(covariant IronManTachometerPainter oldDelegate) {
    return oldDelegate.speed != speed || oldDelegate.rpm != rpm || oldDelegate.pulse != pulse;
  }
}
