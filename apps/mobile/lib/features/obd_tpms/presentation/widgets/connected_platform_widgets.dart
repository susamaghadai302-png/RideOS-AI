import 'dart:math' as math;
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard;

import 'package:flutter/material.dart';
import '../../../../core/design_system/premium_navigation.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../crash_detection/core/services/crash_detection_engine.dart';

class FullObd2DiagnosticsGridWidget extends StatelessWidget {
  final double rpm;
  final double coolantTemp;
  final double batteryVoltage;
  final double throttlePct;
  final double fuelLevelPct;
  final double fuelConsL100;
  final double engineLoadPct;
  final double oilTempC;
  final double airIntakeTempC;
  final double o2Volts;
  final bool checkEngine;
  final List<String> dtcCodes;

  const FullObd2DiagnosticsGridWidget({
    super.key,
    this.rpm = 4850,
    this.coolantTemp = 88.5,
    this.batteryVoltage = 13.8,
    this.throttlePct = 0.0,
    this.fuelLevelPct = 78.0,
    this.fuelConsL100 = 4.8,
    this.engineLoadPct = 56.0,
    this.oilTempC = 92.0,
    this.airIntakeTempC = 0.0,
    this.o2Volts = 0.85,
    this.checkEngine = false,
    this.dtcCodes = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.memory_rounded, color: RoadOSColors.cyberCyan, size: 20),
                SizedBox(width: 8),
                Text('OBD-II CAN-BUS TELEMETRY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: checkEngine ? RoadOSColors.errorCrimson.withValues(alpha: 0.2) : RoadOSColors.apexEmerald.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: checkEngine ? RoadOSColors.errorCrimson : RoadOSColors.apexEmerald),
              ),
              child: Row(
                children: [
                  Icon(checkEngine ? Icons.warning_amber_rounded : Icons.check_circle_rounded, color: checkEngine ? RoadOSColors.errorCrimson : RoadOSColors.apexEmerald, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    checkEngine ? 'CHECK ENGINE' : 'SYSTEM NOMINAL',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: checkEngine ? RoadOSColors.errorCrimson : RoadOSColors.apexEmerald),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.6,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _buildParamCard('ENGINE RPM', '${rpm.round()} RPM', Icons.speed_rounded, RoadOSColors.hyperOrange),
            _buildParamCard('COOLANT TEMP', '${coolantTemp.round()}  degC', Icons.thermostat_rounded, RoadOSColors.cyberCyan),
            _buildParamCard('BATTERY VOLTAGE', '${batteryVoltage.toStringAsFixed(1)} V', Icons.battery_charging_full_rounded, RoadOSColors.solarGold),
            _buildParamCard('THROTTLE POS', '${throttlePct.round()}%', Icons.tune_rounded, const Color(0xFF8B5CF6)),
            _buildParamCard('FUEL LEVEL', '${fuelLevelPct.round()}%', Icons.local_gas_station_rounded, RoadOSColors.apexEmerald),
            _buildParamCard('FUEL CONSUMP.', '$fuelConsL100 L/100', Icons.speed_rounded, RoadOSColors.electricBlue),
            _buildParamCard('ENGINE LOAD', '${engineLoadPct.round()}%', Icons.hardware_rounded, RoadOSColors.hyperOrange),
            _buildParamCard('OIL TEMP', '${oilTempC.round()}  degC', Icons.oil_barrel_rounded, RoadOSColors.solarGold),
            _buildParamCard('INTAKE TEMP', '${airIntakeTempC.round()}  degC', Icons.air_rounded, RoadOSColors.cyberCyan),
            _buildParamCard('O2 SENSOR', '${o2Volts.toStringAsFixed(2)} V', Icons.sensors_rounded, RoadOSColors.apexEmerald),
          ],
        ),
        const SizedBox(height: 12),

        // Live Real-Time Telemetry Waveform Graph Card
        RoadOSCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('REAL-TIME CAN-BUS WAVEFORM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: RoadOSColors.textMuted)),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                width: double.infinity,
                child: CustomPaint(
                  painter: TelemetryGraphPainter(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParamCard(String title, String val, IconData icon, Color color) {
    return RoadOSCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: RoadOSColors.textMuted)),
              Icon(icon, color: color, size: 16),
            ],
          ),
          Text(val, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}

class TelemetryGraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width.isFinite && size.width > 0 ? size.width : 400.0;
    final height = size.height.isFinite && size.height > 0 ? size.height : 200.0;

    final path = Path();
    final paint = Paint()
      ..color = RoadOSColors.cyberCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final glowPaint = Paint()
      ..color = RoadOSColors.cyberCyan.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;

    path.moveTo(0, height * 0.5);
    for (double x = 0; x <= width; x += 10) {
      final y = (height * 0.5) + (math.sin(x * 0.08) * (height * 0.35));
      path.lineTo(x, y);
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TpmsTireVisualizerWidget extends StatelessWidget {
  final double frontPsi;
  final double rearPsi;
  final double tireTempC;
  final bool lowPressureWarning;

  const TpmsTireVisualizerWidget({
    super.key,
    this.frontPsi = 36.0,
    this.rearPsi = 0.0,
    this.tireTempC = 32.0,
    this.lowPressureWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return RoadOSCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.tire_repair_rounded, color: RoadOSColors.apexEmerald, size: 20),
                  SizedBox(width: 8),
                  Text('ANIMATED TPMS SENSORS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                ],
              ),
              Text(
                'Temp: ${tireTempC.round()}  degC',
                style: const TextStyle(fontSize: 10, color: RoadOSColors.textMuted, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTireIndicator('FRONT TIRE', frontPsi, 36.0, Icons.arrow_upward_rounded),
              Container(
                height: 60,
                width: 1,
                color: const Color(0xFF334155),
              ),
              _buildTireIndicator('REAR TIRE', rearPsi, 0.0, Icons.arrow_downward_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTireIndicator(String label, double actual, double target, IconData icon) {
    final isNominal = (actual - target).abs() <= 2.0;
    final color = isNominal ? RoadOSColors.apexEmerald : RoadOSColors.errorCrimson;

    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              '${actual.toStringAsFixed(1)} PSI',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
        Text('Target: $target PSI', style: const TextStyle(fontSize: 9, color: RoadOSColors.textMuted)),
      ],
    );
  }
}

class SmartGarageVaultWidget extends StatelessWidget {
  const SmartGarageVaultWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return RoadOSCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.folder_special_rounded, color: RoadOSColors.solarGold, size: 20),
                  SizedBox(width: 8),
                  Text('SMART GARAGE AI VAULT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                ],
              ),
              Text('3 Documents', style: TextStyle(fontSize: 10, color: RoadOSColors.solarGold, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildVaultTile('Insurance', 'Expires in 42d', Icons.verified_user_rounded, RoadOSColors.apexEmerald)),
              const SizedBox(width: 8),
              Expanded(child: _buildVaultTile('PUC Cert.', 'Valid 180d', Icons.eco_rounded, RoadOSColors.cyberCyan)),
              const SizedBox(width: 8),
              Expanded(child: _buildVaultTile('RC Document', 'Verified', Icons.article_rounded, RoadOSColors.hyperOrange)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF334155), height: 1),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly Fuel Expenses: \$142.50', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
              Text('Warranty Active', style: TextStyle(fontSize: 10, color: RoadOSColors.apexEmerald, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVaultTile(String title, String status, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
          Text(status, style: TextStyle(fontSize: 8, color: color)),
        ],
      ),
    );
  }
}

class CrashDetectionOverlayWidget extends StatefulWidget {
  final CrashDetectionEngine engine;
  final VoidCallback? onCancel;

  const CrashDetectionOverlayWidget({
    super.key,
    required this.engine,
    this.onCancel,
  });

  @override
  State<CrashDetectionOverlayWidget> createState() => _CrashDetectionOverlayWidgetState();
}

class _CrashDetectionOverlayWidgetState extends State<CrashDetectionOverlayWidget> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: widget.engine.countdownStream,
      initialData: widget.engine.secondsRemaining,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 30;
        final isTriggered = widget.engine.state == CrashDetectionState.emergencyTriggered;

        return RoadOSCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded, color: RoadOSColors.errorCrimson, size: 28),
                  SizedBox(width: 8),
                  Text('IMPACT DETECTED!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: RoadOSColors.errorCrimson)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                isTriggered ? 'EMERGENCY SOS DISPATCHED TO CONTACTS!' : 'Automatic SOS Dispatch in $count seconds...',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        LuxAudioHapticsService.heavyImpact();
                        widget.engine.cancelCountdown();
                        widget.onCancel?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white12,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 42),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("I'M OK (CANCEL)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        LuxAudioHapticsService.alertVibrate();
                        showLuxSnack(context, 'Instant SOS Alert Broadcasted to Emergency Services!', variant: LuxSnackVariant.info);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RoadOSColors.errorCrimson,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 42),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('DISPATCH NOW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class EmergencySosPanelWidget extends StatelessWidget {
  const EmergencySosPanelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return RoadOSCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.sos_rounded, color: RoadOSColors.errorCrimson, size: 22),
                  SizedBox(width: 8),
                  Text('EMERGENCY SOS & LIVE TRACKING', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                ],
              ),
              Text('Blood Group O+', style: TextStyle(fontSize: 10, color: RoadOSColors.errorCrimson, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Live Location Sharing Link Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                    Text('Sharing Speed, Battery % & GPS Coordinates', style: TextStyle(fontSize: 9, color: RoadOSColors.textMuted)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.share_rounded, color: RoadOSColors.cyberCyan, size: 20),
                  onPressed: () {
                    LuxAudioHapticsService.mediumImpact();
                    showLuxSnack(context, 'Live GPS tracking link copied to clipboard.', variant: LuxSnackVariant.info);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SquadRideRadarWidget extends StatelessWidget {
  const SquadRideRadarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoadOSCard(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.radar_rounded, color: RoadOSColors.hyperOrange, size: 20),
                  SizedBox(width: 8),
                  Text('SQUAD RIDE MESH RADAR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                ],
              ),
              Text('3 Members', style: TextStyle(fontSize: 10, color: RoadOSColors.hyperOrange, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Mesh Voice Channel Active | Real-time rider distance & battery monitoring.',
            style: TextStyle(fontSize: 10, color: RoadOSColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class AntiTheftGuardWidget extends StatefulWidget {
  const AntiTheftGuardWidget({super.key});

  @override
  State<AntiTheftGuardWidget> createState() => _AntiTheftGuardWidgetState();
}

class _AntiTheftGuardWidgetState extends State<AntiTheftGuardWidget> {
  bool _isArmed = true;
  final double _geofenceMeters = 100.0;

  @override
  Widget build(BuildContext context) {
    return RoadOSCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.security_rounded, color: _isArmed ? RoadOSColors.apexEmerald : RoadOSColors.errorCrimson, size: 20),
                  const SizedBox(width: 8),
                  const Text('ANTI-THEFT GEOFENCE GUARD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                ],
              ),
              Switch(
                value: _isArmed,
                activeTrackColor: RoadOSColors.apexEmerald,
                onChanged: (val) {
                  LuxAudioHapticsService.heavyImpact();
                  setState(() => _isArmed = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isArmed ? 'ARMED: Geofence perimeter active at ${_geofenceMeters.round()}m radius.' : 'DISARMED: Motion monitoring disabled.',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _isArmed ? RoadOSColors.apexEmerald : RoadOSColors.errorCrimson),
          ),
        ],
      ),
    );
  }
}

class SmartHelmetConnectivityWidget extends StatelessWidget {
  const SmartHelmetConnectivityWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoadOSCard(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.headset_mic_rounded, color: Color(0xFF8B5CF6), size: 20),
                  SizedBox(width: 8),
                  Text('SMART HELMET MESH LINK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                ],
              ),
              Text('BATTERY 92%', style: TextStyle(fontSize: 10, color: RoadOSColors.apexEmerald, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _HelmetFeatureBadge(icon: Icons.mic_rounded, label: 'MIC ON'),
              _HelmetFeatureBadge(icon: Icons.volume_up_rounded, label: 'AUDIO DUAL'),
              _HelmetFeatureBadge(icon: Icons.sos_rounded, label: 'ICE BUTTON'),
              _HelmetFeatureBadge(icon: Icons.videocam_rounded, label: 'CAM READY'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HelmetFeatureBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HelmetFeatureBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: RoadOSColors.cyberCyan),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class RideAnalyticsSummaryWidget extends StatelessWidget {
  const RideAnalyticsSummaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoadOSCard(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics_rounded, color: RoadOSColors.solarGold, size: 20),
                  SizedBox(width: 8),
                  Text('RIDE TELEMETRY ANALYTICS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                ],
              ),
              Text('SCORE 96/100', style: TextStyle(fontSize: 10, color: RoadOSColors.apexEmerald, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Lean Score: 94%', style: TextStyle(color: RoadOSColors.cyberCyan, fontSize: 11)),
              Text('Smoothness: 98%', style: TextStyle(color: RoadOSColors.apexEmerald, fontSize: 11)),
              Text('Fuel Efficiency: 4.8L/100', style: TextStyle(color: RoadOSColors.hyperOrange, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
