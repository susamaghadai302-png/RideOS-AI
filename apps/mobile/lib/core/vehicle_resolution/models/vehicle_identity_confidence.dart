import 'vehicle_profile.dart';

enum IdentityConfidenceLevel {
  exactMatch('EXACT_MATCH', 1.0, 'Exact OEM & Model Match Verified'),
  knownModel('KNOWN_MODEL', 0.85, 'Known Model Family Identified'),
  userConfirmed('USER_CONFIRMED', 0.95, 'Identity Confirmed by Rider'),
  scanRequired('SCAN_REQUIRED', 0.40, 'Vehicle Detected but 3D Scan Required'),
  unknown('UNKNOWN', 0.10, 'Unrecognized Vehicle Signature');

  final String code;
  final double score;
  final String label;
  const IdentityConfidenceLevel(this.code, this.score, this.label);

  static IdentityConfidenceLevel fromScore(double score) {
    if (score >= 0.98) return IdentityConfidenceLevel.exactMatch;
    if (score >= 0.80) return IdentityConfidenceLevel.knownModel;
    if (score >= 0.60) return IdentityConfidenceLevel.userConfirmed;
    if (score >= 0.30) return IdentityConfidenceLevel.scanRequired;
    return IdentityConfidenceLevel.unknown;
  }
}

class VehicleIdentityResult {
  final IdentityConfidenceLevel confidenceLevel;
  final double confidenceScore;
  final String manufacturer;
  final String model;
  final String variant;
  final int year;
  final String? vin;
  final String? ecuCalibrationId;
  final String detectionSource; // 'BLE_ADVERT', 'OBD_PID', 'ECU_QUERY', 'MANUAL_SELECTION'
  final VehicleProfile? matchedProfile;
  final bool hasExact3DModel;
  final bool hasSavedDigitalTwin;
  final String? existingDigitalTwinId;

  const VehicleIdentityResult({
    required this.confidenceLevel,
    required this.confidenceScore,
    required this.manufacturer,
    required this.model,
    this.variant = '',
    required this.year,
    this.vin,
    this.ecuCalibrationId,
    required this.detectionSource,
    this.matchedProfile,
    this.hasExact3DModel = false,
    this.hasSavedDigitalTwin = false,
    this.existingDigitalTwinId,
  });

  bool get requiresScan => !hasExact3DModel && !hasSavedDigitalTwin;
  bool get isConfident => confidenceScore >= 0.80;

  Map<String, dynamic> toJson() => {
    'confidenceLevel': confidenceLevel.code,
    'confidenceScore': confidenceScore,
    'manufacturer': manufacturer,
    'model': model,
    'variant': variant,
    'year': year,
    'vin': vin,
    'ecuCalibrationId': ecuCalibrationId,
    'detectionSource': detectionSource,
    'hasExact3DModel': hasExact3DModel,
    'hasSavedDigitalTwin': hasSavedDigitalTwin,
    'existingDigitalTwinId': existingDigitalTwinId,
  };
}
