import '../models/vehicle_profile.dart';
import '../models/vehicle_identity.dart';
import '../services/model_generation_pipeline.dart';
import '../../vehicle_protocols/models/normalized_telemetry.dart';

enum VehicleConnectionStatus {
  connected,
  connecting,
  disconnected,
  unsupported,
  permissionRequired,
  error,
}

enum VehicleModelStatus {
  loading,
  ready,
  error,
  unavailable,
}

enum TelemetryQuality {
  live,
  stale,
  invalid,
  unavailable,
}

class ActiveVehicleContext {
  final String vehicleId;
  final VehicleProfile? profile;
  final VehicleIdentity? identity;
  final VehicleConnectionStatus connectionStatus;
  final VehicleModelStatus modelStatus;
  final ModelResolutionStatus modelResolutionStatus;
  final String model3DPath;
  final List<String> supportedCapabilities;
  final NormalizedTelemetry telemetry;
  final TelemetryQuality telemetryQuality;
  final List<String> activeDtcCodes;
  final String? activeTripId;
  final DateTime lastUpdated;

  const ActiveVehicleContext({
    required this.vehicleId,
    this.profile,
    this.identity,
    this.connectionStatus = VehicleConnectionStatus.disconnected,
    this.modelStatus = VehicleModelStatus.unavailable,
    this.modelResolutionStatus = ModelResolutionStatus.modelNotAvailable,
    this.model3DPath = '',
    this.supportedCapabilities = const [],
    required this.telemetry,
    this.telemetryQuality = TelemetryQuality.unavailable,
    this.activeDtcCodes = const [],
    this.activeTripId,
    required this.lastUpdated,
  });

  bool get hasActiveVehicle => (profile != null || identity != null) && vehicleId.isNotEmpty;
  bool get isConnected => connectionStatus == VehicleConnectionStatus.connected;
  bool get hasExact3DModel => modelStatus == VehicleModelStatus.ready && model3DPath.isNotEmpty;
  bool get isTelemetryLive => telemetryQuality == TelemetryQuality.live;
  String get vehicleName {
    if (profile != null) return '${profile!.manufacturer} ${profile!.model}';
    if (identity != null) return '${identity!.make} ${identity!.model}';
    return '';
  }

  factory ActiveVehicleContext.empty() {
    return ActiveVehicleContext(
      vehicleId: '',
      profile: null,
      identity: null,
      connectionStatus: VehicleConnectionStatus.disconnected,
      modelStatus: VehicleModelStatus.unavailable,
      modelResolutionStatus: ModelResolutionStatus.modelNotAvailable,
      model3DPath: '',
      supportedCapabilities: const [],
      telemetry: NormalizedTelemetry.empty(),
      telemetryQuality: TelemetryQuality.unavailable,
      activeDtcCodes: const [],
      activeTripId: null,
      lastUpdated: DateTime.now(),
    );
  }

  ActiveVehicleContext copyWith({
    String? vehicleId,
    VehicleProfile? profile,
    VehicleIdentity? identity,
    VehicleConnectionStatus? connectionStatus,
    VehicleModelStatus? modelStatus,
    ModelResolutionStatus? modelResolutionStatus,
    String? model3DPath,
    List<String>? supportedCapabilities,
    NormalizedTelemetry? telemetry,
    TelemetryQuality? telemetryQuality,
    List<String>? activeDtcCodes,
    String? activeTripId,
    DateTime? lastUpdated,
  }) {
    return ActiveVehicleContext(
      vehicleId: vehicleId ?? this.vehicleId,
      profile: profile ?? this.profile,
      identity: identity ?? this.identity,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      modelStatus: modelStatus ?? this.modelStatus,
      modelResolutionStatus: modelResolutionStatus ?? this.modelResolutionStatus,
      model3DPath: model3DPath ?? this.model3DPath,
      supportedCapabilities: supportedCapabilities ?? this.supportedCapabilities,
      telemetry: telemetry ?? this.telemetry,
      telemetryQuality: telemetryQuality ?? this.telemetryQuality,
      activeDtcCodes: activeDtcCodes ?? this.activeDtcCodes,
      activeTripId: activeTripId ?? this.activeTripId,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
