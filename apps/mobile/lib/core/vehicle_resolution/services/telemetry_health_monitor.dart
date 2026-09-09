import '../../vehicle_protocols/models/normalized_telemetry.dart';
import '../models/active_vehicle_context.dart';

enum TelemetryHealthState {
  healthy,
  degraded,
  stale,
  failed,
}

class TelemetryValidationResult {
  final bool isValid;
  final List<String> anomalies;

  const TelemetryValidationResult({
    required this.isValid,
    required this.anomalies,
  });
}

class TelemetryHealthMonitor {
  static final TelemetryHealthMonitor _instance = TelemetryHealthMonitor._internal();
  factory TelemetryHealthMonitor() => _instance;
  TelemetryHealthMonitor._internal();

  /// Validates physical telemetry ranges strictly against motorcycle physics
  TelemetryValidationResult validate(NormalizedTelemetry telemetry) {
    final anomalies = <String>[];

    // 1. Validate Speed (0 to 399 km/h)
    if (telemetry.speed.available && telemetry.speed.value != null) {
      final speed = telemetry.speed.value!;
      if (speed < 0.0 || speed > 400.0) {
        anomalies.add('Physical speed anomaly: ${speed.toStringAsFixed(1)} km/h out of range [0, 400]');
      }
    }

    // 2. Validate RPM (0 to 20,000 RPM)
    if (telemetry.rpm.available && telemetry.rpm.value != null) {
      final rpm = telemetry.rpm.value!;
      if (rpm < 0 || rpm > 22000) {
        anomalies.add('RPM anomaly: $rpm RPM out of range [0, 22000]');
      }
    }

    // 3. Validate 12V Battery Voltage (9.0V to 16.0V)
    if (telemetry.batteryVoltage.available && telemetry.batteryVoltage.value != null) {
      final voltage = telemetry.batteryVoltage.value!;
      if (voltage < 5.0 || voltage > 18.0) {
        anomalies.add('Voltage anomaly: ${voltage.toStringAsFixed(1)}V out of physical range [5.0, 18.0]');
      }
    }

    // 4. Validate Coolant Temp (-40C to 150C)
    if (telemetry.engineTemperature.available && telemetry.engineTemperature.value != null) {
      final temp = telemetry.engineTemperature.value!;
      if (temp < -40 || temp > 160) {
        anomalies.add('Temperature anomaly: $temp degC out of range [-40, 160]');
      }
    }

    return TelemetryValidationResult(
      isValid: anomalies.isEmpty,
      anomalies: anomalies,
    );
  }

  /// Evaluates overall health state from context
  TelemetryHealthState evaluate(ActiveVehicleContext context) {
    if (!context.isConnected) {
      return TelemetryHealthState.failed;
    }

    if (context.telemetryQuality == TelemetryQuality.stale) {
      return TelemetryHealthState.stale;
    }

    final validation = validate(context.telemetry);
    if (!validation.isValid) {
      return TelemetryHealthState.degraded;
    }

    if (context.telemetryQuality == TelemetryQuality.live) {
      return TelemetryHealthState.healthy;
    }

    return TelemetryHealthState.degraded;
  }
}
