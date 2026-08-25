import '../../vehicle_capabilities/models/vehicle_capabilities.dart';

enum VehicleCommandType {
  toggleHeadlight,
  setHighBeam,
  triggerLeftIndicator,
  triggerRightIndicator,
  triggerHazard,
  setRidingMode,
  triggerHorn,
  toggleLock,
  toggleAlarm,
  startCharging,
  stopCharging,
  clearFaultCodes;

  ControlCapability get requiredCapability {
    switch (this) {
      case VehicleCommandType.toggleHeadlight:
        return ControlCapability.controlLights;
      case VehicleCommandType.setHighBeam:
        return ControlCapability.controlHighBeam;
      case VehicleCommandType.triggerLeftIndicator:
        return ControlCapability.controlLeftIndicator;
      case VehicleCommandType.triggerRightIndicator:
        return ControlCapability.controlRightIndicator;
      case VehicleCommandType.triggerHazard:
        return ControlCapability.controlHazard;
      case VehicleCommandType.setRidingMode:
        return ControlCapability.controlRidingMode;
      case VehicleCommandType.triggerHorn:
        return ControlCapability.controlHorn;
      case VehicleCommandType.toggleLock:
        return ControlCapability.controlLock;
      case VehicleCommandType.toggleAlarm:
        return ControlCapability.controlAlarm;
      case VehicleCommandType.startCharging:
      case VehicleCommandType.stopCharging:
        return ControlCapability.controlCharging;
      case VehicleCommandType.clearFaultCodes:
        return ControlCapability.clearFaultCodes;
    }
  }
}

class VehicleCommand {
  final String id;
  final VehicleCommandType type;
  final dynamic parameter;
  final DateTime timestamp;
  final Duration timeout;

  VehicleCommand({
    String? id,
    required this.type,
    this.parameter,
    DateTime? timestamp,
    this.timeout = const Duration(milliseconds: 3000),
  })  : id = id ?? 'cmd_${DateTime.now().microsecondsSinceEpoch}',
        timestamp = timestamp ?? DateTime.now();

  ControlCapability get requiredCapability => type.requiredCapability;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'parameter': parameter,
    'timestamp': timestamp.toIso8601String(),
    'timeoutMs': timeout.inMilliseconds,
  };
}
