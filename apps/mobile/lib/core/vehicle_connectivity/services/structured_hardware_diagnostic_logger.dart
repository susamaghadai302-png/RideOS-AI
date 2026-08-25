import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/packet_capture_models.dart';

enum DiagnosticEventType {
  discovery,
  connectionStateChange,
  gattServicesDiscovered,
  characteristicsDiscovered,
  notificationSubscribed,
  packetReceived,
  checksumValidated,
  packetLossDetected,
  reconnectAttempt,
  connectionFailure,
  vehicleIdentified,
}

enum DiagnosticSeverity {
  info,
  warning,
  error,
  critical,
}

@immutable
class StructuredDiagnosticLogEntry {
  final int logIndex;
  final DateTime timestamp;
  final DiagnosticEventType eventType;
  final DiagnosticSeverity severity;
  final String deviceId;
  final String message;
  final Map<String, dynamic> metadata;
  final CaptureSourceClassification sourceMode;

  const StructuredDiagnosticLogEntry({
    required this.logIndex,
    required this.timestamp,
    required this.eventType,
    required this.severity,
    required this.deviceId,
    required this.message,
    this.metadata = const {},
    required this.sourceMode,
  });

  Map<String, dynamic> toJson() => {
    'index': logIndex,
    'timestamp': timestamp.toIso8601String(),
    'eventType': eventType.name,
    'severity': severity.name,
    'deviceId': deviceId,
    'message': message,
    'metadata': metadata,
    'source': sourceMode.label,
  };
}

class StructuredHardwareDiagnosticLogger {
  static final StructuredHardwareDiagnosticLogger _instance = StructuredHardwareDiagnosticLogger._internal();
  factory StructuredHardwareDiagnosticLogger() => _instance;

  final List<StructuredDiagnosticLogEntry> _logs = [];
  List<StructuredDiagnosticLogEntry> get logs => List.unmodifiable(_logs);

  final _logController = StreamController<StructuredDiagnosticLogEntry>.broadcast();
  Stream<StructuredDiagnosticLogEntry> get logStream => _logController.stream;

  StructuredHardwareDiagnosticLogger._internal();

  void log({
    required DiagnosticEventType eventType,
    required DiagnosticSeverity severity,
    required String deviceId,
    required String message,
    Map<String, dynamic> metadata = const {},
    CaptureSourceClassification sourceMode = CaptureSourceClassification.simulated,
  }) {
    final entry = StructuredDiagnosticLogEntry(
      logIndex: _logs.length + 1,
      timestamp: DateTime.now(),
      eventType: eventType,
      severity: severity,
      deviceId: deviceId,
      message: message,
      metadata: metadata,
      sourceMode: sourceMode,
    );

    _logs.add(entry);
    if (_logs.length > 1000) {
      _logs.removeAt(0); // rolling window
    }

    if (!_logController.isClosed) {
      _logController.add(entry);
    }
  }

  void clearLogs() {
    _logs.clear();
  }

  String exportSanitizedLogsJson() {
    return const JsonEncoder.withIndent('  ').convert(
      _logs.map((e) => e.toJson()).toList(),
    );
  }
}
