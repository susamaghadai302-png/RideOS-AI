import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_resolution/models/vehicle_catalog_models.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/vehicle_registry.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/vehicle_model_registry.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/vehicle_model_resolver.dart';
import 'package:rideos_mobile/core/vehicle_resolution/models/active_vehicle_context.dart';
import 'package:rideos_mobile/core/vehicle_resolution/providers/active_vehicle_context_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VehicleRegistry registry;
  late VehicleModelRegistry modelRegistry;
  late VehicleModelResolver resolver;

  setUp(() {
    registry = VehicleRegistry();
    modelRegistry = VehicleModelRegistry();
    resolver = VehicleModelResolver();
  });

  group('Phase 9 — Multi-Brand Vehicle Catalog Architecture Tests', () {
    test('1. Catalog contains all 16 major brands with rich metadata', () {
      final brands = registry.allBrands;
      expect(brands.length, greaterThanOrEqualTo(16));

      final brandNames = brands.map((b) => b.name).toSet();
      final expectedBrands = [
        'Honda',
        'Yamaha',
        'Royal Enfield',
        'Bajaj',
        'TVS',
        'Hero',
        'Suzuki',
        'KTM',
        'Ducati',
        'BMW',
        'Triumph',
        'Aprilia',
        'Harley-Davidson',
        'Indian Motorcycle',
        'Jawa',
        'Yezdi',
      ];

      for (final expected in expectedBrands) {
        expect(brandNames.contains(expected), isTrue, reason: 'Brand $expected must exist in catalog');
      }
    });

    test('2. Catalog contains 80+ verified motorcycle & scooter models with unique IDs', () {
      final vehicles = registry.verifiedProfiles;
      expect(vehicles.length, greaterThanOrEqualTo(80));

      final seenIds = <String>{};
      for (final v in vehicles) {
        expect(v.id, isNotEmpty);
        expect(v.manufacturer, isNotEmpty);
        expect(v.model, isNotEmpty);
        expect(v.category, isNotEmpty);
        expect(seenIds.contains(v.id), isFalse, reason: 'Duplicate vehicle ID: ${v.id}');
        seenIds.add(v.id);
      }
    });

    test('3. Brand Filtering accurately isolates vehicle sets', () {
      final hondaModels = registry.getProfilesByManufacturer('Honda');
      expect(hondaModels.length, greaterThanOrEqualTo(10));
      expect(hondaModels.every((v) => v.manufacturer == 'Honda'), isTrue);

      final hondaNames = hondaModels.map((v) => v.model).toSet();
      expect(hondaNames.contains('Activa 6G'), isTrue);
      expect(hondaNames.contains('Activa 125'), isTrue);
      expect(hondaNames.contains('Dio 125'), isTrue);
      expect(hondaNames.contains('Shine 125'), isTrue);
      expect(hondaNames.contains('SP125'), isTrue);
      expect(hondaNames.contains('Unicorn'), isTrue);
      expect(hondaNames.contains('Hornet 2.0'), isTrue);
      expect(hondaNames.contains('CB200X'), isTrue);
      expect(hondaNames.contains('CB350'), isTrue);
      expect(hondaNames.contains("H'ness CB350"), isTrue);
      expect(hondaNames.contains('CB350RS'), isTrue);

      final reModels = registry.getProfilesByManufacturer('Royal Enfield');
      expect(reModels.length, greaterThanOrEqualTo(9));
      expect(reModels.every((v) => v.manufacturer == 'Royal Enfield'), isTrue);

      final reNames = reModels.map((v) => v.model).toSet();
      expect(reNames.contains('Classic 350'), isTrue);
      expect(reNames.contains('Hunter 350'), isTrue);
      expect(reNames.contains('Himalayan 450'), isTrue);
      expect(reNames.contains('Interceptor 650'), isTrue);
      expect(reNames.contains('Continental GT 650'), isTrue);
      expect(reNames.contains('Super Meteor 650'), isTrue);
    });

    test('4. Category Filtering correctly categorizes vehicle segments', () {
      final scooters = registry.getProfilesByCategory(VehicleTypeCategory.scooter);
      expect(scooters.length, greaterThanOrEqualTo(7));
      expect(scooters.any((s) => s.model.contains('Activa')), isTrue);
      expect(scooters.any((s) => s.model.contains('Jupiter')), isTrue);
      expect(scooters.any((s) => s.model.contains('Ntorq')), isTrue);
      expect(scooters.any((s) => s.model.contains('Access')), isTrue);
      expect(scooters.any((s) => s.model.contains('Burgman')), isTrue);

      final electrics = registry.getProfilesByCategory(VehicleTypeCategory.electric);
      expect(electrics.length, greaterThanOrEqualTo(3));
      expect(electrics.any((e) => e.model.contains('Chetak')), isTrue);
      expect(electrics.any((e) => e.model.contains('iQube')), isTrue);
      expect(electrics.any((e) => e.model.contains('Vida')), isTrue);

      final superbikes = registry.getProfilesByCategory(VehicleTypeCategory.superbike);
      expect(superbikes.length, greaterThanOrEqualTo(4));
      expect(superbikes.any((s) => s.model.contains('Panigale V4 S')), isTrue);
      expect(superbikes.any((s) => s.model.contains('M 1000 RR')), isTrue);
      expect(superbikes.any((s) => s.model.contains('RSV4')), isTrue);
    });

    test('5. Real-Time Search Engine accurately matches queries', () {
      final searchActiva = registry.search('Activa');
      expect(searchActiva.length, equals(2)); // Activa 6G, Activa 125

      final searchDuke = registry.search('Duke');
      expect(searchDuke.length, greaterThanOrEqualTo(4)); // 125, 200, 250, 390

      final searchPulsar = registry.search('Pulsar');
      expect(searchPulsar.length, greaterThanOrEqualTo(5)); // 125, 150, N160, NS200, N250

      final searchSplendor = registry.search('Splendor');
      expect(searchSplendor.length, greaterThanOrEqualTo(1));

      final searchPanigale = registry.search('Panigale');
      expect(searchPanigale.length, greaterThanOrEqualTo(3)); // V2, V4, V4 S
    });

    test('6. Strict 1-to-1 3D Model Verification Invariant Preserved', () {
      final allConfigs = modelRegistry.allConfigs;
      expect(allConfigs.length, greaterThanOrEqualTo(80));

      final verifiedWithGlb = allConfigs.where((c) => c.modelAvailable).toList();
      expect(verifiedWithGlb.length, equals(2)); // Only Ducati Panigale V4 S and BMW M 1000 RR

      final verifiedIds = verifiedWithGlb.map((c) => c.id).toSet();
      expect(verifiedIds.contains('v_ducati_v4s'), isTrue);
      expect(verifiedIds.contains('v_bmw_m1000rr'), isTrue);

      // Verify all newly added models have NO dummy 3D assets
      final pendingModels = [
        'v_honda_activa_6g',
        'v_honda_cb350',
        'v_yamaha_mt15_v2',
        'v_re_classic_350',
        'v_bajaj_pulsar_ns200',
        'v_tvs_apache_rr310',
        'v_hero_splendor_plus',
        'v_ktm_duke_390',
        'v_triumph_speed_400',
        'v_aprilia_rs457',
        'v_hd_x440',
      ];

      for (final id in pendingModels) {
        final profile = registry.getProfileById(id)!;
        final config = modelRegistry.getModelConfig(id);

        expect(profile.model3DUrl, isEmpty, reason: '${profile.model} must not have fake GLB');
        expect(profile.has3DModel, isFalse);
        expect(config.modelAvailable, isFalse);
        expect(config.modelPath, isEmpty);

        final res = resolver.resolve(profile);
        expect(res.status, VehicleModelStatus.unavailable);
        expect(res.modelPath, isEmpty);
      }
    });

    test('7. Sequential Multi-Brand Vehicle Switching & Zero Scene Residue', () {
      final notifier = ActiveVehicleContextNotifier();

      // 1. Activate Honda Activa 6G (Model validation pending)
      final activa = registry.getProfileById('v_honda_activa_6g')!;
      notifier.switchVehicle(activa);
      expect(notifier.state.vehicleId, equals('v_honda_activa_6g'));
      expect(notifier.state.model3DPath, isEmpty);
      expect(notifier.state.hasExact3DModel, isFalse);

      // 2. Switch to Ducati Panigale V4 S (Verified OEM CAD)
      final ducati = registry.getProfileById('v_ducati_v4s')!;
      notifier.switchVehicle(ducati);
      expect(notifier.state.vehicleId, equals('v_ducati_v4s'));
      expect(notifier.state.model3DPath, equals('assets/models/ducati_panigale.glb'));
      expect(notifier.state.hasExact3DModel, isTrue);

      // 3. Switch to Royal Enfield Classic 350 (Must completely purge Ducati 3D path)
      final classic = registry.getProfileById('v_re_classic_350')!;
      notifier.switchVehicle(classic);
      expect(notifier.state.vehicleId, equals('v_re_classic_350'));
      expect(notifier.state.model3DPath, isEmpty);
      expect(notifier.state.hasExact3DModel, isFalse);

      // 4. Switch to BMW M 1000 RR (Verified OEM CAD)
      final bmw = registry.getProfileById('v_bmw_m1000rr')!;
      notifier.switchVehicle(bmw);
      expect(notifier.state.vehicleId, equals('v_bmw_m1000rr'));
      expect(notifier.state.model3DPath, equals('assets/models/bmw_m1000rr.glb'));
      expect(notifier.state.hasExact3DModel, isTrue);
    });
  });
}
