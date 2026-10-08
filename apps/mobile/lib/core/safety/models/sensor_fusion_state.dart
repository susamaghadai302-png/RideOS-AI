enum SensorFusionState {
  normal,
  degraded,
  candidateEvent,
  insufficientData,
}

class SensorSample {
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;

  const SensorSample({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  });
}
