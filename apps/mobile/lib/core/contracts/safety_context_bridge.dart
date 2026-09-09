/// Safety Context Bridge (ADR-16 / Tier 2).
///
/// Provides factory methods to construct a [VehicleSafetyContext] from
/// either of the two existing telemetry models in the codebase:
///
/// 1. [NormalizedTelemetry] — used by `VehicleCommandPipeline` and `BluetoothEngine`.
/// 2. [NormalizedTelemetrySnapshot] — used by Tier 1 `VehicleDataGateway`.
///
/// This ensures both telemetry data paths converge to the same safety
/// decision through a single evaluation contract, without requiring
/// either model to be replaced or modified.
///
/// Platform-independent: No Flutter, Android, iOS, BLE, or OBD SDK imports.
library;

import '../device_providers/interfaces/device_provider.dart';
import '../device_providers/models/normalized_telemetry_models.dart';
import '../vehicle_protocols/models/normalized_telemetry.dart';
import 'safety_interlock.dart';

/// Factory methods for constructing [VehicleSafetyContext].
///
/// These are pure mappers with no side effects.
class SafetyContextBridge {
  SafetyContextBridge._(); // Prevent instantiation

  // ─── From NormalizedTelemetry (existing VehicleCommandPipeline path) ───

  /// Constructs a [VehicleSafetyContext] from the existing
  /// [NormalizedTelemetry] model used by `VehicleSafetyManager`
  /// and `VehicleCommandPipeline`.
  ///
  /// Fail-closed mapping:
  /// - `null` telemetry → `SpeedTrustLevel.unavailable`
  /// - `speed.available == false` → `SpeedTrustLevel.unavailable`
  /// - `speed.isStale` → `SpeedTrustLevel.stale`
  /// - `speed.value == null` → `SpeedTrustLevel.unavailable`
  /// - `speed.value.isNaN || < 0 || > 500` → `SpeedTrustLevel.invalid`
  /// - otherwise → `SpeedTrustLevel.trusted`
  static VehicleSafetyContext fromNormalizedTelemetry(
    NormalizedTelemetry? telemetry, {
    required SafetyClassification commandClassification,
    required bool isVehicleConnected,
  }) {
    if (telemetry == null) {
      return VehicleSafetyContext(
        speedKmh: null,
        speedTrust: isVehicleConnected
            ? SpeedTrustLevel.unavailable
            : SpeedTrustLevel.disconnected,
        isVehicleConnected: isVehicleConnected,
        commandClassification: commandClassification,
      );
    }

    final speedValue = telemetry.speed;

    // Speed unavailable from source
    if (!speedValue.available || speedValue.value == null) {
      return VehicleSafetyContext(
        speedKmh: null,
        speedTrust: SpeedTrustLevel.unavailable,
        isVehicleConnected: isVehicleConnected,
        commandClassification: commandClassification,
        speedAgeMs: speedValue.available ? speedValue.latencyMs : null,
        speedSource: speedValue.source,
      );
    }

    // Speed stale check (reuses existing 3-second threshold from TelemetryValue)
    if (speedValue.isStale || speedValue.quality == 'stale' || speedValue.quality == 'degraded') {
      return VehicleSafetyContext(
        speedKmh: speedValue.value,
        speedTrust: SpeedTrustLevel.stale,
        isVehicleConnected: isVehicleConnected,
        commandClassification: commandClassification,
        speedAgeMs: speedValue.latencyMs,
        speedSource: speedValue.source,
      );
    }

    // Speed validity check
    if (speedValue.value!.isNaN ||
        speedValue.value!.isInfinite ||
        speedValue.value! < 0.0 ||
        speedValue.value! > MotionSafetyInterlock.maxValidSpeedKmh) {
      return VehicleSafetyContext(
        speedKmh: speedValue.value,
        speedTrust: SpeedTrustLevel.invalid,
        isVehicleConnected: isVehicleConnected,
        commandClassification: commandClassification,
        speedAgeMs: speedValue.latencyMs,
        speedSource: speedValue.source,
      );
    }

    // Speed is trusted
    return VehicleSafetyContext(
      speedKmh: speedValue.value,
      speedTrust: SpeedTrustLevel.trusted,
      isVehicleConnected: isVehicleConnected,
      commandClassification: commandClassification,
      speedAgeMs: speedValue.latencyMs,
      speedSource: speedValue.source,
    );
  }

  // ─── From NormalizedTelemetrySnapshot (Tier 1 VehicleDataGateway path) ──

  /// Constructs a [VehicleSafetyContext] from the Tier 1
  /// [NormalizedTelemetrySnapshot] model used by `VehicleDataGateway`.
  ///
  /// Uses the `TelemetryMetric<double>.confidence` and
  /// `TelemetryMetric<double>.isAvailable` provenance.
  static VehicleSafetyContext fromTelemetrySnapshot(
    NormalizedTelemetrySnapshot? snapshot, {
    required SafetyClassification commandClassification,
    DeviceLinkState? linkState,
  }) {
    final isConnected = linkState == DeviceLinkState.connected;

    if (snapshot == null) {
      return VehicleSafetyContext(
        speedKmh: null,
        speedTrust: isConnected
            ? SpeedTrustLevel.unavailable
            : SpeedTrustLevel.disconnected,
        isVehicleConnected: isConnected,
        commandClassification: commandClassification,
      );
    }

    final speedMetric = snapshot.vehicleSpeedKmh;

    // Speed unavailable
    if (!speedMetric.isAvailable || speedMetric.value == null) {
      return VehicleSafetyContext(
        speedKmh: null,
        speedTrust: SpeedTrustLevel.unavailable,
        isVehicleConnected: isConnected,
        commandClassification: commandClassification,
      );
    }

    // Confidence check → stale or unsupported
    if (speedMetric.confidence == MetricConfidence.stale ||
        speedMetric.confidence == MetricConfidence.unsupported) {
      return VehicleSafetyContext(
        speedKmh: speedMetric.value,
        speedTrust: SpeedTrustLevel.stale,
        isVehicleConnected: isConnected,
        commandClassification: commandClassification,
        speedSource: snapshot.dataSource.label,
      );
    }

    // Freshness check on timestamp
    final ageMs = DateTime.now().difference(speedMetric.timestamp).inMilliseconds;
    if (ageMs > MotionSafetyInterlock.freshnessThresholdMs) {
      return VehicleSafetyContext(
        speedKmh: speedMetric.value,
        speedTrust: SpeedTrustLevel.stale,
        isVehicleConnected: isConnected,
        commandClassification: commandClassification,
        speedAgeMs: ageMs,
        speedSource: snapshot.dataSource.label,
      );
    }

    // Validity check
    if (speedMetric.value!.isNaN ||
        speedMetric.value!.isInfinite ||
        speedMetric.value! < 0.0 ||
        speedMetric.value! > MotionSafetyInterlock.maxValidSpeedKmh) {
      return VehicleSafetyContext(
        speedKmh: speedMetric.value,
        speedTrust: SpeedTrustLevel.invalid,
        isVehicleConnected: isConnected,
        commandClassification: commandClassification,
        speedSource: snapshot.dataSource.label,
      );
    }

    // Trusted
    return VehicleSafetyContext(
      speedKmh: speedMetric.value,
      speedTrust: SpeedTrustLevel.trusted,
      isVehicleConnected: isConnected,
      commandClassification: commandClassification,
      speedAgeMs: ageMs,
      speedSource: snapshot.dataSource.label,
    );
  }
}
