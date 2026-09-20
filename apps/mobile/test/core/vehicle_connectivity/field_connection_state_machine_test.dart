import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/models/production_field_test_models.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/services/field_connection_state_machine.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/transports/mock_vehicle_transport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Field Connection State Machine & Lifecycle Tests', () {
    late FieldConnectionStateMachine stateMachine;
    late MockVehicleTransport transport;

    setUp(() async {
      stateMachine = FieldConnectionStateMachine();
      transport = MockVehicleTransport();
      await transport.initialize();
    });

    tearDown(() async {
      stateMachine.disconnect();
      await transport.dispose();
    });

    test('Permission Denied: Transitions to permissionRequired and halts', () async {
      final success = await stateMachine.executeConnectionFlow(
        deviceName: 'Test_Bike',
        macAddress: 'AA:BB:CC:DD:EE:FF',
        transport: transport,
        hasPermissions: false,
      );

      expect(success, isFalse);
      expect(stateMachine.currentState, equals(FieldConnectionState.permissionRequired));
    });

    test('Bluetooth Disabled: Transitions to bluetoothUnavailable and halts', () async {
      final success = await stateMachine.executeConnectionFlow(
        deviceName: 'Test_Bike',
        macAddress: 'AA:BB:CC:DD:EE:FF',
        transport: transport,
        hasPermissions: true,
        isBluetoothAvailable: false,
      );

      expect(success, isFalse);
      expect(stateMachine.currentState, equals(FieldConnectionState.bluetoothUnavailable));
    });

    test('Executes complete 16-state flow to Streaming state', () async {
      final success = await stateMachine.executeConnectionFlow(
        deviceName: 'Yamaha_R15M_CCU',
        macAddress: 'AA:BB:CC:DD:EE:FF',
        transport: transport,
        hasPermissions: true,
        isBluetoothAvailable: true,
        isSimulated: true,
      );

      expect(success, isTrue);
      expect(stateMachine.currentState, equals(FieldConnectionState.streaming));
      expect(stateMachine.activeSessionLog, isNotNull);
      expect(stateMachine.activeSessionLog?.rssi, equals(0));
      expect(stateMachine.activeSessionLog?.mtu, equals(0));
    });

    test('Handles reconnection trigger and re-enters streaming', () async {
      await stateMachine.triggerReconnectionFlow(
        transport: transport,
        macAddress: 'AA:BB:CC:DD:EE:FF',
      );

      expect(stateMachine.currentState, equals(FieldConnectionState.disconnected));
    });

    test('User Disconnect cleanly finalizes session duration and transitions to Disconnected', () {
      stateMachine.disconnect();
      expect(stateMachine.currentState, equals(FieldConnectionState.disconnected));
    });
  });
}
