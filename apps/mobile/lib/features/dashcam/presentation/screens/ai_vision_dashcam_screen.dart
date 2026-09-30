import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard;
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/widgets/roados_visual_environment.dart';
import 'package:camera/camera.dart';

class AiVisionDashcamScreen extends StatefulWidget {
  const AiVisionDashcamScreen({super.key});
  @override
  State<AiVisionDashcamScreen> createState() => _AiVisionDashcamScreenState();
}

class _AiVisionDashcamScreenState extends State<AiVisionDashcamScreen>
    with TickerProviderStateMixin {
  late AnimationController _driveController;   // road animation
  late AnimationController _scanController;    // radar scan ring
  late AnimationController _pulseController;   // REC dot pulse
  bool _recordingActive = true;
  bool _sentryMode = false;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  // Live telemetry values (simulated)
  final double _speed = 62.0;
  final int _threatCount = 0;

  @override
  void initState() {
    super.initState();
    _driveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..forward();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  @override
  void dispose() {
    _driveController.dispose();
    _scanController.dispose();
    _pulseController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RoadOSVisualEnvironment(
        environmentType: RoadOSEnvironmentType.notifications,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: LuxResponsiveContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _buildDashcamViewport(),
                  const SizedBox(height: 16),
                  _buildTelemetryBar(),
                  const SizedBox(height: 20),
                  _buildControlsGrid(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('ACTIVE NEURAL VISION STACK'),
                  const SizedBox(height: 12),
                  ..._detectionItems(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _recordingActive
                      ? RoadOSColors.errorCrimson
                      : RoadOSColors.textMuted,
                  boxShadow: _recordingActive
                      ? [BoxShadow(
                          color: RoadOSColors.errorCrimson.withValues(
                              alpha: _pulseController.value * 0.7),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )]
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _recordingActive ? 'RECORDING  |  AI LIVE' : 'STANDBY',
              style: TextStyle(
                color: _recordingActive
                    ? RoadOSColors.errorCrimson
                    : RoadOSColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            LuxAudioHapticsService.selectionClick();
            setState(() => _recordingActive = !_recordingActive);
            showLuxSnack(
              context,
              _recordingActive
                  ? '🔴 AI Vision Recording Started.'
                  : '⏸ Recording Paused.',
              variant: _recordingActive
                  ? LuxSnackVariant.error
                  : LuxSnackVariant.info,
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              border: Border.all(
                color: _recordingActive
                    ? RoadOSColors.errorCrimson
                    : RoadOSColors.apexEmerald,
              ),
              borderRadius: BorderRadius.circular(20),
              color: (_recordingActive
                      ? RoadOSColors.errorCrimson
                      : RoadOSColors.apexEmerald)
                  .withValues(alpha: 0.12),
            ),
            child: Row(
              children: [
                Icon(
                  _recordingActive
                      ? Icons.stop_circle_outlined
                      : Icons.fiber_manual_record,
                  color: _recordingActive
                      ? RoadOSColors.errorCrimson
                      : RoadOSColors.apexEmerald,
                  size: 14,
                ),
                const SizedBox(width: 5),
                Text(
                  _recordingActive ? 'STOP REC' : 'START REC',
                  style: TextStyle(
                    color: _recordingActive
                        ? RoadOSColors.errorCrimson
                        : RoadOSColors.apexEmerald,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Camera Viewport ────────────────────────────────────────────────────────
  Widget _buildDashcamViewport() {
    return Container(
      height: 275,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF060A12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: RoadOSColors.cyberCyan.withValues(alpha: 0.55),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: RoadOSColors.cyberCyan.withValues(alpha: 0.20),
            blurRadius: 22,
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AnimatedBuilder(
          animation: _driveController,
          builder: (context, _) {
            return Stack(
              children: [
                // Road scene
                if (_isCameraInitialized && _cameraController != null)
                  Positioned.fill(
                    child: CameraPreview(_cameraController!),
                  )
                else
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black,
                    child: const Center(
                      child: Text(
                        'HARDWARE MODULE NOT CONNECTED\n(Camera feed unavailable)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: RoadOSColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // AI scan sweep ring
                AnimatedBuilder(
                  animation: _scanController,
                  builder: (_, __) => CustomPaint(
                    size: const Size(double.infinity, 275),
                    painter: _AiScanPainter(progress: _scanController.value),
                  ),
                ),

                // Corner bracket overlays (camera HUD frame)
                const _CameraCornerBrackets(),

                // Top status strip
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.75),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'REC ${_formatTimestamp()}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: RoadOSColors.errorCrimson,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: RoadOSColors.cyberCyan),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'AI VISION 2.4  |  14ms',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: RoadOSColors.cyberCyan,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom HUD telemetry strip
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.80),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'LAT: 36.7783 degN  LON: 119.4179 degW',
                          style: TextStyle(
                            fontSize: 9,
                            color: RoadOSColors.textMuted
                                .withValues(alpha: 0.8),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.speed_rounded,
                                color: RoadOSColors.hyperOrange, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              '${_speed.toStringAsFixed(0)} MPH',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: RoadOSColors.hyperOrange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Threat count badge (top-right corner)
                Positioned(
                  top: 30, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: RoadOSColors.errorCrimson,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_threatCount THREATS',
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatTimestamp() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2,"0")}:'
        '${now.minute.toString().padLeft(2,"0")}:'
        '${now.second.toString().padLeft(2,"0")}';
  }

  // ── Live telemetry bar ─────────────────────────────────────────────────────
  Widget _buildTelemetryBar() {
    final stats = [
      ('THREATS', '$_threatCount', RoadOSColors.errorCrimson),
      ('SPEED', '${_speed.toStringAsFixed(0)} mph', RoadOSColors.hyperOrange),
      ('LATENCY', '14 ms', RoadOSColors.apexEmerald),
      ('ACCURACY', '99.4%', RoadOSColors.cyberCyan),
    ];
    return RoadOSCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      borderColor: RoadOSColors.cyberCyan,
      child: Row(
        children: stats.map((s) {
          return Expanded(
            child: Column(
              children: [
                Text(s.$1,
                    style: const TextStyle(
                        color: RoadOSColors.textMuted,
                        fontSize: 9,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(s.$2,
                    style: TextStyle(
                        color: s.$3,
                        fontSize: 14,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Controls grid ──────────────────────────────────────────────────────────
  Widget _buildControlsGrid() {
    return Row(
      children: [
        Expanded(
          child: RoadOSCard(
            borderColor: RoadOSColors.hyperOrange,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.shield_outlined,
                        color: RoadOSColors.hyperOrange, size: 22),
                    Switch.adaptive(
                      value: _sentryMode,
                      activeTrackColor: RoadOSColors.hyperOrange,
                      onChanged: (val) {
                        LuxAudioHapticsService.selectionClick();
                        setState(() => _sentryMode = val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('PARKING SENTRY',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: RoadOSColors.platinumWhite)),
                const SizedBox(height: 2),
                const Text('Auto-record on impact',
                    style: TextStyle(
                        fontSize: 10, color: RoadOSColors.textMuted)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: RoadOSCard(
            borderColor: RoadOSColors.cyberCyan,
            padding: EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.memory_rounded,
                    color: RoadOSColors.cyberCyan, size: 22),
                SizedBox(height: 14),
                Text('NEURAL CHIP',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: RoadOSColors.platinumWhite)),
                SizedBox(height: 2),
                Text('15.4 TOPS Active',
                    style: TextStyle(
                        fontSize: 10,
                        color: RoadOSColors.apexEmerald,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Detection items ────────────────────────────────────────────────────────
  List<Widget> _detectionItems() {
    final items = [
      (Icons.memory_rounded, RoadOSColors.textMuted,
          'AWAITING HARDWARE', 'NO NEURAL CO-PROCESSOR',
          'Live Vision requires RoadOS Neural Edge Module'),
    ];
    return items.map((i) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _DetectionItem(
        icon: i.$1,
        iconColor: i.$2,
        title: i.$3,
        status: i.$4,
        sub: i.$5,
      ),
    )).toList();
  }

  Widget _buildSectionHeader(String title) => Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: RoadOSColors.textMuted,
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
//  _CameraCornerBrackets — fixed HUD frame corners
// ─────────────────────────────────────────────────────────────────────────────
class _CameraCornerBrackets extends StatelessWidget {
  const _CameraCornerBrackets();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _FrameBracketPainter(),
      ),
    );
  }
}

class _FrameBracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const arm = 22.0;
    const margin = 10.0;

    final paint = Paint()
      ..color = RoadOSColors.cyberCyan.withValues(alpha: 0.55)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final corner in [
      [const Offset(margin, margin + arm), const Offset(margin, margin), const Offset(margin + arm, margin)],
      [Offset(w - margin - arm, margin), Offset(w - margin, margin), Offset(w - margin, margin + arm)],
      [Offset(margin, h - margin - arm), Offset(margin, h - margin), Offset(margin + arm, h - margin)],
      [Offset(w - margin - arm, h - margin), Offset(w - margin, h - margin), Offset(w - margin, h - margin - arm)],
    ]) {
      final path = Path()
        ..moveTo(corner[0].dx, corner[0].dy)
        ..lineTo(corner[1].dx, corner[1].dy)
        ..lineTo(corner[2].dx, corner[2].dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FrameBracketPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
//  _AiScanPainter — rotating radar sweep line over the viewport
// ─────────────────────────────────────────────────────────────────────────────
class _AiScanPainter extends CustomPainter {
  final double progress;
  const _AiScanPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.44;
    final angle = progress * 2 * math.pi;
    final radius = size.width * 0.55;

    // Sweep arc (trailing gradient)
    const sweepAngle = math.pi / 3;
    final sweepRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: radius * 2,
      height: radius * 2,
    );
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: angle - sweepAngle,
        endAngle: angle,
        colors: [
          Colors.transparent,
          RoadOSColors.cyberCyan.withValues(alpha: 0.18),
        ],
      ).createShader(sweepRect)
      ..style = PaintingStyle.fill;
    canvas.drawArc(sweepRect, angle - sweepAngle, sweepAngle, true, sweepPaint);

    // Leading line
    final lineEnd = Offset(
      cx + math.cos(angle) * radius,
      cy + math.sin(angle) * radius,
    );
    canvas.drawLine(
      Offset(cx, cy), lineEnd,
      Paint()
        ..color = RoadOSColors.cyberCyan.withValues(alpha: 0.45)
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _AiScanPainter old) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
//  _DetectionItem
// ─────────────────────────────────────────────────────────────────────────────
class _DetectionItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String status;
  final String sub;

  const _DetectionItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.status,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return RoadOSCard(
      borderColor: iconColor,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: RoadOSColors.textMuted,
                        letterSpacing: 0.8)),
                const SizedBox(height: 3),
                Text(status,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: RoadOSColors.platinumWhite)),
                const SizedBox(height: 2),
                Text(sub,
                    style: TextStyle(fontSize: 10, color: iconColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DashcamRoadPainter — hyper-realistic night highway
// ─────────────────────────────────────────────────────────────────────────────
class DashcamRoadPainter extends CustomPainter {
  final double progress;
  const DashcamRoadPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width.isFinite && size.width > 0 ? size.width : 400.0;
    final h = size.height.isFinite && size.height > 0 ? size.height : 275.0;
    final horizonY = h * 0.42;
    final vx = w * 0.5;

    // ── Sky ──────────────────────────────────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, horizonY),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF02040B), Color(0xFF08142A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, w, horizonY)),
    );

    // Stars
    final rng = math.Random(42);
    for (int i = 0; i < 28; i++) {
      final sx = rng.nextDouble() * w;
      final sy = rng.nextDouble() * horizonY * 0.8;
      final sr = rng.nextDouble() * 1.1 + 0.2;
      final shimmer = 0.4 + 0.6 * math.sin(progress * math.pi * 2 + sx * 0.3);
      canvas.drawCircle(
        Offset(sx, sy),
        sr,
        Paint()..color = Colors.white.withValues(alpha: 0.5 * shimmer),
      );
    }

    // Distant city glow on horizon
    canvas.drawRect(
      Rect.fromLTWH(0, horizonY - 8, w, 18),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0xFF00F2FE).withValues(alpha: 0.12),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, horizonY - 8, w, 18)),
    );

    // ── Road surface ─────────────────────────────────────────────────────────
    final roadPath = Path()
      ..moveTo(vx - w * 0.04, horizonY)
      ..lineTo(vx + w * 0.04, horizonY)
      ..lineTo(w + 20, h + 10)
      ..lineTo(-20, h + 10)
      ..close();

    canvas.drawPath(
      roadPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E1520), Color(0xFF060A10)],
        ).createShader(Rect.fromLTWH(0, horizonY, w, h - horizonY)),
    );

    // Wet road specular sheen
    final sheenY = horizonY + (h - horizonY) * 0.3;
    canvas.drawRect(
      Rect.fromLTWH(0, sheenY - 10, w, 30),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF00F2FE).withValues(alpha: 0.07),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, sheenY - 10, w, 30)),
    );

    // ── Headlight beams ───────────────────────────────────────────────────────
    for (final side in [-1.0, 1.0]) {
      final beamX = vx + side * w * 0.04;
      final beamPath = Path()
        ..moveTo(beamX, horizonY + 2)
        ..lineTo(beamX + side * w * 0.38, h)
        ..lineTo(beamX + side * w * 0.28, h)
        ..close();

      canvas.drawPath(
        beamPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.10),
              Colors.white.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromLTWH(0, horizonY, w, h - horizonY))
          ..blendMode = BlendMode.screen,
      );
    }

    // ── Lane markings ─────────────────────────────────────────────────────────
    const numDashes = 8;
    for (int i = 0; i < numDashes; i++) {
      final t = ((i / numDashes) + progress) % 1.0;
      final y = horizonY + (h - horizonY) * math.pow(t, 1.6).toDouble();
      final dashW = 1.5 + t * 3.0;
      final dashLen = 10 + t * 18.0;
      final x = vx + (vx * 0 * t);  // centred
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: dashW, height: dashLen),
        Paint()
          ..color = const Color(0xFF00F2FE)
              .withValues(alpha: (0.2 + t * 0.6).clamp(0, 0.9)),
      );
    }

    // Side lane edges
    canvas.drawLine(
      Offset(vx - w * 0.04, horizonY), Offset(-20, h + 10),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..strokeWidth = 1.5,
    );
    canvas.drawLine(
      Offset(vx + w * 0.04, horizonY), Offset(w + 20, h + 10),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..strokeWidth = 1.5,
    );

    // Oncoming tail-light streak (left lane)
    final trailY = horizonY + (h - horizonY) * (0.15 + math.sin(progress * math.pi * 2) * 0.1);
    canvas.drawLine(
      Offset(vx - w * 0.18, horizonY + 4),
      Offset(vx - w * 0.32, trailY + 20),
      Paint()
        ..color = Colors.red.withValues(alpha: 0.35)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant DashcamRoadPainter old) => true;
}
