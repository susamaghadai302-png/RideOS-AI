import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/widgets/cinematic_background.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_system/rideo_logo.dart';
import '../../../../core/design_system/theme_engine.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CINEMATIC SPLASH SCREEN — RideOS AI
//
//  Sequence (total ≈ 4.4 s):
//    0.00–0.80  Deep-space atmosphere blooms (opacity + scale)
//    0.30–1.40  Aurora orbs shimmer in from edges
//    0.60–1.80  Logo + wordmark scale-fade in  (Curves.easeOutBack)
//    1.20–2.30  Road-pulse line draws L→R
//    1.60–2.80  Tagline + kernel badge fade
//    2.80–4.40  2 s hold, then full-screen fade-to-black exit
// ─────────────────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  final VoidCallback onInitialized;
  const SplashScreen({super.key, required this.onInitialized});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // ── Master sequence (drives all non-looping animations)
  late AnimationController _seq;      // 0 → 1 over 4 400 ms

  // ── Looping ambient controllers
  late AnimationController _radar;    // 2 400 ms loop
  late AnimationController _road;     // 1 600 ms loop
  late AnimationController _orb;      // 3 600 ms loop (aurora orbs)

  // ── Derived animations (seq-driven)
  late Animation<double> _atmAnim;    // atmosphere bloom
  late Animation<double> _orbAnim;    // aurora orb opacity
  late Animation<double> _logoAnim;   // logo scale + opacity
  late Animation<double> _lineAnim;   // road pulse line
  late Animation<double> _tagAnim;    // tagline + badge
  late Animation<double> _exitAnim;   // full-screen exit fade (0→1 = black)

  bool _done = false;
  Timer? _guard;

  static const Duration _total = Duration(milliseconds: 4400);

  @override
  void initState() {
    super.initState();

    _seq   = AnimationController(vsync: this, duration: _total);
    _radar = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
    _road  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
    _orb   = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600))..repeat(reverse: true);

    _atmAnim  = _interval(0.00, 0.18, Curves.easeOutCubic);
    _orbAnim  = _interval(0.07, 0.32, Curves.easeOut);
    _logoAnim = _interval(0.14, 0.42, Curves.easeOutBack);
    _lineAnim = _interval(0.28, 0.55, Curves.easeOutCubic);
    _tagAnim  = _interval(0.38, 0.65, Curves.easeOut);
    // exit: from 0.636 (≈2.8 s) to 1.0 (≈4.4 s) — slow 1.6 s fade-to-black
    _exitAnim = _interval(0.636, 1.0, Curves.easeInCubic);

    _seq.addStatusListener((status) {
      if (status == AnimationStatus.completed) _triggerDone();
    });

    _seq.forward();

    // Safety guard: always complete within 6 s even on slow devices
    _guard = Timer(const Duration(seconds: 6), _triggerDone);
  }

  Animation<double> _interval(double begin, double end, Curve curve) =>
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _seq,
          curve: Interval(begin, end, curve: curve),
        ),
      );

  void _triggerDone() {
    if (_done) return;
    _done = true;
    _guard?.cancel();
    LuxAudioHapticsService.selectionClick();
    widget.onInitialized();
  }

  @override
  void dispose() {
    _seq.dispose();
    _radar.dispose();
    _road.dispose();
    _orb.dispose();
    _guard?.cancel();
    super.dispose();
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = LuxThemeEngine().isDarkMode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: CinematicBackground(child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _triggerDone,
        child: AnimatedBuilder(
          animation: Listenable.merge([_seq, _radar, _road, _orb]),
          builder: (context, _) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // ── 1. Deep-space base gradient ────────────────────────────
                RepaintBoundary(
                  child: Opacity(
                    opacity: _atmAnim.value.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: isDark
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF000000), Color(0xFF040816), Color(0xFF000000)],
                                stops: [0.0, 0.5, 1.0],
                              )
                            : const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFF4F6FA), Color(0xFFE8EEFB), Color(0xFFF4F6FA)],
                              ),
                      ),
                    ),
                  ),
                ),

                // ── 2. Aurora orbs (looping) ──────────────────────────────
                RepaintBoundary(
                  child: Opacity(
                    opacity: (_orbAnim.value * 1.0).clamp(0.0, 1.0),
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _AuroraOrbsPainter(
                        orbProgress: _orb.value,
                        radarProgress: _radar.value,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),

                // ── 3. Grid / atmosphere overlay ─────────────────────────
                RepaintBoundary(
                  child: Opacity(
                    opacity: (_atmAnim.value * 0.6).clamp(0.0, 1.0),
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _GridPainter(isDark: isDark),
                    ),
                  ),
                ),

                // ── 4. Central brand hero ─────────────────────────────────
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo: scale 0.82 → 1.0 + fade
                        Transform.scale(
                          scale: 0.82 + (_logoAnim.value * 0.18),
                          child: Opacity(
                            opacity: _logoAnim.value.clamp(0.0, 1.0),
                            child: const RideoUltimateLogo(
                              size: 88,
                              isVertical: true,
                              showWordmark: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Animated road-pulse line
                        Opacity(
                          opacity: _lineAnim.value.clamp(0.0, 1.0),
                          child: SizedBox(
                            width: 280,
                            height: 36,
                            child: CustomPaint(
                              painter: _RoadLinePainter(
                                lineProgress: _lineAnim.value,
                                pulseProgress: _road.value,
                                isDark: isDark,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Tagline & kernel badge
                        Opacity(
                          opacity: _tagAnim.value.clamp(0.0, 1.0),
                          child: Column(
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [Color(0xFF00D4FF), Color(0xFF0066FF)],
                                ).createShader(bounds),
                                child: Text(
                                  'PREMIUM MOTORCYCLE INTELLIGENCE  |  360 deg AI SAFETY',
                                  style: GoogleFonts.robotoMono(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Glowing kernel badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: const Color(0xFF00F2FE).withValues(alpha: 0.08),
                                  border: Border.all(color: const Color(0xFF00F2FE).withValues(alpha: 0.55), width: 1.3),
                                  boxShadow: [
                                    BoxShadow(color: const Color(0xFF00F2FE).withValues(alpha: 0.28), blurRadius: 20, spreadRadius: -2),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(width: 6, height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF00E676),
                                        boxShadow: [BoxShadow(color: const Color(0xFF00E676).withValues(alpha: 0.7), blurRadius: 6)],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'RideOS AI v5.0  |  ALL SYSTEMS GO',
                                      style: GoogleFonts.robotoMono(
                                        color: const Color(0xFF00F2FE),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
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

                // ── 5. Tap hint (subtle, appears with tagline) ────────────
                Positioned(
                  bottom: 36,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: (_tagAnim.value * 0.5).clamp(0.0, 0.5),
                    child: Text(
                      'Tap to continue',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF94A3B8),
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                // ── 6. Exit vignette (full-screen fade-to-black) ──────────
                if (_exitAnim.value > 0)
                  IgnorePointer(
                    child: Opacity(
                      opacity: _exitAnim.value.clamp(0.0, 1.0),
                      child: const ColoredBox(color: Colors.black),
                    ),
                  ),
              ],
            );
          },
        ),
      )),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PAINTERS
// ─────────────────────────────────────────────────────────────────────────────

class _AuroraOrbsPainter extends CustomPainter {
  final double orbProgress;
  final double radarProgress;
  final bool isDark;
  const _AuroraOrbsPainter({required this.orbProgress, required this.radarProgress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width.isFinite && size.width > 0 ? size.width : 400.0;
    final h = size.height.isFinite && size.height > 0 ? size.height : 800.0;

    final orbs = [
      _Orb(Offset(w * 0.15, h * 0.22), w * 0.55, const Color(0xFF0066FF), 0.12),
      _Orb(Offset(w * 0.88, h * 0.30), w * 0.48, const Color(0xFF8A2BE2), 0.10),
      _Orb(Offset(w * 0.50, h * 0.78), w * 0.60, const Color(0xFF00F2FE), 0.09),
      _Orb(Offset(w * 0.72, h * 0.12), w * 0.36, const Color(0xFFFF5500), 0.08),
    ];

    for (int i = 0; i < orbs.length; i++) {
      final orb = orbs[i];
      // Slight drift using sin/cos
      final phase = (orbProgress + i * 0.22) % 1.0;
      final dx = math.sin(phase * math.pi * 2) * 18.0;
      final dy = math.cos(phase * math.pi * 2) * 12.0;
      final center = orb.center + Offset(dx, dy);

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            orb.color.withValues(alpha: orb.alpha),
            orb.color.withValues(alpha: orb.alpha * 0.3),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: orb.radius));

      canvas.drawCircle(center, orb.radius, paint);
    }

    // Radar ring sweep
    if (isDark) {
      final cyanPaint = Paint()
        ..color = const Color(0xFF00F2FE).withValues(alpha: 0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      final cx = w / 2;
      final cy = h * 0.42;
      for (int r = 1; r <= 4; r++) {
        canvas.drawCircle(Offset(cx, cy), w * 0.18 * r, cyanPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraOrbsPainter old) =>
      old.orbProgress != orbProgress || old.radarProgress != radarProgress;
}

class _Orb {
  final Offset center;
  final double radius;
  final Color color;
  final double alpha;
  const _Orb(this.center, this.radius, this.color, this.alpha);
}

class _GridPainter extends CustomPainter {
  final bool isDark;
  const _GridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width.isFinite && size.width > 0 ? size.width : 400.0;
    final h = size.height.isFinite && size.height > 0 ? size.height : 800.0;
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.025)
      ..strokeWidth = 1.0;
    const step = 44.0;
    for (double x = 0; x <= w; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), paint);
    }
    for (double y = 0; y <= h; y += step) {
      canvas.drawLine(Offset(0, y), Offset(w, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => false;
}

class _RoadLinePainter extends CustomPainter {
  final double lineProgress;
  final double pulseProgress;
  final bool isDark;
  const _RoadLinePainter({required this.lineProgress, required this.pulseProgress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width.isFinite && size.width > 0 ? size.width : 200.0;
    final h = size.height.isFinite && size.height > 0 ? size.height : 30.0;
    final cy = h / 2;

    // Track background
    canvas.drawLine(
      Offset(0, cy), Offset(w, cy),
      Paint()..color = Colors.white.withValues(alpha: 0.08)..strokeWidth = 3..strokeCap = StrokeCap.round,
    );

    final activeW = (w * lineProgress).clamp(0.0, w);
    if (activeW <= 0) return;

    // Glowing route ribbon
    canvas.drawLine(
      Offset(0, cy), Offset(activeW, cy),
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFF00F2FE), Color(0xFF0066FF)])
            .createShader(Rect.fromLTWH(0, 0, activeW, h))
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    // Pulse dot
    final px = activeW * pulseProgress.clamp(0.0, 1.0);
    canvas.drawCircle(Offset(px, cy), 4.5, Paint()..color = const Color(0xFF00F2FE));
    canvas.drawCircle(Offset(px, cy), 8.0,
      Paint()..color = const Color(0xFF00F2FE).withValues(alpha: 0.35)..style = PaintingStyle.stroke..strokeWidth = 2.0);
  }

  @override
  bool shouldRepaint(covariant _RoadLinePainter old) =>
      old.lineProgress != lineProgress || old.pulseProgress != pulseProgress;
}
