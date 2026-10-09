import 'dart:async';
import '../../../sos_safety/core/crash_detection_algorithm.dart';

enum CrashDetectionState {
  idle,
  countdownActive,
  emergencyTriggered,
  cancelled
}

class RiderMedicalProfile {
  final String fullName;
  final String bloodType;
  final String allergies;
  final String primaryContactPhone;
  final String insuranceProvider;
  final String insurancePolicyNo;

  const RiderMedicalProfile({
    this.fullName = 'Not configured',
    this.bloodType = 'Not configured',
    this.allergies = 'Not configured',
    this.primaryContactPhone = 'Not configured',
    this.insuranceProvider = 'Not configured',
    this.insurancePolicyNo = 'Not configured',
  });
}

class CrashDetectionEngine {
  CrashDetectionState state = CrashDetectionState.idle;
  int secondsRemaining = 30;
  Timer? _timer;

  final RiderMedicalProfile medicalProfile = const RiderMedicalProfile();
  final StreamController<int> _countdownController =
      StreamController<int>.broadcast();
  Stream<int> get countdownStream => _countdownController.stream;

  final CrashDetectionAlgorithm algorithm = const CrashDetectionAlgorithm();
  String lastTriggerReason = '';

  /// Analyzes IMU accelerometer and gyroscope sensor readings for crash pattern
  bool evaluateSensorInputs({
    required double gForce,
    required double decelerationMps2,
    required double tiltDegrees,
    double currentSpeedKmh = 50.0,
  }) {
    final speedDropKmh = decelerationMps2 * 3.6;

    final evaluation = algorithm.evaluateCrashConfidence(
      accelMagnitudeG: gForce,
      rollAngleDeg: tiltDegrees,
      currentSpeedKmh: currentSpeedKmh,
      speedDropKmh: speedDropKmh,
      durationSecSinceSpeedDrop: 2.5,
      isBleEcuConnected: true,
    );

    if (evaluation.isCrashDetected) {
      lastTriggerReason = evaluation.primaryTriggerReason;
      triggerSimulatedImpact(forceG: gForce);
      return true;
    }
    return false;
  }

  void triggerSimulatedImpact({double forceG = 6.2}) {
    if (state == CrashDetectionState.countdownActive) return;

    state = CrashDetectionState.countdownActive;
    secondsRemaining = 30;
    _countdownController.add(secondsRemaining);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      secondsRemaining--;
      _countdownController.add(secondsRemaining);

      if (secondsRemaining <= 0) {
        t.cancel();
        state = CrashDetectionState.emergencyTriggered;
      }
    });
  }

  String generateEmergencyMessage({required double lat, required double lng}) {
    final reasonPart =
        lastTriggerReason.isNotEmpty ? ' Reason: $lastTriggerReason.' : '';
    return 'EMERGENCY SOS ALERT! Rideo Pro detected a motorcycle crash for ${medicalProfile.fullName}.$reasonPart '
        'Location: https://maps.google.com/?q=$lat,$lng. '
        'Blood Type: ${medicalProfile.bloodType}, Allergies: ${medicalProfile.allergies}. '
        'Insurance: ${medicalProfile.insuranceProvider} (${medicalProfile.insurancePolicyNo}).';
  }

  void cancelCountdown() {
    _timer?.cancel();
    state = CrashDetectionState.cancelled;
    secondsRemaining = 30;
    _countdownController.add(secondsRemaining);
  }

  void reset() {
    _timer?.cancel();
    state = CrashDetectionState.idle;
    secondsRemaining = 30;
  }

  void dispose() {
    _timer?.cancel();
    _countdownController.close();
  }
}
