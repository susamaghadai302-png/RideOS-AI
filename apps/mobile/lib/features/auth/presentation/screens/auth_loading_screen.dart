import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_system/roados_tokens.dart';

/// Premium auth-state loading screen shown during [AuthInitialState] and
/// [AuthLoadingState]. Uses a cinematic deep-space aesthetic consistent with
/// the rest of the RideOS-AI design language.
///
/// This screen appears for the brief moment between the splash completing
/// and the auth state resolving from the backend — typically < 500 ms.
class AuthLoadingScreen extends StatefulWidget {
  const AuthLoadingScreen({super.key});

  @override
  State<AuthLoadingScreen> createState() => _AuthLoadingScreenState();
}

class _AuthLoadingScreenState extends State<AuthLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _fadeController;

  late Animation<double> _pulseAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _pulseAnim = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060C),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _pulseController,
          _rotateController,
          _fadeController,
        ]),
        builder: (context, _) {
          return Opacity(
            opacity: _fadeAnim.value,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Deep-space base ──────────────────────────────────────
                Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.0, -0.2),
                      radius: 1.2,
                      colors: [
                        Color(0xFF080C1A),
                        Color(0xFF04060C),
                      ],
                    ),
                  ),
                ),

                // ── Ambient orbs ─────────────────────────────────────────
                Positioned(
                  left: -80,
                  top: -60,
                  child: _buildOrb(
                    size: 320,
                    color: const Color(0xFF7C3AED),
                    opacity: 0.08 * _pulseAnim.value,
                  ),
                ),
                Positioned(
                  right: -60,
                  bottom: 80,
                  child: _buildOrb(
                    size: 280,
                    color: const Color(0xFF00F2FE),
                    opacity: 0.06 * _pulseAnim.value,
                  ),
                ),

                // ── Center content ───────────────────────────────────────
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Rotating arc ring with center logo
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer spinning arc
                            Transform.rotate(
                              angle: _rotateController.value * 2 * math.pi,
                              child: CustomPaint(
                                size: const Size(120, 120),
                                painter: _ArcRingPainter(
                                  color: RoadOSColors.cyberCyan,
                                  sweepFraction: 0.72,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            ),
                            // Counter-rotating inner arc
                            Transform.rotate(
                              angle:
                                  -_rotateController.value * 2 * math.pi * 0.6,
                              child: CustomPaint(
                                size: const Size(90, 90),
                                painter: _ArcRingPainter(
                                  color: RoadOSColors.hyperOrange,
                                  sweepFraction: 0.45,
                                  strokeWidth: 1.5,
                                ),
                              ),
                            ),
                            // Center icon
                            Transform.scale(
                              scale: _pulseAnim.value,
                              child: Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const RadialGradient(
                                    colors: [
                                      Color(0xFF1A0A3E),
                                      Color(0xFF060B18),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: RoadOSColors.hyperOrange
                                          .withValues(alpha: 0.35 * _pulseAnim.value),
                                      blurRadius: 24,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    'R',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Wordmark
                      Text(
                        'RIDEOS AI',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.90),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 5.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            const LinearGradient(
                              colors: [
                                Color(0xFF00F2FE),
                                Color(0xFF7C3AED),
                              ],
                            ).createShader(bounds),
                        child: Text(
                          'AUTHENTICATING SESSION',
                          style: GoogleFonts.robotoMono(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Dot pulse loading indicator
                      _DotPulse(controller: _pulseController),
                    ],
                  ),
                ),

                // ── Bottom status line ───────────────────────────────────
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: _pulseAnim.value * 0.5,
                    child: Text(
                      'SECURE VEHICLE INTELLIGENCE PLATFORM',
                      style: GoogleFonts.robotoMono(
                        color: const Color(0xFF334155),
                        fontSize: 9,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrb({
    required double size,
    required Color color,
    required double opacity,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: opacity * 0.3),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

// ── Arc ring painter ──────────────────────────────────────────────────────────

class _ArcRingPainter extends CustomPainter {
  final Color color;
  final double sweepFraction; // 0..1
  final double strokeWidth;

  const _ArcRingPainter({
    required this.color,
    required this.sweepFraction,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2 * sweepFraction,
        colors: [
          color.withValues(alpha: 0.0),
          color,
          color.withValues(alpha: 0.9),
        ],
      ).createShader(rect);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * sweepFraction,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcRingPainter old) =>
      old.color != color ||
      old.sweepFraction != sweepFraction ||
      old.strokeWidth != strokeWidth;
}

// ── Dot pulse indicator ───────────────────────────────────────────────────────

class _DotPulse extends StatelessWidget {
  final AnimationController controller;
  const _DotPulse({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Stagger each dot's phase
            final phase = (controller.value + i * 0.28) % 1.0;
            final scale = 0.5 + 0.5 * math.sin(phase * math.pi);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: RoadOSColors.cyberCyan.withValues(alpha: 0.4 + 0.6 * scale),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
