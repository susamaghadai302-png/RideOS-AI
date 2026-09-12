import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/transport/adapters/ble_gatt_adapter.dart';
import 'package:rideos_mobile/core/transport/models/transport_types.dart';
import 'package:rideos_mobile/core/transport/models/transport_device.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BleGattTransportAdapter Tests - Permission & GATT readiness', () {
    late BleGattTransportAdapter adapter;

    setUp(() {
      adapter = BleGattTransportAdapter();
      
      // Mock permission handler
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/permissions/methods'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'checkPermissionStatus') {
            return 0; // 0 = denied
          }
          if (methodCall.method == 'requestPermissions') {
            return {
              19: 0, 34: 0, 35: 0,
            };
          }
          return null;
        },
      );
      
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_blue_plus/methods'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'isSupported') {
            return true;
          }
          if (methodCall.method == 'getAdapterState') {
            return 1; // 1 = on
          }
          if (methodCall.method == 'connect') {
            return null; // success
          }
          if (methodCall.method == 'discoverServices') {
            return []; // No services!
          }
          if (methodCall.method == 'stopScan') {
            return null;
          }
          return null;
        },
      );
    });

    test('permission is not unconditionally granted', () async {
      final state = await adapter.checkPermission();
      expect(state, equals(TransportPermissionState.denied));
    });

    test('permission result is propagated correctly', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/permissions/methods'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'checkPermissionStatus') {
            return 1; // 1 = granted
          }
          return null;
        },
      );
      final state = await adapter.checkPermission();
      expect(state, equals(TransportPermissionState.granted));
    });

    test('capabilities reflect permission state', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/permissions/methods'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'checkPermissionStatus') {
            return 0; // denied
          }
          return null;
        },
      );
      final caps = await adapter.getCapabilities();
      expect(caps.hasPermission, isFalse);
    });

    test('missing required GATT characteristics cannot produce READY', () async {
      final device = TransportDevice(
        deviceId: 'TEST_DEVICE_1',
        displayName: 'TEST',
        address: 'TEST',
        lastSeen: DateTime.now(),
        transportType: TransportType.bluetoothLowEnergy,
      );

      try {
        await adapter.connect(device, timeout: const Duration(milliseconds: 500));
        fail('Should have thrown TransportError');
      } catch (e) {
        expect(adapter.currentState, isNot(equals(TransportState.ready)));
      }
    });
  });
}
