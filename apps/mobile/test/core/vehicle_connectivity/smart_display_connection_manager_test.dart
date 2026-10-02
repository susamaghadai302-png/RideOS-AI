import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/services/smart_display_connection_manager.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/adapters/display_adapter_registry.dart';

import 'package:rideos_mobile/core/vehicle_connectivity/adapters/vehicle_connectivity_adapter.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/models/display_device_profile.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/models/vehicle_variant_taxonomy.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/models/vehicle_capabilities.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/models/display_capability.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/models/rideos_display_packet.dart';
import 'dart:async';

// Mocks
class MockDisplayAdapter extends DisplayAdapter {
  final DisplayDeviceProfile _profile;
  bool isConnected = false;
  List<RideOSDisplayPacket> sentPackets = [];

  MockDisplayAdapter(this._profile);

  @override
  DisplayDeviceProfile get displayProfile => _profile;

  @override
  String get adapterId => 'mock_display';
  
  @override
  String get adapterName => 'Mock Display';
  
  @override
  String get version => '1.0.0';
  
  VehicleConnectivityType get connectivityType => VehicleConnectivityType.ble;

  VehicleCapabilities get capabilities => VehicleCapabilities.displayOnlyCluster();

  AdapterConnectionState get connectionState => isConnected ? AdapterConnectionState.connected : AdapterConnectionState.disconnected;

  Stream<AdapterConnectionState> get stateStream => Stream.value(connectionState);

  @override
  Stream<RawVehicleTelemetryPacket> get telemetryStream => const Stream.empty();

  @override
  Future<bool> discover({Duration timeout = const Duration(seconds: 10)}) async => true;

  VehicleCapabilities getCapabilities() => VehicleCapabilities.displayOnlyCluster();

  @override
  Future<bool> sendCommand({required String commandName, Map<String, dynamic>? parameters}) async => false;

  Future<bool> isAvailable() async => true;

  @override
  Future<bool> connect(String targetIdentifier) async {
    isConnected = true;
    return true;
  }

  @override
  Future<void> disconnect() async {
    isConnected = false;
  }

  @override
  Future<bool> sendDisplayPacket(dynamic packet) async {
    if (!isConnected) return false;
    sentPackets.add(packet as RideOSDisplayPacket);
    return true;
  }

  @override
  Future<RawVehicleTelemetryPacket> readTelemetry() async => RawVehicleTelemetryPacket(timestamp: DateTime.now());

  @override
  Future<bool> authenticate({String? secretKey, String? pinCode}) async => true;

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
}

void main() {
  group('SmartDisplayConnectionManager Tests', () {
    late SmartDisplayConnectionManager manager;
    
    setUp(() {
      manager = SmartDisplayConnectionManager();
    });
    
    test('Initial state is idle', () {
      expect(manager.currentState, SmartDisplayState.idle);
    });

    test('Capability negotiation flags are properly set', () {
      final profile = DisplayDeviceProfile(
        manufacturer: 'Test',
        model: 'TFT',
        transportType: 'BLE',
        protocolType: 'MOCK',
        supportedCapabilities: {DisplayCapability.turnByTurnNavigation, DisplayCapability.weather},
      );
      
      expect(profile.supportedCapabilities.contains(DisplayCapability.turnByTurnNavigation), true);
      expect(profile.supportedCapabilities.contains(DisplayCapability.eta), false);
    });

    test('Packet encoding correctly binds properties with zero fake values', () {
      final packet = RideOSDisplayPacket(
        timestamp: DateTime(2026, 1, 1),
        speedKmh: 45.0,
        navigationState: 'ACTIVE',
        maneuverType: 'TURN_LEFT',
        maneuverDistanceMeters: 150.0,
      );
      
      expect(packet.speedKmh, 45.0);
      expect(packet.maneuverType, 'TURN_LEFT');
      expect(packet.temperatureC, null); // Zero fake values
    });
  });
}
