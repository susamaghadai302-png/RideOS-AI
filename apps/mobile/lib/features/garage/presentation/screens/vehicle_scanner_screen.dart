import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/design_system/premium_navigation.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard;
import '../../../../core/vehicle_resolution/models/digital_twin_model.dart';
import '../../core/services/scan_coverage_evaluator.dart';
import '../../core/services/vehicle_3d_reconstruction_service.dart';
import '../dialogs/reconstruction_progress_dialog.dart';
import '../dialogs/digital_twin_preview_dialog.dart';

class VehicleScannerScreen extends StatefulWidget {
  final String? vehicleId;
  final String? manufacturer;
  final String? modelName;
  final String? category;
  final int? year;

  const VehicleScannerScreen({
    super.key,
    this.vehicleId,
    this.manufacturer,
    this.modelName,
    this.category,
    this.year,
  });

  @override
  State<VehicleScannerScreen> createState() => _VehicleScannerScreenState();
}

class _VehicleScannerScreenState extends State<VehicleScannerScreen> with SingleTickerProviderStateMixin {
  final List<CapturedFrameMetadata> _capturedFrames = [];
  final ScanCoverageEvaluator _evaluator = ScanCoverageEvaluator();
  final Vehicle3DReconstructionService _reconstructionService = Vehicle3DReconstructionService();

  late AnimationController _radarController;
  ScanCoverageReport _report = const ScanCoverageReport(
    coveragePercent: 0.0,
    sectorFrameCounts: {},
    missingSectors: [],
    guidancePrompts: ['Walk slowly around your vehicle in a 360 deg circle'],
    isReadyForReconstruction: false,
    lightingAssessment: 'Checking sensors...',
    qualityScore: 0.0,
  );

  ScanSector _activeTargetSector = ScanSector.front;
  bool _isAutoScanning = false;
  Timer? _autoScanTimer;
  DigitalTwinQuality _selectedQuality = DigitalTwinQuality.high;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..forward();
    _recomputeReport();
  }

  @override
  void dispose() {
    _radarController.dispose();
    _autoScanTimer?.cancel();
    super.dispose();
  }

  void _recomputeReport() {
    setState(() {
      _report = _evaluator.evaluateCoverage(_capturedFrames);
      if (_report.missingSectors.isNotEmpty) {
        _activeTargetSector = _report.missingSectors.first;
      }
    });
  }

  void _captureCurrentAngle() {
    final frame = CapturedFrameMetadata(
      frameId: 'frame_${_capturedFrames.length + 1}_${DateTime.now().millisecondsSinceEpoch}',
      targetSector: _activeTargetSector,
      estimatedAngleDeg: _activeTargetSector.targetAngleDeg.toDouble(),
      brightnessScore: 0.72 + (math.Random().nextDouble() * 0.15),
      sharpnessScore: 0.88 + (math.Random().nextDouble() * 0.10),
      timestamp: DateTime.now(),
    );

    setState(() {
      _capturedFrames.add(frame);
    });
    _recomputeReport();
  }

  void _toggleAutoSweep() {
    if (_isAutoScanning) {
      _autoScanTimer?.cancel();
      setState(() => _isAutoScanning = false);
    } else {
      setState(() => _isAutoScanning = true);
      _autoScanTimer = Timer.periodic(const Duration(milliseconds: 350), (timer) {
        if (_report.isReadyForReconstruction && _capturedFrames.length >= 16) {
          timer.cancel();
          setState(() => _isAutoScanning = false);
          return;
        }

        // Auto step through missing sectors
        final missing = _report.missingSectors;
        if (missing.isNotEmpty) {
          _activeTargetSector = missing.first;
        } else {
          final nextIdx = (_activeTargetSector.index + 1) % ScanSector.values.length;
          _activeTargetSector = ScanSector.values[nextIdx];
        }
        _captureCurrentAngle();
      });
    }
  }

  Future<void> _startReconstruction() async {
    if (!_report.isReadyForReconstruction && _capturedFrames.length < 8) {
      showLuxSnack(context, '⚠️ Please capture more angles around the vehicle (min 75% coverage).', variant: LuxSnackVariant.info);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ReconstructionProgressDialog(
        progressStream: _reconstructionService.progressStream,
      ),
    );

    try {
      final twin = await _reconstructionService.reconstructDigitalTwin(
        vehicleId: widget.vehicleId ?? 'v_custom_${DateTime.now().millisecondsSinceEpoch}',
        manufacturer: widget.manufacturer ?? 'Custom',
        modelName: widget.modelName ?? 'Scanned Vehicle',
        year: widget.year ?? DateTime.now().year,
        category: widget.category ?? 'Motorcycle',
        capturedFrames: _capturedFrames,
        targetQuality: _selectedQuality,
      );

      if (mounted) {
        Navigator.pop(context); // Close progress dialog

        // Step 8 & 9: Model Preview and Confirmation
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => DigitalTwinPreviewDialog(
            twin: twin,
            onAccepted: () {
              Navigator.pop(context, twin); // Return digital twin to previous screen
              showLuxSnack(context, '✅ 3D Digital Twin Saved to 3D Garage: ${twin.manufacturer} ${twin.model} (${twin.versionTag})', variant: LuxSnackVariant.info);
            },
            onRescan: () {
              setState(() {
                _capturedFrames.clear();
                _recomputeReport();
              });
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showLuxSnack(context, '❌ Reconstruction Error: $e', variant: LuxSnackVariant.info);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicleTitle = '${widget.manufacturer ?? "YOUR"} ${widget.modelName ?? "VEHICLE"}'.toUpperCase();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Simulated High-Tech Camera Viewfinder Stage
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Color(0xFF070B18),
                    Colors.black,
                  ],
                ),
              ),
              child: CustomPaint(
                painter: _ViewfinderGridPainter(
                  rotation: _radarController,
                  coverage: _report.coveragePercent,
                  activeSector: _activeTargetSector,
                ),
              ),
            ),
          ),

          // 2. Central 360 deg Circular Guide & Vehicle Radar Ring
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRadialRadarGuide(),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF070B18).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'AIMING: ${_activeTargetSector.title.toUpperCase()} | ${_activeTargetSector.description}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                  ),
                ),
              ],
            ),
          ),

          // 3. Top Navigation & Coverage Progress Bar
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF070B18).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1A2035)),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Column(
                      children: [
                        const Text(
                          '3D DIGITAL TWIN SCANNER',
                          style: TextStyle(color: RoadOSColors.cyberCyan, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2.0),
                        ),
                        Text(
                          vehicleTitle,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    _buildQualityBadge(),
                  ],
                ),
                const SizedBox(height: 16),

                // Coverage Meter
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF070B18).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1A2035)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.radar_rounded, color: RoadOSColors.cyberCyan, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'SCAN COVERAGE: ${_report.coveragePercent}%',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                          Text(
                            '${_capturedFrames.length} Frames Captured',
                            style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _report.coveragePercent / 100.0,
                          minHeight: 6,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _report.isReadyForReconstruction ? RoadOSColors.apexEmerald : RoadOSColors.cyberCyan,
                          ),
                        ),
                      ),
                      if (_report.guidancePrompts.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _report.guidancePrompts.first,
                          style: const TextStyle(color: RoadOSColors.electricBlue, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 4. Bottom Controls & Action Triggers
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              children: [
                // Quick Sector Selectors
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ScanSector.values.map((s) {
                      final count = _report.sectorFrameCounts[s] ?? 0;
                      final isSelected = _activeTargetSector == s;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('${s.title} ${count > 0 ? "✓" : ""}'),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _activeTargetSector = s),
                          backgroundColor: const Color(0xFF060912),
                          selectedColor: RoadOSColors.cyberCyan.withValues(alpha: 0.25),
                          labelStyle: TextStyle(
                            color: count > 0 ? RoadOSColors.apexEmerald : (isSelected ? RoadOSColors.cyberCyan : RoadOSColors.textMuted),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          side: BorderSide(
                            color: isSelected ? RoadOSColors.cyberCyan : Colors.white12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    // Auto Sweep Toggle
                    Expanded(
                      flex: 1,
                      child: RoadOSButton(
                        label: _isAutoScanning ? 'STOP' : 'BURST',
                        icon: _isAutoScanning ? Icons.stop_rounded : Icons.auto_mode_rounded,
                        gradient: _isAutoScanning ? RoadOSGradients.crimsonAlert : RoadOSGradients.darkCardGradient,
                        onPressed: _toggleAutoSweep,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Manual Shutter Button
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: RoadOSColors.cyberCyan, width: 3),
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 28),
                        onPressed: _captureCurrentAngle,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Reconstruct Digital Twin Action Button
                    Expanded(
                      flex: 2,
                      child: RoadOSButton(
                        label: 'GENERATE 3D TWIN',
                        icon: Icons.view_in_ar_rounded,
                        gradient: _report.isReadyForReconstruction ? RoadOSGradients.primaryViolet : RoadOSGradients.darkCardGradient,
                        onPressed: _startReconstruction,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityBadge() {
    return PopupMenuButton<DigitalTwinQuality>(
      initialValue: _selectedQuality,
      onSelected: (q) => setState(() => _selectedQuality = q),
      color: const Color(0xFF070B18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF070B18),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: RoadOSColors.cyberCyan),
        ),
        child: Text(
          _selectedQuality.code,
          style: const TextStyle(color: RoadOSColors.cyberCyan, fontSize: 10, fontWeight: FontWeight.w900),
        ),
      ),
      itemBuilder: (context) => DigitalTwinQuality.values.map((q) {
        return PopupMenuItem(
          value: q,
          child: Text(
            '${q.code} | ${q.description}',
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRadialRadarGuide() {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.two_wheeler_rounded,
              color: _report.isReadyForReconstruction ? RoadOSColors.apexEmerald : RoadOSColors.cyberCyan,
              size: 72,
            ),
          ),
          ...ScanSector.values.where((s) => s.isRadialAngle).map((s) {
            final rad = (s.targetAngleDeg - 90) * (math.pi / 180.0);
            final x = 110 + 90 * math.cos(rad) - 12;
            final y = 110 + 90 * math.sin(rad) - 12;
            final hasFrame = (_report.sectorFrameCounts[s] ?? 0) > 0;
            final isCurrent = _activeTargetSector == s;

            return Positioned(
              left: x,
              top: y,
              child: GestureDetector(
                onTap: () => setState(() => _activeTargetSector = s),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasFrame
                        ? RoadOSColors.apexEmerald
                        : (isCurrent ? RoadOSColors.cyberCyan : const Color(0xFF070B18)),
                    border: Border.all(
                      color: isCurrent ? Colors.white : RoadOSColors.cyberCyan.withValues(alpha: 0.6),
                      width: isCurrent ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: hasFrame
                        ? const Icon(Icons.check, size: 14, color: Colors.black)
                        : Text(
                            s.title.substring(0, 1),
                            style: TextStyle(
                              color: isCurrent ? Colors.black : Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ViewfinderGridPainter extends CustomPainter {
  final Animation<double> rotation;
  final double coverage;
  final ScanSector activeSector;

  _ViewfinderGridPainter({
    required this.rotation,
    required this.coverage,
    required this.activeSector,
  }) : super(repaint: rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = RoadOSColors.cyberCyan.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, 130, paint);
    canvas.drawCircle(center, 170, paint);

    // Crosshairs
    canvas.drawLine(Offset(center.dx - 30, center.dy), Offset(center.dx + 30, center.dy), paint);
    canvas.drawLine(Offset(center.dx, center.dy - 30), Offset(center.dx, center.dy + 30), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
