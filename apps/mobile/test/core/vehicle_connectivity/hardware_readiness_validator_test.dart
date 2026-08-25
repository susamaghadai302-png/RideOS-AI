import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/models/packet_capture_models.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/services/structured_hardware_diagnostic_logger.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/services/hardware_readiness_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Hardware Readiness Validator & Diagnostic Logger Tests', () {
    late HardwareReadinessValidator validator;
    late StructuredHardwareDiagnosticLogger logger;

    setUp(() {
      validator = HardwareReadinessValidator();
      logger = StructuredHardwareDiagnosticLogger();
      logger.clearLogs();
    });

    test('Identifies Yamaha CCU and emits structured discovery logs', () {
      final result = validator.evaluateDiscoveredHardware(
        deviceName: 'Yamaha_CCU_98A2',
        advertisedServices: ['0000fee0-0000-1000-8000-00805f9b34fb'],
        macAddress: 'AA:BB:CC:DD:EE:FF',
        isSimulated: true,
      );

      expect(result.matchedModel, contains('YZF-R15M'));
      expect(result.protocolStatusLabel, contains('Verified Yamaha Y-Connect'));
      expect(result.sourceClassification, equals(CaptureSourceClassification.benchTest));
      expect(logger.logs.length, greaterThanOrEqualTo(2));
      expect(logger.logs.any((l) => l.eventType == DiagnosticEventType.vehicleIdentified), isTrue);
    });

    test('Identifies Royal Enfield Tripper and returns supported capabilities', () {
      final result = validator.evaluateDiscoveredHardware(
        deviceName: 'RE_Tripper_450',
        advertisedServices: ['0000fe50-0000-1000-8000-00805f9b34fb'],
        macAddress: '11:22:33:44:55:66',
        isSimulated: true,
      );

      expect(result.matchedModel, contains('Himalayan 450'));
      expect(result.availableCapabilities, contains('Turn-by-Turn HUD Mirror'));
    });

    test('Flags unknown devices with "Detected — Protocol Not Verified" and unverified status', () {
      final result = validator.evaluateDiscoveredHardware(
        deviceName: 'Unknown_Gadget',
        advertisedServices: ['00001800-0000-1000-8000-00805f9b34fb'],
        macAddress: '99:88:77:66:55:44',
        isSimulated: true,
      );

      expect(result.protocolStatusLabel, equals('Detected — Protocol Not Verified'));
      expect(result.verificationStatus, equals(HardwareBenchVerificationStatus.unverified));
    });

    test('Exports sanitized diagnostic logs without credential leakage', () {
      logger.log(
        eventType: DiagnosticEventType.connectionStateChange,
        severity: DiagnosticSeverity.info,
        deviceId: 'TEST_DEV_01',
        message: 'Connected to GATT peripheral',
      );

      final jsonStr = logger.exportSanitizedLogsJson();
      final list = json.decode(jsonStr) as List<dynamic>;

      expect(list, isNotEmpty);
      expect(jsonStr.contains('password'), isFalse);
      expect(jsonStr.contains('secret'), isFalse);
    });
  });
}
