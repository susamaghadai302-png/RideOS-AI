import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/digital_twin_model.dart';
import '../models/vehicle_identity_confidence.dart';
import '../models/vehicle_profile.dart';
import 'digital_twin_storage_service.dart';
import 'vehicle_identity_confidence_engine.dart';
import 'vehicle_registry.dart';
import 'vehicle_model_registry.dart';
import '../../../features/garage/core/services/model_quality_validator.dart';
import '../../../features/garage/core/services/vehicle_3d_reconstruction_service.dart';
import '../../../features/garage/core/services/scan_coverage_evaluator.dart';

/// Central Digital Twin Management Service for RideOS-AI.
/// Coordinates the entire flow:
/// Vehicle -> Vehicle Identity -> Digital Twin -> 3D Asset -> 3D Garage
class DigitalTwinService {
  static final DigitalTwinService _instance = DigitalTwinService._internal();
  factory DigitalTwinService() => _instance;
  DigitalTwinService._internal();

  final DigitalTwinStorageService _storageService = DigitalTwinStorageService();
  final VehicleIdentityConfidenceEngine _identityEngine = VehicleIdentityConfidenceEngine();
  final VehicleRegistry _registry = VehicleRegistry();
  final VehicleModelRegistry modelRegistry = VehicleModelRegistry();
  final ModelQualityValidator _qualityValidator = ModelQualityValidator();
  final Vehicle3DReconstructionService _reconstructionService = Vehicle3DReconstructionService();

  final _digitalTwinController = StreamController<Map<String, DigitalTwinModel>>.broadcast();
  Stream<Map<String, DigitalTwinModel>> get digitalTwinsStream => _digitalTwinController.stream;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await _storageService.initialize();
    _initialized = true;
    _broadcastCurrentState();
  }

  void _broadcastCurrentState() {
    _digitalTwinController.add(_storageService.getAllSavedTwins());
  }

  /// 1. Identify Vehicle with Multi-Source Resolution
  Future<VehicleIdentityResult> identifyVehicle({
    String? bluetoothName,
    String? vin,
    String? manufacturer,
    String? model,
    int? year,
    String? category,
  }) async {
    if (!_initialized) await initialize();
    return _identityEngine.evaluateIdentity(
      bluetoothName: bluetoothName,
      vin: vin,
      userSpecifiedMake: manufacturer,
      userSpecifiedModel: model,
      userSpecifiedYear: year,
    );
  }

  /// 2. Find Exact Verified OEM Model in Central Model Registry
  VehicleProfile? findExactModel({
    required String manufacturer,
    required String model,
    String? variant,
    int? year,
  }) {
    final cleanMfr = manufacturer.trim().toLowerCase();
    final cleanMdl = model.trim().toLowerCase();

    for (final profile in _registry.verifiedProfiles) {
      final pMfr = profile.manufacturer.toLowerCase();
      final pMdl = profile.model.toLowerCase();

      final mfrMatches = cleanMfr.contains(pMfr) || pMfr.contains(cleanMfr);
      final mdlMatches = cleanMdl.contains(pMdl) || pMdl.contains(cleanMdl);

      if (mfrMatches && mdlMatches) {
        if (profile.has3DModel) {
          return profile;
        }
      }
    }
    return null;
  }

  /// 3. Load Existing Model Path for Vehicle
  Future<String?> loadExistingModel(String vehicleId) async {
    if (!_initialized) await initialize();

    // Check saved digital twin first
    final savedTwin = await _storageService.getDigitalTwinForVehicle(vehicleId);
    if (savedTwin != null && savedTwin.modelGlbPath.isNotEmpty) {
      return savedTwin.modelGlbPath;
    }

    // Check OEM verified registry
    final oemProfile = _registry.getProfileById(vehicleId);
    if (oemProfile != null && oemProfile.has3DModel) {
      return oemProfile.model3DUrl;
    }

    // Strict zero-substitution: return null if no exact model exists
    return null;
  }

  /// 4. Determine Whether Smartphone 3D Scan is Required
  Future<bool> determineWhetherScanIsRequired(String vehicleId) async {
    final existingModel = await loadExistingModel(vehicleId);
    return existingModel == null || existingModel.isEmpty;
  }

  /// 5. Create New Digital Twin Record (v1)
  Future<DigitalTwinModel> createDigitalTwinRecord({
    required String vehicleId,
    required String manufacturer,
    required String modelName,
    String variant = '',
    int year = 2024,
    String category = 'Motorcycle',
    required List<CapturedFrameMetadata> capturedFrames,
    DigitalTwinQuality targetQuality = DigitalTwinQuality.high,
  }) async {
    if (!_initialized) await initialize();

    final twin = await _reconstructionService.reconstructDigitalTwin(
      vehicleId: vehicleId,
      manufacturer: manufacturer,
      modelName: modelName,
      variant: variant,
      year: year,
      category: category,
      capturedFrames: capturedFrames,
      targetQuality: targetQuality,
    );

    await _storageService.saveDigitalTwin(twin);
    _broadcastCurrentState();
    return twin;
  }

  /// Convenience method for test/automation reconstruction without manual frame construction
  Future<DigitalTwinModel> reconstructFromPhotos({
    required String vehicleId,
    required String manufacturer,
    required String modelName,
    String variant = '',
    int year = 2024,
    String category = 'Motorcycle',
    DigitalTwinQuality targetQuality = DigitalTwinQuality.high,
  }) async {
    final frames = ScanSector.values.map((s) => CapturedFrameMetadata(
      frameId: '${vehicleId}_${s.name}',
      targetSector: s,
      estimatedAngleDeg: s.targetAngleDeg.toDouble(),
      timestamp: DateTime.now(),
    )).toList();

    return createDigitalTwinRecord(
      vehicleId: vehicleId,
      manufacturer: manufacturer,
      modelName: modelName,
      variant: variant,
      year: year,
      category: category,
      capturedFrames: frames,
      targetQuality: targetQuality,
    );
  }

  /// 6. Load Saved Digital Twin for Vehicle
  Future<DigitalTwinModel?> loadSavedDigitalTwin(String vehicleId) async {
    if (!_initialized) await initialize();
    return _storageService.getDigitalTwinForVehicle(vehicleId);
  }

  /// 7. Update Digital Twin with Versioning (v1 -> v2 -> v3)
  Future<DigitalTwinModel> updateDigitalTwin({
    required String vehicleId,
    required List<CapturedFrameMetadata> newFrames,
    DigitalTwinQuality? newQuality,
  }) async {
    if (!_initialized) await initialize();

    final currentTwin = await _storageService.getDigitalTwinForVehicle(vehicleId);
    final nextVersion = (currentTwin?.version ?? 0) + 1;
    final nextVersionTag = 'v$nextVersion.0';

    final updatedTwin = await _reconstructionService.reconstructDigitalTwin(
      vehicleId: vehicleId,
      manufacturer: currentTwin?.manufacturer ?? 'Custom',
      modelName: currentTwin?.model ?? 'Vehicle',
      variant: currentTwin?.variant ?? '',
      year: currentTwin?.year ?? DateTime.now().year,
      category: currentTwin?.category ?? 'Motorcycle',
      capturedFrames: newFrames,
      targetQuality: newQuality ?? currentTwin?.quality ?? DigitalTwinQuality.high,
    );

    final versionedTwin = updatedTwin.copyWith(
      version: nextVersion,
      versionTag: nextVersionTag,
      updatedAt: DateTime.now(),
      createdAt: currentTwin?.createdAt ?? DateTime.now(),
    );

    await _storageService.saveDigitalTwin(versionedTwin);
    _broadcastCurrentState();
    debugPrint('✨ Updated Digital Twin for $vehicleId to $nextVersionTag (${versionedTwin.twinId})');
    return versionedTwin;
  }

  /// 8. Delete Digital Twin
  Future<bool> deleteDigitalTwin(String twinId) async {
    if (!_initialized) await initialize();
    final success = await _storageService.deleteDigitalTwin(twinId);
    if (success) _broadcastCurrentState();
    return success;
  }


  /// 10. Validate Digital Twin Model Geometry, Bounds, and Orientation
  ModelValidationResult validateModel(DigitalTwinModel model) {
    return _qualityValidator.validateDigitalTwin(
      modelPath: model.modelGlbPath,
      stats: model.meshStats,
    );
  }

  /// 10. Purge Raw Source Photos for Privacy
  Future<bool> purgeSourcePhotos(String twinId) async {
    if (!_initialized) await initialize();
    final success = await _storageService.purgeSourcePhotos(twinId);
    if (success) _broadcastCurrentState();
    return success;
  }

  /// Get all saved digital twins map
  Map<String, DigitalTwinModel> getAllSavedTwins() {
    return _storageService.getAllSavedTwins();
  }
}
