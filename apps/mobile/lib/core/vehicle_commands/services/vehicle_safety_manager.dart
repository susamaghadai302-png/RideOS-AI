import '../../contracts/safety_classification_registry.dart';
import '../../contracts/safety_context_bridge.dart';
import '../../contracts/safety_interlock.dart';
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

/// Hardened Vehicle Safety Manager (ADR-16).
///
/// Delegates to the canonical [MotionSafetyInterlock] for fail-closed
/// motion-based safety evaluation.
///
/// CRITICAL FIX (Tier 2): The previous implementation treated null/missing
/// telemetry as speed=0.0 (safe), which was a **fail-open bug**. The hardened
/// version defaults to BLOCK when telemetry is missing, stale, or invalid.
///
/// Preserves the existing [SafetyCheckResult] API so [VehicleCommandPipeline]
/// requires zero changes.
class VehicleSafetyManager {
  static final VehicleSafetyManager _instance = VehicleSafetyManager._internal();
  factory VehicleSafetyManager() => _instance;
  VehicleSafetyManager._internal();

  /// The canonical safety interlock instance.
  final SafetyInterlock _interlock = const MotionSafetyInterlock();

  /// Evaluates whether a command is safe to execute given the live telemetry state of the vehicle.
  ///
  /// Fail-closed policy: if telemetry is null, unavailable, stale, invalid,
  /// or the vehicle is disconnected, safety-sensitive commands are BLOCKED.
  SafetyCheckResult evaluateCommandSafety(VehicleCommand command, NormalizedTelemetry? currentTelemetry) {
    // 1. Determine safety classification from canonical registry
    final classification = classifyCommand(command.type);

    // 2. Determine connection state from telemetry availability
    final isConnected = currentTelemetry != null;

    // 3. Build canonical safety context via bridge
    final context = SafetyContextBridge.fromNormalizedTelemetry(
      currentTelemetry,
      commandClassification: classification,
      isVehicleConnected: isConnected,
    );

    // 4. Evaluate through canonical interlock (fail-closed)
    final verdict = _interlock.evaluate(context);

    // 5. If interlock blocked, return immediately
    if (verdict.isBlocked) {
      return SafetyCheckResult.blocked(verdict.reason);
    }

    // 6. Additional non-motion safety checks (engine state, parameter validation)
    //    These are NOT motion-based and are supplementary to the interlock.
    final engineRunning = currentTelemetry?.engineState.available == true &&
        currentTelemetry?.engineState.value == 'RUNNING';

    // Engine Active Lockouts: Prohibit charging controls if engine is actively running
    if (engineRunning) {
      if (command.type == VehicleCommandType.startCharging) {
        return const SafetyCheckResult.blocked('Engine is running. Charging cannot be initiated.');
      }
    }

    // Parameter Validation for conditionally safe commands
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
