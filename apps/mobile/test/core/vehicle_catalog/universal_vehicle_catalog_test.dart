import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rideos_mobile/core/vehicle_catalog/models/vehicle_catalog_models.dart';
import 'package:rideos_mobile/core/vehicle_catalog/services/universal_vehicle_catalog_service.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/models/vehicle_capabilities.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/models/vehicle_variant_taxonomy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Universal Vehicle Catalog & Compatibility Database Tests', () {
    late UniversalVehicleCatalogService catalog;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      catalog = UniversalVehicleCatalogService();
      await catalog.initialize();
    });

    test('Catalog contains verified 2015+ multi-brand manufacturers', () {
      final brands = catalog.getAvailableBrands();
      expect(brands, contains('Yamaha'));
      expect(brands, contains('Suzuki'));
      expect(brands, contains('Ducati'));
      expect(brands, contains('BMW Motorrad'));
      expect(brands, contains('KTM'));
      expect(brands, contains('Royal Enfield'));
      expect(brands, contains('Ather Energy'));
      expect(brands, contains('Ola Electric'));
      expect(brands, contains('Universal / Generic'));
    });

    test('Catalog resolves model families and distinct variants', () {
      final yamahaFamilies = catalog.getFamilies('Yamaha');
      expect(yamahaFamilies, contains('YZF-R15'));
      expect(yamahaFamilies, contains('Aerox'));
      expect(yamahaFamilies, contains('MT-09'));

      final r15Variants = catalog.getVariants('Yamaha', 'YZF-R15');
      expect(r15Variants, isNotEmpty);
      expect(r15Variants.first.variant, contains('M'));
      expect(r15Variants.first.displaySystem.hasTurnByTurnNav, isTrue);
      expect(r15Variants.first.verification, equals(VerificationSource.verified));
    });

    test('Natural language query search correctly filters multiple facets', () {
      final yamahaScooters = catalog.searchAndFilter(
        const CatalogFilterCriteria(searchQuery: 'Yamaha scooter'),
      );
      expect(yamahaScooters, isNotEmpty);
      expect(yamahaScooters.first.model, equals('Aerox 155'));

      final evBikes = catalog.searchAndFilter(
        const CatalogFilterCriteria(searchQuery: 'electric'),
      );
      expect(evBikes.any((p) => p.brand == 'Ather Energy'), isTrue);
      expect(evBikes.any((p) => p.brand == 'Ola Electric'), isTrue);
      expect(evBikes.any((p) => p.brand == 'BMW Motorrad' && p.model == 'CE 04'), isTrue);

      final bleBikes = catalog.searchAndFilter(
        const CatalogFilterCriteria(connectivity: VehicleConnectivityType.ble),
      );
      expect(bleBikes, isNotEmpty);
    });

    test('Dynamic profile registration supports future years (e.g. 2028+) without core changes', () {
      final futureProfile = UniversalVehicleProfile(
        id: 'future_kawasaki_ninja_ev_2028',
        brand: 'Kawasaki',
        family: 'Ninja EV',
        generation: 'Gen 2 (2028+)',
        model: 'Ninja e-1 Pro',
        variant: 'K-Connect Matrix',
        modelYear: 2028,
        vehicleType: 'ElectricMotorcycle',
        fuelType: 'Electric',
        displaySystem: const DisplaySystem(
          displayType: 'Full TFT with Kawasaki Rideology',
          hasTurnByTurnNav: true,
          hasCallerId: true,
          hasMediaControl: true,
        ),
        connectivity: const ConnectivityProfile(
          supportedMethods: [VehicleConnectivityType.ble],
          primaryProtocolAdapterId: 'generic_ble',
        ),
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        compatibility: VehicleCompatibilityLevel.full,
        verification: VerificationSource.documented,
      );

      catalog.registerDynamicProfile(futureProfile);

      final found = catalog.getProfileById('future_kawasaki_ninja_ev_2028');
      expect(found, isNotNull);
      expect(found!.modelYear, equals(2028));
      expect(found.brand, equals('Kawasaki'));
    });

    test('Resolves correct connectivity adapter from catalog profile', () {
      final r15 = catalog.getProfileById('yamaha_r15_v4_m');
      expect(r15, isNotNull);

      final adapter = catalog.resolveAdapterForProfile(r15!);
      expect(adapter, isNotNull);
      expect(adapter!.adapterId, equals('yamaha_y_connect'));
    });
  });
}
