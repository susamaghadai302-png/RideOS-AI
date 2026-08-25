import 'package:flutter/foundation.dart';

enum TelemetryFreshnessState {
  live,
  stale,
  offline,
  historical,
  predicted,
  simulated,
  unsupported,
  unavailable,
}

@immutable
class TelemetryMetric<T> {
  final T? value;
  final String unit;
  final DateTime timestamp;
  final TelemetryFreshnessState state;
  final double qualityScore; // 0.0 to 1.0
  final bool isSupported;
  final String? diagnosticNote;

  const TelemetryMetric({
    this.value,
    required this.unit,
    required this.timestamp,
    required this.state,
    this.qualityScore = 1.0,
    this.isSupported = true,
    this.diagnosticNote,
  });

  const TelemetryMetric.unsupported({
    required this.unit,
    this.diagnosticNote = 'Sensor / metric not exposed by vehicle hardware',
  })  : value = null,
        timestamp = const _StaticEpochDateTime(),
        state = TelemetryFreshnessState.unsupported,
        qualityScore = 0.0,
        isSupported = false;

  const TelemetryMetric.unavailable({
    required this.unit,
    this.diagnosticNote = 'Telemetry stream temporarily disconnected',
  })  : value = null,
        timestamp = const _StaticEpochDateTime(),
        state = TelemetryFreshnessState.unavailable,
        qualityScore = 0.0,
        isSupported = true;

  bool get hasValidLiveValue => isSupported && value != null && state == TelemetryFreshnessState.live;

  String get formattedValue {
    if (!isSupported) return 'N/A';
    if (state == TelemetryFreshnessState.unavailable || value == null) return '—';
    if (value is double) {
      return (value as double).toStringAsFixed(1);
    }
    return value.toString();
  }

  String get formattedWithUnit {
    if (!isSupported) return 'Unsupported';
    if (state == TelemetryFreshnessState.unavailable || value == null) return 'Unavailable';
    return '$formattedValue $unit'.trim();
  }

  Duration get age => DateTime.now().difference(timestamp);
  bool get isStale => age > const Duration(milliseconds: 2500);

  TelemetryMetric<T> copyWithFreshness(TelemetryFreshnessState newState) {
    return TelemetryMetric<T>(
      value: value,
      unit: unit,
      timestamp: timestamp,
      state: newState,
      qualityScore: qualityScore,
      isSupported: isSupported,
      diagnosticNote: diagnosticNote,
    );
  }
}

class _StaticEpochDateTime implements DateTime {
  const _StaticEpochDateTime();

  @override
  int get year => 1970;
  @override
  int get month => 1;
  @override
  int get day => 1;
  @override
  int get hour => 0;
  @override
  int get minute => 0;
  @override
  int get second => 0;
  @override
  int get millisecond => 0;
  @override
  int get microsecond => 0;
  @override
  int get weekday => 4;
  @override
  int get millisecondsSinceEpoch => 0;
  @override
  int get microsecondsSinceEpoch => 0;
  @override
  String get timeZoneName => 'UTC';
  @override
  Duration get timeZoneOffset => Duration.zero;
  @override
  bool get isUtc => true;

  @override
  DateTime add(Duration duration) => DateTime.fromMillisecondsSinceEpoch(0).add(duration);
  @override
  DateTime subtract(Duration duration) => DateTime.fromMillisecondsSinceEpoch(0).subtract(duration);
  @override
  Duration difference(DateTime other) => DateTime.fromMillisecondsSinceEpoch(0).difference(other);
  @override
  int compareTo(DateTime other) => DateTime.fromMillisecondsSinceEpoch(0).compareTo(other);
  @override
  bool isAfter(DateTime other) => DateTime.fromMillisecondsSinceEpoch(0).isAfter(other);
  @override
  bool isBefore(DateTime other) => DateTime.fromMillisecondsSinceEpoch(0).isBefore(other);
  @override
  bool isAtSameMomentAs(DateTime other) => DateTime.fromMillisecondsSinceEpoch(0).isAtSameMomentAs(other);
  @override
  String toIso8601String() => '1970-01-01T00:00:00.000Z';
  @override
  DateTime toLocal() => DateTime.fromMillisecondsSinceEpoch(0).toLocal();
  @override
  DateTime toUtc() => this;
}

@immutable
class LiveVehicleCockpitSnapshot {
  final DateTime timestamp;
  final TelemetryMetric<double> speedKmh;
  final TelemetryMetric<double> rpm;
  final TelemetryMetric<double> fuelLevelPct;
  final TelemetryMetric<double> stateOfChargePct;
  final TelemetryMetric<double> batteryVoltage;
  final TelemetryMetric<double> engineTempC;
  final TelemetryMetric<double> motorTempC;
  final TelemetryMetric<double> odometerKm;
  final TelemetryMetric<double> tripDistanceKm;
  final TelemetryMetric<int> currentGear;
  final TelemetryMetric<String> rideMode;
  final TelemetryMetric<bool> absStatus;
  final TelemetryMetric<bool> tractionControl;
  final TelemetryMetric<List<String>> activeDtcCodes;
  final TelemetryMetric<double> estimatedRangeKm;
  final bool isVehicleConnected;
  final bool isOfflineMode;

  const LiveVehicleCockpitSnapshot({
    required this.timestamp,
    required this.speedKmh,
    required this.rpm,
    required this.fuelLevelPct,
    required this.stateOfChargePct,
    required this.batteryVoltage,
    required this.engineTempC,
    required this.motorTempC,
    required this.odometerKm,
    required this.tripDistanceKm,
    required this.currentGear,
    required this.rideMode,
    required this.absStatus,
    required this.tractionControl,
    required this.activeDtcCodes,
    required this.estimatedRangeKm,
    required this.isVehicleConnected,
    required this.isOfflineMode,
  });

  factory LiveVehicleCockpitSnapshot.initialDisconnected({bool isOffline = false}) {
    return LiveVehicleCockpitSnapshot(
      timestamp: DateTime.now(),
      speedKmh: const TelemetryMetric.unavailable(unit: 'km/h'),
      rpm: const TelemetryMetric.unavailable(unit: 'RPM'),
      fuelLevelPct: const TelemetryMetric.unavailable(unit: '%'),
      stateOfChargePct: const TelemetryMetric.unavailable(unit: '%'),
      batteryVoltage: const TelemetryMetric.unavailable(unit: 'V'),
      engineTempC: const TelemetryMetric.unavailable(unit: ' degC'),
      motorTempC: const TelemetryMetric.unavailable(unit: ' degC'),
      odometerKm: const TelemetryMetric.unavailable(unit: 'km'),
      tripDistanceKm: const TelemetryMetric.unavailable(unit: 'km'),
      currentGear: const TelemetryMetric.unavailable(unit: 'Gear'),
      rideMode: const TelemetryMetric.unavailable(unit: 'Mode'),
      absStatus: const TelemetryMetric.unavailable(unit: 'ABS'),
      tractionControl: const TelemetryMetric.unavailable(unit: 'TCS'),
      activeDtcCodes: const TelemetryMetric.unavailable(unit: 'DTC'),
      estimatedRangeKm: const TelemetryMetric.unavailable(unit: 'km'),
      isVehicleConnected: false,
      isOfflineMode: isOffline,
    );
  }
}
