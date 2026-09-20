class RidingHabitAnalysis {
  final double? brakingSmoothnessScore;
  final double? corneringLeanStabilityScore;
  final double? accelerationIndexScore;
  final double? throttleControlScore;
  final double? speedComplianceScore;
  final double? nightRidingSafetyScore;
  final double? rainRidingControlScore;

  final double? overallSafetyScore;
  final double? overallRideScore;
  final double? smoothnessScore;
  final double? overallEcoScore;
  final double? fuelEfficiencyScore;

  const RidingHabitAnalysis({
    this.brakingSmoothnessScore,
    this.corneringLeanStabilityScore,
    this.accelerationIndexScore,
    this.throttleControlScore,
    this.speedComplianceScore,
    this.nightRidingSafetyScore,
    this.rainRidingControlScore,
    this.overallSafetyScore,
    this.overallRideScore,
    this.smoothnessScore,
    this.overallEcoScore,
    this.fuelEfficiencyScore,
  });
}

class RideDashboardMetrics {
  final double? todaysDistanceKm;
  final double? weeklyDistanceKm;
  final double? monthlyDistanceKm;
  final double? totalLifetimeKm;
  final double? fuelSavedLiters;
  final String? totalRidingTimeStr;
  final double? carbonSavedKg;

  const RideDashboardMetrics({
    this.todaysDistanceKm,
    this.weeklyDistanceKm,
    this.monthlyDistanceKm,
    this.totalLifetimeKm,
    this.fuelSavedLiters,
    this.totalRidingTimeStr,
    this.carbonSavedKg,
  });
}

class RideIntelligenceService {
  RidingHabitAnalysis analyzeCurrentRide() {
    return const RidingHabitAnalysis();
  }

  RideDashboardMetrics getDashboardMetrics() {
    return const RideDashboardMetrics();
  }
}
