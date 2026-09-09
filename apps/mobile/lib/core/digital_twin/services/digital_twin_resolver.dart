import '../domain/models.dart';
import '../../vehicle_resolution/models/vehicle_identity.dart';
import '../../vehicle_resolution/services/exact_vehicle_model_registry.dart';
import '../../vehicle_resolution/services/persistent_exact_model_storage.dart';

class DigitalTwinResolver {
  static final DigitalTwinResolver _instance = DigitalTwinResolver._internal();
  factory DigitalTwinResolver() => _instance;
  DigitalTwinResolver._internal();

  final ExactVehicleModelRegistry _exactRegistry = ExactVehicleModelRegistry();
  final PersistentExactModelStorage _persistentStorage = PersistentExactModelStorage();

  DigitalTwinResolutionResult resolve(VehicleIdentity? identity) {
    if (identity == null) {
      return const DigitalTwinResolutionResult(
        fidelity: DigitalTwinFidelity.level42D,
        reason: 'No vehicle identity provided.',
      );
    }

    // 1. Level 1: Verified Exact 3D
    if (identity.confidence.allowsAutomatic3DModel) {
      final exactAsset = _exactRegistry.resolveExactAsset(identity);
      if (exactAsset != null && exactAsset.glbAssetPath.isNotEmpty) {
        return DigitalTwinResolutionResult(
          fidelity: DigitalTwinFidelity.level1Exact3D,
          asset: DigitalTwinAsset(
            assetId: exactAsset.assetId,
            path: exactAsset.glbAssetPath,
            fidelity: DigitalTwinFidelity.level1Exact3D,
            verificationStatus: DigitalTwinAssetVerification.verified,
            provenance: exactAsset.source,
          ),
          reason: 'Verified exact 3D asset found.',
        );
      }

      final persisted = _persistentStorage.findExactPersistedModel(identity);
      if (persisted != null && persisted.glbAssetPath.isNotEmpty) {
        return DigitalTwinResolutionResult(
          fidelity: DigitalTwinFidelity.level1Exact3D,
          asset: DigitalTwinAsset(
            assetId: persisted.assetId,
            path: persisted.glbAssetPath,
            fidelity: DigitalTwinFidelity.level1Exact3D,
            verificationStatus: DigitalTwinAssetVerification.verified,
            provenance: persisted.toAssetRecord().source,
          ),
          reason: 'Persisted exact 3D asset found.',
        );
      }
    }

    // 2. Level 2: Category Generic 3D
    // If not exact, or no exact asset exists, but we know the category
    final categoryAsset = _resolveGenericCategoryAsset(identity);
    if (categoryAsset != null) {
      return DigitalTwinResolutionResult(
        fidelity: DigitalTwinFidelity.level2Category3D,
        asset: categoryAsset,
        reason: 'Exact 3D asset unavailable. Using generic category 3D.',
      );
    }

    // 3. Level 3: Procedural Wireframe
    if (_canProceduralGenerate(identity)) {
      return DigitalTwinResolutionResult(
        fidelity: DigitalTwinFidelity.level3Procedural,
        asset: DigitalTwinAsset(
          assetId: 'procedural_${identity.make}_${identity.model}',
          path: '', // Procedural has no path
          fidelity: DigitalTwinFidelity.level3Procedural,
          verificationStatus: DigitalTwinAssetVerification.unverified,
          provenance: 'PROCEDURAL',
        ),
        reason: 'No 3D asset available. Using procedural representation.',
      );
    }

    // 4. Level 4: 2D Orthographic Fallback
    return const DigitalTwinResolutionResult(
      fidelity: DigitalTwinFidelity.level42D,
      reason: 'No 3D or procedural representation available. Using 2D fallback.',
    );
  }

  DigitalTwinAsset? _resolveGenericCategoryAsset(VehicleIdentity identity) {
    // Currently, there is NO verified generic category 3D asset in the repository.
    // We cannot simulate or mock one. We must fall back to Level 3.
    return null; 
  }

  bool _canProceduralGenerate(VehicleIdentity identity) {
    // We assume we can procedurally generate wireframes for any known identity
    // even if we don't have a 3D asset.
    return true;
  }
}
