import '../models/vehicle_profile.dart';
import '../models/vehicle_identity.dart';
import '../models/active_vehicle_context.dart';
import 'vehicle_model_registry.dart';
import 'exact_vehicle_model_registry.dart';
import 'persistent_exact_model_storage.dart';
import 'model_generation_pipeline.dart';

class VehicleModelResolution {
  final VehicleModelStatus status;
  final ModelResolutionStatus resolutionStatus;
  final String modelPath;
  final String thumbnailPath;
  final bool isExact;
  final double scale;
  final List<double> cameraPosition;
  final List<double> cameraTarget;
  final double lightingIntensity;

  const VehicleModelResolution({
    required this.status,
    this.resolutionStatus = ModelResolutionStatus.modelNotAvailable,
    required this.modelPath,
    required this.thumbnailPath,
    required this.isExact,
    this.scale = 1.0,
    this.cameraPosition = const [2.5, 1.2, 3.5],
    this.cameraTarget = const [0.0, 0.5, 0.0],
    this.lightingIntensity = 1.0,
  });
}

class VehicleModelResolver {
  static final VehicleModelResolver _instance = VehicleModelResolver._internal();
  factory VehicleModelResolver() => _instance;
  VehicleModelResolver._internal();

  final VehicleModelRegistry _modelRegistry = VehicleModelRegistry();
  final ExactVehicleModelRegistry _exactRegistry = ExactVehicleModelRegistry();
  final PersistentExactModelStorage _persistentStorage = PersistentExactModelStorage();

  /// Resolves the exact 3D model configuration for a canonical VehicleIdentity object
  VehicleModelResolution resolveIdentity(VehicleIdentity? identity) {
    if (identity == null) {
      return const VehicleModelResolution(
        status: VehicleModelStatus.unavailable,
        resolutionStatus: ModelResolutionStatus.modelNotAvailable,
        modelPath: '',
        thumbnailPath: 'assets/garage/generic_bike.png',
        isExact: false,
      );
    }

    if (!identity.confidence.allowsAutomatic3DModel) {
      return VehicleModelResolution(
        status: VehicleModelStatus.unavailable,
        resolutionStatus: identity.confidence == IdentityConfidence.conflict
            ? ModelResolutionStatus.identityConflict
            : ModelResolutionStatus.identityUncertain,
        modelPath: '',
        thumbnailPath: _resolveSpecificThumbnail(identity),
        isExact: false,
      );
    }

    // 1. Check pre-bundled exact registry
    final exactAsset = _exactRegistry.resolveExactAsset(identity);
    if (exactAsset != null && exactAsset.glbAssetPath.isNotEmpty) {
      return VehicleModelResolution(
        status: VehicleModelStatus.ready,
        resolutionStatus: ModelResolutionStatus.modelReady,
        modelPath: exactAsset.glbAssetPath,
        thumbnailPath: exactAsset.thumbnailPath,
        isExact: true,
        scale: exactAsset.scale,
        cameraPosition: exactAsset.cameraPosition,
        cameraTarget: exactAsset.cameraTarget,
        lightingIntensity: exactAsset.lightingIntensity,
      );
    }

    // 2. Check persistent storage for validated dynamic twin
    final persisted = _persistentStorage.findExactPersistedModel(identity);
    if (persisted != null && persisted.glbAssetPath.isNotEmpty) {
      final rec = persisted.toAssetRecord();
      return VehicleModelResolution(
        status: VehicleModelStatus.ready,
        resolutionStatus: ModelResolutionStatus.modelReady,
        modelPath: rec.glbAssetPath,
        thumbnailPath: rec.thumbnailPath,
        isExact: true,
        scale: rec.scale,
        cameraPosition: rec.cameraPosition,
        cameraTarget: rec.cameraTarget,
        lightingIntensity: rec.lightingIntensity,
      );
    }

    final knownThumbnail = _resolveSpecificThumbnail(identity);
    return VehicleModelResolution(
      status: VehicleModelStatus.unavailable,
      resolutionStatus: ModelResolutionStatus.modelPendingValidation,
      modelPath: '',
      thumbnailPath: knownThumbnail,
      isExact: false,
    );
  }

  String _resolveSpecificThumbnail(VehicleIdentity identity) {
    final lower = '${identity.make} ${identity.model} ${identity.variant}'.toLowerCase();
    if (lower.contains('r1m') || lower.contains('r1')) return 'assets/garage/yamaha_r1m.png';
    if (lower.contains('mt-09') || lower.contains('mt09')) return 'assets/garage/yamaha_mt09_sp.png';
    if (lower.contains('panigale') || lower.contains('v4')) return 'assets/garage/ducati_panigale.png';
    if (lower.contains('m 1000') || lower.contains('m1000') || lower.contains('s 1000')) return 'assets/garage/bmw_m1000rr.png';
    if (lower.contains('burgman')) return 'assets/garage/suzuki_burgman.png';
    if (lower.contains('scooter') || lower.contains('ev_scooter') || lower.contains('activa') || lower.contains('aerox')) return 'assets/garage/generic_scooter.png';
    if (lower.contains('obd')) return 'assets/garage/generic_obd.png';
    return 'assets/garage/generic_bike.png';
  }

  /// Resolves the exact 3D model configuration for a legacy VehicleProfile without guessing or substituting
  VehicleModelResolution resolve(VehicleProfile? profile) {
    if (profile == null || profile.id.isEmpty) {
      return const VehicleModelResolution(
        status: VehicleModelStatus.unavailable,
        resolutionStatus: ModelResolutionStatus.modelNotAvailable,
        modelPath: '',
        thumbnailPath: '',
        isExact: false,
      );
    }

    final config = _modelRegistry.getModelConfig(profile.id);

    if (config.modelAvailable && config.modelPath.isNotEmpty) {
      return VehicleModelResolution(
        status: VehicleModelStatus.ready,
        resolutionStatus: ModelResolutionStatus.modelReady,
        modelPath: config.modelPath,
        thumbnailPath: config.thumbnailPath,
        isExact: true,
        scale: config.scale,
        cameraPosition: config.cameraPosition,
        cameraTarget: config.cameraTarget,
        lightingIntensity: config.lightingIntensity,
      );
    }

    return VehicleModelResolution(
      status: VehicleModelStatus.unavailable,
      resolutionStatus: ModelResolutionStatus.modelPendingValidation,
      modelPath: '',
      thumbnailPath: config.thumbnailPath.isNotEmpty ? config.thumbnailPath : profile.thumbnailUrl,
      isExact: false,
    );
  }
}
