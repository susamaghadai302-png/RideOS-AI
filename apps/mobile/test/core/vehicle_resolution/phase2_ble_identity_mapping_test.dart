import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_resolution/models/vehicle_identity.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/vehicle_identity_resolver.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/vehicle_model_registry.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/vehicle_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VehicleIdentityResolver resolver;
  late VehicleModelRegistry modelRegistry;
  late VehicleRegistry registry;

  setUp(() {
    resolver = VehicleIdentityResolver();
    modelRegistry = VehicleModelRegistry();
    registry = VehicleRegistry();
  });

  group('Phase 2 — Real BLE Device Identification & Vehicle Mapping Tests', () {
    test('1. Exact BLE Name: Honda Activa 6G resolves with VERIFIED confidence', () {
      final res = resolver.resolveBleDevice(
        deviceName: 'HONDA-ACTIVA-6G-SMART',
        deviceId: 'c4:5b:be:11:22:33',
        transportType: ConnectionTransportType.ble,
      );

      expect(res.isVerified, isTrue);
      expect(res.identity.confidence, equals(IdentityConfidence.exactMatch));
      expect(res.identity.make, equals('Honda'));
      expect(res.identity.model, equals('Activa 6G'));
      expect(res.identity.connectionType.userFacingLabel, equals('REAL BLE DETECTED'));
      expect(res.hasVerified3DModel, isFalse); // Truthful: no fake 3D model
    });

    test('2. Exact BLE Name: Ducati Panigale V4 S resolves with VERIFIED and OEM 3D Model', () {
      final res = resolver.resolveBleDevice(
        deviceName: 'DUCATI-DMS-V4S',
        deviceId: 'd4:36:39:aa:bb:cc',
        transportType: ConnectionTransportType.ble,
      );

      expect(res.isVerified, isTrue);
      expect(res.identity.make, equals('Ducati'));
      expect(res.identity.model, equals('Panigale V4 S'));
      expect(res.hasVerified3DModel, isTrue);
      expect(res.model3DConfig?.modelAssetPath, equals('assets/models/ducati_panigale.glb'));
      expect(res.model3DConfig?.isVerified, isTrue);
    });

    test('3. Exact BLE Name: BMW M 1000 RR resolves with VERIFIED and OEM 3D Model', () {
      final res = resolver.resolveBleDevice(
        deviceName: 'BMW-M1000RR-COMPETITION',
        deviceId: '00:1a:7d:11:22:33',
        transportType: ConnectionTransportType.ble,
      );

      expect(res.isVerified, isTrue);
      expect(res.identity.make, equals('BMW'));
      expect(res.identity.model, equals('M 1000 RR'));
      expect(res.hasVerified3DModel, isTrue);
      expect(res.model3DConfig?.modelAssetPath, equals('assets/models/bmw_m1000rr.glb'));
    });

    test('4. Exact BLE Name: Suzuki Burgman Street 125 resolves with VERIFIED confidence', () {
      final res = resolver.resolveBleDevice(
        deviceName: 'SUZUKI-BURGMAN-125-EX',
        deviceId: '00:11:22:33:44:55',
        transportType: ConnectionTransportType.ble,
      );

      expect(res.isVerified, isTrue);
      expect(res.identity.make, equals('Suzuki'));
      expect(res.identity.model, equals('Burgman Street 125 EX'));
      expect(res.hasVerified3DModel, isFalse);
    });

    test('5. Brand Family Only: Generic Honda RoadSync resolves as IDENTIFIED without claiming exact model', () {
      final res = resolver.resolveBleDevice(
        deviceName: 'HONDA-ROADSYNC-MODULE',
        deviceId: 'c4:5b:be:99:88:77',
        transportType: ConnectionTransportType.ble,
      );

      expect(res.isVerified, isFalse);
      expect(res.isIdentified, isTrue);
      expect(res.identity.confidence, equals(IdentityConfidence.verifiedMatch));
      expect(res.identity.make, equals('Honda'));
      expect(res.identity.model, contains('Model Validation Pending'));
      expect(res.hasVerified3DModel, isFalse);
      expect(res.model3DConfig?.modelStatus, equals('MODEL VALIDATION PENDING'));
    });

    test('6. Brand Family Only: Generic Yamaha Y-Connect resolves as IDENTIFIED without fake 3D model', () {
      final res = resolver.resolveBleDevice(
        deviceName: 'Y-CONNECT-GENERIC-CCU',
        deviceId: 'ec:da:3b:11:22:33',
        transportType: ConnectionTransportType.ble,
      );

      expect(res.isVerified, isFalse);
      expect(res.isIdentified, isTrue);
      expect(res.identity.make, equals('Yamaha'));
      expect(res.hasVerified3DModel, isFalse);
    });

    test('7. Universal OBD-II Gateway resolves with OBD transport and no motorcycle 3D model', () {
      final res = resolver.resolveBleDevice(
        deviceName: 'OBDLink MX+ BLE',
        deviceId: '00:04:3e:44:55:66',
        transportType: ConnectionTransportType.ble,
      );

      expect(res.identity.connectionType, equals(ConnectionTransportType.obdGateway));
      expect(res.identity.model, equals('OBD-II Gateway'));
      expect(res.hasVerified3DModel, isFalse);
    });

    test('8. CRITICAL: Unknown BLE device NEVER defaults to Yamaha YZF-R1M or another bike', () {
      final res = resolver.resolveBleDevice(
        deviceName: 'FITNESS-BAND-BLE-88',
        deviceId: 'aa:bb:cc:dd:ee:ff',
        transportType: ConnectionTransportType.ble,
      );

      expect(res.isUnknown, isTrue);
      expect(res.identity.confidence, equals(IdentityConfidence.unknown));
      expect(res.identity.make, equals('Unknown'));
      expect(res.identity.model, equals('FITNESS-BAND-BLE-88'));
      expect(res.profile, isNull);
      expect(res.hasVerified3DModel, isFalse);
      expect(res.model3DConfig?.modelAssetPath, isEmpty);
    });

    test('9. Diagnostic logging generates complete 4-step pipeline trace', () {
      final res = resolver.resolveBleDevice(
        deviceName: 'TVS-NTORQ-RACEXP',
        deviceId: 'tvs_ble_909',
        transportType: ConnectionTransportType.ble,
      );

      expect(res.diagnosticLog, contains('[1/4 BLE Device Detected]'));
      expect(res.diagnosticLog, contains('[2/4 Identity Resolved]'));
      expect(res.diagnosticLog, contains('[3/4 Vehicle Profile Activated]'));
      expect(res.diagnosticLog, contains('[4/4 3D Asset Resolution]'));
    });

    test('10. Switching vehicles dynamically updates active vehicle context without cross-contamination', () {
      // Start with Ducati
      final ducatiProfile = registry.getProfileById('v_ducati_v4s')!;
      final ducatiConfig = modelRegistry.getModelConfigForProfile(ducatiProfile);
      expect(ducatiConfig.isVerified, isTrue);
      expect(ducatiConfig.modelAssetPath, equals('assets/models/ducati_panigale.glb'));

      // Switch to Honda Activa 6G
      final activaProfile = registry.getProfileById('v_honda_activa_6g')!;
      final activaConfig = modelRegistry.getModelConfigForProfile(activaProfile);
      expect(activaConfig.modelAssetPath, isEmpty); // Must NOT retain Ducati or Yamaha model
      expect(activaConfig.isVerified, isFalse);
      expect(activaConfig.requiresRealVehicleScan, isTrue);

      // Switch to BMW M 1000 RR
      final bmwProfile = registry.getProfileById('v_bmw_m1000rr')!;
      final bmwConfig = modelRegistry.getModelConfigForProfile(bmwProfile);
      expect(bmwConfig.isVerified, isTrue);
      expect(bmwConfig.modelAssetPath, equals('assets/models/bmw_m1000rr.glb'));
    });

    test('11. Manual Selection and Simulator Transports are distinctly labeled', () {
      expect(ConnectionTransportType.ble.userFacingLabel, equals('REAL BLE DETECTED'));
      expect(ConnectionTransportType.manualSelection.userFacingLabel, equals('MANUAL SELECTION'));
      expect(ConnectionTransportType.simulator.userFacingLabel, equals('SIMULATOR'));
    });
  });
}
