import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/models/persistent_field_evidence_models.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/services/persistent_field_evidence_service.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/transports/vehicle_transport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Persistent Field Evidence Service Tests', () {
    late PersistentFieldEvidenceService service;

    setUp(() {
      service = PersistentFieldEvidenceService();
      service.clearRecords();
    });

    test('Simulated test run strictly assigns BENCH_TEST evidence status', () {
      final record = service.storeTestSessionEvidence(
        manufacturer: 'Yamaha Motor Co.',
        model: 'YZF-R15M',
        modelYear: 2024,
        variant: 'Top Premium TFT',
        vehicleType: 'Motorcycle',
        protocolName: 'Y-Connect GATT v2.1',
        connectionMethod: VehicleTransportType.ble,
        rawDeviceId: 'AA:BB:CC:DD:EE:FF',
        testDuration: const Duration(seconds: 60),
        rssiMeasurements: [-58, -60, -62],
        negotiatedMtu: 185,
        notificationRateHz: 10.0,
        totalPacketsCaptured: 200,
        isPhysicalHardware: false, // Simulated
      );

      expect(record.evidenceStatus, equals(RealDeviceEvidenceStatus.benchTest));
      expect(record.deviceIdentifierMasked, equals('AA:BB:CC:XX:XX:FF'));
      expect(record.warnings, isNotEmpty);
      expect(service.evidenceRecords.length, equals(1));
    });

    test('Physical test with >= 100 clean packets achieves REAL_DEVICE_VERIFIED', () {
      final record = service.storeTestSessionEvidence(
        manufacturer: 'Royal Enfield',
        model: 'Himalayan 450',
        modelYear: 2024,
        variant: 'Tripper TFT',
        vehicleType: 'Motorcycle',
        protocolName: 'Tripper GATT v1.8',
        connectionMethod: VehicleTransportType.ble,
        rawDeviceId: '11:22:33:44:55:66',
        testDuration: const Duration(minutes: 5),
        rssiMeasurements: [-62, -65, -60, -64],
        negotiatedMtu: 185,
        notificationRateHz: 10.0,
        totalPacketsCaptured: 150,
        packetLossCount: 2,
        checksumFailures: 0,
        isPhysicalHardware: true,
      );

      expect(record.evidenceStatus, equals(RealDeviceEvidenceStatus.realDeviceVerified));
      expect(record.packetLossPercent, lessThan(3.0));
    });

    test('Physical test with excessive packet loss (>10%) results in REAL_DEVICE_FAILED', () {
      final record = service.storeTestSessionEvidence(
        manufacturer: 'Ather Energy',
        model: '450X Gen 3',
        modelYear: 2024,
        variant: 'Pro Pack',
        vehicleType: 'Electric Scooter',
        protocolName: 'Ather Telematics Gateway',
        connectionMethod: VehicleTransportType.ble,
        rawDeviceId: '33:44:55:66:77:88',
        testDuration: const Duration(minutes: 2),
        rssiMeasurements: [-88, -90, -92],
        negotiatedMtu: 23,
        notificationRateHz: 2.0,
        totalPacketsCaptured: 50,
        packetLossCount: 15, // > 10% loss
        isPhysicalHardware: true,
      );

      expect(record.evidenceStatus, equals(RealDeviceEvidenceStatus.realDeviceFailed));
      expect(record.warnings.any((w) => w.contains('excessive packet loss')), isTrue);
    });

    test('Generates detailed human-readable Markdown validation report', () {
      final record = service.storeTestSessionEvidence(
        manufacturer: 'Yamaha Motor Co.',
        model: 'YZF-R15M',
        modelYear: 2024,
        variant: 'Top Premium TFT',
        vehicleType: 'Motorcycle',
        protocolName: 'Y-Connect GATT',
        connectionMethod: VehicleTransportType.ble,
        rawDeviceId: 'AA:BB:CC:DD:EE:FF',
        testDuration: const Duration(seconds: 45),
        rssiMeasurements: [-60, -62],
        negotiatedMtu: 185,
        notificationRateHz: 10.0,
        totalPacketsCaptured: 100,
        isPhysicalHardware: false,
      );

      final markdown = service.generateHumanReadableReport(record);
      expect(markdown, contains('# RIDEOS-AI HARDWARE FIELD VALIDATION REPORT'));
      expect(markdown, contains('**Evidence Status:** **BENCH_TEST**'));
      expect(markdown, contains('YZF-R15M'));
      expect(markdown, contains('185 Bytes'));
    });

    test('Exports sanitized JSON report without leaking full credentials', () {
      final record = service.storeTestSessionEvidence(
        manufacturer: 'TVS Motor Company',
        model: 'Apache RTR 310',
        modelYear: 2024,
        variant: 'SmartXonnect TFT',
        vehicleType: 'Motorcycle',
        protocolName: 'SmartXonnect BLE',
        connectionMethod: VehicleTransportType.ble,
        rawDeviceId: '99:88:77:66:55:44',
        testDuration: const Duration(seconds: 30),
        rssiMeasurements: [-65],
        negotiatedMtu: 185,
        notificationRateHz: 10.0,
        totalPacketsCaptured: 80,
      );

      final jsonStr = service.exportJsonReport(record);
      final decoded = json.decode(jsonStr) as Map<String, dynamic>;

      expect(decoded.containsKey('testSessionId'), isTrue);
      expect(decoded['link']['deviceIdMasked'], equals('99:88:77:XX:XX:44'));
      expect(jsonStr.contains('password'), isFalse);
    });
  });
}
