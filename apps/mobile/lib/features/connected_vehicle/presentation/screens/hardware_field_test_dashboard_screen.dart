import 'package:flutter/material.dart';
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard, RoadOSThemeEngine;

import '../../../../core/design_system/premium_navigation.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/vehicle_connectivity/models/physical_field_evidence_models.dart';
import '../../../../core/vehicle_connectivity/services/physical_field_evidence_engine.dart';
import '../../../../core/vehicle_connectivity/transports/mock_vehicle_transport.dart';

class HardwareFieldTestDashboardScreen extends StatefulWidget {
  const HardwareFieldTestDashboardScreen({super.key});

  @override
  State<HardwareFieldTestDashboardScreen> createState() => _HardwareFieldTestDashboardScreenState();
}

class _HardwareFieldTestDashboardScreenState extends State<HardwareFieldTestDashboardScreen> {
  final _evidenceEngine = PhysicalFieldEvidenceEngine();
  final _mockTransport = MockVehicleTransport();
  PhysicalTestEvidenceRecord? _evidenceRecord;

  @override
  void initState() {
    super.initState();
    _mockTransport.initialize();
    _mockTransport.connect('FIELD_TEST_LINK_01');
  }

  @override
  void dispose() {
    _mockTransport.dispose();
    super.dispose();
  }

  void _startEvidenceSession() {
    _evidenceEngine.startEvidenceSession(
      transport: _mockTransport,
      deviceName: 'Yamaha Y-Connect Test Bench',
      macAddress: 'AA:BB:CC:DD:EE:FF',
      manufacturer: 'Yamaha Motor Co.',
      modelName: 'YZF-R15M',
      variantTrim: 'Top Premium TFT',
      modelYear: '2023',
      protocolName: 'Yamaha Y-Connect GATT v2.1',
      initialMtu: 185,
      isSimulated: true,
    );

    for (int i = 0; i < 6; i++) {
      _mockTransport.injectValidFrame(
        speedKmh: 40 + i * 5,
        rpm: 4500 + i * 200,
        batteryVoltage: 13.6,
        coolantTemp: 86,
        fuelPct: 80,
      );
      _evidenceEngine.recordRssiSample(-60 - i);
    }
    setState(() {});
  }

  void _stopAndGenerateEvidence() {
    final record = _evidenceEngine.stopEvidenceSession(
      deviceName: 'Yamaha Y-Connect Test Bench',
      macAddress: 'AA:BB:CC:DD:EE:FF',
      manufacturer: 'Yamaha Motor Co.',
      modelName: 'YZF-R15M',
      variantTrim: 'Top Premium TFT',
      modelYear: '2023',
      protocolName: 'Yamaha Y-Connect GATT v2.1',
      negotiatedMtu: 185,
      isPhysicalHardwareTest: false,
    );
    setState(() {
      _evidenceRecord = record;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoadOSColors.deepSpaceBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.assignment_turned_in_rounded, color: RoadOSColors.electricBlue, size: 20),
            SizedBox(width: 8),
            Text(
              'HARDWARE EVIDENCE BENCH',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildPendingBanner(),
          const SizedBox(height: 16),
          _buildActiveEvidenceCard(),
          const SizedBox(height: 16),
          if (_evidenceRecord != null) ...[
            _buildGeneratedReportCard(_evidenceRecord!),
            const SizedBox(height: 16),
          ],
          _buildActionControls(),
        ],
      ),
    );
  }

  Widget _buildPendingBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: const [
          Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'PHYSICAL VALIDATION PENDING — Bench evidence harness active.',
              style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveEvidenceCard() {
    final recording = _evidenceEngine.isRecording;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: RoadOSColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: recording ? RoadOSColors.apexEmerald : RoadOSColors.borderTranslucent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('EVIDENCE RECORDER STATUS', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (recording ? RoadOSColors.apexEmerald : RoadOSColors.textMuted).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  recording ? 'RECORDING SAMPLES' : 'IDLE',
                  style: TextStyle(color: recording ? RoadOSColors.apexEmerald : RoadOSColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Target Profile: Yamaha YZF-R15M (Top Premium TFT)', style: TextStyle(color: RoadOSColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Protocol: Yamaha Y-Connect GATT v2.1 | MTU: 185', style: TextStyle(color: RoadOSColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildGeneratedReportCard(PhysicalTestEvidenceRecord rec) {
    return Container(
      padding: const EdgeInsets.all(18),
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
              const Text('GENERATED EVIDENCE RECORD', style: TextStyle(color: RoadOSColors.electricBlue, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              Text(rec.evidenceLevel.label, style: const TextStyle(color: RoadOSColors.apexEmerald, fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Evidence ID: ${rec.evidenceId}', style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Packets: ${rec.totalPacketsCaptured} | Packet Loss: ${rec.packetLossPercent.toStringAsFixed(1)}% | Avg RSSI: ${rec.averageRssi.toInt()} dBm', style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11)),
          if (rec.warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Notice: ${rec.warnings.first}', style: const TextStyle(color: Colors.amber, fontSize: 10)),
          ],
        ],
      ),
    );
  }

  Widget _buildActionControls() {
    final recording = _evidenceEngine.isRecording;

    return Column(
      children: [
        ElevatedButton.icon(
          icon: Icon(recording ? Icons.stop_circle_rounded : Icons.fiber_manual_record_rounded),
          label: Text(
            recording ? 'STOP & GENERATE EVIDENCE REPORT' : 'START EVIDENCE SESSION',
            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: recording ? Colors.redAccent : RoadOSColors.electricBlue,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: recording ? _stopAndGenerateEvidence : _startEvidenceSession,
        ),
        if (_evidenceRecord != null) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('EXPORT EVIDENCE REPORT (JSON)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: RoadOSColors.electricBlue,
              side: const BorderSide(color: RoadOSColors.electricBlue),
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final jsonStr = _evidenceEngine.exportEvidenceReportJson(_evidenceRecord!);
              showLuxSnack(context, 'Exported Evidence (${jsonStr.length} bytes)', variant: LuxSnackVariant.info);
            },
          ),
        ],
      ],
    );
  }
}
