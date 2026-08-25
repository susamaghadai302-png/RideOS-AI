import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/helmet/core/services/smart_helmet_service.dart';

void main() {
  group('Phase 5 - Smart Helmet Abstraction Layer Tests', () {
    late SmartHelmetService helmetService;

    setUp(() {
      helmetService = SmartHelmetService();
    });

    tearDown(() async {
      await helmetService.disconnect();
    });

    test('Initializes in disconnected state', () {
      expect(helmetService.state, equals(SmartHelmetConnectionState.disconnected));
      expect(helmetService.isConnected, isFalse);
      expect(helmetService.connectedDevice, isNull);
    });

    test('Connects simulated smart helmet device and establishes audio profile', () async {
      await helmetService.connectSimulatedHelmet();
      expect(helmetService.isConnected, isTrue);
      expect(helmetService.state, equals(SmartHelmetConnectionState.connected));
      expect(helmetService.connectedDevice?.name, contains('Smart Helmet'));
      expect(helmetService.connectedDevice?.batteryLevelPct, equals(88));
      expect(helmetService.audioProfile, equals(SmartHelmetAudioProfile.noiseCancellationActive));
    });

    test('Streams HUD turn metadata when helmet is connected', () async {
      await helmetService.connectSimulatedHelmet();

      const testMetadata = SmartHelmetHudTurnMetadata(
        turnInstruction: 'Turn right on Pacific Coast Hwy in 250m',
        distanceMeters: 250.0,
        speedLimitKmh: 65,
        currentSpeedKmh: 58,
      );

      expectLater(
        helmetService.hudStream,
        emits(predicate<SmartHelmetHudTurnMetadata>((m) {
          return m.turnInstruction == testMetadata.turnInstruction &&
              m.distanceMeters == 250.0 &&
              m.currentSpeedKmh == 58;
        })),
      );

      helmetService.streamHudTurnMetadata(testMetadata);
    });

    test('Cleanly disconnects and resets state without leaks', () async {
      await helmetService.connectSimulatedHelmet();
      expect(helmetService.isConnected, isTrue);

      await helmetService.disconnect();
      expect(helmetService.isConnected, isFalse);
      expect(helmetService.state, equals(SmartHelmetConnectionState.disconnected));
      expect(helmetService.connectedDevice, isNull);
    });
  });
}
