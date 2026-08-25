import 'dart:developer' as developer;

class MaintenancePrediction {
  final int estimatedKmRemainingToService;
  final String componentNeedingAttention;
  final String urgencyLevel; // 'Low', 'Medium', 'High'
  final double predictedCostUsd;

  const MaintenancePrediction({
    required this.estimatedKmRemainingToService,
    required this.componentNeedingAttention,
    required this.urgencyLevel,
    required this.predictedCostUsd,
  });
}

class HazardPrediction {
  final String hazardType; // 'Sharp Curve', 'Low Visibility', 'Road Surface Hazard'
  final double distanceMeters;
  final double recommendedSpeedKmh;

  const HazardPrediction({
    required this.hazardType,
    required this.distanceMeters,
    required this.recommendedSpeedKmh,
  });
}

class AiPredictiveEngine {
  static final AiPredictiveEngine instance = AiPredictiveEngine._internal();
  AiPredictiveEngine._internal();

  MaintenancePrediction predictNextServiceInterval({required int currentOdometerKm}) {
    final nextServiceKm = ((currentOdometerKm ~/ 5000) + 1) * 5000;
    final remainingKm = nextServiceKm - currentOdometerKm;

    developer.log('Predicted next service in $remainingKm km', name: 'RideOS.AiPredictiveEngine');

    return MaintenancePrediction(
      estimatedKmRemainingToService: remainingKm,
      componentNeedingAttention: remainingKm < 500 ? 'Brake Fluid & Oil Filter' : 'Standard Inspection',
      urgencyLevel: remainingKm < 300 ? 'High' : 'Low',
      predictedCostUsd: 149.0,
    );
  }

  List<HazardPrediction> scanRouteHazardsAhead({required double currentSpeedKmh}) {
    return const [
      HazardPrediction(hazardType: 'Sharp Hairpin Curve', distanceMeters: 450.0, recommendedSpeedKmh: 45.0),
      HazardPrediction(hazardType: 'Surface Oil Slick / Wet Asphalt', distanceMeters: 1200.0, recommendedSpeedKmh: 50.0),
    ];
  }

  double predictTripFuelConsumption({required double distanceKm, required String rideMode}) {
    double baseEfficiency = 4.2; // L per 100km
    if (rideMode == 'SPORT') baseEfficiency = 5.8;
    if (rideMode == 'TRACK') baseEfficiency = 7.2;

    return (distanceKm / 100.0) * baseEfficiency;
  }
}
