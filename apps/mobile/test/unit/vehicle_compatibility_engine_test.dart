import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:rideos_mobile/core/vehicle_protocols/protocol_detector.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/vehicle_registry.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/vehicle_model_registry.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/vehicle_compatibility_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Vehicle Registry Tests', () {
    test('Contains verified profiles with exact maintenance and spec details', () {
      final registry = VehicleRegistry();
      final profiles = registry.verifiedProfiles;

      expect(profiles.length, greaterThanOrEqualTo(4));

      final mt09 = registry.getProfileById('v_yamaha_mt09_sp');
      expect(mt09, isNotNull);
      expect(mt09!.manufacturer, 'Yamaha');
      expect(mt09.protocolAdapter, 'yamaha_y_connect');
      expect(mt09.maintenanceIntervals.containsKey('engineOilKm'), isTrue);

      final v4s = registry.getProfileById('v_ducati_v4s');
      expect(v4s, isNotNull);
      expect(v4s!.manufacturer, 'Ducati');
      expect(v4s.protocolAdapter, 'ducati_multimedia');
    });

    test('Resolves vehicle profile by matching Bluetooth identifiers', () {
      final registry = VehicleRegistry();

      final yamaha = registry.findProfileByBluetoothName('YAMAHA-CCU-9801');
      expect(yamaha, isNotNull);
      expect(yamaha!.manufacturer, 'Yamaha');

      final ducati = registry.findProfileByBluetoothName('DUCATI-DMS-V4');
      expect(ducati, isNotNull);
      expect(ducati!.manufacturer, 'Ducati');

      final unknown = registry.findProfileByBluetoothName('UnknownHeadphones');
      expect(unknown, isNull);
    });
  });

  group('Vehicle Model Registry Tests', () {
    test('Identifies 3D model availability strictly without fake substitutes', () {
      final modelRegistry = VehicleModelRegistry();

      final r1m = modelRegistry.getModelConfig('v_yamaha_r1m');
      expect(r1m.modelAvailable, isFalse);
      expect(r1m.modelPath, isEmpty);

      final panigale = modelRegistry.getModelConfig('v_ducati_v4s');
      expect(panigale.modelAvailable, isTrue);
      expect(panigale.modelPath, 'assets/models/ducati_panigale.glb');

      final genericObd = modelRegistry.getModelConfig('v_generic_obd2');
      expect(genericObd.modelAvailable, isFalse);
      expect(genericObd.modelPath, isEmpty);

      final nonExistent = modelRegistry.getModelConfig('v_unknown_random');
      expect(nonExistent.modelAvailable, isFalse);
    });
  });

  group('Vehicle Compatibility & Protocol Detection Tests', () {
    test('ProtocolDetector identifies Yamaha CCU GATT UUIDs', () {
      final detector = ProtocolDetector();
      final adv = AdvertisementData(
        advName: 'CCU-Yamaha',
        txPowerLevel: null,
        appearance: null,
        connectable: true,
        manufacturerData: {},
        serviceData: {},
        serviceUuids: [Guid('0000fee0-0000-1000-8000-00805f9b34fb')],
      );

      final device = BluetoothDevice(remoteId: const DeviceIdentifier('AA:BB:CC:DD:EE:01'));
      final result = detector.detectFromScan(device: device, advertisementData: adv);

      expect(result.isSupported, isTrue);
      expect(result.adapterId, 'yamaha_y_connect');
      expect(result.confidence, greaterThan(0.9));
    });

    test('ProtocolDetector identifies standard OBD-II ELM327 devices', () {
      final detector = ProtocolDetector();
      final adv = AdvertisementData(
        advName: 'OBDLink MX+',
        txPowerLevel: null,
        appearance: null,
        connectable: true,
        manufacturerData: {},
        serviceData: {},
        serviceUuids: [Guid('0000fff0-0000-1000-8000-00805f9b34fb')],
      );

      final device = BluetoothDevice(remoteId: const DeviceIdentifier('AA:BB:CC:DD:EE:02'));
      final result = detector.detectFromScan(device: device, advertisementData: adv);

      expect(result.isSupported, isTrue);
      expect(result.adapterId, 'obd2_standard');
    });

    test('ProtocolDetector marks non-automotive devices as unknown', () {
      final detector = ProtocolDetector();
      final adv = AdvertisementData(
        advName: 'SmartBulb',
        txPowerLevel: null,
        appearance: null,
        connectable: true,
        manufacturerData: {},
        serviceData: {},
        serviceUuids: [],
      );

      final device = BluetoothDevice(remoteId: const DeviceIdentifier('AA:BB:CC:DD:EE:03'));
      final result = detector.detectFromScan(device: device, advertisementData: adv);

      expect(result.isSupported, isFalse);
      expect(result.state, ProtocolDetectionState.unknown);
    });

    test('VehicleCompatibilityEngine evaluates device scan and computes report', () {
      final engine = VehicleCompatibilityEngine();
      final adv = AdvertisementData(
        advName: 'CCU-Yamaha-R1M',
        txPowerLevel: null,
        appearance: null,
        connectable: true,
        manufacturerData: {},
        serviceData: {},
        serviceUuids: [Guid('0000fee0-0000-1000-8000-00805f9b34fb')],
      );

      final device = BluetoothDevice(remoteId: const DeviceIdentifier('AA:BB:CC:DD:EE:04'));
      final report = engine.evaluateDevice(device: device, advertisementData: adv);

      expect(report.status, CompatibilityStatus.supported);
      expect(report.profile.manufacturer, 'Yamaha');
      expect(report.has3DModel, isFalse);
      expect(report.supportedCapabilities.contains('speed'), isTrue);
    });
  });
}
