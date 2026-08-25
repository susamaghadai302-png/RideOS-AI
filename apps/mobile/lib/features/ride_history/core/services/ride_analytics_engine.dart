import 'dart:convert';
import 'dart:math' as math;
import '../../domain/entities/ride_analytics_summary.dart';

class RideAnalyticsEngine {
  static final RideAnalyticsEngine _instance = RideAnalyticsEngine._internal();
  factory RideAnalyticsEngine() => _instance;
  RideAnalyticsEngine._internal();

  RideAnalyticsSummary computeSummary({
    required String tripId,
    required DateTime startTime,
    required DateTime endTime,
    required List<TelemetryDataPoint> points,
  }) {
    if (points.isEmpty) {
      return RideAnalyticsSummary(
        tripId: tripId,
        startTime: startTime,
        endTime: endTime,
        totalDistanceKm: 0.0,
        durationMinutes: endTime.difference(startTime).inSeconds / 60.0,
        maxSpeedKmh: 0.0,
        avgSpeedKmh: 0.0,
        maxLeanAngleLeft: 0.0,
        maxLeanAngleRight: 0.0,
        maxAccelerationG: 0.0,
        maxBrakingG: 0.0,
        totalElevationGainMeters: 0.0,
        safetyScore: 100,
        twistyRoadScore: 0,
        dataPoints: const [],
      );
    }

    double maxSpeed = 0.0;
    double speedSum = 0.0;
    double maxLeanLeft = 0.0;
    double maxLeanRight = 0.0;
    double maxAccelG = 0.0;
    double maxBrakeG = 0.0;
    double elevationGain = 0.0;
    double totalDistance = 0.0;

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      if (p.speedKmh > maxSpeed) maxSpeed = p.speedKmh;
      speedSum += p.speedKmh;

      if (p.leanAngleDeg < 0 && p.leanAngleDeg.abs() > maxLeanLeft) {
        maxLeanLeft = p.leanAngleDeg.abs();
      } else if (p.leanAngleDeg > 0 && p.leanAngleDeg > maxLeanRight) {
        maxLeanRight = p.leanAngleDeg;
      }

      if (p.gForce > maxAccelG) maxAccelG = p.gForce;
      if (p.gForce < -maxBrakeG) maxBrakeG = p.gForce.abs();

      if (i > 0) {
        final prev = points[i - 1];
        if (p.elevationMeters > prev.elevationMeters) {
          elevationGain += (p.elevationMeters - prev.elevationMeters);
        }
        totalDistance += _haversineDistanceKm(
          prev.latitude,
          prev.longitude,
          p.latitude,
          p.longitude,
        );
      }
    }

    final avgSpeed = speedSum / points.length;
    final durationMin = math.max(1.0, endTime.difference(startTime).inSeconds / 60.0);

    // Calculate twisty score (0-100 based on lean angle distribution)
    final highLeanCount = points.where((p) => p.leanAngleDeg.abs() > 25.0).length;
    final twistyScore = ((highLeanCount / points.length) * 100.0).clamp(0.0, 100.0).round();

    // Calculate safety compliance score
    int penalty = 0;
    if (maxSpeed > 140.0) penalty += 15;
    if (maxBrakeG > 0.9) penalty += 10;
    final safetyScore = (100 - penalty).clamp(0, 100);

    return RideAnalyticsSummary(
      tripId: tripId,
      startTime: startTime,
      endTime: endTime,
      totalDistanceKm: double.parse(totalDistance.toStringAsFixed(2)),
      durationMinutes: double.parse(durationMin.toStringAsFixed(1)),
      maxSpeedKmh: double.parse(maxSpeed.toStringAsFixed(1)),
      avgSpeedKmh: double.parse(avgSpeed.toStringAsFixed(1)),
      maxLeanAngleLeft: double.parse(maxLeanLeft.toStringAsFixed(1)),
      maxLeanAngleRight: double.parse(maxLeanRight.toStringAsFixed(1)),
      maxAccelerationG: double.parse(maxAccelG.toStringAsFixed(2)),
      maxBrakingG: double.parse(maxBrakeG.toStringAsFixed(2)),
      totalElevationGainMeters: double.parse(elevationGain.toStringAsFixed(1)),
      safetyScore: safetyScore,
      twistyRoadScore: twistyScore,
      dataPoints: points,
    );
  }

  String exportToGpx(RideAnalyticsSummary summary) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<gpx version="1.1" creator="RideOS-AI Motorcycle Platform" xmlns="http://www.topografix.com/GPX/1/1">');
    buffer.writeln('  <metadata>');
    buffer.writeln('    <name>RideOS Trip ${summary.tripId}</name>');
    buffer.writeln('    <time>${summary.startTime.toIso8601String()}</time>');
    buffer.writeln('  </metadata>');
    buffer.writeln('  <trk>');
    buffer.writeln('    <name>Motorcycle Telemetry Track</name>');
    buffer.writeln('    <trkseg>');

    for (final p in summary.dataPoints) {
      buffer.writeln('      <trkpt lat="${p.latitude}" lon="${p.longitude}">');
      buffer.writeln('        <ele>${p.elevationMeters}</ele>');
      buffer.writeln('        <time>${p.timestamp.toIso8601String()}</time>');
      buffer.writeln('        <extensions>');
      buffer.writeln('          <speed_kmh>${p.speedKmh}</speed_kmh>');
      buffer.writeln('          <lean_angle_deg>${p.leanAngleDeg}</lean_angle_deg>');
      buffer.writeln('          <g_force>${p.gForce}</g_force>');
      buffer.writeln('        </extensions>');
      buffer.writeln('      </trkpt>');
    }

    buffer.writeln('    </trkseg>');
    buffer.writeln('  </trk>');
    buffer.writeln('</gpx>');
    return buffer.toString();
  }

  String exportToCsv(RideAnalyticsSummary summary) {
    final buffer = StringBuffer();
    buffer.writeln('timestamp,latitude,longitude,speed_kmh,lean_angle_deg,elevation_m,g_force');
    for (final p in summary.dataPoints) {
      buffer.writeln('${p.timestamp.toIso8601String()},${p.latitude},${p.longitude},${p.speedKmh},${p.leanAngleDeg},${p.elevationMeters},${p.gForce}');
    }
    return buffer.toString();
  }

  String exportToJson(RideAnalyticsSummary summary) {
    return const JsonEncoder.withIndent('  ').convert(summary.toJson());
  }

  double _haversineDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0; // Earth radius in km
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) * math.cos(_degToRad(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);
}
