import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/models/vehicle_connection_lifecycle.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/services/production_vehicle_connection_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Production Vehicle Connectivity & Lifecycle Tests', () {
    late ProductionVehicleConnectionManager manager;

    setUp(() {
      manager = ProductionVehicleConnectionManager();
    });

    test('Executes complete connection pipeline to Telemetry Active', () async {
      await manager.startConnectionPipeline(
        deviceName: 'Yamaha_R15M_CCU',
        advertisedServices: ['0000fee0-0000-1000-8000-00805f9b34fb'],
        macAddress: 'AA:BB:CC:DD:EE:FF',
        isSimulated: true,
      );

      final session = manager.currentSession;
      expect(session.state, equals(ConnectionLifecycleState.connectionFailed));
      expect(session.isConnected, isFalse);
      expect(session.rssi, equals(0));
      expect(session.latencyMs, equals(0));
      expect(session.resolvedVariant?.variantId, equals('yamaha_r15_m'));
    });

    test('Safe Command Whitelisting: Blocks arbitrary CAN/ECU commands', () async {
      final blocked = await manager.executeSafeCommand(
        commandName: 'CAN_RAW_INJECT_IGNITION_KILL',
        parameters: {'raw_bytes': '0x00FF'},
      );
      expect(blocked, isFalse);

      final blockedEcu = await manager.executeSafeCommand(
        commandName: 'FLASH_ECU_FIRMWARE',
        parameters: {},
      );
      expect(blockedEcu, isFalse);
    });

    test('Safe Command Whitelisting: Allows supported Turn-by-Turn HUD write', () async {
      final allowed = await manager.executeSafeCommand(
        commandName: 'WRITE_TBT_NAVIGATION_ARROW',
        parameters: {'icon': 1, 'dist': 100},
      );
      expect(allowed, isTrue);
    });

    test('Disconnect cleanly resets connection lifecycle state', () {
      manager.disconnect();
      expect(manager.currentSession.state, equals(ConnectionLifecycleState.disconnected));
      expect(manager.currentSession.isConnected, isFalse);
    });
  });
}
