import '../../vehicle_protocols/models/normalized_telemetry.dart';
import '../models/vehicle_command.dart';

class SafetyCheckResult {
  final bool isSafe;
  final String reason;

  const SafetyCheckResult.safe()
      : isSafe = true,
        reason = '';

  const SafetyCheckResult.blocked(this.reason) : isSafe = false;
}

class VehicleSafetyManager {
  static final VehicleSafetyManager _instance = VehicleSafetyManager._internal();
  factory VehicleSafetyManager() => _instance;
  VehicleSafetyManager._internal();

  /// Evaluates whether a command is safe to execute given the live telemetry state of the vehicle
  SafetyCheckResult evaluateCommandSafety(VehicleCommand command, NormalizedTelemetry? currentTelemetry) {
    final speed = currentTelemetry?.speed.available == true ? (currentTelemetry?.speed.value ?? 0.0) : 0.0;
    final isMoving = speed > 1.0;
    final engineRunning = currentTelemetry?.engineState.available == true && currentTelemetry?.engineState.value == 'RUNNING';

    // 1. Motion Lockouts: Critical operations prohibited while riding
    if (isMoving) {
      switch (command.type) {
        case VehicleCommandType.toggleLock:
          return SafetyCheckResult.blocked('Vehicle is in motion (${speed.toStringAsFixed(1)} km/h). Lock operations are prohibited for rider safety.');
        case VehicleCommandType.toggleAlarm:
          return const SafetyCheckResult.blocked('Vehicle is in motion. Alarm arming is prohibited.');
        case VehicleCommandType.startCharging:
        case VehicleCommandType.stopCharging:
          return const SafetyCheckResult.blocked('Vehicle is in motion. Charging controls are locked.');
        case VehicleCommandType.clearFaultCodes:
          return const SafetyCheckResult.blocked('Cannot clear diagnostic fault codes while vehicle is moving.');
        default:
          break;
      }
    }

    // 2. Engine Active Lockouts: Prohibit charging controls if engine is actively running
    if (engineRunning) {
      if (command.type == VehicleCommandType.startCharging) {
        return const SafetyCheckResult.blocked('Engine is running. Charging cannot be initiated.');
      }
    }

    // 3. Parameter Validation
    switch (command.type) {
      case VehicleCommandType.setRidingMode:
        final mode = command.parameter?.toString().toUpperCase();
        const validModes = ['ECO', 'RAIN', 'ROAD', 'SPORT', 'TRACK', 'TOURING', 'URBAN'];
        if (mode == null || !validModes.contains(mode)) {
          return SafetyCheckResult.blocked('Invalid riding mode "$mode". Allowed modes: ${validModes.join(', ')}');
        }
        break;
      default:
        break;
    }

    return const SafetyCheckResult.safe();
  }
}
