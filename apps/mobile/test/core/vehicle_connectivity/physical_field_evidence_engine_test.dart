import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/models/physical_field_evidence_models.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/transports/vehicle_transport.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/services/physical_field_evidence_engine.dart';
import 'mocks/mock_vehicle_transport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Physical Field Evidence Engine Tests', () {
    late PhysicalFieldEvidenceEngine engine;
    late MockVehicleTransport transport;

    setUp(() async {
      engine = PhysicalFieldEvidenceEngine();
      transport = MockVehicleTransport();
      await transport.initialize();
      await transport.connect('EVIDENCE_TEST_LINK');
    });

    tearDown(() async {
      await transport.dispose();
    });

    test('Records session, samples RSSI, and calculates average RSSI accurately', () async {
      engine.startEvidenceSession(
        transport: transport,
        deviceName: 'Test_Yamaha_CCU',
        macAddress: 'AA:BB:CC:DD:EE:FF',
        manufacturer: 'Yamaha Motor Co.',
        modelName: 'YZF-R15M',
        variantTrim: 'Top Premium TFT',
        modelYear: '2023',
        protocolName: 'Yamaha Y-Connect GATT',
        initialMtu: 185,
        isSimulated: true,
      );

      expect(engine.isRecording, isTrue);

      engine.recordRssiSample(-60);
      engine.recordRssiSample(-70);

      transport.injectValidFrame(
        speedKmh: 45,
        rpm: 4800,
        batteryVoltage: 13.6,
        coolantTemp: 86,
        fuelPct: 80,
      );

      await Future.delayed(const Duration(milliseconds: 50));

      final record = engine.stopEvidenceSession(
        deviceName: 'Test_Yamaha_CCU',
        macAddress: 'AA:BB:CC:DD:EE:FF',
        manufacturer: 'Yamaha Motor Co.',
        modelName: 'YZF-R15M',
        variantTrim: 'Top Premium TFT',
        modelYear: '2023',
        protocolName: 'Yamaha Y-Connect GATT',
        negotiatedMtu: 185,
        isPhysicalHardwareTest: false,
      );

      expect(record.averageRssi, equals(-65.0));
      expect(record.totalPacketsCaptured, equals(1));
      expect(record.evidenceLevel, equals(FieldEvidenceLevel.benchTest));
      expect(record.privacySafeMac, equals('AA:BB::XX:XX:FF'));
    });

    test('Promotes to realDeviceVerified only when physical test has >= 100 clean frames', () async {
      engine.startEvidenceSession(
        transport: transport,
        deviceName: 'Physical_Yamaha_CCU',
        macAddress: '11:22:33:44:55:66',
        manufacturer: 'Yamaha Motor Co.',
        modelName: 'YZF-R15M',
        variantTrim: 'Top Premium TFT',
        modelYear: '2023',
        protocolName: 'Yamaha Y-Connect GATT',
        initialMtu: 185,
      );

      for (int i = 0; i < 105; i++) {
        transport.injectValidFrame(
          speedKmh: 50,
          rpm: 5000,
          batteryVoltage: 13.8,
          coolantTemp: 88,
          fuelPct: 75,
        );
      }

      await Future.delayed(const Duration(milliseconds: 50));

      final record = engine.stopEvidenceSession(
        deviceName: 'Physical_Yamaha_CCU',
        macAddress: '11:22:33:44:55:66',
        manufacturer: 'Yamaha Motor Co.',
        modelName: 'YZF-R15M',
        variantTrim: 'Top Premium TFT',
        modelYear: '2023',
        protocolName: 'Yamaha Y-Connect GATT',
        negotiatedMtu: 185,
        isPhysicalHardwareTest: true,
      );

      expect(record.evidenceLevel, equals(FieldEvidenceLevel.realDeviceVerified));
      expect(record.checksumFailures, equals(0));
      expect(record.warnings, isEmpty);
    });

    test('Exports sanitized evidence report in JSON', () {
      final record = PhysicalTestEvidenceRecord(
        evidenceId: 'TEST_EVID_01',
        recordTimestamp: DateTime(2026, 8, 16, 23, 0),
        deviceName: 'RE_Tripper_Field',
        privacySafeMac: '11:22::XX:XX:66',
        manufacturer: 'Royal Enfield',
        modelName: 'Himalayan 450',
        variantTrim: 'Tripper TFT',
        modelYear: '2024',
        transport: VehicleTransportType.ble,
        protocolName: 'Tripper GATT',
        negotiatedMtu: 185,
        totalPacketsCaptured: 50,
        checksumFailures: 0,
        malformedPackets: 0,
        reconnectEvents: 0,
        testDuration: const Duration(seconds: 30),
        averageNotificationFrequencyHz: 10.0,
        evidenceLevel: FieldEvidenceLevel.realDevicePending,
      );

      final jsonStr = engine.exportEvidenceReportJson(record);
      final map = json.decode(jsonStr) as Map<String, dynamic>;

      expect(map['evidenceId'], equals('TEST_EVID_01'));
      expect(map['evidenceLevel'], equals('REAL DEVICE PENDING'));
      expect(map.containsKey('disclaimer'), isTrue);
    });
  });
}
