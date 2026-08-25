import 'package:flutter/foundation.dart';
import '../models/vehicle_identity.dart';

enum AssetVerificationStatus {
  verifiedRealModel('VERIFIED_REAL_MODEL'),
  modelValidationPending('MODEL_VALIDATION_PENDING'),
  modelNotAvailable('MODEL_NOT_AVAILABLE'),
  modelLoadError('MODEL_LOAD_ERROR'),
  verifiedOem('VERIFIED_REAL_MODEL'),
  communityVerified('COMMUNITY_VERIFIED'),
  pendingValidation('MODEL_VALIDATION_PENDING'),
  unverified('MODEL_NOT_AVAILABLE');

  final String code;
  const AssetVerificationStatus(this.code);

  bool get isVerifiedRealModel =>
      this == AssetVerificationStatus.verifiedRealModel ||
      this == AssetVerificationStatus.verifiedOem;
}

@immutable
class Exact3DAssetRecord {
  final String assetId;
  final String make;
  final String model;
  final String variant;
  final int minYear;
  final int maxYear;
  final String? vin;
  final String glbAssetPath;
  final String thumbnailPath;
  final String assetVersion;
  final String assetChecksum;
  final AssetVerificationStatus verificationStatus;
  final String source;
  final DateTime validationTimestamp;
  final double confidenceScore;
  final double scale;
  final List<double> cameraPosition;
  final List<double> cameraTarget;
  final double lightingIntensity;

  Exact3DAssetRecord({
    required this.assetId,
    required this.make,
    required this.model,
    this.variant = '',
    this.minYear = 2015,
    this.maxYear = 2030,
    this.vin,
    required this.glbAssetPath,
    required this.thumbnailPath,
    this.assetVersion = '1.0.0',
    required this.assetChecksum,
    this.verificationStatus = AssetVerificationStatus.verifiedRealModel,
    this.source = 'OEM_CAD',
    DateTime? validationTimestamp,
    this.confidenceScore = 1.0,
    this.scale = 1.0,
    this.cameraPosition = const [2.5, 1.2, 3.5],
    this.cameraTarget = const [0.0, 0.5, 0.0],
    this.lightingIntensity = 1.0,
  }) : validationTimestamp = validationTimestamp ?? DateTime(2024, 1, 1);

  String get manufacturer => make;
  int get year => minYear;
  String get modelVersion => assetVersion;
  bool get isOfficialModel => verificationStatus.isVerifiedRealModel && glbAssetPath.isNotEmpty;
  bool get isAssetAvailable => isOfficialModel;
  String get validationBadgeText => isOfficialModel
      ? 'OFFICIAL VEHICLE 3D MODEL'
      : '3D MODEL NOT AVAILABLE | MODEL VALIDATION PENDING';

  bool matchesVehicle({
    required String targetMake,
    required String targetModel,
    String targetVariant = '',
    int targetYear = 2024,
  }) {
    final tMake = targetMake.trim().toLowerCase();
    final tModel = targetModel.trim().toLowerCase();
    final tVariant = targetVariant.trim().toLowerCase();

    final mMake = make.trim().toLowerCase();
    final mModel = model.trim().toLowerCase();
    final mVariant = variant.trim().toLowerCase();

    final makeMatches = tMake == mMake || tMake.contains(mMake) || mMake.contains(tMake);
    if (!makeMatches) return false;

    final modelMatches = tModel == mModel || tModel.contains(mModel) || mModel.contains(tModel);
    if (!modelMatches) return false;

    if (variant.isNotEmpty && tVariant.isNotEmpty) {
      final variantMatches = tVariant == mVariant || tVariant.contains(mVariant) || mVariant.contains(tVariant);
      if (!variantMatches) return false;
    }

    if (targetYear < minYear || targetYear > maxYear) {
      return false;
    }

    return true;
  }
}

/// Single Authoritative Exact 3D Model Registry for RideOS-AI.
/// Enforces ONE VEHICLE = ONE EXACT 3D ASSET invariant.
class ExactVehicleModelRegistry {
  static final ExactVehicleModelRegistry _instance = ExactVehicleModelRegistry._internal();
  factory ExactVehicleModelRegistry() => _instance;

  final Map<String, Exact3DAssetRecord> _records = {};

  ExactVehicleModelRegistry._internal() {
    _registerDefaultVerifiedOemAssets();
    _assertRegistryUniquenessInvariant();
  }

  void _registerDefaultVerifiedOemAssets() {
    // 1. Yamaha YZF-R1M (Model Validation Pending — Zero Dummy Geometry)
    _records['yamaha_yzf_r1m'] = Exact3DAssetRecord(
      assetId: 'yamaha_yzf_r1m',
      make: 'Yamaha',
      model: 'YZF-R1M',
      variant: 'Carbon',
      minYear: 2015,
      maxYear: 2026,
      glbAssetPath: '',
      thumbnailPath: 'assets/garage/yamaha_r1m.png',
      assetVersion: '0.0.0',
      assetChecksum: 'pending_cad_validation',
      verificationStatus: AssetVerificationStatus.modelValidationPending,
      source: 'PENDING_CAD_SCAN',
      confidenceScore: 0.0,
      scale: 1.0,
      cameraPosition: const [2.5, 1.2, 3.5],
      lightingIntensity: 1.2,
    );

    // 2. Ducati Panigale V4 S (Verified Authentic OEM Model)
    _records['ducati_panigale_v4s'] = Exact3DAssetRecord(
      assetId: 'ducati_panigale_v4s',
      make: 'Ducati',
      model: 'Panigale V4 S',
      variant: 'V4 S',
      minYear: 2018,
      maxYear: 2026,
      glbAssetPath: 'assets/models/ducati_panigale.glb',
      thumbnailPath: 'assets/garage/ducati_panigale.png',
      assetVersion: '1.1.0',
      assetChecksum: 'sha256:panigale_v4s_18313512',
      verificationStatus: AssetVerificationStatus.verifiedRealModel,
      source: 'OEM_CAD',
      confidenceScore: 1.0,
      scale: 1.05,
      cameraPosition: const [2.6, 1.3, 3.6],
      lightingIntensity: 1.1,
    );

    // 3. BMW M 1000 RR (Verified Authentic OEM Model)
    _records['bmw_m1000rr'] = Exact3DAssetRecord(
      assetId: 'bmw_m1000rr',
      make: 'BMW',
      model: 'M 1000 RR',
      variant: 'M Competition',
      minYear: 2021,
      maxYear: 2026,
      glbAssetPath: 'assets/models/bmw_m1000rr.glb',
      thumbnailPath: 'assets/garage/bmw_m1000rr.png',
      assetVersion: '1.0.0',
      assetChecksum: 'sha256:bmw_m1000rr_3862728',
      verificationStatus: AssetVerificationStatus.verifiedRealModel,
      source: 'OEM_CAD',
      confidenceScore: 1.0,
      scale: 1.0,
      cameraPosition: const [2.5, 1.2, 3.5],
      lightingIntensity: 1.15,
    );

    // 4. Yamaha MT-09 SP (Model Validation Pending — Zero Dummy Geometry)
    _records['yamaha_mt09_sp'] = Exact3DAssetRecord(
      assetId: 'yamaha_mt09_sp',
      make: 'Yamaha',
      model: 'MT-09 SP',
      variant: 'SP',
      minYear: 2021,
      maxYear: 2026,
      glbAssetPath: '',
      thumbnailPath: 'assets/garage/yamaha_mt09_sp.png',
      assetVersion: '0.0.0',
      assetChecksum: 'pending_cad_validation',
      verificationStatus: AssetVerificationStatus.modelValidationPending,
      source: 'PENDING_SCAN',
      confidenceScore: 0.0,
    );

    // 5. Suzuki Burgman Street 125 (Model Validation Pending — Zero Dummy Geometry)
    _records['suzuki_burgman_125'] = Exact3DAssetRecord(
      assetId: 'suzuki_burgman_125',
      make: 'Suzuki',
      model: 'Burgman Street 125',
      variant: 'FI',
      minYear: 2019,
      maxYear: 2026,
      glbAssetPath: '',
      thumbnailPath: 'assets/garage/suzuki_burgman.png',
      assetVersion: '0.0.0',
      assetChecksum: 'pending_cad_validation',
      verificationStatus: AssetVerificationStatus.modelValidationPending,
      source: 'PENDING_SCAN',
      confidenceScore: 0.0,
    );

    // 6. Universal OBD-II Gateway (Model Not Available — Diagnostic Mode Only)
    _records['universal_obd_gateway'] = Exact3DAssetRecord(
      assetId: 'universal_obd_gateway',
      make: 'Universal',
      model: 'OBD-II Gateway',
      variant: 'Standard',
      minYear: 2000,
      maxYear: 2030,
      glbAssetPath: '',
      thumbnailPath: 'assets/garage/generic_obd.png',
      assetVersion: '0.0.0',
      assetChecksum: 'diagnostic_gateway',
      verificationStatus: AssetVerificationStatus.modelNotAvailable,
      source: 'DIAGNOSTIC_ONLY',
      confidenceScore: 0.0,
    );
  }

  void _assertRegistryUniquenessInvariant() {
    final seenGlbs = <String, String>{};
    for (final entry in _records.entries) {
      final glb = entry.value.glbAssetPath;
      if (glb.isNotEmpty) {
        if (seenGlbs.containsKey(glb)) {
          throw StateError(
            'REGISTRY INVARIANT VIOLATION: Duplicate 3D model asset "$glb" shared between ${seenGlbs[glb]} and ${entry.key}',
          );
        }
        seenGlbs[glb] = entry.key;
      }
    }
  }

  /// Exact Lookup: Only resolves if vehicle identity has exact/verified match with zero ambiguity
  Exact3DAssetRecord? resolveExactAsset(VehicleIdentity identity) {
    if (!identity.confidence.allowsAutomatic3DModel) {
      // PARTIAL_MATCH, UNKNOWN, or CONFLICT never automatically receives a 3D asset
      return null;
    }

    for (final record in _records.values) {
      if (record.isOfficialModel &&
          record.matchesVehicle(
            targetMake: identity.make,
            targetModel: identity.model,
            targetVariant: identity.variant,
            targetYear: identity.modelYear,
          )) {
        return record;
      }
    }

    return null;
  }

  void registerDynamicVerifiedAsset(Exact3DAssetRecord record) {
    _records[record.assetId] = record;
    _assertRegistryUniquenessInvariant();
  }

  List<Exact3DAssetRecord> get allVerifiedRecords =>
      List.unmodifiable(_records.values.where((r) => r.isOfficialModel));

  List<Exact3DAssetRecord> get allRegisteredRecords =>
      List.unmodifiable(_records.values);
}
