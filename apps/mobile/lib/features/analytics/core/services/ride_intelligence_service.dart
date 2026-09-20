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
      brakingSmoothnessScore: 0.0,
      corneringLeanStabilityScore: 0.0,
      accelerationIndexScore: 0.0,
      throttleControlScore: 0.0,
      speedComplianceScore: 0.0,
      nightRidingSafetyScore: 0.0,
      rainRidingControlScore: 0.0,
      overallSafetyScore: 0.0,
      overallRideScore: 0.0,
      smoothnessScore: 0.0,
      overallEcoScore: 0.0,
      fuelEfficiencyScore: 0.0,
    );
  }

  RideDashboardMetrics getDashboardMetrics() {
    return const RideDashboardMetrics(
      todaysDistanceKm: 0.0,
      weeklyDistanceKm: 0.0,
      monthlyDistanceKm: 0.0,
      totalLifetimeKm: 0.0,
      fuelSavedLiters: 0.0,
      totalRidingTimeStr: '--',
      carbonSavedKg: 0.0,
    );
  }
}
