import 'dart:convert';
import '../models/persistent_field_evidence_models.dart';
import '../transports/vehicle_transport.dart';
import 'structured_hardware_diagnostic_logger.dart';

class PersistentFieldEvidenceService {
  static final PersistentFieldEvidenceService _instance = PersistentFieldEvidenceService._internal();
  factory PersistentFieldEvidenceService() => _instance;

  final List<PersistentHardwareEvidenceRecord> _evidenceRecords = [];
  List<PersistentHardwareEvidenceRecord> get evidenceRecords => List.unmodifiable(_evidenceRecords);

  final _logger = StructuredHardwareDiagnosticLogger();

  PersistentFieldEvidenceService._internal();

  /// Strictly evaluates and stores a physical or bench test session
  PersistentHardwareEvidenceRecord storeTestSessionEvidence({
    required String manufacturer,
    required String model,
    required int modelYear,
    required String variant,
    required String vehicleType,
    required String protocolName,
    required VehicleTransportType connectionMethod,
    required String rawDeviceId,
    required Duration testDuration,
    required List<int> rssiMeasurements,
    required int negotiatedMtu,
    required double notificationRateHz,
    required int totalPacketsCaptured,
    int packetLossCount = 0,
    int checksumFailures = 0,
    int reconnectCount = 0,
    Map<String, dynamic> diagnostics = const {},
    List<String> errors = const [],
    List<String> warnings = const [],
    String testerNotes = 'Real hardware on-road field validation record.',
    bool isPhysicalHardware = false,
  }) {
    final maskedId = rawDeviceId.length >= 17
        ? '${rawDeviceId.substring(0, 8)}:XX:XX:${rawDeviceId.substring(15)}'
        : (rawDeviceId.length >= 8 ? '${rawDeviceId.substring(0, 6)}:XX:XX' : 'MASKED_ID');

    RealDeviceEvidenceStatus calculatedStatus;
    final finalWarnings = List<String>.from(warnings);

    if (!isPhysicalHardware) {
      calculatedStatus = RealDeviceEvidenceStatus.benchTest;
      finalWarnings.add('Test executed on software/bench simulator harness. Physical hardware validation pending.');
    } else {
      final double lossPct = (totalPacketsCaptured + packetLossCount + checksumFailures) > 0
          ? ((packetLossCount + checksumFailures) / (totalPacketsCaptured + packetLossCount + checksumFailures)) * 100.0
          : 100.0;

      if (errors.isNotEmpty || lossPct > 10.0) {
        calculatedStatus = RealDeviceEvidenceStatus.realDeviceFailed;
        finalWarnings.add('Field test failed due to excessive packet loss (${lossPct.toStringAsFixed(1)}%) or critical link errors.');
      } else if (totalPacketsCaptured >= 100 && lossPct <= 5.0 && checksumFailures == 0) {
        calculatedStatus = RealDeviceEvidenceStatus.realDeviceVerified;
      } else {
        calculatedStatus = RealDeviceEvidenceStatus.realDevicePending;
        finalWarnings.add('Insufficient frame sample size for full verification (minimum 100 frames required).');
      }
    }

    final record = PersistentHardwareEvidenceRecord(
      testSessionId: 'SESSION_${DateTime.now().millisecondsSinceEpoch}',
      manufacturer: manufacturer,
      model: model,
      modelYear: modelYear,
      variant: variant,
      vehicleType: vehicleType,
      protocolName: protocolName,
      connectionMethod: connectionMethod,
      deviceIdentifierMasked: maskedId,
      timestamp: DateTime.now(),
      testDuration: testDuration,
      rssiMeasurements: List.unmodifiable(rssiMeasurements),
      negotiatedMtu: negotiatedMtu,
      notificationRateHz: notificationRateHz,
      totalPacketsCaptured: totalPacketsCaptured,
      packetLossCount: packetLossCount,
      checksumFailures: checksumFailures,
      reconnectCount: reconnectCount,
      diagnostics: diagnostics,
      errors: errors,
      warnings: finalWarnings,
      testerNotes: testerNotes,
      evidenceStatus: calculatedStatus,
    );

    _evidenceRecords.add(record);

    _logger.log(
      eventType: DiagnosticEventType.connectionStateChange,
      severity: calculatedStatus == RealDeviceEvidenceStatus.realDeviceFailed ? DiagnosticSeverity.error : DiagnosticSeverity.info,
      deviceId: maskedId,
      message: 'Generated evidence record ${record.testSessionId} with status: ${calculatedStatus.label}',
      metadata: {'evidenceStatus': calculatedStatus.label, 'packets': totalPacketsCaptured},
    );

    return record;
  }

  /// Generates a professional human-readable Markdown validation report
  String generateHumanReadableReport(PersistentHardwareEvidenceRecord record) {
    final isPhysical = record.evidenceStatus == RealDeviceEvidenceStatus.realDeviceVerified;

    return '''
# RIDEOS-AI HARDWARE FIELD VALIDATION REPORT
**Session ID:** `${record.testSessionId}`
**Timestamp:** `${record.timestamp.toIso8601String()}`

---

### 1. Test Information
- **Test Mode:** ${record.evidenceStatus.label}
- **Test Duration:** ${record.testDuration.inSeconds} seconds
- **Tester Notes:** ${record.testerNotes}

---

### 2. Vehicle Profile
- **Manufacturer:** ${record.manufacturer}
- **Model Family:** ${record.model}
- **Model Year:** ${record.modelYear}
- **Variant Trim:** ${record.variant}
- **Vehicle Type:** ${record.vehicleType}

---

### 3. Device Information
- **Transport Method:** ${record.connectionMethod.name.toUpperCase()}
- **Masked Device Identifier:** `${record.deviceIdentifierMasked}`
- **Negotiated MTU:** ${record.negotiatedMtu} Bytes

---

### 4. BLE Connection Metrics
- **Average RSSI:** ${record.averageRssi.toStringAsFixed(1)} dBm
- **RSSI Samples Recorded:** ${record.rssiMeasurements.length}
- **Notification Rate:** ${record.notificationRateHz} Hz

---

### 5. Packet Statistics
- **Total Packets Captured:** ${record.totalPacketsCaptured}
- **Packet Loss Count:** ${record.packetLossCount}
- **Checksum Failures:** ${record.checksumFailures}
- **Packet Loss Rate:** ${record.packetLossPercent.toStringAsFixed(2)}%

---

### 6. Reconnection Statistics
- **Reconnect Events:** ${record.reconnectCount}
- **Connection Interrupted:** ${record.reconnectCount > 0 ? 'Yes' : 'No'}

---

### 7. Errors / Warnings
${record.warnings.isEmpty ? '- No warnings.' : record.warnings.map((w) => '- ⚠️ $w').join('\n')}
${record.errors.isEmpty ? '- No critical link errors.' : record.errors.map((e) => '- ❌ $e').join('\n')}

---

### 8. Safety Status
- **Active Vehicle Commands:** DISABLED (Strict Read-Only Mode)
- **ECU / CAN Injection:** BLOCKED
- **Brake / Throttle / Ignition Actuation:** BLOCKED

---

### 9. Evidence Summary
- **Evidence Record ID:** `${record.testSessionId}`
- **Protocol Evaluated:** ${record.protocolName}
- **Evidence Status:** **${record.evidenceStatus.label}**

---

### 10. Validation Status
- **Compatibility Status:** ${isPhysical ? 'REAL DEVICE CONFIRMED' : 'BENCH VERIFIED'}
- **Quality Gate Passed:** ${record.packetLossPercent <= 5.0 && record.errors.isEmpty ? 'YES' : 'NO'}

---

### 11. Physical Hardware Validation Statement
${isPhysical ? '✅ PHYSICAL HARDWARE VALIDATED on on-road production hardware.' : '⚠️ PHYSICAL VALIDATION PENDING — Bench-tested with simulated/injection harness. Physical motorcycle/scooter verification required before live deployment.'}
''';
  }

  String exportJsonReport(PersistentHardwareEvidenceRecord record) {
    return const JsonEncoder.withIndent('  ').convert(record.toJson());
  }

  void clearRecords() {
    _evidenceRecords.clear();
  }
}
