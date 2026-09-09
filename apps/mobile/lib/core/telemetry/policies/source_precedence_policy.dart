import 'package:flutter/foundation.dart';
import '../models/metric_types.dart';
import '../../diagnostics/models/diagnostic_types.dart';

/// Precedence and arbitration policy when a single telemetry metric can originate
/// from multiple ECUs on the vehicle network.
@immutable
class SourcePrecedencePolicy {
  /// Priority list of ECU modules per metric ID (first in list has highest priority).
  final Map<TelemetryMetricId, List<EcuModule>> precedenceRules;

  const SourcePrecedencePolicy({
    this.precedenceRules = const {
      // Vehicle speed: ABS high-resolution wheel pulse > ECM powertrain speed > Cluster
      TelemetryMetricId.vehicleSpeed: [
        EcuModule.antiLockBraking_ABS,
        EcuModule.engineControlModule_ECM,
        EcuModule.instrumentCluster_IPC,
      ],
      // Engine RPM: ECM > Quickshifter TCU
      TelemetryMetricId.engineRpm: [
        EcuModule.engineControlModule_ECM,
        EcuModule.transmissionControlUnit_TCU,
      ],
      // Battery / System Voltage: Battery Management BMS > ECM > Body Controller BCM
      TelemetryMetricId.batteryVoltage: [
        EcuModule.batteryManagementSystem_BMS,
        EcuModule.engineControlModule_ECM,
        EcuModule.bodyControlModule_BCM,
      ],
      // Throttle: ECM
      TelemetryMetricId.throttlePosition: [
        EcuModule.engineControlModule_ECM,
      ],
      // Coolant: ECM
      TelemetryMetricId.coolantTemperature: [
        EcuModule.engineControlModule_ECM,
      ],
    },
  });

  /// Standard production source precedence policy.
  static const SourcePrecedencePolicy standard = SourcePrecedencePolicy();

  /// Resolves whether a candidate measurement from [candidateEcu] should override
  /// an existing live measurement from [currentEcu] for the specified [metricId].
  bool shouldOverride(
    TelemetryMetricId metricId,
    EcuModule currentEcu,
    EcuModule candidateEcu,
  ) {
    if (currentEcu == candidateEcu) return true;

    final rule = precedenceRules[metricId];
    if (rule == null || rule.isEmpty) {
      // No explicit precedence rule: allow update
      return true;
    }

    final currentRank = rule.indexOf(currentEcu);
    final candidateRank = rule.indexOf(candidateEcu);

    // If candidate is ranked and current is unranked -> candidate wins
    if (candidateRank != -1 && currentRank == -1) return true;

    // If current is ranked and candidate is unranked -> current keeps precedence
    if (currentRank != -1 && candidateRank == -1) return false;

    // Both ranked: lower index = higher priority
    return candidateRank <= currentRank;
  }
}
