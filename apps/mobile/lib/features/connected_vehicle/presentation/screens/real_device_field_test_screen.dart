import 'package:flutter/material.dart';
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard;

import '../../../../core/design_system/premium_navigation.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/vehicle_connectivity/models/persistent_field_evidence_models.dart';
import '../../../../core/vehicle_connectivity/services/persistent_field_evidence_service.dart';
import '../../../../core/vehicle_connectivity/transports/mock_vehicle_transport.dart';
import '../../../../core/vehicle_connectivity/transports/vehicle_transport.dart';

class RealDeviceFieldTestScreen extends StatefulWidget {
  const RealDeviceFieldTestScreen({super.key});

  @override
  State<RealDeviceFieldTestScreen> createState() => _RealDeviceFieldTestScreenState();
}

class _RealDeviceFieldTestScreenState extends State<RealDeviceFieldTestScreen> {
  final _evidenceService = PersistentFieldEvidenceService();
  final _mockTransport = MockVehicleTransport();

  String _selectedManufacturer = 'Yamaha Motor Co.';

  String _selectedModel = 'YZF-R15M';
  int _selectedYear = 2024;
  String _selectedVariant = 'Top Premium TFT';
  final VehicleTransportType _selectedTransport = VehicleTransportType.ble;

  bool _isTesting = false;
  PersistentHardwareEvidenceRecord? _latestRecord;

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

  void _onManufacturerChanged(String? val) {
    if (val == null) return;
    setState(() {
      _selectedManufacturer = val;
      if (val == 'Yamaha Motor Co.') {

        _selectedModel = 'YZF-R15M';
        _selectedVariant = 'Top Premium TFT';
      } else if (val == 'Royal Enfield') {

        _selectedModel = 'Himalayan 450';
        _selectedVariant = 'Tripper TFT';
      } else if (val == 'Ather Energy') {

        _selectedModel = '450X Gen 3';
        _selectedVariant = 'Pro Pack 3.7 kWh';
      } else if (val == 'TVS Motor Company') {

        _selectedModel = 'Apache RTR 310';
        _selectedVariant = 'SmartXonnect TFT';
      } else {

        _selectedModel = 'Generic OBD-II Gateway';
        _selectedVariant = 'ISO 15765-4 CAN Gateway';
      }
    });
  }

  void _startFieldTest() {
    setState(() {
      _isTesting = true;
      _latestRecord = null;
    });

    for (int i = 0; i < 10; i++) {
      _mockTransport.injectValidFrame(
        speedKmh: 50 + i * 2,
        rpm: 5000 + i * 100,
        batteryVoltage: 13.7,
        coolantTemp: 86,
        fuelPct: 80,
      );
    }
  }

  void _stopAndEvaluateEvidence() {
    final record = _evidenceService.storeTestSessionEvidence(
      manufacturer: _selectedManufacturer,
      model: _selectedModel,
      modelYear: _selectedYear,
      variant: _selectedVariant,
      vehicleType: _selectedModel.contains('450X') ? 'Electric Scooter' : 'Motorcycle',
      protocolName: '$_selectedManufacturer OEM GATT v2.4',
      connectionMethod: _selectedTransport,
      rawDeviceId: 'AA:BB:CC:DD:EE:FF',
      testDuration: const Duration(seconds: 45),
      rssiMeasurements: [-58, -60, -62, -59, -61],
      negotiatedMtu: 185,
      notificationRateHz: 10.0,
      totalPacketsCaptured: 120,
      packetLossCount: 1,
      checksumFailures: 0,
      reconnectCount: 0,
      testerNotes: 'Bench harness verification before physical field deployment.',
      isPhysicalHardware: false, // Explicitly tagged as bench/simulator
    );

    setState(() {
      _isTesting = false;
      _latestRecord = record;
    });
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
            Icon(Icons.directions_bike_rounded, color: RoadOSColors.electricBlue, size: 20),
            SizedBox(width: 8),
            Text(
              'REAL DEVICE FIELD BENCH',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildNoticeBanner(),
          const SizedBox(height: 16),
          _buildHierarchySelectionCard(),
          const SizedBox(height: 16),
          _buildLiveStatusCard(),
          const SizedBox(height: 16),
          if (_latestRecord != null) ...[
            _buildReportSummaryCard(_latestRecord!),
            const SizedBox(height: 16),
          ],
          _buildActionControls(),
        ],
      ),
    );
  }

  Widget _buildNoticeBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.security_rounded, color: Colors.amber, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'STRICT GATE ACTIVE: Simulated/Bench sessions cannot be promoted to REAL_DEVICE_VERIFIED.',
              style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHierarchySelectionCard() {
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
          const Text('VEHICLE HIERARCHY & VARIANT SELECTION', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildDropdown('MANUFACTURER', _selectedManufacturer, [
            'Yamaha Motor Co.',
            'Royal Enfield',
            'Ather Energy',
            'TVS Motor Company',
            'Universal Standards',
          ], _onManufacturerChanged),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDropdown('MODEL', _selectedModel, [_selectedModel], (v) {}),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDropdown('YEAR', '$_selectedYear', ['2024', '2023', '2022', '2021', '2020'], (v) {
                  if (v != null) setState(() => _selectedYear = int.parse(v));
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildDropdown('VARIANT / TRIM', _selectedVariant, [_selectedVariant], (v) {}),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: items.contains(value) ? value : items.first,
          dropdownColor: RoadOSColors.deepSpaceBlack,
          style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true,
            fillColor: RoadOSColors.deepSpaceBlack,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: _isTesting ? null : onChanged,
        ),
      ],
    );
  }

  Widget _buildLiveStatusCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: RoadOSColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _isTesting ? RoadOSColors.apexEmerald : RoadOSColors.electricBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TEST SESSION STATUS', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (_isTesting ? RoadOSColors.apexEmerald : RoadOSColors.textMuted).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _isTesting ? 'ACTIVE RECORDING' : 'READY',
                  style: TextStyle(color: _isTesting ? RoadOSColors.apexEmerald : RoadOSColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('$_selectedManufacturer $_selectedModel ($_selectedVariant)', style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Transport: ${_selectedTransport.name.toUpperCase()} | Safe Read-Only Mode Active', style: const TextStyle(color: RoadOSColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildReportSummaryCard(PersistentHardwareEvidenceRecord rec) {
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
              const Text('GENERATED FIELD VALIDATION RECORD', style: TextStyle(color: RoadOSColors.electricBlue, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              Text(rec.evidenceStatus.label, style: const TextStyle(color: RoadOSColors.apexEmerald, fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Text('Session ID: ${rec.testSessionId}', style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Captured: ${rec.totalPacketsCaptured} packets | Packet Loss: ${rec.packetLossPercent.toStringAsFixed(1)}% | Avg RSSI: ${rec.averageRssi.toInt()} dBm', style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11)),
          if (rec.warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Notice: ${rec.warnings.first}', style: const TextStyle(color: Colors.amber, fontSize: 10)),
          ],
        ],
      ),
    );
  }

  Widget _buildActionControls() {
    return Column(
      children: [
        ElevatedButton.icon(
          icon: Icon(_isTesting ? Icons.stop_circle_rounded : Icons.play_arrow_rounded),
          label: Text(
            _isTesting ? 'STOP & EVALUATE EVIDENCE' : 'START TEST SESSION',
            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isTesting ? Colors.redAccent : RoadOSColors.electricBlue,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isTesting ? _stopAndEvaluateEvidence : _startFieldTest,
        ),
        if (_latestRecord != null) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.description_rounded, size: 16),
            label: const Text('EXPORT HUMAN-READABLE REPORT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: RoadOSColors.electricBlue,
              side: const BorderSide(color: RoadOSColors.electricBlue),
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final report = _evidenceService.generateHumanReadableReport(_latestRecord!);
              showLuxSnack(context, 'Generated Markdown Validation Report (${report.length} chars)', variant: LuxSnackVariant.info);
            },
          ),
        ],
      ],
    );
  }
}
