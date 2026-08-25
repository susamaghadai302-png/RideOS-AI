import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/services/ble_characteristic_tuning_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BLE Characteristic Tuning & Stream Scenario Tests', () {
    late BleCharacteristicTuningEngine engine;

    setUp(() {
      engine = BleCharacteristicTuningEngine();
    });

    tearDown(() {
      engine.stopScenario();
    });

    test('Initializes stable connection scenario with optimal MTU and RSSI', () {
      engine.startScenario(BleStreamScenario.stableConnection);
      final state = engine.currentState;

      expect(state.isStreaming, isTrue);
      expect(state.mtu, equals(185));
      expect(state.rssi, equals(-58));
      expect(state.isSubscribedToCharacteristics, isTrue);
      expect(state.vehicleProfileLabel, contains('Yamaha'));
    });

    test('Weak signal scenario simulates severe RSSI attenuation', () async {
      engine.startScenario(BleStreamScenario.weakSignal);
      expect(engine.currentState.rssi, equals(-88));

      await Future.delayed(const Duration(milliseconds: 150));
      expect(engine.currentState.rssi, lessThanOrEqualTo(-85));
    });

    test('Unknown vehicle scenario flags protocol as unverified', () {
      engine.startScenario(BleStreamScenario.unknownVehicle);
      final state = engine.currentState;

      expect(state.protocolVerificationLabel, equals('Detected — Protocol Not Verified'));
      expect(state.vehicleProfileLabel, equals('Unknown Two-Wheeler'));
      expect(state.mtu, equals(23));
    });

    test('Packet loss scenario increments dropped packet count', () async {
      engine.startScenario(BleStreamScenario.packetLoss);

      await Future.delayed(const Duration(milliseconds: 650));
      expect(engine.currentState.packetsDropped, greaterThanOrEqualTo(1));
    });

    test('Stops scenario cleanly and halts periodic timers', () {
      engine.startScenario(BleStreamScenario.stableConnection);
      expect(engine.currentState.isStreaming, isTrue);

      engine.stopScenario();
      expect(engine.currentState.isStreaming, isFalse);
    });
  });
}
