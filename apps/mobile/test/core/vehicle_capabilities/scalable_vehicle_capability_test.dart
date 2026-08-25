import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_capabilities/models/universal_vehicle_capability_models.dart';
import 'package:rideos_mobile/core/vehicle_capabilities/services/scalable_vehicle_capability_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Scalable Vehicle Capability Engine & Provider Tests', () {
    late ScalableVehicleCapabilityEngine engine;

    setUp(() {
      engine = ScalableVehicleCapabilityEngine();
    });

    test('Catalog contains multi-variant taxonomy with distinct capability levels', () {
      final catalog = engine.catalog;
      expect(catalog, isNotEmpty);

      final yamaha = catalog.firstWhere((m) => m.manufacturerId == 'yamaha');
      final r15Model = yamaha.families.first.models.first;
      expect(r15Model.variants.length, greaterThanOrEqualTo(2));

      final baseVariant = r15Model.variants.firstWhere((v) => v.trimLevel == VariantTrimLevel.base);
      expect(baseVariant.connectivity.hasBle, isFalse);
      expect(baseVariant.compatibility, equals(CompatibilityLevel.hardwareRequired));

      final topVariant = r15Model.variants.firstWhere((v) => v.trimLevel == VariantTrimLevel.topPremium);
      expect(topVariant.connectivity.hasBle, isTrue);
      expect(topVariant.protocol.supportsTurnByTurnMirror, isTrue);
      expect(topVariant.compatibility, equals(CompatibilityLevel.fullySupported));
    });

    test('Detects Yamaha Y-Connect CCU signature from advertised GATT UUID', () async {
      final detected = await engine.resolveCapabilities(
        deviceName: 'Y-Connect_98A2',
        advertisedServiceUuids: ['0000fee0-0000-1000-8000-00805f9b34fb'],
        macAddress: 'AA:BB:CC:DD:EE:FF',
      );

      expect(detected.variantId, equals('yamaha_r15_m'));
      expect(detected.protocol.protocolName, contains('Yamaha Y-Connect'));
      expect(detected.display.supportsNavigationArrows, isTrue);
    });

    test('Detects Royal Enfield Tripper Dash from GATT UUID', () async {
      final detected = await engine.resolveCapabilities(
        deviceName: 'RE_Tripper_450',
        advertisedServiceUuids: ['0000fe50-0000-1000-8000-00805f9b34fb'],
        macAddress: '11:22:33:44:55:66',
      );

      expect(detected.variantId, equals('re_himalayan_450_tripper'));
      expect(detected.protocol.supportsTurnByTurnMirror, isTrue);
      expect(detected.display.displayType, contains('TFT'));
    });

    test('Falls back gracefully to Generic OBD-II Gateway when device signature is unknown', () async {
      final detected = await engine.resolveCapabilities(
        deviceName: 'Unknown_OBD_Dongle',
        advertisedServiceUuids: ['00001800-0000-1000-8000-00805f9b34fb'],
        macAddress: '99:88:77:66:55:44',
      );

      expect(detected.variantId, equals('universal_generic_obd'));
      expect(detected.compatibility, equals(CompatibilityLevel.supportedWithGateway));
      expect(detected.protocol.supportsDtcDiagnostics, isTrue);
    });
  });
}
