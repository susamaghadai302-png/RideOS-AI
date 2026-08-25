import 'dart:async';
import '../models/normalized_telemetry_models.dart';

enum DeviceLinkState {
  disconnected,
  scanning,
  connecting,
  connected,
  reconnecting,
  error;
}

abstract class DeviceProvider {
  String get providerId;
  String get displayName;
  TelemetryDataSource get dataSourceClassification;
  bool get canClearDtcCodes;

  DeviceLinkState get linkState;
  Stream<DeviceLinkState> get linkStateStream;
  Stream<NormalizedTelemetrySnapshot> get telemetryStream;
  Stream<List<DiagnosticTroubleCode>> get diagnosticCodesStream;

  Future<bool> initialize();
  Future<bool> connect(String targetIdentifier);
  Future<void> disconnect();
  Future<bool> clearDtcCodes();
  Future<void> dispose();
}
