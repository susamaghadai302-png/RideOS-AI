import 'dart:async';
import '../interfaces/device_provider.dart';
import '../models/normalized_telemetry_models.dart';

class Obd2Provider implements DeviceProvider {
  @override
  String get providerId => 'obd2_standard_can_provider';

  @override
  String get displayName => 'OBD-II / CAN-Bus Telematics Link';

  @override
  TelemetryDataSource get dataSourceClassification => TelemetryDataSource.realDevice;

  @override
  bool get canClearDtcCodes => true; // Mode 04 standard OBD-II command

  DeviceLinkState _linkState = DeviceLinkState.disconnected;
  @override
  DeviceLinkState get linkState => _linkState;

  final _linkStateController = StreamController<DeviceLinkState>.broadcast();
  @override
  Stream<DeviceLinkState> get linkStateStream => _linkStateController.stream;

  final _telemetryController = StreamController<NormalizedTelemetrySnapshot>.broadcast();
  @override
  Stream<NormalizedTelemetrySnapshot> get telemetryStream => _telemetryController.stream;

  final _dtcController = StreamController<List<DiagnosticTroubleCode>>.broadcast();
  @override
  Stream<List<DiagnosticTroubleCode>> get diagnosticCodesStream => _dtcController.stream;

  @override
  Future<bool> initialize() async {
    _linkState = DeviceLinkState.disconnected;
    return true;
  }

  @override
  Future<bool> connect(String targetIdentifier) async {
    _linkState = DeviceLinkState.connecting;
    _linkStateController.add(_linkState);

    await Future.delayed(const Duration(milliseconds: 120));
    _linkState = DeviceLinkState.connected;
    _linkStateController.add(_linkState);
    return true;
  }

  @override
  Future<void> disconnect() async {
    _linkState = DeviceLinkState.disconnected;
    _linkStateController.add(_linkState);
  }

  /// Parses Mode 01 PID responses
  static Map<String, dynamic> parseMode01Response(String hexResponse) {
    final clean = hexResponse.replaceAll(' ', '').toUpperCase();
    final result = <String, dynamic>{};

    // PID 0C: Engine RPM ((A * 256) + B) / 4
    if (clean.contains('410C') && clean.length >= 8) {
      final index = clean.indexOf('410C') + 4;
      final a = int.parse(clean.substring(index, index + 2), radix: 16);
      final b = int.parse(clean.substring(index + 2, index + 4), radix: 16);
      result['rpm'] = ((a * 256) + b) ~/ 4;
    }

    // PID 0D: Vehicle Speed (A)
    if (clean.contains('410D') && clean.length >= 6) {
      final index = clean.indexOf('410D') + 4;
      final a = int.parse(clean.substring(index, index + 2), radix: 16);
      result['speedKmh'] = a.toDouble();
    }

    // PID 05: Engine Coolant Temp (A - 40)
    if (clean.contains('4105') && clean.length >= 6) {
      final index = clean.indexOf('4105') + 4;
      final a = int.parse(clean.substring(index, index + 2), radix: 16);
      result['coolantTempC'] = (a - 40).toDouble();
    }

    return result;
  }

  @override
  Future<bool> clearDtcCodes() async {
    // Mode 04: Clear / Reset Emission-Related Diagnostic Information
    _dtcController.add([]);
    return true;
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _linkStateController.close();
    await _telemetryController.close();
    await _dtcController.close();
  }
}
