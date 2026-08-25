import '../models/active_vehicle_context.dart';

enum VisualAnimationMode {
  idle,
  connected,
  activeRide,
  warning,
}

class VisualAnimationState {
  final VisualAnimationMode mode;
  final double leanAngleDeg;
  final double rpmNormalized;
  final double speedKmh;
  final bool isEngineRunning;

  const VisualAnimationState({
    required this.mode,
    this.leanAngleDeg = 0.0,
    this.rpmNormalized = 0.0,
    this.speedKmh = 0.0,
    this.isEngineRunning = false,
  });
}

class VehicleAnimationController {
  static final VehicleAnimationController _instance = VehicleAnimationController._internal();
  factory VehicleAnimationController() => _instance;
  VehicleAnimationController._internal();

  /// Translates verified vehicle telemetry into realistic, non-exaggerated visual animation state
  VisualAnimationState computeVisualState(ActiveVehicleContext context) {
    if (!context.hasActiveVehicle || !context.isConnected) {
      return const VisualAnimationState(mode: VisualAnimationMode.idle);
    }

    if (context.activeDtcCodes.isNotEmpty) {
      return const VisualAnimationState(mode: VisualAnimationMode.warning);
    }

    final speed = context.telemetry.speed.value ?? 0.0;
    final rpm = context.telemetry.rpm.value ?? 0.0;
    final lean = context.telemetry.leanAngle.value ?? 0.0;
    final isRunning = rpm > 500.0;

    final normalizedRpm = (rpm / 14000.0).clamp(0.0, 1.0);

    if (speed > 5.0 || context.activeTripId != null) {
      return VisualAnimationState(
        mode: VisualAnimationMode.activeRide,
        leanAngleDeg: lean.clamp(-55.0, 55.0),
        rpmNormalized: normalizedRpm,
        speedKmh: speed,
        isEngineRunning: isRunning,
      );
    }

    return VisualAnimationState(
      mode: VisualAnimationMode.connected,
      rpmNormalized: normalizedRpm,
      speedKmh: 0.0,
      isEngineRunning: isRunning,
    );
  }
}
