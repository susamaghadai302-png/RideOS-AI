import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle_catalog_models.dart';
import '../../vehicle_connectivity/models/vehicle_capabilities.dart';
import '../../vehicle_connectivity/models/vehicle_variant_taxonomy.dart';
import '../../vehicle_connectivity/services/vehicle_adapter_registry.dart';
import '../../vehicle_connectivity/adapters/vehicle_connectivity_adapter.dart';

class CatalogFilterCriteria {
  final String? vehicleType; // Motorcycle, Scooter, ElectricMotorcycle, ElectricScooter
  final String? brand;
  final int? minYear;
  final int? maxYear;
  final String? fuelType; // Petrol, Electric, Hybrid
  final VehicleConnectivityType? connectivity;
  final VehicleCompatibilityLevel? compatibility;
  final String? searchQuery;

  const CatalogFilterCriteria({
    this.vehicleType,
    this.brand,
    this.minYear,
    this.maxYear,
    this.fuelType,
    this.connectivity,
    this.compatibility,
    this.searchQuery,
  });
}

class UniversalVehicleCatalogService {
  static final UniversalVehicleCatalogService _instance = UniversalVehicleCatalogService._internal();
  factory UniversalVehicleCatalogService() => _instance;

  static const String catalogVersion = '1.0.0';
  static const String _storageKey = 'rideos_universal_vehicle_catalog_cache_v1';

  final List<UniversalVehicleProfile> _catalog = [];
  bool _isLoaded = false;

  UniversalVehicleCatalogService._internal() {
    _seedCatalog();
  }

  List<UniversalVehicleProfile> get allProfiles => List.unmodifiable(_catalog);
  bool get isLoaded => _isLoaded;

  Future<void> initialize() async {
    if (_isLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        for (final item in list) {
          final profile = UniversalVehicleProfile.fromJson(item as Map<String, dynamic>);
          _catalog.removeWhere((e) => e.id == profile.id);
          _catalog.add(profile);
        }
      }
    } catch (_) {}
    _isLoaded = true;
  }

  List<String> getAvailableBrands({String? vehicleType}) {
    var query = _catalog.asEnumerable();
    if (vehicleType != null && vehicleType.isNotEmpty) {
      query = query.where((e) => e.vehicleType.toLowerCase() == vehicleType.toLowerCase());
    }
    return query.map((e) => e.brand).toSet().toList()..sort();
  }

  List<String> getFamilies(String brand, {String? vehicleType}) {
    return _catalog
        .where((e) =>
            e.brand.toLowerCase() == brand.toLowerCase() &&
            (vehicleType == null || vehicleType.isEmpty || e.vehicleType.toLowerCase() == vehicleType.toLowerCase()))
        .map((e) => e.family)
        .toSet()
        .toList()
      ..sort();
  }

  List<UniversalVehicleProfile> getVariants(String brand, String family) {
    return _catalog
        .where((e) =>
            e.brand.toLowerCase() == brand.toLowerCase() &&
            e.family.toLowerCase() == family.toLowerCase())
        .toList();
  }

  UniversalVehicleProfile? getProfileById(String id) {
    try {
      return _catalog.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Advanced multi-faceted search & natural keyword filter
  List<UniversalVehicleProfile> searchAndFilter(CatalogFilterCriteria criteria) {
    return _catalog.where((p) {
      // 1. Vehicle Type filter
      if (criteria.vehicleType != null && criteria.vehicleType!.isNotEmpty) {
        if (p.vehicleType.toLowerCase() != criteria.vehicleType!.toLowerCase()) {
          return false;
        }
      }

      // 2. Brand filter
      if (criteria.brand != null && criteria.brand!.isNotEmpty) {
        if (p.brand.toLowerCase() != criteria.brand!.toLowerCase()) {
          return false;
        }
      }

      // 3. Year range
      if (criteria.minYear != null && p.modelYear < criteria.minYear!) {
        return false;
      }
      if (criteria.maxYear != null && p.modelYear > criteria.maxYear!) {
        return false;
      }

      // 4. Fuel type
      if (criteria.fuelType != null && criteria.fuelType!.isNotEmpty) {
        if (p.fuelType.toLowerCase() != criteria.fuelType!.toLowerCase()) {
          return false;
        }
      }

      // 5. Connectivity Method
      if (criteria.connectivity != null) {
        if (!p.connectivity.supportedMethods.contains(criteria.connectivity)) {
          return false;
        }
      }

      // 6. Compatibility Tier
      if (criteria.compatibility != null) {
        if (p.compatibility != criteria.compatibility) {
          return false;
        }
      }

      // 7. Natural text search query
      if (criteria.searchQuery != null && criteria.searchQuery!.trim().isNotEmpty) {
        final tokens = criteria.searchQuery!.toLowerCase().trim().split(RegExp(r'\s+'));
        for (final token in tokens) {
          final matchesToken = p.brand.toLowerCase().contains(token) ||
              p.model.toLowerCase().contains(token) ||
              p.family.toLowerCase().contains(token) ||
              p.variant.toLowerCase().contains(token) ||
              p.vehicleType.toLowerCase().contains(token) ||
              p.fuelType.toLowerCase().contains(token) ||
              p.displaySystem.displayType.toLowerCase().contains(token) ||
              p.modelYear.toString().contains(token) ||
              (token == 'ble' && p.connectivity.supportedMethods.contains(VehicleConnectivityType.ble)) ||
              (token == 'ev' && p.isElectric) ||
              (token == 'electric' && p.isElectric) ||
              (token == 'scooter' && p.vehicleType.toLowerCase().contains('scooter')) ||
              (token == 'motorcycle' && p.vehicleType.toLowerCase().contains('motorcycle'));

          if (!matchesToken) return false;
        }
      }

      return true;
    }).toList();
  }

  /// Resolves the corresponding connectivity adapter from the registry
  VehicleConnectivityAdapter? resolveAdapterForProfile(UniversalVehicleProfile profile) {
    return VehicleAdapterRegistry().getAdapter(profile.connectivity.primaryProtocolAdapterId);
  }

  void registerDynamicProfile(UniversalVehicleProfile profile) {
    _catalog.removeWhere((e) => e.id == profile.id);
    _catalog.add(profile);
    _persistCache();
  }

  Future<void> _persistCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_catalog.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, raw);
    } catch (_) {}
  }

  void _seedCatalog() {
    _catalog.addAll([
      // ==========================================
      // YAMAHA (2015+ Open Catalog)
      // ==========================================
      UniversalVehicleProfile(
        id: 'yamaha_r15_v4_m',
        brand: 'Yamaha',
        family: 'YZF-R15',
        generation: 'Gen 4 (2021+)',
        model: 'YZF-R15',
        variant: 'M (TFT + Quickshifter)',
        modelYear: 2024,
        vehicleType: 'Motorcycle',
        fuelType: 'Petrol',
        displaySystem: const DisplaySystem(
          displayType: 'Full-Color TFT with Track/Street Modes',
          hasTurnByTurnNav: true,
          hasCallerId: true,
          hasMediaControl: true,
        ),
        connectivity: const ConnectivityProfile(
          supportedMethods: [VehicleConnectivityType.ble, VehicleConnectivityType.obd2Gateway],
          primaryProtocolAdapterId: 'yamaha_y_connect',
          requiresExternalGateway: false,
        ),
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        compatibility: VehicleCompatibilityLevel.full,
        verification: VerificationSource.verified,
        specifications: const {
          'engineCc': 155,
          'powerBhp': 18.4,
          'torqueNm': 14.2,
          'curbWeightKg': 141,
          'transmission': '6-Speed with Assist & Slipper Clutch',
        },
        thumbnailUrl: 'assets/garage/generic_bike.png',
      ),
      UniversalVehicleProfile(
        id: 'yamaha_aerox155',
        brand: 'Yamaha',
        family: 'Aerox',
        generation: 'Gen 2 (2021+)',
        model: 'Aerox 155',
        variant: 'Connected Standard',
        modelYear: 2024,
        vehicleType: 'Scooter',
        fuelType: 'Petrol',
        displaySystem: const DisplaySystem(
          displayType: 'Negative LCD with Y-Connect Sub-Display',
          hasTurnByTurnNav: false,
          hasCallerId: true,
          hasMediaControl: false,
        ),
        connectivity: const ConnectivityProfile(
          supportedMethods: [VehicleConnectivityType.ble, VehicleConnectivityType.obd2Gateway],
          primaryProtocolAdapterId: 'yamaha_y_connect',
          requiresExternalGateway: false,
        ),
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        compatibility: VehicleCompatibilityLevel.full,
        verification: VerificationSource.verified,
        specifications: const {
          'engineCc': 155,
          'powerBhp': 15.0,
          'torqueNm': 13.9,
          'curbWeightKg': 126,
        },
        thumbnailUrl: 'assets/garage/generic_scooter.png',
      ),
      UniversalVehicleProfile(
        id: 'yamaha_mt09_sp',
        brand: 'Yamaha',
        family: 'MT-09',
        generation: 'Gen 4 (2024+)',
        model: 'MT-09',
        variant: 'SP Premium',
        modelYear: 2024,
        vehicleType: 'Motorcycle',
        fuelType: 'Petrol',
        displaySystem: const DisplaySystem(
          displayType: '5-inch Full Color TFT with Garmin StreetCross',
          hasTurnByTurnNav: true,
          hasCallerId: true,
          hasMediaControl: true,
        ),
        connectivity: const ConnectivityProfile(
          supportedMethods: [VehicleConnectivityType.ble, VehicleConnectivityType.canGateway, VehicleConnectivityType.obd2Gateway],
          primaryProtocolAdapterId: 'yamaha_y_connect',
          requiresExternalGateway: false,
        ),
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        compatibility: VehicleCompatibilityLevel.full,
        verification: VerificationSource.verified,
        specifications: const {
          'engineCc': 890,
          'powerBhp': 117.3,
          'torqueNm': 93.0,
          'curbWeightKg': 190,
        },
        model3DUrl: null,
        thumbnailUrl: 'assets/garage/yamaha_mt09_sp.png',
      ),

      // ==========================================
      // SUZUKI
      // ==========================================
      UniversalVehicleProfile(
        id: 'suzuki_burgman_ex',
        brand: 'Suzuki',
        family: 'Burgman Street',
        generation: 'EX Edition (2023+)',
        model: 'Burgman Street 125',
        variant: 'EX (Ride Connect)',
        modelYear: 2024,
        vehicleType: 'Scooter',
        fuelType: 'Petrol',
        displaySystem: const DisplaySystem(
          displayType: 'Digital Cluster with Turn-by-Turn Nav',
          hasTurnByTurnNav: true,
          hasCallerId: true,
          hasMediaControl: false,
        ),
        connectivity: const ConnectivityProfile(
          supportedMethods: [VehicleConnectivityType.ble, VehicleConnectivityType.obd2Gateway],
          primaryProtocolAdapterId: 'suzuki_ride_connect',
          requiresExternalGateway: false,
        ),
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        compatibility: VehicleCompatibilityLevel.full,
        verification: VerificationSource.verified,
        specifications: const {
          'engineCc': 124,
          'powerBhp': 8.6,
          'torqueNm': 10.0,
          'curbWeightKg': 111,
        },
        model3DUrl: null,
        thumbnailUrl: 'assets/garage/suzuki_burgman.png',
      ),

      // ==========================================
      // DUCATI
      // ==========================================
      UniversalVehicleProfile(
        id: 'ducati_panigale_v4s',
        brand: 'Ducati',
        family: 'Panigale',
        generation: 'V4 2024 Facelift',
        model: 'Panigale V4',
        variant: 'S (Electronic Suspension)',
        modelYear: 2024,
        vehicleType: 'Motorcycle',
        fuelType: 'Petrol',
        displaySystem: const DisplaySystem(
          displayType: '6.9-inch Racing TFT with DMS',
          hasTurnByTurnNav: true,
          hasCallerId: true,
          hasMediaControl: true,
        ),
        connectivity: const ConnectivityProfile(
          supportedMethods: [VehicleConnectivityType.ble, VehicleConnectivityType.wifiDirect, VehicleConnectivityType.canGateway],
          primaryProtocolAdapterId: 'ducati_dms',
          requiresExternalGateway: false,
        ),
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        compatibility: VehicleCompatibilityLevel.full,
        verification: VerificationSource.verified,
        specifications: const {
          'engineCc': 1103,
          'powerBhp': 215.5,
          'torqueNm': 123.6,
          'curbWeightKg': 195.5,
        },
        model3DUrl: 'assets/models/ducati_panigale.glb',
        thumbnailUrl: 'assets/garage/ducati_panigale.png',
      ),

      // ==========================================
      // BMW MOTORRAD
      // ==========================================
      UniversalVehicleProfile(
        id: 'bmw_s1000rr_m',
        brand: 'BMW Motorrad',
        family: 'S 1000 RR',
        generation: 'K67 (2023+)',
        model: 'S 1000 RR',
        variant: 'M Package',
        modelYear: 2024,
        vehicleType: 'Motorcycle',
        fuelType: 'Petrol',
        displaySystem: const DisplaySystem(
          displayType: '6.5-inch Connectivity TFT',
          hasTurnByTurnNav: true,
          hasCallerId: true,
          hasMediaControl: true,
        ),
        connectivity: const ConnectivityProfile(
          supportedMethods: [VehicleConnectivityType.ble, VehicleConnectivityType.wifiDirect, VehicleConnectivityType.canGateway],
          primaryProtocolAdapterId: 'bmw_motorrad_connect',
          requiresExternalGateway: false,
        ),
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        compatibility: VehicleCompatibilityLevel.full,
        verification: VerificationSource.verified,
        specifications: const {
          'engineCc': 999,
          'powerBhp': 210.0,
          'torqueNm': 113.0,
          'curbWeightKg': 193.5,
        },
        model3DUrl: 'assets/models/bmw_s1000rr.glb',
        thumbnailUrl: 'assets/garage/bmw_s1000rr.png',
      ),
      UniversalVehicleProfile(
        id: 'bmw_ce04_ev',
        brand: 'BMW Motorrad',
        family: 'CE 04',
        generation: 'Gen 1 (2022+)',
        model: 'CE 04',
        variant: 'Connected EV',
        modelYear: 2024,
        vehicleType: 'ElectricScooter',
        fuelType: 'Electric',
        displaySystem: const DisplaySystem(
          displayType: '10.25-inch Full HD Split Screen TFT',
          hasTurnByTurnNav: true,
          hasCallerId: true,
          hasMediaControl: true,
        ),
        connectivity: const ConnectivityProfile(
          supportedMethods: [VehicleConnectivityType.ble, VehicleConnectivityType.wifiDirect],
          primaryProtocolAdapterId: 'bmw_motorrad_connect',
          requiresExternalGateway: false,
        ),
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        compatibility: VehicleCompatibilityLevel.full,
        verification: VerificationSource.verified,
        specifications: const {
          'batteryCapacityKwh': 8.9,
          'powerBhp': 42.0,
          'topSpeedKmh': 120,
        },
        thumbnailUrl: 'assets/garage/generic_scooter.png',
      ),

      // ==========================================
      // KTM
      // ==========================================
      UniversalVehicleProfile(
        id: 'ktm_duke390_gen3',
        brand: 'KTM',
        family: 'Duke',
        generation: 'Gen 3 (2024+)',
        model: '390 Duke',
        variant: 'Standard TFT with Launch Control',
        modelYear: 2024,
        vehicleType: 'Motorcycle',
        fuelType: 'Petrol',
        displaySystem: const DisplaySystem(
          displayType: '5-inch Color TFT with KTM Connect',
          hasTurnByTurnNav: true,
          hasCallerId: true,
          hasMediaControl: true,
        ),
        connectivity: const ConnectivityProfile(
          supportedMethods: [VehicleConnectivityType.ble, VehicleConnectivityType.obd2Gateway],
          primaryProtocolAdapterId: 'ktm_my_ride',
          requiresExternalGateway: false,
        ),
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        compatibility: VehicleCompatibilityLevel.full,
        verification: VerificationSource.verified,
        specifications: const {
          'engineCc': 398.7,
          'powerBhp': 45.3,
          'torqueNm': 39.0,
          'curbWeightKg': 165,
        },
        thumbnailUrl: 'assets/garage/generic_bike.png',
      ),

      // ==========================================
      // ROYAL ENFIELD
      // ==========================================
      UniversalVehicleProfile(
        id: 're_himalayan450',
        brand: 'Royal Enfield',
        family: 'Himalayan',
        generation: 'Sherpa 450 (2023+)',
        model: 'Himalayan 450',
        variant: 'Tripper Navigation Edition',
        modelYear: 2024,
        vehicleType: 'Motorcycle',
        fuelType: 'Petrol',
        displaySystem: const DisplaySystem(
          displayType: '4-inch Circular Full Color TFT with Google Maps',
          hasTurnByTurnNav: true,
          hasCallerId: true,
          hasMediaControl: true,
        ),
        connectivity: const ConnectivityProfile(
          supportedMethods: [VehicleConnectivityType.smartDisplayMirror, VehicleConnectivityType.wifiDirect, VehicleConnectivityType.obd2Gateway],
          primaryProtocolAdapterId: 'royal_enfield_tripper',
          requiresExternalGateway: false,
        ),
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        compatibility: VehicleCompatibilityLevel.full,
        verification: VerificationSource.verified,
        specifications: const {
          'engineCc': 452,
          'powerBhp': 40.0,
          'torqueNm': 40.0,
          'curbWeightKg': 196,
        },
        thumbnailUrl: 'assets/garage/generic_bike.png',
      ),

      // ==========================================
      // ATHER ENERGY (EV)
      // ==========================================
      UniversalVehicleProfile(
        id: 'ather_450x_gen4',
        brand: 'Ather Energy',
        family: '450',
        generation: 'Gen 4 (2024+)',
        model: '450X',
        variant: 'Pro Pack 3.7 kWh',
        modelYear: 2024,
        vehicleType: 'ElectricScooter',
        fuelType: 'Electric',
        displaySystem: const DisplaySystem(
          displayType: '7-inch Touchscreen Snapdragon Dashboard',
          hasTurnByTurnNav: true,
          hasCallerId: true,
          hasMediaControl: true,
          isTouchscreen: true,
        ),
        connectivity: const ConnectivityProfile(
          supportedMethods: [VehicleConnectivityType.manufacturerApi, VehicleConnectivityType.ble],
          primaryProtocolAdapterId: 'ather_cloud_telematics',
          requiresExternalGateway: false,
        ),
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        compatibility: VehicleCompatibilityLevel.full,
        verification: VerificationSource.verified,
        specifications: const {
          'batteryCapacityKwh': 3.7,
          'powerBhp': 8.6,
          'torqueNm': 26.0,
          'topSpeedKmh': 90,
        },
        thumbnailUrl: 'assets/garage/generic_scooter.png',
      ),

      // ==========================================
      // OLA ELECTRIC (EV)
      // ==========================================
      UniversalVehicleProfile(
        id: 'ola_s1_pro_gen2',
        brand: 'Ola Electric',
        family: 'S1',
        generation: 'Gen 2 (2023+)',
        model: 'S1 Pro',
        variant: 'Gen 2 4.0 kWh',
        modelYear: 2024,
        vehicleType: 'ElectricScooter',
        fuelType: 'Electric',
        displaySystem: const DisplaySystem(
          displayType: '7-inch Touchscreen MoveOS 4',
          hasTurnByTurnNav: true,
          hasCallerId: true,
          hasMediaControl: true,
          isTouchscreen: true,
        ),
        connectivity: const ConnectivityProfile(
          supportedMethods: [VehicleConnectivityType.manufacturerApi, VehicleConnectivityType.ble],
          primaryProtocolAdapterId: 'ola_moveos_telematics',
          requiresExternalGateway: false,
        ),
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        compatibility: VehicleCompatibilityLevel.full,
        verification: VerificationSource.verified,
        specifications: const {
          'batteryCapacityKwh': 4.0,
          'powerBhp': 14.7,
          'topSpeedKmh': 120,
        },
        thumbnailUrl: 'assets/garage/generic_scooter.png',
      ),

      // ==========================================
      // UNIVERSAL DIAGNOSTIC GATEWAYS (2015+)
      // ==========================================
      UniversalVehicleProfile(
        id: 'universal_euro5_obd2',
        brand: 'Universal / Generic',
        family: 'OBD-II Two-Wheeler',
        generation: 'Euro 4/5/6 & BS-VI Standard (2015+)',
        model: 'Diagnostic Gateway Vehicle',
        variant: '4-Pin / 6-Pin / 16-Pin Adapter',
        modelYear: 2024,
        vehicleType: 'Motorcycle',
        fuelType: 'Petrol',
        displaySystem: const DisplaySystem(
          displayType: 'External Diagnostic Interface',
        ),
        connectivity: const ConnectivityProfile(
          supportedMethods: [VehicleConnectivityType.obd2Gateway],
          primaryProtocolAdapterId: 'obd2_gateway_standard',
          requiresExternalGateway: true,
          gatewayType: '4-Pin / 6-Pin OBD-II to Bluetooth/USB Interface',
        ),
        capabilities: VehicleCapabilities.standardObdGateway(),
        compatibility: VehicleCompatibilityLevel.diagnosticOnly,
        verification: VerificationSource.documented,
        specifications: const {},
        thumbnailUrl: 'assets/garage/generic_obd.png',
      ),
    ]);
  }
}

extension _IterableExt<T> on Iterable<T> {
  Iterable<T> asEnumerable() => this;
}
