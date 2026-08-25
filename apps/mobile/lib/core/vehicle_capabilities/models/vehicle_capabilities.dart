enum TelemetryCapability {
  speed,
  rpm,
  engineTemperature,
  coolantTemperature,
  ambientTemperature,
  batteryPercentage,
  batteryVoltage,
  fuelLevel,
  throttlePosition,
  odometer,
  tripDistance,
  gear,
  leanAngle,
  pitch,
  roll,
  heading,
  wheelSpeed,
  engineState,
  ignitionState,
  brakeState,
  indicatorLeft,
  indicatorRight,
  headlight,
  abs,
  tractionControl,
  ridingMode,
  chargingState,
  gps,
  deviceVoltage,
  faultCodes,
  connectionQuality;

  static TelemetryCapability? fromString(String key) {
    final clean = key.trim().toLowerCase().replaceAll('_', '');
    for (final cap in TelemetryCapability.values) {
      if (cap.name.toLowerCase() == clean) {
        return cap;
      }
    }
    return null;
  }
}

enum ControlCapability {
  controlLights,
  controlHighBeam,
  controlLeftIndicator,
  controlRightIndicator,
  controlHazard,
  controlRidingMode,
  controlHorn,
  controlLock,
  controlAlarm,
  controlCharging,
  clearFaultCodes;

  static ControlCapability? fromString(String key) {
    final clean = key.trim().toLowerCase().replaceAll('_', '');
    for (final cap in ControlCapability.values) {
      if (cap.name.toLowerCase() == clean) {
        return cap;
      }
    }
    return null;
  }
}

class VehicleCapabilities {
  final Set<TelemetryCapability> supportedTelemetry;
  final Set<ControlCapability> supportedControls;
  final bool requiresAuthentication;
  final bool supportsStateAcknowledgement;

  const VehicleCapabilities({
    this.supportedTelemetry = const {},
    this.supportedControls = const {},
    this.requiresAuthentication = false,
    this.supportsStateAcknowledgement = true,
  });

  bool hasTelemetry(TelemetryCapability capability) => supportedTelemetry.contains(capability);
  bool hasControl(ControlCapability capability) => supportedControls.contains(capability);

  factory VehicleCapabilities.empty() {
    return const VehicleCapabilities(
      supportedTelemetry: {},
      supportedControls: {},
    );
  }

  factory VehicleCapabilities.fromAdapter({
    required List<String> features,
    bool requiresAuth = false,
    bool supportsAck = true,
  }) {
    final Set<TelemetryCapability> telemetry = {};
    final Set<ControlCapability> controls = {};

    for (final feature in features) {
      final tCap = TelemetryCapability.fromString(feature);
      if (tCap != null) {
        telemetry.add(tCap);
      }
      final cCap = ControlCapability.fromString(feature);
      if (cCap != null) {
        controls.add(cCap);
      }
    }

    return VehicleCapabilities(
      supportedTelemetry: telemetry,
      supportedControls: controls,
      requiresAuthentication: requiresAuth,
      supportsStateAcknowledgement: supportsAck,
    );
  }

  Map<String, dynamic> toJson() => {
    'supportedTelemetry': supportedTelemetry.map((e) => e.name).toList(),
    'supportedControls': supportedControls.map((e) => e.name).toList(),
    'requiresAuthentication': requiresAuthentication,
    'supportsStateAcknowledgement': supportsStateAcknowledgement,
  };

  factory VehicleCapabilities.fromJson(Map<String, dynamic> json) {
    final tList = (json['supportedTelemetry'] as List<dynamic>? ?? [])
        .map((e) => TelemetryCapability.fromString(e.toString()))
        .whereType<TelemetryCapability>()
        .toSet();

    final cList = (json['supportedControls'] as List<dynamic>? ?? [])
        .map((e) => ControlCapability.fromString(e.toString()))
        .whereType<ControlCapability>()
        .toSet();

    return VehicleCapabilities(
      supportedTelemetry: tList,
      supportedControls: cList,
      requiresAuthentication: json['requiresAuthentication'] ?? false,
      supportsStateAcknowledgement: json['supportsStateAcknowledgement'] ?? true,
    );
  }
}
