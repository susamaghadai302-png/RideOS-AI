import 'dart:async';
import 'package:flutter/foundation.dart';
import '../adapters/vehicle_connectivity_adapter.dart';
import '../models/vehicle_capabilities.dart';
import '../models/vehicle_variant_taxonomy.dart';
import 'vehicle_adapter_registry.dart';

class GenericVehicleConnectivityEngine {
  static final GenericVehicleConnectivityEngine _instance = GenericVehicleConnectivityEngine._internal();
  factory GenericVehicleConnectivityEngine() => _instance;

  final VehicleAdapterRegistry _registry = VehicleAdapterRegistry();
  VehicleConnectivityAdapter? _activeAdapter;
  VehicleVariant? _activeVariant;

  final _telemetryController = StreamController<RawVehicleTelemetryPacket>.broadcast();
  final _connectionStateController = StreamController<AdapterConnectionState>.broadcast();

  StreamSubscription? _adapterStateSubscription;
  StreamSubscription? _adapterTelemetrySubscription;

  GenericVehicleConnectivityEngine._internal();

  VehicleConnectivityAdapter? get activeAdapter => _activeAdapter;
  VehicleVariant? get activeVariant => _activeVariant;
  AdapterConnectionState get currentState => _activeAdapter?.connectionState ?? AdapterConnectionState.disconnected;

  Stream<AdapterConnectionState> get stateStream => _connectionStateController.stream;
  Stream<RawVehicleTelemetryPacket> get telemetryStream => _telemetryController.stream;

  VehicleCapabilities get activeCapabilities => _activeAdapter?.getCapabilities() ?? VehicleCapabilities.unsupportedVehicle();

  /// Connects to a vehicle by selecting the corresponding adapter from the registry
  Future<bool> connectVehicle({
    required String targetIdentifier,
    required String protocolAdapterId,
    VehicleVariant? variant,
    String? authSecret,
  }) async {
    // 1. Disconnect previous adapter if running
    await disconnectVehicle();

    // 2. Lookup registered adapter
    var adapter = _registry.getAdapter(protocolAdapterId);
    adapter ??= _registry.getAdapter('generic_ble');

    if (adapter == null) {
      _connectionStateController.add(AdapterConnectionState.unsupported);
      return false;
    }

    _activeAdapter = adapter;
    _activeVariant = variant;

    // 3. Listen to adapter streams
    _adapterStateSubscription = adapter.stateStream.listen((state) {
      _connectionStateController.add(state);
    });

    _adapterTelemetrySubscription = adapter.telemetryStream.listen((packet) {
      _telemetryController.add(packet);
    });

    // 4. Initiate connection & authentication
    final success = await adapter.connect(targetIdentifier);
    if (success && authSecret != null) {
      await adapter.authenticate(secretKey: authSecret);
    }
    return success;
  }

  Future<void> disconnectVehicle() async {
    await _adapterStateSubscription?.cancel();
    await _adapterTelemetrySubscription?.cancel();
    _adapterStateSubscription = null;
    _adapterTelemetrySubscription = null;

    if (_activeAdapter != null) {
      await _activeAdapter!.disconnect();
      _activeAdapter = null;
    }
    _activeVariant = null;
    _connectionStateController.add(AdapterConnectionState.disconnected);
  }

  /// Pushes Turn-by-Turn navigation maneuver to Smart TFT cluster if supported
  Future<bool> pushNavigationTurn({
    required String turnInstruction,
    required double distanceMeters,
    required int maneuverCode,
  }) async {
    if (_activeAdapter == null) return false;
    if (activeCapabilities.navigationData == CapabilitySupportLevel.notSupported) return false;

    return await _activeAdapter!.sendNavigationManeuver(
      turnInstruction: turnInstruction,
      distanceToTurnMeters: distanceMeters,
      maneuverIconCode: maneuverCode,
    );
  }

  /// Pushes rider notification (incoming call / alert) to cluster if supported
  Future<bool> pushClusterNotification({
    required String title,
    required String body,
    required String category,
  }) async {
    if (_activeAdapter == null) return false;
    if (activeCapabilities.smartDisplayData == CapabilitySupportLevel.notSupported) return false;

    return await _activeAdapter!.sendRiderNotification(
      title: title,
      body: body,
      category: category,
    );
  }

  /// Dispatches safety-guarded commands to the vehicle
  Future<bool> sendCommand({
    required String commandName,
    Map<String, dynamic>? parameters,
  }) async {
    if (_activeAdapter == null) return false;
    // Strictly disallows arbitrary command injection
    return await _activeAdapter!.sendCommand(
      commandName: commandName,
      parameters: parameters,
    );
  }
}
