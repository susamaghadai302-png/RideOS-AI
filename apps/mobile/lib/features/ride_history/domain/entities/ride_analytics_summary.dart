import 'package:flutter/foundation.dart';

@immutable
class TelemetryDataPoint {
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double speedKmh;
  final double leanAngleDeg;
  final double elevationMeters;
  final double gForce;

  const TelemetryDataPoint({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.speedKmh,
    required this.leanAngleDeg,
    required this.elevationMeters,
    required this.gForce,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'speedKmh': speedKmh,
      'leanAngleDeg': leanAngleDeg,
      'elevationMeters': elevationMeters,
      'gForce': gForce,
    };
  }
}

@immutable
class RideAnalyticsSummary {
  final String tripId;
  final DateTime startTime;
  final DateTime endTime;
  final double totalDistanceKm;
  final double durationMinutes;
  final double maxSpeedKmh;
  final double avgSpeedKmh;
  final double maxLeanAngleLeft;
  final double maxLeanAngleRight;
  final double maxAccelerationG;
  final double maxBrakingG;
  final double totalElevationGainMeters;
  final int safetyScore;
  final int twistyRoadScore;
  final List<TelemetryDataPoint> dataPoints;

  const RideAnalyticsSummary({
    required this.tripId,
    required this.startTime,
    required this.endTime,
    required this.totalDistanceKm,
    required this.durationMinutes,
    required this.maxSpeedKmh,
    required this.avgSpeedKmh,
    required this.maxLeanAngleLeft,
    required this.maxLeanAngleRight,
    required this.maxAccelerationG,
    required this.maxBrakingG,
    required this.totalElevationGainMeters,
    required this.safetyScore,
    required this.twistyRoadScore,
    this.dataPoints = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'tripId': tripId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'totalDistanceKm': totalDistanceKm,
      'durationMinutes': durationMinutes,
      'maxSpeedKmh': maxSpeedKmh,
      'avgSpeedKmh': avgSpeedKmh,
      'maxLeanAngleLeft': maxLeanAngleLeft,
      'maxLeanAngleRight': maxLeanAngleRight,
      'maxAccelerationG': maxAccelerationG,
      'maxBrakingG': maxBrakingG,
      'totalElevationGainMeters': totalElevationGainMeters,
      'safetyScore': safetyScore,
      'twistyRoadScore': twistyRoadScore,
      'dataPoints': dataPoints.map((p) => p.toJson()).toList(),
    };
  }
}
