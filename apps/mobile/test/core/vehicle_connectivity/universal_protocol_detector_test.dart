import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_capabilities/models/universal_protocol_detection_models.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/services/universal_protocol_detector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Universal Protocol Detector & Compatibility Tests', () {
    late UniversalProtocolDetector detector;

    setUp(() {
      detector = UniversalProtocolDetector();
    });

    test('Identifies Yamaha YZF-R15M (Top Premium TFT) via 0xFEE0 GATT signature', () {
      final report = detector.detectProtocol(
        deviceName: 'Yamaha_CCU_R15M',
        advertisedServices: ['0000fee0-0000-1000-8000-00805f9b34fb'],
        macAddress: 'AA:BB:CC:DD:EE:FF',
      );

      expect(report.manufacturer, equals('Yamaha Motor Co.'));
      expect(report.modelName, equals('YZF-R15M'));
      expect(report.variantTrim, equals('Top Premium TFT'));
      expect(report.vehicleType, equals(VehicleClassificationType.motorcycleIce));
      expect(report.confidenceScore, greaterThanOrEqualTo(0.9));
      expect(report.overallStatus, equals(CompatibilityReportStatus.supported));
      expect(report.hasTurnByTurnNav, isTrue);
      expect(report.areActiveCommandsBlocked, isTrue);
    });

    test('Identifies Royal Enfield Himalayan 450 via 0xFE50 Tripper signature', () {
      final report = detector.detectProtocol(
        deviceName: 'RE_Tripper_Himalayan_450',
        advertisedServices: ['0000fe50-0000-1000-8000-00805f9b34fb'],
        macAddress: '11:22:33:44:55:66',
      );

      expect(report.manufacturer, equals('Royal Enfield'));
      expect(report.modelName, equals('Himalayan 450'));
      expect(report.variantTrim, equals('Tripper TFT'));
      expect(report.hasTurnByTurnNav, isTrue);
      expect(report.hasSpeedTelemetry, isTrue);
    });

    test('Identifies Ather 450X Electric Scooter via 0x18F0 signature', () {
      final report = detector.detectProtocol(
        deviceName: 'Ather_450X_Gen3',
        advertisedServices: ['000018f0-0000-1000-8000-00805f9b34fb'],
        macAddress: '33:44:55:66:77:88',
      );

      expect(report.manufacturer, equals('Ather Energy'));
      expect(report.vehicleType, equals(VehicleClassificationType.scooterEv));
      expect(report.hasBatterySoc, isTrue);
    });

    test('Identifies Generic SAE J1979 OBD-II Gateway via 0xFFF0 signature', () {
      final report = detector.detectProtocol(
        deviceName: 'OBDII_ELM327_Gateway',
        advertisedServices: ['0000fff0-0000-1000-8000-00805f9b34fb'],
        macAddress: '88:99:AA:BB:CC:DD',
      );

      expect(report.protocolName, contains('SAE J1979'));
      expect(report.overallStatus, equals(CompatibilityReportStatus.readOnlySupported));
      expect(report.hasObdDiagnostics, isTrue);
    });

    test('Flags unknown GATT device as "Detected — Protocol Not Verified" with low confidence', () {
      final report = detector.detectProtocol(
        deviceName: 'Unknown_BLE_Device',
        advertisedServices: ['00001800-0000-1000-8000-00805f9b34fb'],
        macAddress: '99:88:77:66:55:44',
      );

      expect(report.overallStatus, equals(CompatibilityReportStatus.protocolNotVerified));
      expect(report.confidenceScore, lessThan(0.2));
      expect(report.statusExplanation, contains('Detected — Protocol Not Verified'));
      expect(report.areActiveCommandsBlocked, isTrue);
    });

    test('Exports sanitized compatibility report in JSON', () {
      final report = detector.detectProtocol(
        deviceName: 'Yamaha_Aerox_155',
        advertisedServices: ['0000fee0-0000-1000-8000-00805f9b34fb'],
        macAddress: 'AA:BB:CC:DD:EE:00',
      );

      final jsonMap = report.toJson();
      expect(jsonMap.containsKey('vehicle'), isTrue);
      expect(jsonMap.containsKey('capabilityMatrix'), isTrue);
      expect(jsonMap.containsKey('versioning'), isTrue);
      expect(json.encode(jsonMap).contains('password'), isFalse);
    });
  });
}
