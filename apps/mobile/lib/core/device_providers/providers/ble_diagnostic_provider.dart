import 'dart:async';
import '../interfaces/device_provider.dart';
import '../models/normalized_telemetry_models.dart';

class BleDiagnosticProvider implements DeviceProvider {
  @override
  String get providerId => 'ble_diagnostic_provider';

  @override
  String get displayName => 'Generic BLE Diagnostic Adapter';

  @override
  TelemetryDataSource get dataSourceClassification => TelemetryDataSource.realDevice;

  @override
  bool get canClearDtcCodes => false; // Generic BLE GATT does not allow arbitrary ECU flash/clear

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

    // In a real device setup, this binds to FlutterBluePlus target characteristic stream
    await Future.delayed(const Duration(milliseconds: 100));
    _linkState = DeviceLinkState.connected;
    _linkStateController.add(_linkState);
    return true;
  }

  @override
  Future<void> disconnect() async {
    _linkState = DeviceLinkState.disconnected;
    _linkStateController.add(_linkState);
  }

  @override
  Future<bool> clearDtcCodes() async {
    return false; // Hardware safety constraint
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _linkStateController.close();
    await _telemetryController.close();
    await _dtcController.close();
  }
}
