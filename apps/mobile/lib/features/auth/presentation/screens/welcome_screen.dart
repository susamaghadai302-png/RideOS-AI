import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/widgets/cinematic_background.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import '../../../../core/design_system/premium_navigation.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _radarController;
  late AnimationController _breatheController;
  late Animation<double> _breatheAnim;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..forward();

    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    _breatheAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _radarController.dispose();
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: CinematicBackground(child: Stack(
        children: [
          // Radial background glow
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _breatheController,
              builder: (_, __) => Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.25),
                    radius: 0.85,
                    colors: [
                      const Color(0xFF7C3AED).withValues(alpha: 0.28 * _breatheController.value),
                      const Color(0xFF00F2FE).withValues(alpha: 0.06),
                      Colors.black,
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand wordmark
                  const RoadOSLogo(size: 42, showWordmark: true),
                  const Spacer(flex: 1),

                  // ── Animated Radar Crest ──────────────────────────────
                  Center(
                    child: SizedBox(
                      width: 260,
                      height: 260,
                      child: AnimatedBuilder(
                        animation: Listenable.merge([
                          _radarController,
                          _breatheAnim,
                        ]),
                        builder: (_, __) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer orbit ring
                              Container(
                                width: 252,
                                height: 252,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF7C3AED).withValues(alpha: 0.22),
                                    width: 1.2,
                                  ),
                                ),
                              ),
                              // Rotating radar sweep
                              CustomPaint(
                                size: const Size(252, 252),
                                painter: _RadarSweepPainter(
                                  angle: _radarController.value * 2 * math.pi,
                                ),
                              ),
                              // Mid ring
                              Container(
                                width: 198,
                                height: 198,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF00F2FE).withValues(alpha: 0.30),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF7C3AED).withValues(alpha: _breatheAnim.value * 0.30),
                                      blurRadius: 36,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              // Inner crest
                              Container(
                                width: 128,
                                height: 128,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const RadialGradient(
                                    colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF7C3AED).withValues(
                                        alpha: _breatheAnim.value * 0.65,
                                      ),
                                      blurRadius: 28,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.60),
                                    width: 2,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.speed_rounded,
                                    size: 60,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Subtitle
                  const Center(
                    child: Text(
                      'CONNECTED COCKPIT OS',
                      style: TextStyle(
                        letterSpacing: 3.5,
                        color: RoadOSColors.cyberCyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text(
                      'AI-Powered  |  Hyper-Realtime  |  360 deg Safety',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Sign In
                  RoadOSButton(
                    label: 'Sign In to Cockpit',
                    icon: Icons.login_rounded,
                    gradient: RoadOSGradients.primaryViolet,
                    onPressed: () {
                      LuxAudioHapticsService.selectionClick();
                      Navigator.push(context, premiumRoute(const LoginScreen()));
                    },
                  ),
                  const SizedBox(height: 12),

                  // Create Account
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1.2,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          LuxAudioHapticsService.selectionClick();
                          Navigator.push(context, premiumRoute(const RegisterScreen()));
                        },
                        child: const Center(
                          child: Text(
                            'CREATE ACCOUNT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 16),
                  _buildLegalFooter(),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Ride smarter. Ride safer. RideOS.',
                      style: TextStyle(
                        color: Color(0xFF374151),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
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

  void _showLegalDialog(String title, String content) {
    LuxAudioHapticsService.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D1322),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.3), width: 1.5),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(
                color: RoadOSColors.platinumWhite,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: RoadOSColors.cyberCyan,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('I UNDERSTAND', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalFooter() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _showLegalDialog(
              'Privacy Policy',
              'RideOS-AI processes your motorcycle telemetry, trip statistics, and diagnostics locally on-device with zero unauthorized third-party sharing.',
            ),
            child: const Text(
              'Privacy Policy',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '·',
              style: TextStyle(color: Color(0xFF374151)),
            ),
          ),
          GestureDetector(
            onTap: () => _showLegalDialog(
              'Terms of Service',
              'By using RideOS-AI, you agree that telemetry advisories, lean angle metrics, and safety alerts are assistive tools.',
            ),
            child: const Text(
              'Terms of Service',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Rotating radar sweep painter
// ─────────────────────────────────────────────────────────────────────────────
class _RadarSweepPainter extends CustomPainter {
  final double angle;
  _RadarSweepPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Sweep arc (45 deg sweep)
    const sweepAngle = math.pi / 4;
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: angle - sweepAngle,
        endAngle: angle,
        colors: [
          Colors.transparent,
          const Color(0xFF00F2FE).withValues(alpha: 0.35),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      angle - sweepAngle,
      sweepAngle,
      true,
      sweepPaint,
    );

    // Leading sweep line
    final tipX = center.dx + (radius - 4) * math.cos(angle);
    final tipY = center.dy + (radius - 4) * math.sin(angle);
    canvas.drawLine(
      center,
      Offset(tipX, tipY),
      Paint()
        ..color = const Color(0xFF00F2FE).withValues(alpha: 0.65)
        ..strokeWidth = 1.2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Cross-hair dots at ring intersections
    for (int i = 0; i < 8; i++) {
      final dotAngle = (i / 8) * 2 * math.pi;
      final dx = center.dx + (radius - 4) * math.cos(dotAngle);
      final dy = center.dy + (radius - 4) * math.sin(dotAngle);
      canvas.drawCircle(
        Offset(dx, dy),
        2,
        Paint()..color = const Color(0xFF00F2FE).withValues(alpha: 0.40),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarSweepPainter old) => old.angle != angle;
}
