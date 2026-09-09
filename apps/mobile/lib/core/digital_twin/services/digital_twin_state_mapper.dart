import '../domain/models.dart';
import '../../vehicle_resolution/models/active_vehicle_context.dart';

class DigitalTwinStateMapper {
  /// Maps canonical ActiveVehicleContext and NormalizedTelemetry into DigitalTwinState.
  /// Enforces UNKNOWN ≠ ZERO principle.
  static DigitalTwinState mapState(ActiveVehicleContext context) {
    if (context.telemetryQuality == TelemetryQuality.unavailable || 
        context.telemetryQuality == TelemetryQuality.invalid) {
      // If telemetry is fundamentally unavailable or stale beyond safe visualization,
      // return empty state (everything is null).
      return DigitalTwinState.unavailable();
    }

    final t = context.telemetry;

    return DigitalTwinState(
      speedKmh: t.speed.hasValue ? t.speed.value : null,
      rpm: t.rpm.hasValue ? t.rpm.value?.toDouble() : null,
      fuelPercent: t.fuelLevel.hasValue ? t.fuelLevel.value?.toDouble() : null,
      batteryPercent: t.batteryPercentage.hasValue ? t.batteryPercentage.value?.toDouble() : null,
      engineTempC: t.engineTemperature.hasValue ? t.engineTemperature.value?.toDouble() : null,
      isEngineRunning: t.engineState.hasValue ? t.engineState.value == 'RUNNING' : null,
      isCharging: t.chargingState.hasValue ? t.chargingState.value == 'CHARGING' : null,
      activeDiagnosticState: context.activeDtcCodes.isNotEmpty ? 'FAULT' : 'HEALTHY',
      maintenanceIndicator: null, // Hook into maintenance service if available
    );
  }
}
