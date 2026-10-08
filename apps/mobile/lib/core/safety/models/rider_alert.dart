enum AlertSeverity {
  info,
  warning,
  critical,
}

enum AlertSource {
  telemetry,
  navigation,
  system,
  sensorFusion,
}

class RiderAlert {
  final String id;
  final String reason;
  final AlertSeverity severity;
  final AlertSource source;
  final double confidence;
  final DateTime timestamp;

  const RiderAlert({
    required this.id,
    required this.reason,
    required this.severity,
    required this.source,
    required this.confidence,
    required this.timestamp,
  });
}
