import 'package:flutter/material.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/device_providers/models/field_bench_models.dart';
import '../../../../core/device_providers/models/normalized_telemetry_models.dart';
import '../../../../core/device_providers/services/fleet_telematics_engine.dart';
import '../../../../core/device_providers/services/physical_field_bench_service.dart';

class FieldTestBenchScreen extends StatefulWidget {
  const FieldTestBenchScreen({super.key});

  @override
  State<FieldTestBenchScreen> createState() => _FieldTestBenchScreenState();
}

class _FieldTestBenchScreenState extends State<FieldTestBenchScreen> {
  final _benchService = PhysicalFieldBenchService();
  final telematicsEngine = FleetTelematicsEngine();
  RecordedRideSession? _completedSession;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoadOSColors.deepSpaceBlack,
      appBar: AppBar(
        backgroundColor: RoadOSColors.obsidianSurface,
        title: const Text(
          'FIELD TEST MODE & BENCH',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Link Health Stream HUD
          StreamBuilder<FieldLinkHealthSnapshot>(
            stream: _benchService.linkHealthStream,
            initialData: _benchService.latestHealthSnapshot,
            builder: (context, snapshot) {
              final health = snapshot.data;
              final source = health?.source ?? TelemetryDataSource.simulated;
              final isLiveHardware = source == TelemetryDataSource.realDevice;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isLiveHardware
                          ? RoadOSColors.apexEmerald.withValues(alpha: 0.15)
                          : const Color(0xFFFFD600).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isLiveHardware ? RoadOSColors.apexEmerald : const Color(0xFFFFD600),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isLiveHardware ? Icons.sensors_rounded : Icons.science_rounded,
                              size: 16,
                              color: isLiveHardware ? RoadOSColors.apexEmerald : const Color(0xFFFFD600),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isLiveHardware ? 'LIVE HARDWARE LINK' : 'SIMULATED TELEMETRY LINK',
                              style: TextStyle(
                                color: isLiveHardware ? RoadOSColors.apexEmerald : const Color(0xFFFFD600),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Quality: ${health?.dataQualityScore ?? 100}%',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Health Matrix
                  Row(
                    children: [
                      Expanded(child: _buildHealthTile('PACKET RATE', health?.packetRateHz.toStringAsFixed(1) ?? '10.0', 'Hz', RoadOSColors.cyberCyan)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildHealthTile('PACKET LOSS', health?.packetLossPercentage.toStringAsFixed(1) ?? '0.0', '%', RoadOSColors.warningAmber)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildHealthTile('LATENCY', '${health?.latencyMs ?? 100}', 'ms', RoadOSColors.electricBlue)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildHealthTile('RECONNECTS', '${health?.reconnectCount ?? 0}', 'drops', RoadOSColors.hyperOrange)),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),

          // 2. Active Ride Session Recording Control
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: RoadOSColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: RoadOSColors.borderTranslucent),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ON-ROAD RIDE SESSION', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _benchService.isRideSessionActive ? Colors.redAccent.withValues(alpha: 0.2) : Colors.white10,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _benchService.isRideSessionActive ? 'RECORDING' : 'IDLE',
                        style: TextStyle(
                          color: _benchService.isRideSessionActive ? Colors.redAccent : RoadOSColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _benchService.isRideSessionActive
                      ? 'Live on-road telemetry session recording in progress...'
                      : 'Press Start to begin recording telemetry, GPS track, RPM curve, and lean angle.',
                  style: const TextStyle(color: RoadOSColors.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  icon: Icon(_benchService.isRideSessionActive ? Icons.stop_rounded : Icons.play_arrow_rounded),
                  label: Text(_benchService.isRideSessionActive ? 'STOP & PERSIST SESSION' : 'START LIVE RIDE SESSION'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _benchService.isRideSessionActive ? Colors.redAccent : RoadOSColors.apexEmerald,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    setState(() {
                      if (_benchService.isRideSessionActive) {
                        _completedSession = _benchService.stopLiveRideSession();
                      } else {
                        _benchService.startLiveRideSession();
                        _completedSession = null;
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 3. Completed Session Summary (if available)
          if (_completedSession != null) _buildCompletedSessionCard(_completedSession!),

          // 4. Live Sensor Freshness Checklist
          const Text('LIVE SENSOR FRESHNESS CHECKLIST', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 10),
          _buildSensorCheckRow('Engine RPM & Crankshaft Pulse', true, '100 Hz'),
          _buildSensorCheckRow('Wheel Speed Sensor (Front/Rear)', true, '50 Hz'),
          _buildSensorCheckRow('Coolant & Cylinder Head Temp', true, '5 Hz'),
          _buildSensorCheckRow('Throttle Position Sensor (TPS)', true, '50 Hz'),
          _buildSensorCheckRow('6-Axis IMU (Lean & Vibration)', true, '100 Hz'),
          _buildSensorCheckRow('Battery Charging Circuit (V/A)', true, '2 Hz'),
        ],
      ),
    );
  }

  Widget _buildHealthTile(String label, String value, String unit, Color accent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RoadOSColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: RoadOSColors.borderTranslucent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: TextStyle(color: accent, fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(width: 4),
              Text(unit, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedSessionCard(RecordedRideSession session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RoadOSColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RoadOSColors.apexEmerald.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: RoadOSColors.apexEmerald, size: 18),
              SizedBox(width: 8),
              Text('SESSION COMPLETED & PERSISTED', style: TextStyle(color: RoadOSColors.apexEmerald, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Duration: ${session.durationMinutes.toStringAsFixed(1)} mins | Distance: ${session.totalDistanceKm.toStringAsFixed(2)} km', style: const TextStyle(color: Colors.white, fontSize: 12)),
          const SizedBox(height: 4),
          Text('Max Speed: ${session.maxSpeedKmh.toStringAsFixed(1)} km/h | Max RPM: ${session.maxRpm}', style: const TextStyle(color: RoadOSColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 4),
          Text('Max Lean: ${session.maxLeanAngleDeg.toStringAsFixed(1)} deg | Packets: ${session.totalPacketsReceived}', style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildSensorCheckRow(String sensorName, bool isHealthy, String rate) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: RoadOSColors.obsidianSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RoadOSColors.borderTranslucent),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(sensorName, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          Row(
            children: [
              Text(rate, style: const TextStyle(color: RoadOSColors.cyberCyan, fontSize: 10, fontFamily: 'monospace')),
              const SizedBox(width: 8),
              Icon(isHealthy ? Icons.check_circle_rounded : Icons.cancel_rounded, color: isHealthy ? RoadOSColors.apexEmerald : Colors.redAccent, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}
