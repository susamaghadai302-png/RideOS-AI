class AntiTheftService {
  bool isGuardArmed = true;
  bool isGeofenceActive = true;
  double geofenceRadiusMeters = 100.0;
  bool unauthorizedMovementDetected = false;
  bool remoteAlarmTriggered = false;

  void armGuard(bool arm) {
    isGuardArmed = arm;
    if (!arm) {
      unauthorizedMovementDetected = false;
      remoteAlarmTriggered = false;
    }
  }

  void toggleRemoteAlarm() {
    remoteAlarmTriggered = !remoteAlarmTriggered;
  }

  void updateGeofenceRadius(double radiusMeters) {
    geofenceRadiusMeters = radiusMeters;
  }
}
