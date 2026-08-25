import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/ride_history/core/services/ride_analytics_engine.dart';
import 'package:rideos_mobile/features/ride_history/domain/entities/ride_analytics_summary.dart';

void main() {
  group('Phase 6 - Ride Analytics & Telemetry Export Tests', () {
    late RideAnalyticsEngine analyticsEngine;

    setUp(() {
      analyticsEngine = RideAnalyticsEngine();
    });

    test('Computes maximum speed, lean angles, G-forces and elevation gain accurately', () {
      final now = DateTime.now();
      final points = [
        TelemetryDataPoint(
          timestamp: now,
          latitude: 37.7749,
          longitude: -122.4194,
          speedKmh: 45.0,
          leanAngleDeg: -28.5, // Left lean
          elevationMeters: 50.0,
          gForce: 0.45,
        ),
        TelemetryDataPoint(
          timestamp: now.add(const Duration(seconds: 30)),
          latitude: 37.7760,
          longitude: -122.4180,
          speedKmh: 92.0,
          leanAngleDeg: 34.0, // Right lean
          elevationMeters: 85.0,
          gForce: 0.85,
        ),
        TelemetryDataPoint(
          timestamp: now.add(const Duration(seconds: 60)),
          latitude: 37.7770,
          longitude: -122.4170,
          speedKmh: 60.0,
          leanAngleDeg: 12.0,
          elevationMeters: 110.0,
          gForce: -0.65, // Braking
        ),
      ];

      final summary = analyticsEngine.computeSummary(
        tripId: 'trip_test_001',
        startTime: now,
        endTime: now.add(const Duration(minutes: 2)),
        points: points,
      );

      expect(summary.maxSpeedKmh, equals(92.0));
      expect(summary.maxLeanAngleLeft, equals(28.5));
      expect(summary.maxLeanAngleRight, equals(34.0));
      expect(summary.maxAccelerationG, equals(0.85));
      expect(summary.maxBrakingG, equals(0.65));
      expect(summary.totalElevationGainMeters, equals(60.0)); // (85-50) + (110-85)
      expect(summary.safetyScore, equals(100));
    });

    test('Generates valid GPX export format', () {
      final now = DateTime.now();
      final points = [
        TelemetryDataPoint(
          timestamp: now,
          latitude: 37.7749,
          longitude: -122.4194,
          speedKmh: 50.0,
          leanAngleDeg: 15.0,
          elevationMeters: 20.0,
          gForce: 0.3,
        ),
      ];

      final summary = analyticsEngine.computeSummary(
        tripId: 'trip_gpx_01',
        startTime: now,
        endTime: now.add(const Duration(minutes: 1)),
        points: points,
      );

      final gpx = analyticsEngine.exportToGpx(summary);
      expect(gpx, contains('<?xml version="1.0" encoding="UTF-8"?>'));
      expect(gpx, contains('<gpx version="1.1"'));
      expect(gpx, contains('<trkpt lat="37.7749" lon="-122.4194">'));
      expect(gpx, contains('<speed_kmh>50.0</speed_kmh>'));
    });

    test('Generates valid CSV export format', () {
      final now = DateTime.now();
      final points = [
        TelemetryDataPoint(
          timestamp: now,
          latitude: 37.7749,
          longitude: -122.4194,
          speedKmh: 50.0,
          leanAngleDeg: 15.0,
          elevationMeters: 20.0,
          gForce: 0.3,
        ),
      ];

      final summary = analyticsEngine.computeSummary(
        tripId: 'trip_csv_01',
        startTime: now,
        endTime: now.add(const Duration(minutes: 1)),
        points: points,
      );

      final csv = analyticsEngine.exportToCsv(summary);
      expect(csv, contains('timestamp,latitude,longitude,speed_kmh,lean_angle_deg,elevation_m,g_force'));
      expect(csv, contains('37.7749,-122.4194,50.0,15.0,20.0,0.3'));
    });
  });
}
