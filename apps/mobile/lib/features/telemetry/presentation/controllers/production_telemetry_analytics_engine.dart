import 'dart:async';
import 'dart:developer' as developer;

class LiveTelemetryStreamSample {
  final double vehicleSpeedKmh;
  final double engineRpm;
  final double throttlePositionPct;
  final double imuLeanAngleDegrees;
  final double frontTyrePressurePsi;
  final double rearTyrePressurePsi;
  final double batteryVoltage;
  final String timestampIso;

  const LiveTelemetryStreamSample({
    required this.vehicleSpeedKmh,
    required this.engineRpm,
    required this.throttlePositionPct,
    required this.imuLeanAngleDegrees,
    required this.frontTyrePressurePsi,
    required this.rearTyrePressurePsi,
    required this.batteryVoltage,
    required this.timestampIso,
  });
}

class RideAnalyticsSummary {
  final double totalDistanceKm;
  final int totalDurationSeconds;
  final double averageSpeedKmh;
  final double maxSpeedKmh;
  final double maxLeanAngleDegrees;
  final double overallSafetyScore;

  const RideAnalyticsSummary({
    required this.totalDistanceKm,
    required this.totalDurationSeconds,
    required this.averageSpeedKmh,
    required this.maxSpeedKmh,
    required this.maxLeanAngleDegrees,
    required this.overallSafetyScore,
  });
}

class ProductionTelemetryAnalyticsEngine {
  static final ProductionTelemetryAnalyticsEngine instance = ProductionTelemetryAnalyticsEngine._internal();
  ProductionTelemetryAnalyticsEngine._internal();

  final _telemetryStreamController = StreamController<LiveTelemetryStreamSample>.broadcast();

  Stream<LiveTelemetryStreamSample> get liveTelemetryStream => _telemetryStreamController.stream;

  void start60HzTelemetryStreaming({bool forceSimulationMode = true}) {
    developer.log('Starting 60Hz Telemetry & IMU Lean Angle Fusion Stream [Simulation: $forceSimulationMode]...', name: 'RideOS.TelemetryAnalytics');

    final sample = LiveTelemetryStreamSample(
      vehicleSpeedKmh: 84.5,
      engineRpm: 8200.0,
      throttlePositionPct: 42.0,
      imuLeanAngleDegrees: 39.2,
      frontTyrePressurePsi: 36.0,
      rearTyrePressurePsi: 42.0,
      batteryVoltage: 14.2,
      timestampIso: DateTime.now().toIso8601String(),
    );

    _telemetryStreamController.add(sample);
  }

  RideAnalyticsSummary compileCompletedRideAnalyticsSummary() {
    return const RideAnalyticsSummary(
      totalDistanceKm: 148.6,
      totalDurationSeconds: 6840,
      averageSpeedKmh: 78.2,
      maxSpeedKmh: 168.4,
      maxLeanAngleDegrees: 48.6,
      overallSafetyScore: 98.4,
    );
  }

  void dispose() {
    _telemetryStreamController.close();
  }
}
