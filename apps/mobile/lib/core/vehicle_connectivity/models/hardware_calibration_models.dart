import 'package:flutter/foundation.dart';

enum HardwareValidationMode {
  realDevice,
  simulator,
  offline,
  production;

  String get label {
    switch (this) {
      case HardwareValidationMode.realDevice:
        return 'REAL PHYSICAL HARDWARE (LIVE)';
      case HardwareValidationMode.simulator:
        return 'SIMULATED TEST BENCH';
      case HardwareValidationMode.offline:
        return 'OFFLINE CACHED TELEMETRY';
    }
  }
}

enum HardwareVerificationStatus {
  verified,
  partiallyVerified,
  unverified,
  unsupported;

  String get label {
    switch (this) {
      case HardwareVerificationStatus.verified:
        return 'VERIFIED ON PHYSICAL HARDWARE';
      case HardwareVerificationStatus.partiallyVerified:
        return 'PARTIALLY VERIFIED (GATEWAY TESTED)';
      case HardwareVerificationStatus.unverified:
        return 'UNVERIFIED (REQUIRES TEST BENCH)';
      case HardwareVerificationStatus.unsupported:
        return 'UNSUPPORTED VEHICLE PROTOCOL';
    }
  }
}

@immutable
class SignalCalibrationMetrics {
  final int rssi; // dBm
  final int latencyMs;
  final int jitterMs;
  final double notificationFrequencyHz;
  final int packetsReceived;
  final int packetsLost;
  final int malformedPacketsCount;

  const SignalCalibrationMetrics({
    this.rssi = -65,
    this.latencyMs = 25,
    this.jitterMs = 4,
    this.notificationFrequencyHz = 10.0,
    this.packetsReceived = 0,
    this.packetsLost = 0,
    this.malformedPacketsCount = 0,
  });

  double get packetLossPercentage {
    final total = packetsReceived + packetsLost;
    if (total == 0) return 0.0;
    return (packetsLost / total) * 100.0;
  }

  String get signalQualityLabel {
    if (rssi >= -60) return 'EXCELLENT';
    if (rssi >= -75) return 'GOOD';
    if (rssi >= -85) return 'FAIR';
    return 'WEAK / ATTENUATED';
  }
}

@immutable
class CalibratedTelemetrySnapshot {
  final double speedKmh;
  final double rpm;
  final double batteryVoltage;
  final double coolantTempCelsius;
  final double fuelPercent;
  final List<String> activeDtcCodes;
  final HardwareValidationMode validationMode;
  final HardwareVerificationStatus verificationStatus;
  final String sourceTag; // "LIVE", "SIMULATED", "HISTORICAL"
  final DateTime timestamp;
  final SignalCalibrationMetrics metrics;

  const CalibratedTelemetrySnapshot({
    required this.speedKmh,
    required this.rpm,
    required this.batteryVoltage,
    required this.coolantTempCelsius,
    required this.fuelPercent,
    this.activeDtcCodes = const [],
    required this.validationMode,
    required this.verificationStatus,
    required this.sourceTag,
    required this.timestamp,
    required this.metrics,
  });
}
