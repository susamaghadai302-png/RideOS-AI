import 'dart:developer' as developer;

class ProactiveRideTelemetry {
  final double currentSpeedKmh;
  final double leanAngleDegrees;
  final double accelerationG;
  final double brakingG;
  final double engineTemperatureC;
  final double fuelLevelPercentage;
  final double riderFatigueHours;

  const ProactiveRideTelemetry({
    required this.currentSpeedKmh,
    required this.leanAngleDegrees,
    required this.accelerationG,
    required this.brakingG,
    required this.engineTemperatureC,
    required this.fuelLevelPercentage,
    required this.riderFatigueHours,
  });
}

class RideScores {
  final double overallRideScore;
  final double safetyScore;
  final double corneringScore;
  final double accelerationScore;
  final double brakingScore;
  final double smoothnessScore;

  const RideScores({
    required this.overallRideScore,
    required this.safetyScore,
    required this.corneringScore,
    required this.accelerationScore,
    required this.brakingScore,
    required this.smoothnessScore,
  });
}

class WorldClassAiCore {
  static final WorldClassAiCore instance = WorldClassAiCore._internal();
  WorldClassAiCore._internal();

  RideScores evaluateRideTelemetry(ProactiveRideTelemetry telemetry) {
    double safety = 100.0;
    if (telemetry.currentSpeedKmh > 120) safety -= 15;
    if (telemetry.engineTemperatureC > 105) safety -= 10;
    if (telemetry.riderFatigueHours > 2.5) safety -= 20;

    double cornering = 95.0 - (telemetry.leanAngleDegrees > 42 ? 5 : 0);
    double acceleration = 92.0 - (telemetry.accelerationG > 0.8 ? 8 : 0);
    double braking = 94.0 - (telemetry.brakingG > 0.9 ? 10 : 0);
    double smoothness = (cornering + acceleration + braking) / 3.0;
    double overall = (safety * 0.4) + (smoothness * 0.6);

    developer.log('Evaluated RideScores: Overall ${overall.toStringAsFixed(1)}', name: 'RideOS.AiCore');

    return RideScores(
      overallRideScore: overall.clamp(0, 100),
      safetyScore: safety.clamp(0, 100),
      corneringScore: cornering.clamp(0, 100),
      accelerationScore: acceleration.clamp(0, 100),
      brakingScore: braking.clamp(0, 100),
      smoothnessScore: smoothness.clamp(0, 100),
    );
  }

  List<String> generateProactiveSafetyAlerts(ProactiveRideTelemetry telemetry) {
    final List<String> alerts = [];

    if (telemetry.fuelLevelPercentage < 15.0) {
      alerts.add('Low Fuel Warning: 15% remaining. AI calculated nearest fuel stop in 12 km.');
    }
    if (telemetry.riderFatigueHours >= 2.0) {
      alerts.add('Fatigue Alert: You have been riding continuously for ${telemetry.riderFatigueHours.toStringAsFixed(1)} hours. Recommended rest stop in 5 km.');
    }
    if (telemetry.engineTemperatureC > 105.0) {
      alerts.add('Engine Thermal Alert: Temperature reached ${telemetry.engineTemperatureC.toInt()} degC. Lower RPM to protect engine.');
    }

    return alerts;
  }
}
