import 'package:flutter/foundation.dart';

enum RoadSurfaceGrip {
  dryOptimal,
  dampCaution,
  wetReducedGrip,
  hydroplaneRisk,
  iceHazard,
}

enum WeatherSeverityLevel {
  clear,
  notice,
  advisory,
  severeWarning,
}

@immutable
class RouteWeatherAdvisory {
  final double ambientTempC;
  final int rainProbabilityPct;
  final double windSpeedKmh;
  final double windGustKmh;
  final RoadSurfaceGrip roadGrip;
  final WeatherSeverityLevel severity;
  final String conditionSummary;
  final String safetyAdvisory;
  final bool hasCrosswindWarning;
  final DateTime timestamp;

  const RouteWeatherAdvisory({
    required this.ambientTempC,
    required this.rainProbabilityPct,
    required this.windSpeedKmh,
    required this.windGustKmh,
    required this.roadGrip,
    required this.severity,
    required this.conditionSummary,
    required this.safetyAdvisory,
    required this.hasCrosswindWarning,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'ambientTempC': ambientTempC,
      'rainProbabilityPct': rainProbabilityPct,
      'windSpeedKmh': windSpeedKmh,
      'windGustKmh': windGustKmh,
      'roadGrip': roadGrip.name,
      'severity': severity.name,
      'conditionSummary': conditionSummary,
      'safetyAdvisory': safetyAdvisory,
      'hasCrosswindWarning': hasCrosswindWarning,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
