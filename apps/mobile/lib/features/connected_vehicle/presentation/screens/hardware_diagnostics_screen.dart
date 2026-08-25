import 'package:flutter/material.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/vehicle_connectivity/models/hardware_calibration_models.dart';
import '../../../../core/vehicle_connectivity/services/hardware_calibration_engine.dart';
import '../../../../core/vehicle_connectivity/transports/mock_vehicle_transport.dart';

class HardwareDiagnosticsScreen extends StatefulWidget {
  const HardwareDiagnosticsScreen({super.key});

  @override
  State<HardwareDiagnosticsScreen> createState() => _HardwareDiagnosticsScreenState();
}

class _HardwareDiagnosticsScreenState extends State<HardwareDiagnosticsScreen> {
  final _engine = HardwareCalibrationEngine();
  final _mockTransport = MockVehicleTransport();
  bool _isBenchmarking = false;

  @override
  void initState() {
    super.initState();
    _mockTransport.initialize();
    _mockTransport.connect('BENCH_TEST_CCU_01');
    _engine.attachTransport(
      _mockTransport,
      validationMode: HardwareValidationMode.simulator,
      verificationStatus: HardwareVerificationStatus.partiallyVerified,
    );
  }

  @override
  void dispose() {
    _mockTransport.dispose();
    super.dispose();
  }

  Future<void> _runHardwareBenchmark() async {
    setState(() => _isBenchmarking = true);
    for (int i = 0; i < 5; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      _mockTransport.injectValidFrame(
        speedKmh: 45 + (i * 5),
        rpm: 5200 + (i * 300),
        batteryVoltage: 13.6,
        coolantTemp: 88,
        fuelPct: 75,
      );
    }
    if (mounted) {
      setState(() => _isBenchmarking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.tune_rounded, color: RoadOSColors.electricBlue, size: 20),
            SizedBox(width: 8),
            Text(
              'HARDWARE CALIBRATION',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: CinematicBackground(child: StreamBuilder<CalibratedTelemetrySnapshot>(
        stream: _engine.telemetryStream,
        initialData: _engine.currentSnapshot,
        builder: (context, snapshot) {
          final snap = snapshot.data ?? _engine.currentSnapshot;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildVerificationBadge(snap),
              const SizedBox(height: 16),
              _buildSignalCalibrationCard(snap.metrics),
              const SizedBox(height: 16),
              _buildLiveTelemetryGrid(snap),
              const SizedBox(height: 16),
              _buildDiagnosticCodesCard(snap.activeDtcCodes),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: Icon(_isBenchmarking ? Icons.hourglass_bottom_rounded : Icons.speed_rounded),
                label: Text(
                  _isBenchmarking ? 'STREAMING CALIBRATION FRAMES...' : 'RUN HARDWARE BENCHMARK & CALIBRATION',
                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: RoadOSColors.electricBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isBenchmarking ? null : _runHardwareBenchmark,
              ),
            ],
          ));
        },
      ),
    );
  }

  Widget _buildVerificationBadge(CalibratedTelemetrySnapshot snap) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RoadOSColors.electricBlue.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: RoadOSColors.electricBlue.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user_rounded, color: RoadOSColors.electricBlue, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  snap.verificationStatus.label,
                  style: const TextStyle(color: RoadOSColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mode: ${snap.validationMode.label} | Tag: [${snap.sourceTag}]',
                  style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalCalibrationCard(SignalCalibrationMetrics metrics) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1A2035)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('LINK STABILITY & CALIBRATION METRICS', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildMetricTile('RSSI SIGNAL', '${metrics.rssi} dBm', metrics.signalQualityLabel)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricTile('AVG LATENCY', '${metrics.latencyMs} ms', '+/-${metrics.jitterMs} ms Jitter')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetricTile('NOTIF FREQ', '${metrics.notificationFrequencyHz} Hz', '${metrics.packetsReceived} Packets')),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricTile('PACKET LOSS', '${metrics.packetLossPercentage.toStringAsFixed(1)}%', '${metrics.malformedPacketsCount} Malformed')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String title, String value, String subtext) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: RoadOSColors.electricBlue, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(subtext, style: const TextStyle(color: RoadOSColors.textSecondary, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildLiveTelemetryGrid(CalibratedTelemetrySnapshot snap) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1A2035)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DECODED SENSOR STREAM', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSensorRow('Wheel Speed', '${snap.speedKmh.toInt()} km/h', Icons.speed_rounded)),
              Expanded(child: _buildSensorRow('Engine RPM', '${snap.rpm.toInt()} RPM', Icons.rotate_right_rounded)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildSensorRow('Battery Volt', '${snap.batteryVoltage.toStringAsFixed(1)} V', Icons.battery_charging_full_rounded)),
              Expanded(child: _buildSensorRow('Coolant Temp', '${snap.coolantTempCelsius.toInt()}  degC', Icons.thermostat_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSensorRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: RoadOSColors.electricBlue, size: 14),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11)),
        Text(value, style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDiagnosticCodesCard(List<String> dtcs) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1A2035)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DIAGNOSTIC TROUBLE CODES (DTC)', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (dtcs.isEmpty)
            const Text('✓ Zero active DTC fault codes (ECU Nominal)', style: TextStyle(color: RoadOSColors.apexEmerald, fontSize: 12, fontWeight: FontWeight.bold))
          else
            Column(
              children: dtcs.map((code) => Text('| $code', style: const TextStyle(color: Colors.redAccent, fontSize: 12))).toList(),
            ),
        ],
      ),
    );
  }
}
