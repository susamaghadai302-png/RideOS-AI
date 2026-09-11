import 'dart:async';

enum CrashDetectionState { idle, countdownActive, emergencyTriggered, cancelled }

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
  final StreamController<int> _countdownController = StreamController<int>.broadcast();
  Stream<int> get countdownStream => _countdownController.stream;

  /// Analyzes IMU accelerometer and gyroscope sensor readings for crash pattern
  bool evaluateSensorInputs({
    required double gForce,
    required double decelerationMps2,
    required double tiltDegrees,
  }) {
    // Impact > 4.5 Gs OR rapid stop > 12 m/s² WITH severe tilt > 70 deg
    if (gForce > 4.5 || (decelerationMps2 > 12.0 && tiltDegrees > 70.0)) {
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
    return 'EMERGENCY SOS ALERT! Rideo Pro detected a motorcycle crash for ${medicalProfile.fullName}. '
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
