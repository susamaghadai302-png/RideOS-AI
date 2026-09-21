import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/bluetooth/web/web_bluetooth_models.dart';
import 'package:rideos_mobile/core/bluetooth/web/web_bluetooth_manager.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/vehicle_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WebBluetoothManager webBle;
  late VehicleRegistry registry;

  setUp(() {
    webBle = WebBluetoothManager();
    registry = VehicleRegistry();
  });

  test('WebBluetoothManager initializes correctly', () {
    expect(webBle, isNotNull);
  });

  group('Phase 1 — Web Bluetooth BLE Architecture & Verification Tests', () {
    test('1. Web Bluetooth Models correctly serialize and deserialize support status', () {
      final jsonMap = {
        'supported': true,
        'isSecureContext': true,
        'isLocalhost': true,
        'userAgent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/122.0.0.0 Safari/537.36',
        'reason': 'Web Bluetooth is fully operational on macOS Chrome/Edge.',
      };

      final info = WebBleSupportInfo.fromJson(jsonMap);
      expect(info.isSupported, isTrue);
      expect(info.isSecureContext, isTrue);
      expect(info.isLocalhost, isTrue);
      expect(info.reason, contains('macOS Chrome'));
    });

    test('2. Web Bluetooth GATT Service and Characteristic Models parse accurately', () {
      final gattJson = {
        'success': true,
        'deviceId': 'ble_dev_c1284f09',
        'deviceName': 'CCU-R1M',
        'isConnected': true,
        'services': [
          {
            'uuid': '0000180f-0000-1000-8000-00805f9b34fb',
            'name': 'Battery Service',
            'isPrimary': true,
            'characteristicsCount': 1,
            'characteristics': [
              {
                'uuid': '00002a19-0000-1000-8000-00805f9b34fb',
                'properties': ['READ', 'NOTIFY'],
              }
            ]
          },
          {
            'uuid': '0000180a-0000-1000-8000-00805f9b34fb',
            'name': 'Device Information',
            'isPrimary': true,
            'characteristicsCount': 2,
            'characteristics': [
              {
                'uuid': '00002a24-0000-1000-8000-00805f9b34fb',
                'properties': ['READ'],
              },
              {
                'uuid': '00002a26-0000-1000-8000-00805f9b34fb',
                'properties': ['READ'],
              }
            ]
          }
        ]
      };

      final gattRes = WebBleGattResult.fromJson(gattJson);
      expect(gattRes.success, isTrue);
      expect(gattRes.deviceId, equals('ble_dev_c1284f09'));
      expect(gattRes.deviceName, equals('CCU-R1M'));
      expect(gattRes.services.length, equals(2));
      expect(gattRes.services.first.name, equals('Battery Service'));
      expect(gattRes.services.first.characteristics.first.properties, contains('READ'));
      expect(gattRes.services.first.characteristics.first.properties, contains('NOTIFY'));
    });

    test('3. User cancellation of BLE requestDevice is gracefully handled', () {
      final cancelJson = {
        'success': false,
        'cancelled': true,
        'error': 'User cancelled Bluetooth device selection.',
      };

      final cancelRes = WebBleRequestResult.fromJson(cancelJson);
      expect(cancelRes.success, isFalse);
      expect(cancelRes.cancelled, isTrue);
      expect(cancelRes.error, contains('User cancelled'));
    });

    test('4. Discovered Web Bluetooth device resolves to authentic vehicle profile in registry', () {
      const devName = 'Y-CONNECT-PRO';
      final matched = registry.findProfileByBluetoothName(devName);

      expect(matched, isNotNull);
      expect(matched!.manufacturer, equals('Yamaha'));
      expect(matched.model, equals('YZF-R1M'));
    });

    test('5. Discovered Ducati DMS device resolves to Ducati profile', () {
      const devName = 'DUCATI-DMS';
      final matched = registry.findProfileByBluetoothName(devName);

      expect(matched, isNotNull);
      expect(matched!.manufacturer, equals('Ducati'));
      expect(matched.model, equals('Panigale V4 S'));
    });

    test('6. Discovered BMW CCU device resolves to BMW profile', () {
      const devName = 'BMW-M1000RR';
      final matched = registry.findProfileByBluetoothName(devName);

      expect(matched, isNotNull);
      expect(matched!.manufacturer, equals('BMW'));
      expect(matched.model, equals('M 1000 RR'));
    });

    test('7. Discovered TVS SmartXonnect resolves to TVS Ntorq profile', () {
      const devName = 'TVS-NTORQ-RACEXP';
      final matched = registry.findProfileByBluetoothName(devName);

      expect(matched, isNotNull);
      expect(matched!.manufacturer, equals('TVS'));
      expect(matched.model, equals('Ntorq 125'));
    });
  });
}
