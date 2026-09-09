import 'package:flutter/material.dart';
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard;

import '../../../../core/design_system/premium_navigation.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/vehicle_connectivity/models/packet_capture_models.dart';
import '../../../../core/vehicle_connectivity/services/packet_capture_engine.dart';
import '../../../../core/vehicle_connectivity/transports/mock_vehicle_transport.dart';

class HardwareTestBenchScreen extends StatefulWidget {
  const HardwareTestBenchScreen({super.key});

  @override
  State<HardwareTestBenchScreen> createState() => _HardwareTestBenchScreenState();
}

class _HardwareTestBenchScreenState extends State<HardwareTestBenchScreen> {
  final _captureEngine = PacketCaptureEngine();
  final _mockTransport = MockVehicleTransport();

  @override
  void initState() {
    super.initState();
    _mockTransport.initialize();
    _mockTransport.connect('BENCH_GATT_CCU_01');
  }

  @override
  void dispose() {
    _captureEngine.stopSession();
    _mockTransport.dispose();
    super.dispose();
  }

  void _startBenchSession() {
    _captureEngine.startSession(
      transport: _mockTransport,
      deviceId: 'CCU_BLE_TEST_BENCH_01',
      deviceName: 'Yamaha Y-Connect Test Bench CCU',
      manufacturer: 'Yamaha Motor Co.',
      mtu: 185,
      services: ['0000fee0-0000-1000-8000-00805f9b34fb'],
      characteristics: ['0000fee1-0000-1000-8000-00805f9b34fb', '0000fee2-0000-1000-8000-00805f9b34fb'],
      sourceClassification: CaptureSourceClassification.benchTest,
      verificationStatus: HardwareBenchVerificationStatus.benchVerified,
    );

    // Inject initial frames
    for (int i = 0; i < 4; i++) {
      _mockTransport.injectValidFrame(
        speedKmh: 30 + (i * 10),
        rpm: 4000 + (i * 500),
        batteryVoltage: 13.5,
        coolantTemp: 84 + i,
        fuelPct: 80,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoadOSColors.deepSpaceBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.biotech_rounded, color: RoadOSColors.electricBlue, size: 20),
            SizedBox(width: 8),
            Text(
              'HARDWARE TEST BENCH',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<TestBenchSessionState>(
        stream: _captureEngine.sessionStream,
        initialData: _captureEngine.currentSession,
        builder: (context, snapshot) {
          final session = snapshot.data ?? _captureEngine.currentSession;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildDeviceHeader(session),
              const SizedBox(height: 16),
              _buildBenchMetricsCard(session),
              const SizedBox(height: 16),
              _buildRawFrameStreamCard(session),
              const SizedBox(height: 20),
              _buildControlBar(session),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDeviceHeader(TestBenchSessionState session) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RoadOSColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RoadOSColors.electricBlue.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(session.manufacturer.toUpperCase(), style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: RoadOSColors.electricBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  session.verificationStatus.label,
                  style: const TextStyle(color: RoadOSColors.electricBlue, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(session.deviceName, style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('ID: ${session.deviceId} | MTU: ${session.mtu} | Source: [${session.sourceClassification.label}]', style: const TextStyle(color: RoadOSColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildBenchMetricsCard(TestBenchSessionState session) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RoadOSColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RoadOSColors.borderTranslucent),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat('FRAMES', '${session.totalFramesCaptured}'),
          _buildStat('NOTIF RATE', '${session.notificationRateHz} Hz'),
          _buildStat('LATENCY', '${session.roundTripLatencyMs} ms'),
          _buildStat('LOSS', '${session.packetLossPercent.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  Widget _buildStat(String title, String val) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRawFrameStreamCard(TestBenchSessionState session) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RoadOSColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RoadOSColors.borderTranslucent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('LIVE RAW PACKET LOG (HEX STREAM)', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (session.frames.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Awaiting packet capture session...', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 12))),
            )
          else
            Column(
              children: session.frames.reversed.take(6).map((f) => _buildFrameRow(f)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildFrameRow(CapturedDiagnosticFrame frame) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: RoadOSColors.deepSpaceBlack,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#${frame.sequenceNumber} [${frame.direction.name.toUpperCase()}]', style: const TextStyle(color: RoadOSColors.electricBlue, fontSize: 10, fontWeight: FontWeight.bold)),
              Text(frame.isChecksumValid ? '✓ CHK OK' : '✕ CHK ERR', style: TextStyle(color: frame.isChecksumValid ? RoadOSColors.apexEmerald : Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(frame.payloadHex, style: const TextStyle(fontFamily: 'monospace', color: RoadOSColors.textPrimary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildControlBar(TestBenchSessionState session) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: Icon(session.isRecording ? Icons.stop_rounded : Icons.play_arrow_rounded),
            label: Text(session.isRecording ? 'STOP SESSION' : 'START SESSION', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: session.isRecording ? Colors.redAccent : RoadOSColors.electricBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: session.isRecording ? () => _captureEngine.stopSession() : _startBenchSession,
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          icon: const Icon(Icons.download_rounded, size: 16),
          label: const Text('EXPORT REPORT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            foregroundColor: RoadOSColors.textPrimary,
            side: const BorderSide(color: RoadOSColors.borderTranslucent),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            final json = _captureEngine.exportDiagnosticReportJson();
            showLuxSnack(context, 'Diagnostic Report Generated (${json.length} bytes)', variant: LuxSnackVariant.info);
          },
        ),
      ],
    );
  }
}
