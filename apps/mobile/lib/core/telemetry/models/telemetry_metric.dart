import 'package:flutter/foundation.dart';
import 'metric_types.dart';
import '../../diagnostics/models/diagnostic_types.dart';

/// An individual normalized vehicle telemetry measurement.
@immutable
class NormalizedTelemetryMetric {
  final TelemetryMetricId metricId;
  final TelemetryMetricCategory category;
  final double? value;
  final TelemetryUnit unit;
  final DateTime timestamp;
  final EcuModule sourceEcu;
  final String diagnosticPidCode;
  final TelemetryFreshness freshness;
  final double qualityScore; // 0.0 to 1.0
  final bool isSimulated;
  final String? diagnosticNote;

  const NormalizedTelemetryMetric({
    required this.metricId,
    required this.category,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.sourceEcu = EcuModule.engineControlModule_ECM,
    this.diagnosticPidCode = 'N/A',
    required this.freshness,
    this.qualityScore = 1.0,
    this.isSimulated = false,
    this.diagnosticNote,
  });

  /// Factory constructor for an unavailable metric.
  factory NormalizedTelemetryMetric.unavailable({
    required TelemetryMetricId metricId,
    required TelemetryUnit unit,
    EcuModule sourceEcu = EcuModule.engineControlModule_ECM,
    String? diagnosticNote,
  }) {
    return NormalizedTelemetryMetric(
      metricId: metricId,
      category: metricId.category,
      value: null,
      unit: unit,
      timestamp: DateTime.now(),
      sourceEcu: sourceEcu,
      freshness: TelemetryFreshness.unavailable,
      qualityScore: 0.0,
      diagnosticNote: diagnosticNote ?? 'Sensor unmapped or stream disconnected',
    );
  }

  /// Factory constructor for an invalid/out-of-bounds metric.
  factory NormalizedTelemetryMetric.invalid({
    required TelemetryMetricId metricId,
    required double rawValue,
    required TelemetryUnit unit,
    EcuModule sourceEcu = EcuModule.engineControlModule_ECM,
    required String reason,
  }) {
    return NormalizedTelemetryMetric(
      metricId: metricId,
      category: metricId.category,
      value: rawValue,
      unit: unit,
      timestamp: DateTime.now(),
      sourceEcu: sourceEcu,
      freshness: TelemetryFreshness.invalid,
      qualityScore: 0.0,
      diagnosticNote: 'Invalid reading ($rawValue ${unit.symbol}): $reason',
    );
  }

  /// Returns true if this metric has a valid, non-null numeric value and is fresh.
  bool get isLive => freshness == TelemetryFreshness.fresh && value != null;

  /// Formatted string display of the value and unit.
  String get formattedDisplay {
    switch (freshness) {
      case TelemetryFreshness.unavailable:
        return '—';
      case TelemetryFreshness.invalid:
        return 'ERR';
      case TelemetryFreshness.stale:
        return value != null ? '${value!.toStringAsFixed(1)} (STALE)' : '—';
      case TelemetryFreshness.fresh:
        if (value == null) return '—';
        if (metricId == TelemetryMetricId.engineRpm) {
          return value!.toStringAsFixed(0);
        }
        return value!.toStringAsFixed(1);
    }
  }

  /// Creates a copy with updated freshness state.
  NormalizedTelemetryMetric copyWithFreshness(TelemetryFreshness nextFreshness) {
    return NormalizedTelemetryMetric(
      metricId: metricId,
      category: category,
      value: value,
      unit: unit,
      timestamp: timestamp,
      sourceEcu: sourceEcu,
      diagnosticPidCode: diagnosticPidCode,
      freshness: nextFreshness,
      qualityScore: nextFreshness == TelemetryFreshness.fresh ? qualityScore : 0.5,
      isSimulated: isSimulated,
      diagnosticNote: diagnosticNote,
    );
  }

  Map<String, dynamic> toJson() => {
        'metricId': metricId.name,
        'category': category.name,
        'value': value,
        'unit': unit.symbol,
        'timestamp': timestamp.toIso8601String(),
        'sourceEcu': sourceEcu.name,
        'diagnosticPidCode': diagnosticPidCode,
        'freshness': freshness.name,
        'qualityScore': qualityScore,
        'isSimulated': isSimulated,
        'diagnosticNote': diagnosticNote,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NormalizedTelemetryMetric &&
          runtimeType == other.runtimeType &&
          metricId == other.metricId &&
          value == other.value &&
          freshness == other.freshness &&
          sourceEcu == other.sourceEcu;

  @override
  int get hashCode =>
      metricId.hashCode ^ value.hashCode ^ freshness.hashCode ^ sourceEcu.hashCode;

  @override
  String toString() =>
      'NormalizedTelemetryMetric(${metricId.name}: $formattedDisplay ${unit.symbol} [${freshness.label}] from ${sourceEcu.name})';
}
