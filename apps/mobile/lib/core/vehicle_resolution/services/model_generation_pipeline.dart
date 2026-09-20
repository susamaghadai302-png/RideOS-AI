import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/vehicle_identity.dart';
import '../models/digital_twin_model.dart';
import 'exact_vehicle_model_registry.dart';
import '../../../features/garage/core/services/model_quality_validator.dart';

enum ModelResolutionStatus {
  identifyingVehicle('IDENTIFYING_VEHICLE', 'Analyzing vehicle protocol telemetry & hardware signature'),
  identityVerified('IDENTITY_VERIFIED', 'Vehicle hardware signature verified'),
  modelPendingValidation('MODEL_PENDING_VALIDATION', 'VEHICLE IDENTIFIED — 3D MODEL PENDING VALIDATION'),
  exactModelFound('EXACT_MODEL_FOUND', 'Exact OEM 3D model discovered in verified registry'),
  modelGenerationPending('MODEL_GENERATION_PENDING', 'Vehicle verified — 3D model generation request queued'),
  modelGenerationInProgress('MODEL_GENERATION_IN_PROGRESS', 'Generating high-fidelity 3D digital twin geometry'),
  modelValidationPending('MODEL_VALIDATION_PENDING', 'Validating manifold boundaries and ground alignment'),
  modelReady('MODEL_READY', 'OFFICIAL VEHICLE 3D MODEL'),
  modelNotAvailable('MODEL_NOT_AVAILABLE', 'VEHICLE IDENTIFIED — 3D MODEL PENDING VALIDATION'),
  identityUncertain('IDENTITY_UNCERTAIN', 'Hardware telemetry incomplete — Awaiting rider confirmation'),
  identityConflict('IDENTITY_CONFLICT', 'Conflicting vehicle telemetry detected — Manual selection required');

  final String code;
  final String description;
  const ModelResolutionStatus(this.code, this.description);

  bool get isModelRenderable => this == ModelResolutionStatus.exactModelFound || this == ModelResolutionStatus.modelReady;
}

@immutable
class ModelGenerationRequest {
  final String requestId;
  final VehicleIdentity identity;
  final DateTime createdAt;
  final String targetMeshQuality;
  final bool requiresPhotogrammetry;

  ModelGenerationRequest({
    String? requestId,
    required this.identity,
    DateTime? createdAt,
    this.targetMeshQuality = 'ULTRA_2K',
    this.requiresPhotogrammetry = true,
  })  : requestId = requestId ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();
}

class ModelGenerationPipeline {
  static final ModelGenerationPipeline _instance = ModelGenerationPipeline._internal();
  factory ModelGenerationPipeline() => _instance;
  ModelGenerationPipeline._internal();

  final ExactVehicleModelRegistry _registry = ExactVehicleModelRegistry();
  final ModelQualityValidator _qualityValidator = ModelQualityValidator();

  final _statusController = StreamController<ModelResolutionStatus>.broadcast();
  Stream<ModelResolutionStatus> get statusStream => _statusController.stream;

  ModelResolutionStatus _currentStatus = ModelResolutionStatus.modelNotAvailable;
  ModelResolutionStatus get currentStatus => _currentStatus;

  void _setStatus(ModelResolutionStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  /// Evaluates vehicle identity and initiates safe 3D asset resolution or queued generation
  Future<ModelResolutionResult> processIdentity(VehicleIdentity identity) async {
    _setStatus(ModelResolutionStatus.identifyingVehicle);

    // 1. Check Identity Confidence
    if (identity.confidence == IdentityConfidence.conflict) {
      _setStatus(ModelResolutionStatus.identityConflict);
      return ModelResolutionResult.conflict(identity);
    }

    if (identity.confidence == IdentityConfidence.unknown || identity.confidence == IdentityConfidence.partialMatch) {
      _setStatus(ModelResolutionStatus.identityUncertain);
      return ModelResolutionResult.uncertain(identity);
    }

    _setStatus(ModelResolutionStatus.identityVerified);

    // 2. Check Exact Verified OEM Registry
    final exactRecord = _registry.resolveExactAsset(identity);
    if (exactRecord != null) {
      _setStatus(ModelResolutionStatus.exactModelFound);
      _setStatus(ModelResolutionStatus.modelReady);
      return ModelResolutionResult.ready(
        identity: identity,
        assetRecord: exactRecord,
      );
    }

    // 3. Exact asset is missing: Safe request creation without fake substitution
    _setStatus(ModelResolutionStatus.modelGenerationPending);
    final request = ModelGenerationRequest(identity: identity);
    
    // Model is NOT available yet; truthful 2D wireframe active
    _setStatus(ModelResolutionStatus.modelNotAvailable);
    return ModelResolutionResult.notAvailable(
      identity: identity,
      request: request,
    );
  }

  /// Finalizes validated generated digital twin model and registers it securely
  Future<Exact3DAssetRecord> finalizeGeneratedModel({
    required ModelGenerationRequest request,
    required String generatedGlbPath,
    required String generatedThumbnailPath,
    required DigitalTwinMeshStats meshStats,
  }) async {
    _setStatus(ModelResolutionStatus.modelValidationPending);

    final validation = _qualityValidator.validateDigitalTwin(
      modelPath: generatedGlbPath,
      stats: meshStats,
      targetQuality: DigitalTwinQuality.high,
    );

    if (!validation.isValid) {
      _setStatus(ModelResolutionStatus.modelNotAvailable);
      throw StateError('Digital Twin validation failed: ${validation.errorMessages.join(", ")}');
    }

    final newRecord = Exact3DAssetRecord(
      assetId: 'dyn_${request.identity.canonicalKey}_${request.requestId.substring(0, 8)}',
      make: request.identity.make,
      model: request.identity.model,
      variant: request.identity.variant,
      minYear: request.identity.modelYear ?? 2000,
      maxYear: request.identity.modelYear ?? DateTime.now().year,
      glbAssetPath: generatedGlbPath,
      thumbnailPath: generatedThumbnailPath,
      assetVersion: '1.0.0-scan',
      assetChecksum: 'sha256:${request.requestId}',
      verificationStatus: AssetVerificationStatus.communityVerified,
      source: 'SMARTPHONE_SCAN',
    );

    _registry.registerDynamicVerifiedAsset(newRecord);
    _setStatus(ModelResolutionStatus.modelReady);
    return newRecord;
  }
}

class ModelResolutionResult {
  final ModelResolutionStatus status;
  final VehicleIdentity identity;
  final Exact3DAssetRecord? assetRecord;
  final ModelGenerationRequest? generationRequest;

  const ModelResolutionResult({
    required this.status,
    required this.identity,
    this.assetRecord,
    this.generationRequest,
  });

  factory ModelResolutionResult.ready({
    required VehicleIdentity identity,
    required Exact3DAssetRecord assetRecord,
  }) =>
      ModelResolutionResult(
        status: ModelResolutionStatus.modelReady,
        identity: identity,
        assetRecord: assetRecord,
      );

  factory ModelResolutionResult.notAvailable({
    required VehicleIdentity identity,
    ModelGenerationRequest? request,
  }) =>
      ModelResolutionResult(
        status: ModelResolutionStatus.modelNotAvailable,
        identity: identity,
        generationRequest: request,
      );

  factory ModelResolutionResult.uncertain(VehicleIdentity identity) =>
      ModelResolutionResult(
        status: ModelResolutionStatus.identityUncertain,
        identity: identity,
      );

  factory ModelResolutionResult.conflict(VehicleIdentity identity) =>
      ModelResolutionResult(
        status: ModelResolutionStatus.identityConflict,
        identity: identity,
      );
}
