import 'package:flutter/material.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/widgets/cinematic_background.dart';

class ArNavigationHudScreen extends StatefulWidget {
  const ArNavigationHudScreen({super.key});

  @override
  State<ArNavigationHudScreen> createState() => _ArNavigationHudScreenState();
}

class _ArNavigationHudScreenState extends State<ArNavigationHudScreen> with SingleTickerProviderStateMixin {
  late AnimationController _arPulseController;
  final double _speed = 84.0;
  final String _nextInstruction = 'In 180m | Turn Right onto Alpine Pass Way';

  @override
  void initState() {
    super.initState();
    _arPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _arPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: CinematicBackground(child: Stack(
        children: [
          // 1. Live Camera View Simulation Feed
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F141D), Colors.black],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: CustomPaint(
                painter: ArCameraFeedSimPainter(pulse: _arPulseController.value),
              ),
            ),
          ),

          // 2. AR Directional Arrow & Road Hazard Overlay
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _arPulseController,
              builder: (context, _) {
                return CustomPaint(
                  painter: ArNavArrowOverlayPainter(pulse: _arPulseController.value),
                );
              },
            ),
          ),

          // 3. Top Telematics Glass Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
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
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: RoadOSColors.cyberCyan),
                          boxShadow: LuxShadows.glassGlow(RoadOSColors.cyberCyan),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.view_in_ar_rounded, color: RoadOSColors.cyberCyan, size: 14),
                            SizedBox(width: 6),
                            Text(
                              'LIVE AR HUD VISION V2.0',
                              style: TextStyle(color: RoadOSColors.cyberCyan, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.camera_enhance_rounded, color: RoadOSColors.cyberCyan, size: 22),
                        onPressed: () {
                          LuxAudioHapticsService.lightImpact();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Maneuver Banner
                  RoadOSCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LuxGradients.quantumCyan,
                          ),
                          child: const Icon(Icons.turn_right_rounded, color: Colors.black, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('AUGMENTED MANEUVER', style: TextStyle(color: RoadOSColors.cyberCyan, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(_nextInstruction, style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Bottom Speed & Telematics Badge
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: RoadOSCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Text(
                            _speed.toInt().toString(),
                            style: const TextStyle(color: RoadOSColors.platinumWhite, fontSize: 36, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(width: 8),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('KM/H', style: TextStyle(color: RoadOSColors.hyperOrange, fontWeight: FontWeight.w900, fontSize: 11)),
                              Text('LIMIT 90', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: RoadOSCard(
                      padding: EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(Icons.shield_rounded, color: RoadOSColors.apexEmerald, size: 28),
                          SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('AR HAZARD SCAN', style: TextStyle(color: RoadOSColors.apexEmerald, fontWeight: FontWeight.bold, fontSize: 10)),
                              Text('ROAD CLEAR', style: TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      )),
    );
  }
}

class ArCameraFeedSimPainter extends CustomPainter {
  final double pulse;
  const ArCameraFeedSimPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = RoadOSColors.cyberCyan.withValues(alpha: 0.1)
      ..strokeWidth = 1.0;

    // Horizon Line
    final horizonY = size.height * 0.5;
    canvas.drawLine(Offset(0, horizonY), Offset(size.width, horizonY), gridPaint);

    // Perspective Road Lines
    canvas.drawLine(Offset(size.width * 0.5, horizonY), Offset(0, size.height), gridPaint);
    canvas.drawLine(Offset(size.width * 0.5, horizonY), Offset(size.width, size.height), gridPaint);
  }

  @override
  bool shouldRepaint(covariant ArCameraFeedSimPainter oldDelegate) => oldDelegate.pulse != pulse;
}

class ArNavArrowOverlayPainter extends CustomPainter {
  final double pulse;
  const ArNavArrowOverlayPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.65);

    final arrowPaint = Paint()
      ..color = RoadOSColors.cyberCyan
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6.0);

    final arrowPath = Path();
    arrowPath.moveTo(center.dx - 40, center.dy + 40);
    arrowPath.lineTo(center.dx, center.dy - 30 - (pulse * 10));
    arrowPath.lineTo(center.dx + 40, center.dy + 40);

    canvas.drawPath(arrowPath, arrowPaint);

    // Dynamic Waypoint Ring
    final ringPaint = Paint()
      ..color = RoadOSColors.hyperOrange.withValues(alpha: 0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.55), 24 + (pulse * 6), ringPaint);
  }

  @override
  bool shouldRepaint(covariant ArNavArrowOverlayPainter oldDelegate) => oldDelegate.pulse != pulse;
}
