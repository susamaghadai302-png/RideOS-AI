import 'dart:developer' as developer;

class DigitalHealthScores {
  final double overallVehicleScore;
  final double safetyScore;
  final double maintenanceScore;
  final double efficiencyScore;
  final double rideQualityScore;

  const DigitalHealthScores({
    required this.overallVehicleScore,
    required this.safetyScore,
    required this.maintenanceScore,
    required this.efficiencyScore,
    required this.rideQualityScore,
  });
}

class RideReplayFrame {
  final int timestampMs;
  final double speedKmh;
  final double leanAngleDegrees;
  final double rpm;
  final String activeGeoFence;

  const RideReplayFrame({
    required this.timestampMs,
    required this.speedKmh,
    required this.leanAngleDegrees,
    required this.rpm,
    required this.activeGeoFence,
  });
}

class GlobalDigitalTwinPlatform {
  static final GlobalDigitalTwinPlatform instance = GlobalDigitalTwinPlatform._internal();
  GlobalDigitalTwinPlatform._internal();

  DigitalHealthScores auditDigitalHealth() {
    developer.log('Executing Digital Twin Health Audit...', name: 'RideOS.DigitalTwinPlatform');
    return const DigitalHealthScores(
      overallVehicleScore: 98.2,
      safetyScore: 99.0,
      maintenanceScore: 96.5,
      efficiencyScore: 97.8,
      rideQualityScore: 99.5,
    );
  }

  List<RideReplayFrame> getHistoricalRideReplay({required String rideId}) {
    return const [
      RideReplayFrame(timestampMs: 1000, speedKmh: 45.0, leanAngleDegrees: 12.0, rpm: 4200, activeGeoFence: 'Pacific Coast Highway'),
      RideReplayFrame(timestampMs: 2000, speedKmh: 78.0, leanAngleDegrees: 28.0, rpm: 6800, activeGeoFence: 'Canyon Curve Alpha'),
      RideReplayFrame(timestampMs: 3000, speedKmh: 92.0, leanAngleDegrees: 34.0, rpm: 8100, activeGeoFence: 'Canyon Curve Beta'),
    ];
  }
}
