enum DiagnosticState {
  idle,
  checking,
  permissionRequired,
  bluetoothOff,
  scanning,
  deviceFound,
  connecting,
  connected,
  discovering,
  ready,
  streaming,
  disconnected,
  timeout,
  error,
}

class PhysicalValidationRecord {
  final String testId;
  final DateTime timestamp;
  final String deviceType;
  final String? manufacturer;
  final String transport;
  final String connectionState;
  final String protocolState;
  final String? rawDataObserved;
  final String? parserResult;
  final String? telemetryResult;
  final String? notes;

  PhysicalValidationRecord({
    required this.testId,
    required this.timestamp,
    required this.deviceType,
    this.manufacturer,
    required this.transport,
    required this.connectionState,
    required this.protocolState,
    this.rawDataObserved,
    this.parserResult,
    this.telemetryResult,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'testId': testId,
      'timestamp': timestamp.toIso8601String(),
      'deviceType': deviceType,
      'manufacturer': manufacturer,
      'transport': transport,
      'connectionState': connectionState,
      'protocolState': protocolState,
      'rawDataObserved': rawDataObserved,
      'parserResult': parserResult,
      'telemetryResult': telemetryResult,
      'notes': notes,
    };
  }
}
