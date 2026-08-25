import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_capabilities/models/universal_vehicle_capability_models.dart';
import 'package:rideos_mobile/core/vehicle_capabilities/services/scalable_vehicle_capability_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Universal Motorcycle & Scooter Platform Architecture Tests', () {
    late ScalableVehicleCapabilityEngine engine;

    setUp(() {
      engine = ScalableVehicleCapabilityEngine();
    });

    test('CompatibilityLevel states provide distinct explanations', () {
      for (final level in CompatibilityLevel.values) {
        expect(level.label, isNotEmpty);
        expect(level.explanation, isNotEmpty);
      }
    });

    test('Variant trims differentiate base LCD from top premium TFT clusters', () {
      final yamaha = engine.catalog.firstWhere((m) => m.manufacturerId == 'yamaha');
      final r15Model = yamaha.families.first.models.first;

      final base = r15Model.variants.firstWhere((v) => v.trimLevel == VariantTrimLevel.base);
      expect(base.connectivity.hasBle, isFalse);
      expect(base.compatibility, equals(CompatibilityLevel.hardwareRequired));

      final top = r15Model.variants.firstWhere((v) => v.trimLevel == VariantTrimLevel.topPremium);
      expect(top.connectivity.hasBle, isTrue);
      expect(top.display.supportsNavigationArrows, isTrue);
      expect(top.compatibility, equals(CompatibilityLevel.fullySupported));
    });

    test('Resolves Ather Energy EV Smart Scooter capabilities with cloud telematics', () async {
      final ather = await engine.resolveCapabilities(
        deviceName: 'Ather450X_B098',
        advertisedServiceUuids: ['000018f0-0000-1000-8000-00805f9b34fb'],
        macAddress: 'CC:DD:EE:FF:00:11',
      );

      expect(ather.variantId, equals('ather_450x_pro'));
      expect(ather.telemetry.supportsBatterySoc, isTrue);
      expect(ather.telemetry.supportsRpm, isFalse);
      expect(ather.telemetry.supportsTpms, isTrue);
      expect(ather.compatibility, equals(CompatibilityLevel.supportedWithManufacturerApi));
    });

    test('Dynamic runtime registration allows future vehicles without modifying core application', () {
      const futureDucati = VehicleManufacturer(
        manufacturerId: 'ducati_future',
        name: 'Ducati Motor Holding',
        country: 'Italy',
        families: [
          VehicleFamily(
            familyId: 'ducati_panigale_series',
            familyName: 'Panigale V4 Supersport',
            models: [
              VehicleModel(
                modelId: 'panigale_v4_2026',
                modelName: 'Panigale V4 S (2026)',
                startYear: 2026,
                variants: [
                  ModelVariant(
                    variantId: 'panigale_v4s_dms',
                    variantName: 'Panigale V4 S DMS TFT',
                    trimLevel: VariantTrimLevel.topPremium,
                    connectivity: ConnectivityCapabilities(hasBle: true, hasWifi: true),
                    protocol: ProtocolCapabilities(
                      protocolName: 'Ducati Multimedia System 2026',
                      gattServiceUuid: '000018f5-0000-1000-8000-00805f9b34fb',
                      readCharacteristicUuid: '000018f6-0000-1000-8000-00805f9b34fb',
                      supportsTurnByTurnMirror: true,
                    ),
                    telemetry: TelemetryCapabilities(
                      supportsSpeed: true,
                      supportsRpm: true,
                      supportsTractionControl: true,
                      supportsAbsStatus: true,
                    ),
                    display: DisplayCapabilities(displayType: '6.9-inch OLED TFT'),
                    compatibility: CompatibilityLevel.fullySupported,
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      engine.registerNewVehicleProfile(futureDucati);
      expect(engine.catalog.any((m) => m.manufacturerId == 'ducati_future'), isTrue);
    });
  });
}
