import 'package:flutter/foundation.dart';
import '../models/vehicle_capabilities.dart';
import '../models/vehicle_variant_taxonomy.dart';

@immutable
class UniversalVehicleEntry {
  final String id;
  final String brand;
  final String family;
  final String generation;
  final String model;
  final String variant; // Base, Mid, High, M-Sport, S, SP, Pro, Apex
  final int modelYear;
  final String vehicleType; // Motorcycle, Scooter, ElectricMotorcycle, ElectricScooter
  final String fuelType; // Petrol, Electric, Hybrid
  final String displayType; // 5" TFT, 7" Touchscreen, Segmented LCD, Analogue
  final VehicleConnectivityType connectionMethod;
  final String protocolAdapterId;
  final VehicleCapabilities capabilities;
  final VehicleCompatibilityLevel compatibilityLevel;
  final String? model3DUrl;
  final String? thumbnailUrl;

  const UniversalVehicleEntry({
    required this.id,
    required this.brand,
    required this.family,
    required this.generation,
    required this.model,
    required this.variant,
    required this.modelYear,
    required this.vehicleType,
    required this.fuelType,
    required this.displayType,
    required this.connectionMethod,
    required this.protocolAdapterId,
    required this.capabilities,
    required this.compatibilityLevel,
    this.model3DUrl,
    this.thumbnailUrl,
  });

  String get fullName => '$brand $model ($variant $modelYear)';
}

class UniversalVehicleDatabase {
  static final UniversalVehicleDatabase _instance = UniversalVehicleDatabase._internal();
  factory UniversalVehicleDatabase() => _instance;

  final List<UniversalVehicleEntry> _catalog = [];

  UniversalVehicleDatabase._internal() {
    _seedUniversalCatalog();
  }

  List<UniversalVehicleEntry> get allEntries => List.unmodifiable(_catalog);

  void registerEntry(UniversalVehicleEntry entry) {
    _catalog.removeWhere((e) => e.id == entry.id);
    _catalog.add(entry);
  }

  List<String> get availableBrands => _catalog.map((e) => e.brand).toSet().toList()..sort();

  List<String> getFamiliesForBrand(String brand) {
    return _catalog
        .where((e) => e.brand.toLowerCase() == brand.toLowerCase())
        .map((e) => e.family)
        .toSet()
        .toList()
      ..sort();
  }

  List<UniversalVehicleEntry> getModelsForFamily(String brand, String family) {
    return _catalog
        .where((e) => e.brand.toLowerCase() == brand.toLowerCase() && e.family.toLowerCase() == family.toLowerCase())
        .toList();
  }

  UniversalVehicleEntry? findById(String id) {
    try {
      return _catalog.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  List<UniversalVehicleEntry> search({
    String? category,
    String? brand,
    String? query,
    int? year,
  }) {
    return _catalog.where((e) {
      if (category != null && category.isNotEmpty && e.vehicleType.toLowerCase() != category.toLowerCase()) {
        return false;
      }
      if (brand != null && brand.isNotEmpty && e.brand.toLowerCase() != brand.toLowerCase()) {
        return false;
      }
      if (year != null && e.modelYear != year) {
        return false;
      }
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        final match = e.brand.toLowerCase().contains(q) ||
            e.model.toLowerCase().contains(q) ||
            e.family.toLowerCase().contains(q) ||
            e.variant.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  void _seedUniversalCatalog() {
    // --- YAMAHA ---
    _catalog.addAll([
      UniversalVehicleEntry(
        id: 'yamaha_r15_v4_m',
        brand: 'Yamaha',
        family: 'YZF-R15',
        generation: 'Gen 4 (2021+)',
        model: 'YZF-R15',
        variant: 'M (TFT + Quickshifter)',
        modelYear: 2024,
        vehicleType: 'Motorcycle',
        fuelType: 'Petrol',
        displayType: 'Full-Color TFT with Track/Street Modes',
        connectionMethod: VehicleConnectivityType.ble,
        protocolAdapterId: 'yamaha_y_connect',
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        compatibilityLevel: VehicleCompatibilityLevel.full,
        thumbnailUrl: 'assets/garage/generic_bike.png',
      ),
      UniversalVehicleEntry(
        id: 'yamaha_aerox155',
        brand: 'Yamaha',
        family: 'Aerox',
        generation: 'Gen 2 (2021+)',
        model: 'Aerox 155',
        variant: 'Connected Standard',
        modelYear: 2024,
        vehicleType: 'Scooter',
        fuelType: 'Petrol',
        displayType: 'Negative LCD with Y-Connect Sub-Display',
        connectionMethod: VehicleConnectivityType.ble,
        protocolAdapterId: 'yamaha_y_connect',
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        compatibilityLevel: VehicleCompatibilityLevel.full,
        thumbnailUrl: 'assets/garage/generic_scooter.png',
      ),
      UniversalVehicleEntry(
        id: 'yamaha_mt09_sp',
        brand: 'Yamaha',
        family: 'MT-09',
        generation: 'Gen 4 (2024+)',
        model: 'MT-09',
        variant: 'SP Premium',
        modelYear: 2024,
        vehicleType: 'Motorcycle',
        fuelType: 'Petrol',
        displayType: '5-inch Full Color TFT with Garmin StreetCross',
        connectionMethod: VehicleConnectivityType.ble,
        protocolAdapterId: 'yamaha_y_connect',
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        compatibilityLevel: VehicleCompatibilityLevel.full,
        model3DUrl: null,
        thumbnailUrl: 'assets/garage/yamaha_mt09_sp.png',
      ),
    ]);

    // --- SUZUKI ---
    _catalog.addAll([
      UniversalVehicleEntry(
        id: 'suzuki_burgman_ex',
        brand: 'Suzuki',
        family: 'Burgman Street',
        generation: 'EX Edition (2023+)',
        model: 'Burgman Street 125',
        variant: 'EX (Ride Connect)',
        modelYear: 2024,
        vehicleType: 'Scooter',
        fuelType: 'Petrol',
        displayType: 'Digital Cluster with Turn-by-Turn Nav',
        connectionMethod: VehicleConnectivityType.ble,
        protocolAdapterId: 'suzuki_ride_connect',
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        compatibilityLevel: VehicleCompatibilityLevel.full,
        model3DUrl: null,
        thumbnailUrl: 'assets/garage/suzuki_burgman.png',
      ),
      UniversalVehicleEntry(
        id: 'suzuki_vstrom_sx',
        brand: 'Suzuki',
        family: 'V-Strom',
        generation: 'SX 250 (2022+)',
        model: 'V-Strom SX 250',
        variant: 'Adventure Connect',
        modelYear: 2024,
        vehicleType: 'Motorcycle',
        fuelType: 'Petrol',
        displayType: 'Suzuki Ride Connect LCD',
        connectionMethod: VehicleConnectivityType.ble,
        protocolAdapterId: 'suzuki_ride_connect',
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        compatibilityLevel: VehicleCompatibilityLevel.full,
        thumbnailUrl: 'assets/garage/generic_bike.png',
      ),
    ]);

    // --- DUCATI ---
    _catalog.addAll([
      UniversalVehicleEntry(
        id: 'ducati_panigale_v4s',
        brand: 'Ducati',
        family: 'Panigale',
        generation: 'V4 2024 Facelift',
        model: 'Panigale V4',
        variant: 'S (Electronic Suspension)',
        modelYear: 2024,
        vehicleType: 'Motorcycle',
        fuelType: 'Petrol',
        displayType: '6.9-inch Racing TFT with Cornering DMS',
        connectionMethod: VehicleConnectivityType.ble,
        protocolAdapterId: 'ducati_dms',
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        compatibilityLevel: VehicleCompatibilityLevel.full,
        model3DUrl: 'assets/models/ducati_panigale.glb',
        thumbnailUrl: 'assets/garage/ducati_panigale.png',
      ),
    ]);

    // --- BMW MOTORRAD ---
    _catalog.addAll([
      UniversalVehicleEntry(
        id: 'bmw_s1000rr_m',
        brand: 'BMW Motorrad',
        family: 'S 1000 RR',
        generation: 'K67 (2023+)',
        model: 'S 1000 RR',
        variant: 'M Package',
        modelYear: 2024,
        vehicleType: 'Motorcycle',
        fuelType: 'Petrol',
        displayType: '6.5-inch Connectivity TFT',
        connectionMethod: VehicleConnectivityType.ble,
        protocolAdapterId: 'bmw_motorrad_connect',
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        compatibilityLevel: VehicleCompatibilityLevel.full,
        model3DUrl: 'assets/models/bmw_s1000rr.glb',
        thumbnailUrl: 'assets/garage/bmw_s1000rr.png',
      ),
      UniversalVehicleEntry(
        id: 'bmw_ce04_ev',
        brand: 'BMW Motorrad',
        family: 'CE 04',
        generation: 'Gen 1 (2022+)',
        model: 'CE 04',
        variant: 'Avantgarde Connected EV',
        modelYear: 2024,
        vehicleType: 'ElectricScooter',
        fuelType: 'Electric',
        displayType: '10.25-inch Full HD Split Screen TFT',
        connectionMethod: VehicleConnectivityType.ble,
        protocolAdapterId: 'bmw_motorrad_connect',
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        compatibilityLevel: VehicleCompatibilityLevel.full,
        thumbnailUrl: 'assets/garage/generic_scooter.png',
      ),
    ]);

    // --- KTM ---
    _catalog.addAll([
      UniversalVehicleEntry(
        id: 'ktm_duke390_gen3',
        brand: 'KTM',
        family: 'Duke',
        generation: 'Gen 3 (2024+)',
        model: '390 Duke',
        variant: 'Standard TFT with Launch Control',
        modelYear: 2024,
        vehicleType: 'Motorcycle',
        fuelType: 'Petrol',
        displayType: '5-inch Color TFT with KTM Connect',
        connectionMethod: VehicleConnectivityType.ble,
        protocolAdapterId: 'ktm_my_ride',
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        compatibilityLevel: VehicleCompatibilityLevel.full,
        thumbnailUrl: 'assets/garage/generic_bike.png',
      ),
    ]);

    // --- ROYAL ENFIELD ---
    _catalog.addAll([
      UniversalVehicleEntry(
        id: 're_himalayan450',
        brand: 'Royal Enfield',
        family: 'Himalayan',
        generation: 'Sherpa 450 (2023+)',
        model: 'Himalayan 450',
        variant: 'Kamet White / Hanle Black (Tripper Navigation)',
        modelYear: 2024,
        vehicleType: 'Motorcycle',
        fuelType: 'Petrol',
        displayType: '4-inch Circular Full Color TFT with Google Maps',
        connectionMethod: VehicleConnectivityType.smartDisplayMirror,
        protocolAdapterId: 'royal_enfield_tripper',
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        compatibilityLevel: VehicleCompatibilityLevel.full,
        thumbnailUrl: 'assets/garage/generic_bike.png',
      ),
    ]);

    // --- TVS MOTOR ---
    _catalog.addAll([
      UniversalVehicleEntry(
        id: 'tvs_apache_rr310',
        brand: 'TVS Motor',
        family: 'Apache',
        generation: '2024 Facelift',
        model: 'Apache RR 310',
        variant: 'BTO (Built To Order)',
        modelYear: 2024,
        vehicleType: 'Motorcycle',
        fuelType: 'Petrol',
        displayType: '5-inch Vertical SmartXonnect TFT',
        connectionMethod: VehicleConnectivityType.ble,
        protocolAdapterId: 'tvs_smartxonnect',
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        compatibilityLevel: VehicleCompatibilityLevel.full,
        thumbnailUrl: 'assets/garage/generic_bike.png',
      ),
    ]);

    // --- ATHER ENERGY ---
    _catalog.addAll([
      UniversalVehicleEntry(
        id: 'ather_450x_gen4',
        brand: 'Ather Energy',
        family: '450',
        generation: 'Gen 4 (2024+)',
        model: '450X',
        variant: 'Pro Pack 3.7 kWh',
        modelYear: 2024,
        vehicleType: 'ElectricScooter',
        fuelType: 'Electric',
        displayType: '7-inch Touchscreen Snapdragon Dashboard',
        connectionMethod: VehicleConnectivityType.manufacturerApi,
        protocolAdapterId: 'ather_cloud_telematics',
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        compatibilityLevel: VehicleCompatibilityLevel.full,
        thumbnailUrl: 'assets/garage/generic_scooter.png',
      ),
    ]);

    // --- OLA ELECTRIC ---
    _catalog.addAll([
      UniversalVehicleEntry(
        id: 'ola_s1_pro_gen2',
        brand: 'Ola Electric',
        family: 'S1',
        generation: 'Gen 2 (2023+)',
        model: 'S1 Pro',
        variant: 'Gen 2 4.0 kWh',
        modelYear: 2024,
        vehicleType: 'ElectricScooter',
        fuelType: 'Electric',
        displayType: '7-inch Touchscreen MoveOS 4',
        connectionMethod: VehicleConnectivityType.manufacturerApi,
        protocolAdapterId: 'ola_moveos_telematics',
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        compatibilityLevel: VehicleCompatibilityLevel.full,
        thumbnailUrl: 'assets/garage/generic_scooter.png',
      ),
    ]);

    // --- UNIVERSAL OBD-II & CAN GATEWAYS (2015+) ---
    _catalog.addAll([
      UniversalVehicleEntry(
        id: 'universal_euro5_obd2',
        brand: 'Universal / Generic',
        family: 'OBD-II Two-Wheeler',
        generation: 'Euro 4/5/6 & BS-VI Standard (2015+)',
        model: 'Diagnostic Gateway Vehicle',
        variant: '4-Pin / 6-Pin / 16-Pin Adapter',
        modelYear: 2024,
        vehicleType: 'Motorcycle',
        fuelType: 'Petrol',
        displayType: 'External Diagnostic Interface',
        connectionMethod: VehicleConnectivityType.obd2Gateway,
        protocolAdapterId: 'obd2_gateway_standard',
        capabilities: VehicleCapabilities.standardObdGateway(),
        compatibilityLevel: VehicleCompatibilityLevel.diagnosticOnly,
        thumbnailUrl: 'assets/garage/generic_obd.png',
      ),
    ]);
  }
}
