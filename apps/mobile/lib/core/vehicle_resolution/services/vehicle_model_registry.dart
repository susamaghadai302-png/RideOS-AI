import '../models/vehicle_profile.dart';
import 'vehicle_catalog_data.dart';

class Vehicle3DConfig {
  final String id;
  final String manufacturer;
  final String model;
  final String variant;
  final int year;
  final String category;
  final String model3d;
  final String thumbnail;
  final String source; // 'OEM_CAD', 'OEM_SCAN', 'USER_PHOTOGRAMMETRY'
  final String license; // 'OEM_LICENSED', 'COMMUNITY_VERIFIED'
  final String verificationStatus; // 'VERIFIED_OEM', 'UNVERIFIED'
  final bool modelAvailable;
  final double scale;
  final List<double> cameraPosition;
  final List<double> cameraTarget;
  final double lightingIntensity;

  const Vehicle3DConfig({
    required this.id,
    required this.manufacturer,
    required this.model,
    this.variant = '',
    this.year = 2024,
    this.category = 'Motorcycle',
    required this.model3d,
    required this.thumbnail,
    this.source = 'OEM_CAD',
    this.license = 'OEM_LICENSED',
    this.verificationStatus = 'VERIFIED_OEM',
    required this.modelAvailable,
    this.scale = 1.0,
    this.cameraPosition = const [2.5, 1.2, 3.5],
    this.cameraTarget = const [0.0, 0.5, 0.0],
    this.lightingIntensity = 1.0,
  });

  // Aliases and convenience getters
  String get vehicleId => id;
  String get modelPath => model3d;
  String get modelAssetPath => model3d;
  String get thumbnailPath => thumbnail;
  bool get isVerified => modelAvailable && (verificationStatus == 'VERIFIED_OEM' || verificationStatus == 'VERIFIED_REAL_MODEL');
  String get modelStatus => modelAvailable ? 'VERIFIED_OEM' : 'MODEL VALIDATION PENDING';
  bool get requiresRealVehicleScan => !modelAvailable;
}

class VehicleModelRegistry {
  static final VehicleModelRegistry _instance = VehicleModelRegistry._internal();
  factory VehicleModelRegistry() => _instance;

  final Map<String, Vehicle3DConfig> _configs = {};

  VehicleModelRegistry._internal() {
    _populateFromCatalog();
    _assertModelUniqueness();
  }

  void _populateFromCatalog() {
    for (final profile in VehicleCatalogData.catalogProfiles) {
      final isRealModel = profile.model3DUrl.isNotEmpty;
      _configs[profile.id] = Vehicle3DConfig(
        id: profile.id,
        manufacturer: profile.manufacturer,
        model: profile.model,
        variant: profile.variant,
        year: profile.year,
        category: profile.category,
        model3d: profile.model3DUrl,
        thumbnail: profile.thumbnailUrl,
        source: isRealModel ? 'OEM_CAD' : 'PENDING_CAD_SCAN',
        license: isRealModel ? 'OEM_LICENSED' : 'PENDING_VALIDATION',
        verificationStatus: isRealModel ? 'VERIFIED_OEM' : 'MODEL_VALIDATION_PENDING',
        modelAvailable: isRealModel,
        scale: 1.0,
        cameraPosition: const [2.5, 1.2, 3.5],
        lightingIntensity: 1.15,
      );
    }
  }

  void _assertModelUniqueness() {
    final seen = <String, String>{};
    for (final entry in _configs.entries) {
      final model = entry.value.model3d;
      if (model.isNotEmpty) {
        if (seen.containsKey(model)) {
          throw StateError(
            'INVARIANT VIOLATION: Duplicate 3D model path "$model" shared by ${seen[model]} and ${entry.key}',
          );
        }
        seen[model] = entry.key;
      }
    }
  }

  Vehicle3DConfig getModelConfig(String vehicleId) {
    return _configs[vehicleId] ??
        Vehicle3DConfig(
          id: vehicleId,
          manufacturer: 'Custom',
          model: 'Vehicle',
          model3d: '',
          thumbnail: '',
          modelAvailable: false,
        );
  }

  Vehicle3DConfig getModelConfigForProfile(VehicleProfile profile) => getModelConfig(profile.id);

  List<Vehicle3DConfig> get allVerifiedConfigs => _configs.values.where((c) => c.modelAvailable).toList();
  List<Vehicle3DConfig> get allConfigs => _configs.values.toList();
}
