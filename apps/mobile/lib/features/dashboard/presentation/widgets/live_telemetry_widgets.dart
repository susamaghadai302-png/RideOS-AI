import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';

class SpeedometerArcWidget extends StatelessWidget {
  final double currentSpeed;
  final double maxSpeed;
  final double leanAngle;
  final String unit;
  final VoidCallback? onUnitToggle;

  const SpeedometerArcWidget({
    super.key,
    required this.currentSpeed,
    this.maxSpeed = 299.0,
    required this.leanAngle,
    this.unit = 'KM/H',
    this.onUnitToggle,
  });

  @override
  Widget build(BuildContext context) {
    return RoadOSCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.speed_rounded, color: RoadOSColors.hyperOrange, size: 20),
                  const SizedBox(width: 8),
                  Text('SPEEDOMETER', style: LuxTypography.titleMedium(color: RoadOSColors.platinumWhite)),
                ],
              ),
              GestureDetector(
                onTap: () {
                  LuxAudioHapticsService.selectionClick();
                  onUnitToggle?.call();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: RoadOSColors.hyperOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: RoadOSColors.hyperOrange.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    unit,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: RoadOSColors.hyperOrange),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            width: 220,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _SpeedGaugePainter(
                  speed: currentSpeed,
                  maxSpeed: maxSpeed,
                  accentColor: RoadOSColors.hyperOrange,
                ),
                child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 18),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: RoadOSColors.platinumWhite,
                        shadows: LuxShadows.textGlow(RoadOSColors.hyperOrange),
                      ),
                      child: Text('${currentSpeed.round()}'),
                    ),
                    Text(
                      unit,
                      style: LuxTypography.caption(color: RoadOSColors.textMuted).copyWith(
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.screen_rotation_rounded, color: RoadOSColors.cyberCyan, size: 14),
                const SizedBox(width: 6),
                Text(
                  'LEAN ANGLE: ${leanAngle.toStringAsFixed(1)} deg',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RoadOSColors.cyberCyan),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedGaugePainter extends CustomPainter {
  final double speed;
  final double maxSpeed;
  final Color accentColor;

  _SpeedGaugePainter({
    required this.speed,
    required this.maxSpeed,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width.isFinite && size.width > 0 ? size.width : 220.0;
    final height = size.height.isFinite && size.height > 0 ? size.height : 160.0;
    final center = Offset(width / 2, height * 0.7);
    final radius = width * 0.42;

    const startAngle = math.pi * 0.8;
    const sweepAngle = math.pi * 1.4;

    final bgPaint = Paint()
      ..color = const Color(0xFF1B2332)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    final ratio = (speed / (maxSpeed > 0 ? maxSpeed : 299.0)).clamp(0.0, 1.0);
    final activeSweep = sweepAngle * ratio;

    final activePaint = Paint()
      ..shader = LinearGradient(
        colors: [accentColor, RoadOSColors.cyberCyan],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    if (activeSweep > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        activeSweep,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpeedGaugePainter oldDelegate) {
    return oldDelegate.speed != speed || oldDelegate.maxSpeed != maxSpeed;
  }
}

class LiveTachometerWidget extends StatelessWidget {
  final double currentRpm;
  final double maxRpm;

  const LiveTachometerWidget({
    super.key,
    required this.currentRpm,
    this.maxRpm = 14000,
  });

  @override
  Widget build(BuildContext context) {
    final rpmPct = (currentRpm / maxRpm).clamp(0.0, 1.0);
    final isRedline = rpmPct >= 0.85;

    return RoadOSCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.tune_rounded, color: isRedline ? RoadOSColors.errorCrimson : RoadOSColors.cyberCyan, size: 20),
                  const SizedBox(width: 8),
                  Text('TACHOMETER (RPM)', style: LuxTypography.titleMedium(color: RoadOSColors.platinumWhite)),
                ],
              ),
              Text(
                '${(currentRpm).round()} RPM',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isRedline ? RoadOSColors.errorCrimson : RoadOSColors.cyberCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: rpmPct,
              minHeight: 12,
              backgroundColor: const Color(0xFF1A2230),
              valueColor: AlwaysStoppedAnimation<Color>(
                isRedline ? RoadOSColors.errorCrimson : (rpmPct > 0.65 ? RoadOSColors.solarGold : RoadOSColors.cyberCyan),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0', style: TextStyle(fontSize: 10, color: RoadOSColors.textMuted)),
              Text('7K', style: TextStyle(fontSize: 10, color: RoadOSColors.textMuted)),
              Text('14K REDLINE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: RoadOSColors.errorCrimson)),
            ],
          ),
        ],
      ),
    );
  }
}

class GearIndicatorWidget extends StatelessWidget {
  final String currentGear;

  const GearIndicatorWidget({
    super.key,
    required this.currentGear,
  });

  @override
  Widget build(BuildContext context) {
    final isNeutral = currentGear == 'N';

    return RoadOSCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.settings_suggest_rounded, color: isNeutral ? RoadOSColors.apexEmerald : RoadOSColors.hyperOrange, size: 22),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TRANSMISSION', style: LuxTypography.caption(color: RoadOSColors.textMuted)),
                  Text(
                    isNeutral ? 'NEUTRAL GEAR' : 'GEAR POSITION',
                    style: LuxTypography.titleMedium(color: RoadOSColors.platinumWhite),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              gradient: isNeutral ? LuxGradients.emeraldPulse : LuxGradients.hyperOrange,
              borderRadius: BorderRadius.circular(16),
              boxShadow: LuxShadows.glassGlow(isNeutral ? RoadOSColors.apexEmerald : RoadOSColors.hyperOrange),
            ),
            child: Text(
              currentGear,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FuelBatteryGaugeWidget extends StatelessWidget {
  final double fuelPercent;
  final double batteryPercent;

  const FuelBatteryGaugeWidget({
    super.key,
    required this.fuelPercent,
    required this.batteryPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: RoadOSCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.local_gas_station_rounded, color: RoadOSColors.solarGold, size: 18),
                    Text('${fuelPercent.round()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: RoadOSColors.solarGold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('FUEL LEVEL', style: LuxTypography.caption(color: RoadOSColors.textMuted)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: fuelPercent / 100.0,
                    minHeight: 8,
                    backgroundColor: const Color(0xFF1B2332),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      fuelPercent < 20 ? RoadOSColors.errorCrimson : RoadOSColors.solarGold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RoadOSCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.battery_charging_full_rounded, color: RoadOSColors.apexEmerald, size: 18),
                    Text('${batteryPercent.round()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: RoadOSColors.apexEmerald)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('12V BATTERY', style: LuxTypography.caption(color: RoadOSColors.textMuted)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: batteryPercent / 100.0,
                    minHeight: 8,
                    backgroundColor: const Color(0xFF1B2332),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      batteryPercent < 20 ? RoadOSColors.errorCrimson : RoadOSColors.apexEmerald,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class EngineTemperatureWidget extends StatelessWidget {
  final double engineTempCelsius;

  const EngineTemperatureWidget({
    super.key,
    required this.engineTempCelsius,
  });

  @override
  Widget build(BuildContext context) {
    final isHot = engineTempCelsius > 105;

    return RoadOSCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.thermostat_rounded, color: isHot ? RoadOSColors.errorCrimson : RoadOSColors.cyberCyan, size: 20),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('COOLANT TEMP', style: LuxTypography.caption(color: RoadOSColors.textMuted)),
                  Text(
                    isHot ? 'WARNING: HIGH TEMP' : 'OPERATING TEMPERATURE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isHot ? RoadOSColors.errorCrimson : RoadOSColors.platinumWhite,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            '${engineTempCelsius.round()} degC',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isHot ? RoadOSColors.errorCrimson : RoadOSColors.cyberCyan,
            ),
          ),
        ],
      ),
    );
  }
}
