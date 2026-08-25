class SmartCityGlosaData {
  final String nextSignalName;
  final int signalSecondsRemaining;
  final String currentSignalState; // GREEN, AMBER, RED
  final double optimalGreenWaveSpeedKmH;
  final String congestionStatus;

  const SmartCityGlosaData({
    required this.nextSignalName,
    required this.signalSecondsRemaining,
    required this.currentSignalState,
    required this.optimalGreenWaveSpeedKmH,
    required this.congestionStatus,
  });
}

class SmartCityService {
  SmartCityGlosaData getGlosaRecommendation() {
    return const SmartCityGlosaData(
      nextSignalName: 'Grand Ave & 4th Street Intersection',
      signalSecondsRemaining: 18,
      currentSignalState: 'GREEN',
      optimalGreenWaveSpeedKmH: 45.0,
      congestionStatus: 'OPTIMAL URBAN FLOW',
    );
  }
}
