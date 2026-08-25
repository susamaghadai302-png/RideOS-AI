import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_resolution/models/vehicle_identity.dart';
import 'package:rideos_mobile/core/vehicle_resolution/models/vehicle_catalog_models.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/vehicle_registry.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/vehicle_model_registry.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/vehicle_identity_resolver.dart';

void main() {
  group('Phase 3 — Real Multi-Brand Two-Wheeler Catalog Tests', () {
    late VehicleRegistry registry;
    late VehicleModelRegistry modelRegistry;
    late VehicleIdentityResolver resolver;

    setUp(() {
      registry = VehicleRegistry();
      modelRegistry = VehicleModelRegistry();
      resolver = VehicleIdentityResolver();
    });

    test('1. Catalog Architecture: Contains 21 Major Brands and >100 Authentic Profiles', () {
      expect(registry.allBrands.length, greaterThanOrEqualTo(21));
      expect(registry.verifiedProfiles.length, greaterThanOrEqualTo(100));

      final brandNames = registry.allBrands.map((b) => b.name).toList();
      expect(brandNames, containsAll([
        'Honda',
        'Yamaha',
        'Suzuki',
        'TVS',
        'Hero',
        'Bajaj',
        'Royal Enfield',
        'KTM',
        'Kawasaki',
        'Ducati',
        'BMW',
        'Aprilia',
        'Triumph',
        'Harley-Davidson',
        'Vespa',
        'Piaggio',
        'Ola Electric',
        'Ather',
        'Indian Motorcycle',
        'Jawa',
        'Yezdi',
      ]));
    });

    test('2. Honda Catalog Expansion: Full Lineup Verified with Genuine Specifications', () {
      final hondaVehicles = registry.getProfilesByManufacturer('Honda');
      expect(hondaVehicles.length, greaterThanOrEqualTo(15));

      final activa6g = registry.getProfileById('v_honda_activa_6g')!;
      expect(activa6g.model, equals('Activa 6G'));
      expect(activa6g.displacementCc, equals(110));
      expect(activa6g.powerBhp, equals(7.79));
      expect(activa6g.curbWeightKg, equals(106.0));
      expect(activa6g.has3DModel, isFalse);
      expect(activa6g.model3DStatus, equals('3D MODEL NOT AVAILABLE'));

      final cb650r = registry.getProfileById('v_honda_cb650r')!;
      expect(cb650r.model, equals('CB650R'));
      expect(cb650r.displacementCc, equals(649));
      expect(cb650r.powerBhp, equals(87.0));

      final goldwing = registry.getProfileById('v_honda_gold_wing')!;
      expect(goldwing.displacementCc, equals(1833));
      expect(goldwing.powerBhp, equals(124.7));
      expect(goldwing.curbWeightKg, equals(390.0));
    });

    test('3. Kawasaki & Superbike Expansion: Full Lineup with WSBK and Supercharged Models', () {
      final kawasakiVehicles = registry.getProfilesByManufacturer('Kawasaki');
      expect(kawasakiVehicles.length, greaterThanOrEqualTo(10));

      final ninjaH2 = registry.getProfileById('v_kawasaki_ninja_h2')!;
      expect(ninjaH2.model, equals('Ninja H2'));
      expect(ninjaH2.powerBhp, equals(231.0));
      expect(ninjaH2.topSpeedKmh, equals(337));

      final zx10r = registry.getProfileById('v_kawasaki_ninja_zx10r')!;
      expect(zx10r.powerBhp, equals(203.0));

      final zx4r = registry.getProfileById('v_kawasaki_ninja_zx4r')!;
      expect(zx4r.displacementCc, equals(399));
      expect(zx4r.powerBhp, equals(77.0));
    });

    test('4. EV Expansion: Ola Electric & Ather Energy Full Ecosystem', () {
      final olaPro = registry.getProfileById('v_ola_s1_pro_gen2')!;
      expect(olaPro.manufacturer, equals('Ola Electric'));
      expect(olaPro.batteryCapacityKwh, equals(4.0));
      expect(olaPro.powerBhp, equals(14.75));
      expect(olaPro.isElectric, isTrue);

      final ather450x = registry.getProfileById('v_ather_450x_gen3')!;
      expect(ather450x.manufacturer, equals('Ather'));
      expect(ather450x.batteryCapacityKwh, equals(3.7));
      expect(ather450x.isElectric, isTrue);
    });

    test('5. CRITICAL 3D MODEL ISOLATION: 1-Vehicle = 1-Model Strict Invariant', () {
      // 1. Ducati Panigale V4 S has authentic verified CAD model
      final ducatiConfig = modelRegistry.getModelConfig('v_ducati_v4s');
      expect(ducatiConfig.model3d, equals('assets/models/ducati_panigale.glb'));
      expect(ducatiConfig.isVerified, isTrue);
      expect(ducatiConfig.verificationStatus, equals('VERIFIED_OEM'));

      // 2. BMW M 1000 RR has authentic verified CAD model
      final bmwConfig = modelRegistry.getModelConfig('v_bmw_m1000rr');
      expect(bmwConfig.model3d, equals('assets/models/bmw_m1000rr.glb'));
      expect(bmwConfig.isVerified, isTrue);
      expect(bmwConfig.verificationStatus, equals('VERIFIED_OEM'));

      // 3. Every other vehicle in the catalog has NO fake/generic 3D model
      final allProfiles = registry.verifiedProfiles;
      final nonOem3DProfiles = allProfiles.where((p) => p.id != 'v_ducati_v4s' && p.id != 'v_bmw_m1000rr').toList();

      for (final profile in nonOem3DProfiles) {
        expect(profile.model3DUrl, isEmpty,
            reason: 'Vehicle ${profile.id} must NOT have an unverified or reused 3D model path.');
        expect(profile.has3DModel, isFalse);
        expect(profile.model3DStatus, equals('3D MODEL NOT AVAILABLE'));
      }
    });

    test('6. CRITICAL CROSS-CONTAMINATION PREVENTION: Cross-Model Mapping Fails Strictly', () {
      final activa = registry.getProfileById('v_honda_activa_6g')!;
      final r1m = registry.getProfileById('v_yamaha_r1m')!;
      final ducati = registry.getProfileById('v_ducati_v4s')!;
      final bmw = registry.getProfileById('v_bmw_m1000rr')!;
      final ninjaH2 = registry.getProfileById('v_kawasaki_ninja_h2')!;

      // Activa must NEVER resolve to R1M or Ducati 3D asset
      expect(activa.model3DUrl, isNot(equals(ducati.model3DUrl)));
      expect(activa.model3DUrl, isNot(equals(bmw.model3DUrl)));

      // BMW must NEVER resolve to Ducati or Yamaha asset
      expect(bmw.model3DUrl, isNot(equals(ducati.model3DUrl)));
      expect(bmw.model3DUrl, isNot(equals(r1m.model3DUrl)));

      // Ducati must NEVER resolve to BMW asset
      expect(ducati.model3DUrl, isNot(equals(bmw.model3DUrl)));

      // Ninja H2 must NOT borrow Ducati or BMW asset
      expect(ninjaH2.model3DUrl, isEmpty);
      expect(ninjaH2.model3DUrl, isNot(equals(ducati.model3DUrl)));
    });

    test('7. Search and Filtering: Multi-Faceted Query Verification', () {
      // 1. Filter by Brand
      final ducatiFilter = const CatalogFilterState(selectedBrand: 'Ducati');
      final ducatiResults = registry.filter(ducatiFilter);
      expect(ducatiResults.every((v) => v.manufacturer == 'Ducati'), isTrue);
      expect(ducatiResults.length, greaterThanOrEqualTo(9));

      // 2. Filter by Category
      final scooterFilter = const CatalogFilterState(selectedCategory: VehicleTypeCategory.scooter);
      final scooterResults = registry.filter(scooterFilter);
      expect(scooterResults.every((v) => v.isScooter), isTrue);

      // 3. Filter by 3D Ready
      final ready3DFilter = const CatalogFilterState(only3DReady: true);
      final ready3DResults = registry.filter(ready3DFilter);
      expect(ready3DResults.length, equals(2)); // Ducati Panigale V4 S and BMW M 1000 RR only
      expect(ready3DResults.map((v) => v.id), containsAll(['v_ducati_v4s', 'v_bmw_m1000rr']));

      // 4. Free-text Search
      final searchResults = registry.search('Sherpa');
      expect(searchResults.any((v) => v.id == 'v_re_himalayan_450'), isTrue);
      expect(searchResults.any((v) => v.id == 'v_re_guerrilla_450'), isTrue);
    });

    test('8. Real BLE Device Resolution to Expanded Multi-Brand Catalog', () {
      // Kawasaki Ninja H2 BLE Device
      final resKawasaki = resolver.resolveBleDevice(
        deviceName: 'KAWASAKI-H2-SUPERCHARGED',
        deviceId: '00:11:22:33:44:55',
        transportType: ConnectionTransportType.ble,
      );
      expect(resKawasaki.identity.confidence, equals(IdentityConfidence.exactMatch));
      expect(resKawasaki.profile?.id, equals('v_kawasaki_ninja_h2'));
      expect(resKawasaki.identity.model, equals('Ninja H2'));
      expect(resKawasaki.hasVerified3DModel, isFalse);

      // Ola S1 Pro BLE Device
      final resOla = resolver.resolveBleDevice(
        deviceName: 'MOVEOS-BLE-S1PRO',
        deviceId: 'aa:bb:cc:dd:ee:11',
        transportType: ConnectionTransportType.ble,
      );
      expect(resOla.identity.confidence, equals(IdentityConfidence.exactMatch));
      expect(resOla.profile?.id, equals('v_ola_s1_pro_gen2'));
      expect(resOla.profile?.isElectric, isTrue);

      // Ather 450X BLE Device
      final resAther = resolver.resolveBleDevice(
        deviceName: 'ATHER-WARP-BT',
        deviceId: 'aa:bb:cc:dd:ee:22',
        transportType: ConnectionTransportType.ble,
      );
      expect(resAther.identity.confidence, equals(IdentityConfidence.exactMatch));
      expect(resAther.profile?.id, equals('v_ather_450x_gen3'));
      expect(resAther.profile?.isElectric, isTrue);
    });
  });
}
