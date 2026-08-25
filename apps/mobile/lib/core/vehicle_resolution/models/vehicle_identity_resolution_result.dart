import 'vehicle_identity.dart';
import 'vehicle_profile.dart';
import '../services/vehicle_model_registry.dart';

class VehicleIdentityResolutionResult {
  final VehicleIdentity identity;
  final VehicleProfile? profile;
  final Vehicle3DConfig? model3DConfig;
  final String diagnosticLog;

  const VehicleIdentityResolutionResult({
    required this.identity,
    this.profile,
    this.model3DConfig,
    required this.diagnosticLog,
  });

  bool get isVerified => identity.confidence == IdentityConfidence.exactMatch;
  bool get isIdentified => identity.confidence == IdentityConfidence.verifiedMatch || identity.confidence == IdentityConfidence.exactMatch;
  bool get isUnknown => identity.confidence == IdentityConfidence.unknown || identity.confidence == IdentityConfidence.conflict;
  bool get isModelValidationPending => identity.confidence == IdentityConfidence.partialMatch || (isIdentified && !isVerified);
  bool get hasVerified3DModel => model3DConfig?.isVerified == true && (model3DConfig?.modelAssetPath.isNotEmpty == true);

  String get statusCategory => identity.confidence.statusCategory;
}
