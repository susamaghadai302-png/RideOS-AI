import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/models/packet_capture_models.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/services/packet_capture_engine.dart';
import 'mocks/mock_vehicle_transport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Packet Capture Engine & Diagnostic Test Bench Tests', () {
    late PacketCaptureEngine engine;
    late MockVehicleTransport transport;

    setUp(() async {
      engine = PacketCaptureEngine();
      transport = MockVehicleTransport();
      await transport.initialize();
      await transport.connect('MOCK_TEST_CCU');
    });

    tearDown(() async {
      engine.stopSession();
      await transport.dispose();
    });

    test('Starts session, captures valid frame and formats hex string representation', () async {
      engine.startSession(
        transport: transport,
        deviceId: 'TEST_GATT_CCU_01',
        deviceName: 'Yamaha Y-Connect Test Bench',
        manufacturer: 'Yamaha Motor Co.',
        mtu: 185,
        services: ['0000fee0-0000-1000-8000-00805f9b34fb'],
        characteristics: ['0000fee1-0000-1000-8000-00805f9b34fb'],
        sourceClassification: CaptureSourceClassification.benchTest,
        verificationStatus: HardwareBenchVerificationStatus.benchVerified,
      );

      transport.injectValidFrame(
        speedKmh: 50,
        rpm: 5000,
        batteryVoltage: 13.5,
        coolantTemp: 86,
        fuelPct: 80,
      );

      await Future.delayed(const Duration(milliseconds: 50));
      final session = engine.currentSession;

      expect(session.isRecording, isTrue);
      expect(session.totalFramesCaptured, equals(1));
      expect(session.frames.first.payloadHex, contains('AA 55'));
      expect(session.frames.first.isChecksumValid, isTrue);
      expect(session.frames.first.direction, equals(CaptureFrameDirection.inbound));
      expect(session.sourceClassification, equals(CaptureSourceClassification.benchTest));
    });

    test('Identifies and flags malformed/corrupted frames in capture stream', () async {
      engine.startSession(
        transport: transport,
        deviceId: 'TEST_CORRUPT_BENCH',
        deviceName: 'Corrupt Diagnostic Source',
        manufacturer: 'Universal Standards',
        mtu: 23,
        services: [],
        characteristics: [],
      );

      transport.injectMalformedFrame();

      await Future.delayed(const Duration(milliseconds: 50));
      final session = engine.currentSession;

      expect(session.totalFramesCaptured, equals(1));
      expect(session.malformedFramesCount, equals(1));
      expect(session.frames.first.isChecksumValid, isFalse);
    });

    test('Exports sanitized diagnostic report in JSON without credential leakage', () async {
      engine.startSession(
        transport: transport,
        deviceId: 'SECURE_DEVICE_99',
        deviceName: 'Diagnostic Device',
        manufacturer: 'Test OEM',
        mtu: 64,
        services: ['00001800-0000-1000-8000-00805f9b34fb'],
        characteristics: [],
      );

      transport.injectValidFrame(
        speedKmh: 20,
        rpm: 2000,
        batteryVoltage: 12.6,
        coolantTemp: 75,
        fuelPct: 90,
      );

      await Future.delayed(const Duration(milliseconds: 50));
      final jsonStr = engine.exportDiagnosticReportJson();

      final decoded = json.decode(jsonStr) as Map<String, dynamic>;
      expect(decoded.containsKey('deviceInfo'), isTrue);
      expect(decoded['deviceInfo']['deviceId'], equals('SECURE_DEVICE_99'));
      expect(decoded.containsKey('status'), isTrue);
      expect(decoded.containsKey('recentFrames'), isTrue);
      // Ensure no passwords or tokens exist
      expect(jsonStr.contains('password'), isFalse);
      expect(jsonStr.contains('secret'), isFalse);
    });
  });
}
