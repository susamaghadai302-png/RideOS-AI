import 'package:flutter/foundation.dart';
import '../../vehicle_connectivity/models/vehicle_capabilities.dart';
import '../../vehicle_connectivity/models/vehicle_variant_taxonomy.dart';
import '../../vehicle_catalog/models/vehicle_catalog_models.dart';

enum LabStep {
  selectVehicle,
  selectMethod,
  scanAndDiscover,
  protocolDetection,
  serviceDiscovery,
  capabilityDetection,
  connectionStressTest,
  verificationReport,
}

enum HardwareVerificationGrade {
  realHardwareVerified,
  automatedBenchVerified,
  requiresPhysicalHardware,
  unverifiedUnsupported,
}

@immutable
class DiscoveredGattCharacteristicInfo {
  final String uuid;
  final String name;
  final bool canRead;
  final bool canWrite;
  final bool canNotify;
  final bool isVerifiedProtocol;
  final String? decodedMetric;

  const DiscoveredGattCharacteristicInfo({
    required this.uuid,
    required this.name,
    required this.canRead,
    required this.canWrite,
    required this.canNotify,
    this.isVerifiedProtocol = false,
    this.decodedMetric,
  });
}

@immutable
class DiscoveredGattServiceInfo {
  final String uuid;
  final String serviceName;
  final List<DiscoveredGattCharacteristicInfo> characteristics;
  final bool isStandardService;

  const DiscoveredGattServiceInfo({
    required this.uuid,
    required this.serviceName,
    required this.characteristics,
    this.isStandardService = false,
  });
}

@immutable
class ConnectionQualityMetrics {
  final int signalStrengthRssi; // e.g. -55 dBm
  final double latencyMs; // e.g. 18.5 ms
  final double packetSuccessRatePct; // e.g. 99.4%
  final double stabilityScorePct; // 0 to 100
  final Duration reconnectTime; // e.g. 1.2s
  final int disconnectCount;
  final bool autoRecoveryVerified;

  const ConnectionQualityMetrics({
    required this.signalStrengthRssi,
    required this.latencyMs,
    required this.packetSuccessRatePct,
    required this.stabilityScorePct,
    required this.reconnectTime,
    required this.disconnectCount,
    required this.autoRecoveryVerified,
  });

  String get signalLabel {
    if (signalStrengthRssi > -60) return 'Excellent';
    if (signalStrengthRssi > -75) return 'Good';
    if (signalStrengthRssi > -85) return 'Fair';
    return 'Weak';
  }

  String get latencyLabel {
    if (latencyMs < 30) return 'Ultra Low (<30ms)';
    if (latencyMs < 75) return 'Optimal (<75ms)';
    return 'High Latency (>75ms)';
  }

  String get stabilityGrade {
    if (stabilityScorePct >= 95) return 'Rock Solid';
    if (stabilityScorePct >= 80) return 'Stable';
    return 'Unstable Link';
  }
}

@immutable
class CapabilityDetectionAuditItem {
  final String capabilityName;
  final String category;
  final CapabilitySupportLevel detectedLevel;
  final String dataSource; // LIVE, SIMULATED, OFFLINE, UNAVAILABLE
  final String technicalEvidence;
  final bool isVerified;

  const CapabilityDetectionAuditItem({
    required this.capabilityName,
    required this.category,
    required this.detectedLevel,
    required this.dataSource,
    required this.technicalEvidence,
    required this.isVerified,
  });
}

@immutable
class ProtocolVerificationReport {
  final String reportId;
  final String vehicleFullName;
  final String manufacturer;
  final String model;
  final String variant;
  final int modelYear;
  final VehicleConnectivityType connectionMethod;
  final String protocolAdapterId;
  final String detectedProtocolName;
  final VerificationSource verificationSource;
  final HardwareVerificationGrade verificationGrade;
  final VehicleCompatibilityLevel compatibilityTier;
  final int overallScorePercentage;
  final ConnectionQualityMetrics qualityMetrics;
  final List<DiscoveredGattServiceInfo> discoveredServices;
  final List<CapabilityDetectionAuditItem> capabilityAudits;
  final bool requiresExternalGateway;
  final String? gatewayRequiredDescription;
  final DateTime verifiedAt;
  final bool isSimulatedBenchDevice;

  const ProtocolVerificationReport({
    required this.reportId,
    required this.vehicleFullName,
    required this.manufacturer,
    required this.model,
    required this.variant,
    required this.modelYear,
    required this.connectionMethod,
    required this.protocolAdapterId,
    required this.detectedProtocolName,
    required this.verificationSource,
    required this.verificationGrade,
    required this.compatibilityTier,
    required this.overallScorePercentage,
    required this.qualityMetrics,
    required this.discoveredServices,
    required this.capabilityAudits,
    required this.requiresExternalGateway,
    this.gatewayRequiredDescription,
    required this.verifiedAt,
    this.isSimulatedBenchDevice = false,
  });

  Map<String, dynamic> toJson() => {
        'reportId': reportId,
        'vehicleFullName': vehicleFullName,
        'manufacturer': manufacturer,
        'model': model,
        'variant': variant,
        'modelYear': modelYear,
        'connectionMethod': connectionMethod.name,
        'protocolAdapterId': protocolAdapterId,
        'detectedProtocolName': detectedProtocolName,
        'verificationSource': verificationSource.name,
        'verificationGrade': verificationGrade.name,
        'compatibilityTier': compatibilityTier.name,
        'overallScorePercentage': overallScorePercentage,
        'requiresExternalGateway': requiresExternalGateway,
        'gatewayRequiredDescription': gatewayRequiredDescription,
        'verifiedAt': verifiedAt.toIso8601String(),
        'isSimulatedBenchDevice': isSimulatedBenchDevice,
      };
}
