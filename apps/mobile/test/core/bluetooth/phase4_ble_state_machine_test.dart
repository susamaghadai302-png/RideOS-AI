import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/bluetooth/connection_manager.dart';
import 'package:rideos_mobile/core/bluetooth/models/bluetooth_connection_state.dart';

void main() {
  group('Phase 4 - BLE Connection State Machine Tests', () {
    late ConnectionManager connectionManager;

    setUp(() {
      connectionManager = ConnectionManager();
    });

    test('Initial connectedDevice is null', () {
      expect(connectionManager.connectedDevice, isNull);
    });

    test('BluetoothConnectionState enum values map correctly', () {
      expect(BluetoothConnectionState.connected.name, 'connected');
      expect(BluetoothConnectionState.disconnected.name, 'disconnected');
      expect(BluetoothConnectionState.connecting.name, 'connecting');
      expect(BluetoothConnectionState.reconnecting.name, 'reconnecting');
      expect(BluetoothConnectionState.live.name, 'live');
    });

    test('Disconnect resets connectedDevice cleanly', () async {
      await connectionManager.disconnect();
      expect(connectionManager.connectedDevice, isNull);
    });
  });
}
