import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/services/phase3_validation_controller.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/adapters/vehicle_connectivity_adapter.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/models/vehicle_capabilities.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/models/vehicle_variant_taxonomy.dart';

class MockValidationAdapter implements VehicleConnectivityAdapter {
  @override
  final String adapterId = 'mock_validation';
  @override
  final String adapterName = 'Mock Validation Adapter';
  @override
  final String version = '1.0';
  @override
  final VehicleConnectivityType connectivityType = VehicleConnectivityType.obd2Gateway;
  @override
  final VehicleCapabilities capabilities = VehicleCapabilities.standardObdGateway();

  final _stateController = StreamController<AdapterConnectionState>.broadcast();
  final _telemetryController = StreamController<RawVehicleTelemetryPacket>.broadcast();
  AdapterConnectionState _currentState = AdapterConnectionState.disconnected;

  @override
  AdapterConnectionState get connectionState => _currentState;
  @override
  Stream<AdapterConnectionState> get stateStream => _stateController.stream;
  @override
  Stream<RawVehicleTelemetryPacket> get telemetryStream => _telemetryController.stream;

  bool shouldFailConnect = false;
  bool shouldReturnNoTelemetry = false;

  @override
  Future<bool> discover({Duration timeout = const Duration(seconds: 10)}) async => true;

  @override
  Future<bool> connect(String targetIdentifier) async {
    if (shouldFailConnect) return false;
    _currentState = AdapterConnectionState.connected;
    return true;
  }

  @override
  Future<bool> authenticate({String? secretKey, String? pinCode}) async => true;

  @override
  Future<void> disconnect() async {
    _currentState = AdapterConnectionState.disconnected;
  }

  @override
  VehicleCapabilities getCapabilities() => capabilities;

  @override
  Future<RawVehicleTelemetryPacket> readTelemetry() async {
    if (shouldReturnNoTelemetry) {
      return RawVehicleTelemetryPacket(
        timestamp: DateTime.now(),
        speedKmh: null,
        rpm: null,
        batteryVoltage: null,
        engineTempC: null,
        fuelLevelPct: null,
      );
    }
    return RawVehicleTelemetryPacket(
      timestamp: DateTime.now(),
      speedKmh: 45.0,
      rpm: 3000.0,
      batteryVoltage: 13.8,
      engineTempC: 85.0,
      fuelLevelPct: null,
    );
  }

  @override
  Future<List<String>> readDiagnostics() async => [];

  @override
  Future<bool> sendNavigationManeuver({
    required String turnInstruction,
    required double distanceToTurnMeters,
    required int maneuverIconCode,
  }) async => false;

  @override
  Future<bool> sendRiderNotification({
    required String title,
    required String body,
    required String category,
  }) async => false;

  @override
  Future<bool> sendCommand({
    required String commandName,
    Map<String, dynamic>? parameters,
  }) async => false;
}

void main() {
  group('Phase3ValidationController Tests', () {
    test('Successful validation flow generates COMPLETE status', () async {
      final adapter = MockValidationAdapter();
      final controller = Phase3ValidationController(adapter);
      final report = await controller.runValidation('fake_device');

      expect(report, contains('- Connection: PASS'));
      expect(report, contains('- Telemetry Received: Speed=45.0, RPM=3000.0, Temp=85.0'));
      expect(report, contains('- Disconnect: PASS'));
      expect(report, contains('- Reconnect: PASS'));
      expect(report, contains('Phase 3 status: COMPLETE'));
    });

    test('Failed connection aborts validation', () async {
      final adapter = MockValidationAdapter()..shouldFailConnect = true;
      final controller = Phase3ValidationController(adapter);
      final report = await controller.runValidation('fake_device');

      expect(report, contains('Failed to connect'));
      expect(report, isNot(contains('Phase 3 status: COMPLETE')));
    });

    test('No telemetry aborts validation', () async {
      final adapter = MockValidationAdapter()..shouldReturnNoTelemetry = true;
      final controller = Phase3ValidationController(adapter);
      final report = await controller.runValidation('fake_device');

      expect(report, contains('No actual telemetry values received'));
      expect(report, isNot(contains('Phase 3 status: COMPLETE')));
    });
  });
}
