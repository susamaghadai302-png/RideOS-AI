import 'dart:math';

class LeanAngleReading {
  final double rollAngleDegree;
  final double pitchAngleDegree;
  final double accelMagnitudeG;
  final DateTime timestamp;

  const LeanAngleReading({
    required this.rollAngleDegree,
    required this.pitchAngleDegree,
    required this.accelMagnitudeG,
    required this.timestamp,
  });
}

class SensorFusionService {
  /// Computes roll/lean angle from 3-axis accelerometer values (ax, ay, az)
  LeanAngleReading computeOrientation({
    required double ax,
    required double ay,
    required double az,
  }) {
    final magnitude = sqrt(ax * ax + ay * ay + az * az) / 9.81;
    final rollRad = atan2(ay, az);
    final pitchRad = atan2(-ax, sqrt(ay * ay + az * az));

    final rollDeg = rollRad * (180.0 / pi);
    final pitchDeg = pitchRad * (180.0 / pi);

    return LeanAngleReading(
      rollAngleDegree: double.parse(rollDeg.toStringAsFixed(1)),
      pitchAngleDegree: double.parse(pitchDeg.toStringAsFixed(1)),
      accelMagnitudeG: double.parse(magnitude.toStringAsFixed(2)),
      timestamp: DateTime.now(),
    );
  }
}
