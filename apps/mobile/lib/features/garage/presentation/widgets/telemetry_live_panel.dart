import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../obd_tpms/core/services/obd_full_telemetry_service.dart';
import '../../core/services/garage_audio_engine_service.dart';
import '../../domain/entities/garage_vehicle_model.dart';

/// 60 FPS Real-Time Live Performance & Telemetry HUD Panel
class TelemetryLivePanel extends StatefulWidget {
  final GarageVehicleModel vehicle;
  final bool isEngineRunning;
  final VoidCallback onToggleEngine;
  final VoidCallback? onClose;

  const TelemetryLivePanel({
    super.key,
    required this.vehicle,
    required this.isEngineRunning,
    required this.onToggleEngine,
    this.onClose,
  });

  @override
  State<TelemetryLivePanel> createState() => _TelemetryLivePanelState();
}

class _TelemetryLivePanelState extends State<TelemetryLivePanel> {
  final GarageAudioEngineService _audioService = GarageAudioEngineService();
  StreamSubscription<ObdFullTelemetryData>? _telemetrySub;

  double _currentRpm = 0.0;
  double _throttle = 0.0;
  double _liveBatteryVolts = 12.6;
  double _liveCoolantTemp = 88.0;
  bool _isLiveCanBusMode = false;
  int _currentGear = 0; // 0 = Neutral, 1-6 // ignore: prefer_final_fields

  bool _isDynoMode = false;

  // Derived telemetry metrics
  double get _speedKmh => widget.isEngineRunning
      ? (_currentGear == 0
          ? 0.0
          : (_currentRpm / 14500.0) * double.parse(widget.vehicle.topSpeedKmh.split(' ')[0]))
      : 0.0;

  double get _engineTempC => _isLiveCanBusMode
      ? _liveCoolantTemp
      : (widget.isEngineRunning ? 88.0 + (_currentRpm / 15000.0) * 18.0 : 24.0);

  double get _batteryVoltage => _isLiveCanBusMode ? _liveBatteryVolts : (widget.isEngineRunning ? 14.2 : 12.6);

  double get _oilPressureBar => widget.isEngineRunning
      ? 2.2 + (_currentRpm / 15000.0) * 3.4
      : 0.0;

  // Live Dyno HP & Torque estimation
  double get _instantHp {
    if (!widget.isEngineRunning || _currentRpm <= 0) return 0.0;
    final maxHpVal = widget.vehicle.id.contains('ducati')
        ? 214.0
        : widget.vehicle.id.contains('bmw')
            ? 205.0
            : 200.0;
    final curveRatio = math.sin((_currentRpm / 14500.0).clamp(0.0, 1.0) * (math.pi / 2.0));
    return (maxHpVal * curveRatio * (0.20 + 0.80 * (_throttle > 0 ? _throttle : 0.15))).clamp(0.0, maxHpVal);
  }

  double get _instantTorqueNm {
    if (!widget.isEngineRunning || _currentRpm <= 0) return 0.0;
    final maxTorqueVal = widget.vehicle.id.contains('ducati')
        ? 124.0
        : widget.vehicle.id.contains('bmw')
            ? 113.0
            : 113.3;
    final peakRpm = widget.vehicle.id.contains('ducati') ? 9500.0 : 11000.0;
    final dist = ((_currentRpm - peakRpm) / 14000.0).abs();
    final factor = (1.0 - (dist * 0.45)).clamp(0.2, 1.0);
    return (maxTorqueVal * factor * (0.25 + 0.75 * (_throttle > 0 ? _throttle : 0.18))).clamp(0.0, maxTorqueVal);
  }

  @override
  void initState() {
    super.initState();
    _currentRpm = widget.isEngineRunning ? 1250.0 : 0.0;
    _telemetrySub = ObdFullTelemetryService().telemetryStream.listen((data) {
      if (data.source == TelemetryDataSource.realHardwareBle && mounted) {
        setState(() {
          _isLiveCanBusMode = true;
          if (data.engineRpm != null && data.engineRpm! > 0) {
            _currentRpm = data.engineRpm!;
          }
          if (data.throttlePositionPct != null) {
            _throttle = (data.throttlePositionPct! / 100.0).clamp(0.0, 1.0);
          }
          if (data.batteryVoltage != null) {
            _liveBatteryVolts = data.batteryVoltage!;
          }
          if (data.coolantTempC != null) {
            _liveCoolantTemp = data.coolantTempC!;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _telemetrySub?.cancel();
    super.dispose();
  }

  void _onThrottleChanged(double val) {
    setState(() => _throttle = val);
    _audioService.setThrottle(val);
  }

  void _onRevButtonDown(TapDownDetails _) {
    LuxAudioHapticsService.heavyImpact();
    setState(() => _throttle = 0.85);
    _audioService.setThrottle(0.85);
  }

  void _onRevButtonUp(TapUpDetails _) {
    setState(() => _throttle = 0.0);
    _audioService.setThrottle(0.0);
  }

  void _onRevButtonCancel() {
    setState(() => _throttle = 0.0);
    _audioService.setThrottle(0.0);
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.vehicle.factoryAccentColor;

    return StreamBuilder<double>(
      stream: _audioService.rpmStream,
      initialData: widget.isEngineRunning ? 1250.0 : 0.0,
      builder: (context, snapshot) {
        _currentRpm = snapshot.data ?? 0.0;

        return Container(
          width: 410,
          decoration: BoxDecoration(
            color: const Color(0xF0070B14),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.2),
            boxShadow: const [
              BoxShadow(color: Colors.black87, blurRadius: 30, spreadRadius: 8),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isEngineRunning ? const Color(0xFF00E676) : Colors.grey,
                      boxShadow: widget.isEngineRunning
                          ? [const BoxShadow(color: Color(0xFF00E676), blurRadius: 8, spreadRadius: 2)]
                          : [],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'TELEMETRY & DYNO BENCH',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  // Dyno Mode Toggle
                  GestureDetector(
                    onTap: () {
                      LuxAudioHapticsService.selectionClick();
                      setState(() => _isDynoMode = !_isDynoMode);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _isDynoMode
                            ? const Color(0xFFFF9100).withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isDynoMode ? const Color(0xFFFF9100) : Colors.white24,
                        ),
                      ),
                      child: Text(
                        _isDynoMode ? '⚡ DYNO BENCH' : 'GAUGES',
                        style: TextStyle(
                          color: _isDynoMode ? const Color(0xFFFF9100) : Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (widget.onClose != null) ...[
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      onPressed: widget.onClose,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Dyno Curve or Analog RPM Gauge
              if (_isDynoMode) ...[
                // Live Dyno Power Curve
                SizedBox(
                  width: double.infinity,
                  height: 125,
                  child: CustomPaint(
                    painter: _DynoCurvePainter(
                      rpm: _currentRpm,
                      maxRpm: 15000.0,
                      currentHp: _instantHp,
                      currentTorque: _instantTorqueNm,
                      accentColor: accent,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricPill('DYNO POWER', '${_instantHp.toStringAsFixed(1)} HP', Icons.bolt_rounded, const Color(0xFFFF9100)),
                    _buildMetricPill('TORQUE', '${_instantTorqueNm.toStringAsFixed(1)} NM', Icons.rotate_right_rounded, const Color(0xFF00E5FF)),
                    _buildMetricPill('RPM SWEEP', '${_currentRpm.round()} RPM', Icons.speed_rounded, accent),
                  ],
                ),
              ] else ...[
                // RPM Circular Gauge with Analog Sweep Needle & Digital Readout
                Center(
                  child: SizedBox(
                    width: 200,
                    height: 120,
                    child: CustomPaint(
                      painter: _RpmGaugePainter(
                        rpm: _currentRpm,
                        maxRpm: 15000.0,
                        accentColor: accent,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _currentRpm.round().toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Text(
                            'RPM x 1000',
                            style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Digital Speedometer & Gear Indicator Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricPill('SPEED', '${_speedKmh.round()} KM/H', Icons.speed_rounded, accent),
                    _buildMetricPill('GEAR', _currentGear == 0 ? 'N' : '$_currentGear', Icons.tune_rounded, const Color(0xFF00E676)),
                    _buildMetricPill('TEMP', '${_engineTempC.round()}  degC', Icons.thermostat_rounded, const Color(0xFFFF9100)),
                    _buildMetricPill('OIL', '${_oilPressureBar.toStringAsFixed(1)} BAR', Icons.opacity_rounded, const Color(0xFF00E5FF)),
                  ],
                ),
              ],
              const SizedBox(height: 16),

              // Interactive Throttle Slider & Rev Trigger Button
              Row(
                children: [
                  // Throttle Slider
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('THROTTLE POSITION', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                            Text('${(_throttle * 100).round()}%', style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        SliderTheme(
                          data: SliderThemeData(
                            thumbColor: accent,
                            activeTrackColor: accent,
                            inactiveTrackColor: Colors.white12,
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          ),
                          child: Slider(
                            value: _throttle,
                            onChanged: widget.isEngineRunning ? _onThrottleChanged : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Hold to Rev Button
                  GestureDetector(
                    onTapDown: widget.isEngineRunning ? _onRevButtonDown : null,
                    onTapUp: widget.isEngineRunning ? _onRevButtonUp : null,
                    onTapCancel: widget.isEngineRunning ? _onRevButtonCancel : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: widget.isEngineRunning ? accent.withValues(alpha: 0.25) : Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.isEngineRunning ? accent : Colors.white24,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.sports_score_rounded, color: widget.isEngineRunning ? accent : Colors.white38, size: 16),
                          const SizedBox(height: 2),
                          Text(
                            'REV',
                            style: TextStyle(
                              color: widget.isEngineRunning ? Colors.white : Colors.white38,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Master Engine Start / Stop Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    widget.onToggleEngine();
                    if (!widget.isEngineRunning) {
                      _audioService.startEngine();
                    } else {
                      _audioService.stopEngine();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isEngineRunning ? const Color(0xFF3B1515) : const Color(0xFF153B1D),
                    foregroundColor: widget.isEngineRunning ? const Color(0xFFFF5252) : const Color(0xFF69F0AE),
                    side: BorderSide(
                      color: widget.isEngineRunning ? const Color(0xFFFF5252) : const Color(0xFF69F0AE),
                      width: 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: Icon(
                    widget.isEngineRunning ? Icons.power_settings_new_rounded : Icons.play_arrow_rounded,
                    size: 18,
                  ),
                  label: Text(
                    widget.isEngineRunning ? 'STOP MOTORCYCLE ENGINE' : 'START MOTORCYCLE ENGINE',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.8),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricPill(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// RPM ANALOG GAUGE PAINTER
// ═════════════════════════════════════════════════════════════════════════════

class _RpmGaugePainter extends CustomPainter {
  final double rpm;
  final double maxRpm;
  final Color accentColor;

  _RpmGaugePainter({
    required this.rpm,
    required this.maxRpm,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 10;

    const startAngle = math.pi * 0.9;
    const sweepAngle = math.pi * 1.2;

    // Background track arc
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Active RPM sweep arc
    final progress = (rpm / maxRpm).clamp(0.0, 1.0);
    final activePaint = Paint()
      ..shader = LinearGradient(
        colors: [accentColor, const Color(0xFFFF3D00)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * progress,
      false,
      activePaint,
    );

    // Redline Zone (last 20%)
    final redlinePaint = Paint()
      ..color = const Color(0xFFFF1744).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius + 7),
      startAngle + (sweepAngle * 0.8),
      sweepAngle * 0.2,
      false,
      redlinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RpmGaugePainter oldDelegate) =>
      oldDelegate.rpm != rpm;
}

// ═════════════════════════════════════════════════════════════════════════════
// LIVE DYNO BENCH POWER & TORQUE CURVE PAINTER
// ═════════════════════════════════════════════════════════════════════════════

class _DynoCurvePainter extends CustomPainter {
  final double rpm;
  final double maxRpm;
  final double currentHp;
  final double currentTorque;
  final Color accentColor;

  _DynoCurvePainter({
    required this.rpm,
    required this.maxRpm,
    required this.currentHp,
    required this.currentTorque,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Background Grid & Axis Lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 4; i++) {
      final y = size.height * (i / 4.0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (int i = 1; i <= 5; i++) {
      final x = size.width * (i / 5.0);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // 2. Horsepower Curve (Neon Orange/Red)
    final hpPath = Path();
    final hpFillPath = Path();
    hpFillPath.moveTo(0, size.height);

    for (double r = 0; r <= maxRpm; r += 250) {
      final x = (r / maxRpm) * size.width;
      final hpRatio = math.sin((r / 14500.0).clamp(0.0, 1.0) * (math.pi / 2.0));
      final y = size.height - (hpRatio * (size.height - 15));

      if (r == 0) {
        hpPath.moveTo(x, y);
      } else {
        hpPath.lineTo(x, y);
      }
      hpFillPath.lineTo(x, y);
    }
    hpFillPath.lineTo(size.width, size.height);
    hpFillPath.close();

    final hpFillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFF6D00).withValues(alpha: 0.25),
          const Color(0xFFFF6D00).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(hpFillPath, hpFillPaint);

    final hpStrokePaint = Paint()
      ..color = const Color(0xFFFF9100)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    canvas.drawPath(hpPath, hpStrokePaint);

    // 3. Torque Curve (Cyan / Blue)
    final tqPath = Path();
    for (double r = 0; r <= maxRpm; r += 250) {
      final x = (r / maxRpm) * size.width;
      final dist = ((r - 10500.0) / 14000.0).abs();
      final factor = (1.0 - (dist * 0.45)).clamp(0.2, 1.0);
      final y = size.height - (factor * (size.height - 25));

      if (r == 0) {
        tqPath.moveTo(x, y);
      } else {
        tqPath.lineTo(x, y);
      }
    }
    final tqStrokePaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(tqPath, tqStrokePaint);

    // 4. Live Dynamic RPM Sweep Cursor & Value Tracker Point
    final cursorX = (rpm / maxRpm).clamp(0.0, 1.0) * size.width;
    final cursorPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(cursorX, 0), Offset(cursorX, size.height), cursorPaint);

    // Dyno Tracking Indicator Dot
    final hpAtCurrentRpm = (currentHp / 220.0).clamp(0.0, 1.0);
    final dotY = size.height - (hpAtCurrentRpm * (size.height - 15));
    final dotPaint = Paint()
      ..color = const Color(0xFFFF3D00)
      ..style = PaintingStyle.fill;
    final dotGlowPaint = Paint()
      ..color = const Color(0xFFFF9100).withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawCircle(Offset(cursorX, dotY), 7.0, dotGlowPaint);
    canvas.drawCircle(Offset(cursorX, dotY), 4.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _DynoCurvePainter oldDelegate) =>
      oldDelegate.rpm != rpm ||
      oldDelegate.currentHp != currentHp ||
      oldDelegate.currentTorque != currentTorque;
}
