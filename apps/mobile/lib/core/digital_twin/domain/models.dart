import 'package:equatable/equatable.dart';

enum DigitalTwinFidelity {
  level1Exact3D('LEVEL_1_EXACT_3D', 'Verified Exact 3D', 1),
  level2Category3D('LEVEL_2_CATEGORY_3D', 'Category Generic 3D', 2),
  level3Procedural('LEVEL_3_PROCEDURAL', 'Procedural Vector Wireframe', 3),
  level42D('LEVEL_4_2D', '2D Orthographic Fallback', 4);

  final String code;
  final String description;
  final int level;
  
  const DigitalTwinFidelity(this.code, this.description, this.level);
}

enum DigitalTwinAssetVerification {
  verified('VERIFIED'),
  unverified('UNVERIFIED'),
  incompatible('INCOMPATIBLE'),
  missing('MISSING'),
  unavailable('UNAVAILABLE');

  final String code;
  const DigitalTwinAssetVerification(this.code);
}

class DigitalTwinAsset extends Equatable {
  final String assetId;
  final String path;
  final DigitalTwinFidelity fidelity;
  final DigitalTwinAssetVerification verificationStatus;
  final String provenance;
  
  const DigitalTwinAsset({
    required this.assetId,
    required this.path,
    required this.fidelity,
    required this.verificationStatus,
    required this.provenance,
  });

  @override
  List<Object?> get props => [assetId, path, fidelity, verificationStatus, provenance];
}

class DigitalTwinResolutionResult extends Equatable {
  final DigitalTwinFidelity fidelity;
  final DigitalTwinAsset? asset;
  final String reason;

  const DigitalTwinResolutionResult({
    required this.fidelity,
    this.asset,
    required this.reason,
  });

  @override
  List<Object?> get props => [fidelity, asset, reason];
}

class DigitalTwinState extends Equatable {
  final double? speedKmh;
  final double? rpm;
  final double? fuelPercent;
  final double? batteryPercent;
  final double? engineTempC;
  final bool? isEngineRunning;
  final bool? isCharging;
  final String? activeDiagnosticState;
  final String? maintenanceIndicator;

  // Additional states can be added for doors, lights, etc. if telemetry supports it.

  const DigitalTwinState({
    this.speedKmh,
    this.rpm,
    this.fuelPercent,
    this.batteryPercent,
    this.engineTempC,
    this.isEngineRunning,
    this.isCharging,
    this.activeDiagnosticState,
    this.maintenanceIndicator,
  });
  
  factory DigitalTwinState.unavailable() => const DigitalTwinState();

  @override
  List<Object?> get props => [
        speedKmh,
        rpm,
        fuelPercent,
        batteryPercent,
        engineTempC,
        isEngineRunning,
        isCharging,
        activeDiagnosticState,
        maintenanceIndicator,
      ];
}
