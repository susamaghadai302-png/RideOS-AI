enum CrashDetectionState {
  normal,
  suspectedIncident,
  validating,
  countdown,
  userConfirmed,
  sosSent,
  sosCancelled,
  networkUnavailable,
}

enum SosState {
  idle,
  candidate,
  countdown,
  confirmed,
  sending,
  sent,
  failed,
  cancelled,
}

class SosRequest {
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double confidence;
  final String triggerSource;

  const SosRequest({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.confidence,
    required this.triggerSource,
  });
}

abstract class SosTransport {
  Future<SosState> sendSos(SosRequest request);
}
