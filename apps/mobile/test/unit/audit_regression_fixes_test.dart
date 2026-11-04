import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_resolution/models/vehicle_identity.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/vehicle_model_resolver.dart';
import 'package:rideos_mobile/core/bluetooth/permission_manager.dart';
import 'package:rideos_mobile/core/transport/adapters/ble_gatt_adapter.dart';
import 'package:rideos_mobile/core/transport/models/transport_types.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'checkPermissionStatus') {
          return 1; // 1 = granted
        }
        if (methodCall.method == 'requestPermissions') {
          return {19: 1, 34: 1, 35: 1};
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      null,
    );
  });

  group('Audit & Bug Fixing Regression Tests', () {
    test('Fallback garage studio assets exist and are non-empty on disk', () {
      final bikeFile = File('assets/garage/generic_bike.png');
      expect(bikeFile.existsSync(), isTrue, reason: 'generic_bike.png must exist');
      expect(bikeFile.lengthSync(), greaterThan(1000));

      final scooterFile = File('assets/garage/generic_scooter.png');
      expect(scooterFile.existsSync(), isTrue, reason: 'generic_scooter.png must exist');
      expect(scooterFile.lengthSync(), greaterThan(1000));
    });

    test('VehicleModelResolver resolves generic scooter and motorcycle thumbnails without exception', () {
      final resolver = VehicleModelResolver();

      final scooterIdentity = VehicleIdentity(
        connectionType: ConnectionTransportType.manualSelection,
        deviceIdentifier: 'dev_scooter_01',
        manufacturer: 'Ather',
        model: '450X',
        variant: 'EV Scooter Gen 3',
        protocolAdapterId: 'generic_ble',
        confidence: IdentityConfidence.verifiedMatch,
      );

      final scooterResolution = resolver.resolveIdentity(scooterIdentity);
      expect(scooterResolution.thumbnailPath, equals('assets/garage/generic_scooter.png'));

      final bikeIdentity = VehicleIdentity(
        connectionType: ConnectionTransportType.manualSelection,
        deviceIdentifier: 'dev_bike_unknown',
        manufacturer: 'Custom',
        model: 'Special 500',
        variant: 'Roadster',
        protocolAdapterId: 'generic_obd2',
        confidence: IdentityConfidence.verifiedMatch,
      );

      final bikeResolution = resolver.resolveIdentity(bikeIdentity);
      expect(bikeResolution.thumbnailPath, equals('assets/garage/generic_bike.png'));
    });

    test('PermissionManager executes safely without crashing on platform checks', () async {
      final pm = PermissionManager();
      expect(pm, isNotNull);
      final hasPerm = await pm.hasPermissions();
      expect(hasPerm, isA<bool>());
    });

    test('BleGattTransportAdapter checkPermission executes safely without crashing', () async {
      final adapter = BleGattTransportAdapter();
      expect(adapter, isNotNull);
      final permState = await adapter.checkPermission();
      expect(permState, equals(TransportPermissionState.granted));
    });
  });
}
