class RidingHabitAnalysis {
  final double brakingSmoothnessScore; // 0-100
  final double corneringLeanStabilityScore; // 0-100
  final double accelerationIndexScore; // 0-100
  final double throttleControlScore; // 0-100
  final double speedComplianceScore; // 0-100
  final double nightRidingSafetyScore; // 0-100
  final double rainRidingControlScore; // 0-100

  final double overallSafetyScore; // 0-100
  final double overallRideScore; // 0-100
  final double smoothnessScore; // 0-100
  final double overallEcoScore; // 0-100
  final double fuelEfficiencyScore; // 0-100

  const RidingHabitAnalysis({
    required this.brakingSmoothnessScore,
    required this.corneringLeanStabilityScore,
    required this.accelerationIndexScore,
    required this.throttleControlScore,
    required this.speedComplianceScore,
    required this.nightRidingSafetyScore,
    required this.rainRidingControlScore,
    required this.overallSafetyScore,
    required this.overallRideScore,
    required this.smoothnessScore,
    required this.overallEcoScore,
    required this.fuelEfficiencyScore,
  });
}

class RideDashboardMetrics {
  final double todaysDistanceKm;
  final double weeklyDistanceKm;
  final double monthlyDistanceKm;
  final double totalLifetimeKm;
  final double fuelSavedLiters;
  final String totalRidingTimeStr;
  final double carbonSavedKg;

  const RideDashboardMetrics({
    required this.todaysDistanceKm,
    required this.weeklyDistanceKm,
    required this.monthlyDistanceKm,
    required this.totalLifetimeKm,
    required this.fuelSavedLiters,
    required this.totalRidingTimeStr,
    required this.carbonSavedKg,
  });
}

class RideIntelligenceService {
  RidingHabitAnalysis analyzeCurrentRide() {
    return const RidingHabitAnalysis(
      brakingSmoothnessScore: 94.5,
      corneringLeanStabilityScore: 92.0,
      accelerationIndexScore: 88.5,
      throttleControlScore: 90.0,
      speedComplianceScore: 95.0,
      nightRidingSafetyScore: 96.0,
      rainRidingControlScore: 91.0,
      overallSafetyScore: 96.0,
      overallRideScore: 94.0,
      smoothnessScore: 93.5,
      overallEcoScore: 91.5,
      fuelEfficiencyScore: 93.0,
    );
  }

  RideDashboardMetrics getDashboardMetrics() {
    return const RideDashboardMetrics(
      todaysDistanceKm: 48.6,
      weeklyDistanceKm: 342.0,
      monthlyDistanceKm: 1280.5,
      totalLifetimeKm: 8420.0,
      fuelSavedLiters: 18.4,
      totalRidingTimeStr: '142h 30m',
      carbonSavedKg: 42.5,
    );
  }
}
