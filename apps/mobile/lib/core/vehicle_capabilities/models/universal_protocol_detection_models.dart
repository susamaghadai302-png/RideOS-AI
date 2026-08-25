import 'package:flutter/foundation.dart';
import '../../vehicle_connectivity/models/packet_capture_models.dart';

enum VehicleClassificationType {
  motorcycleIce,
  scooterIce,
  motorcycleEv,
  scooterEv,
  hybrid;

  String get label {
    switch (this) {
      case VehicleClassificationType.motorcycleIce:
        return 'ICE Motorcycle';
      case VehicleClassificationType.scooterIce:
        return 'ICE Scooter';
      case VehicleClassificationType.motorcycleEv:
        return 'Electric Motorcycle';
      case VehicleClassificationType.scooterEv:
        return 'Electric Scooter';
      case VehicleClassificationType.hybrid:
        return 'Hybrid Two-Wheeler';
    }
  }
}

enum CompatibilityReportStatus {
  supported,
  partiallySupported,
  readOnlySupported,
  protocolNotVerified,
  unsupported;

  String get label {
    switch (this) {
      case CompatibilityReportStatus.supported:
        return 'SUPPORTED';
      case CompatibilityReportStatus.partiallySupported:
        return 'PARTIALLY SUPPORTED';
      case CompatibilityReportStatus.readOnlySupported:
        return 'READ-ONLY SUPPORTED';
      case CompatibilityReportStatus.protocolNotVerified:
        return 'DETECTED — PROTOCOL NOT VERIFIED';
      case CompatibilityReportStatus.unsupported:
        return 'NOT SUPPORTED';
    }
  }
}

@immutable
class ProfileVersionMetadata {
  final String vehicleProfileVersion;
  final String protocolVersion;
  final String capabilityVersion;
  final int supportedSinceYear;
  final int? deprecatedSinceYear;

  const ProfileVersionMetadata({
    this.vehicleProfileVersion = '3.0.0',
    this.protocolVersion = 'GATT_v2',
    this.capabilityVersion = '2026.1',
    this.supportedSinceYear = 2015,
    this.deprecatedSinceYear,
  });

  bool isSupportedYear(int year) {
    if (year < supportedSinceYear) return false;
    if (deprecatedSinceYear != null && year > deprecatedSinceYear!) return false;
    return true;
  }
}

@immutable
class DetailedCompatibilityBreakdown {
  final String manufacturer;
  final String modelName;
  final String variantTrim;
  final int modelYear;
  final VehicleClassificationType vehicleType;
  final String protocolName;
  final double confidenceScore; // 0.0 to 1.0
  final CompatibilityReportStatus overallStatus;
  final HardwareBenchVerificationStatus verificationStatus;
  final bool hasTurnByTurnNav;
  final bool hasSpeedTelemetry;
  final bool hasRpmTelemetry;
  final bool hasBatterySoc;
  final bool hasObdDiagnostics;
  final bool areActiveCommandsBlocked;
  final String statusExplanation;
  final ProfileVersionMetadata versionMetadata;

  const DetailedCompatibilityBreakdown({
    required this.manufacturer,
    required this.modelName,
    required this.variantTrim,
    required this.modelYear,
    required this.vehicleType,
    required this.protocolName,
    required this.confidenceScore,
    required this.overallStatus,
    required this.verificationStatus,
    required this.hasTurnByTurnNav,
    required this.hasSpeedTelemetry,
    required this.hasRpmTelemetry,
    required this.hasBatterySoc,
    required this.hasObdDiagnostics,
    this.areActiveCommandsBlocked = true,
    required this.statusExplanation,
    this.versionMetadata = const ProfileVersionMetadata(),
  });

  Map<String, dynamic> toJson() => {
    'vehicle': {
      'manufacturer': manufacturer,
      'model': modelName,
      'variant': variantTrim,
      'year': modelYear,
      'type': vehicleType.label,
    },
    'protocol': {
      'name': protocolName,
      'confidencePercent': (confidenceScore * 100).toInt(),
      'overallStatus': overallStatus.label,
      'verificationStatus': verificationStatus.label,
    },
    'capabilityMatrix': {
      'turnByTurnNav': hasTurnByTurnNav,
      'speedTelemetry': hasSpeedTelemetry,
      'rpmTelemetry': hasRpmTelemetry,
      'batterySoc': hasBatterySoc,
      'obdDiagnostics': hasObdDiagnostics,
      'activeCommandsBlocked': areActiveCommandsBlocked,
    },
    'explanation': statusExplanation,
    'versioning': {
      'profileVersion': versionMetadata.vehicleProfileVersion,
      'protocolVersion': versionMetadata.protocolVersion,
      'supportedSince': versionMetadata.supportedSinceYear,
    },
  };
}
