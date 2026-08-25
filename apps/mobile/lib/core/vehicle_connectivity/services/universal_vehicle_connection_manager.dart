import 'dart:async';
import 'package:flutter/foundation.dart';
import '../transports/vehicle_transport.dart';
import '../registry/vehicle_compatibility_registry.dart';

enum ConnectionCategory {
  bluetoothAudioOnly,
  smartDisplay,
  bleGattTelemetry,
  diagnosticGateway,
  oemCloudApi,
}

enum ConnectionLifecyclePhase {
  idle,
  scanning,
  discovered,
  identifying,
  pairing,
  connecting,
  negotiatingCapabilities,
  connected,
  telemetryActive,
  disconnected,
  error,
}

@immutable
class UniversalConnectionState {
  final ConnectionLifecyclePhase phase;
  final CompatibilityRegistryEntry? activeProfile;
  final ConnectionCategory category;
  final VehicleTransportType transportType;
  final int signalRssi;
  final int latencyMs;
  final String? errorMessage;
  final bool isSimulated;

  const UniversalConnectionState({
    required this.phase,
    this.activeProfile,
    this.category = ConnectionCategory.bluetoothAudioOnly,
    this.transportType = VehicleTransportType.ble,
    this.signalRssi = 0,
    this.latencyMs = 0,
    this.errorMessage,
    this.isSimulated = false,
  });

  bool get isConnected => phase == ConnectionLifecyclePhase.connected || phase == ConnectionLifecyclePhase.telemetryActive;
}

class UniversalVehicleConnectionManager {
  static final UniversalVehicleConnectionManager _instance = UniversalVehicleConnectionManager._internal();
  factory UniversalVehicleConnectionManager() => _instance;

  final _registry = VehicleCompatibilityRegistry();
  VehicleTransport? _activeTransport;

  final _stateController = StreamController<UniversalConnectionState>.broadcast();
  Stream<UniversalConnectionState> get stateStream => _stateController.stream;

  UniversalConnectionState _currentState = const UniversalConnectionState(
    phase: ConnectionLifecyclePhase.idle,
  );
  UniversalConnectionState get currentState => _currentState;

  UniversalVehicleConnectionManager._internal();

  /// Initiates discovery and auto-detection
  Future<void> connectVehicle({
    required String deviceName,
    required List<String> advertisedServices,
    required String endpointOrMac,
    bool isSimulated = false,
  }) async {
    _updateState(UniversalConnectionState(
      phase: ConnectionLifecyclePhase.scanning,
      isSimulated: isSimulated,
    ));

    await Future.delayed(const Duration(milliseconds: 150));
    _updateState(_currentState.copyWith(phase: ConnectionLifecyclePhase.discovered));

    await Future.delayed(const Duration(milliseconds: 150));
    _updateState(_currentState.copyWith(phase: ConnectionLifecyclePhase.identifying));

    // Match signature from compatibility registry
    final profile = _registry.matchDeviceSignature(
      deviceName: deviceName,
      advertisedServices: advertisedServices,
    );

    ConnectionCategory category;
    switch (profile.primaryTransport) {
      case VehicleTransportType.oemApi:
        category = ConnectionCategory.oemCloudApi;
        break;
      case VehicleTransportType.obdGateway:
      case VehicleTransportType.canGateway:
      case VehicleTransportType.usbDiagnostic:
        category = ConnectionCategory.diagnosticGateway;
        break;
      case VehicleTransportType.ble:
      default:
        category = profile.supportedCommands.isNotEmpty
            ? ConnectionCategory.smartDisplay
            : ConnectionCategory.bleGattTelemetry;
        break;
    }

    _activeTransport = isSimulated ? SimulatorTransport() : BleTransport();
    await _activeTransport!.initialize();

    _updateState(_currentState.copyWith(
      phase: ConnectionLifecyclePhase.pairing,
      activeProfile: profile,
      category: category,
      transportType: profile.primaryTransport,
    ));

    await Future.delayed(const Duration(milliseconds: 150));
    _updateState(_currentState.copyWith(phase: ConnectionLifecyclePhase.connecting));

    final connected = await _activeTransport!.connect(endpointOrMac);
    if (!connected) {
      _updateState(_currentState.copyWith(
        phase: ConnectionLifecyclePhase.error,
        errorMessage: 'Failed to establish physical transport link.',
      ));
      return;
    }

    _updateState(_currentState.copyWith(phase: ConnectionLifecyclePhase.negotiatingCapabilities));

    await Future.delayed(const Duration(milliseconds: 150));
    _updateState(_currentState.copyWith(
      phase: ConnectionLifecyclePhase.connected,
      signalRssi: -52,
      latencyMs: 18,
    ));

    await Future.delayed(const Duration(milliseconds: 100));
    _updateState(_currentState.copyWith(phase: ConnectionLifecyclePhase.telemetryActive));
  }

  /// Strict Command Safety Guard: Checks registry whitelist and read-only status
  Future<bool> sendVehicleCommand({
    required String commandName,
    required Map<String, dynamic> parameters,
  }) async {
    final profile = _currentState.activeProfile;
    if (profile == null) return false;

    // 1. If profile is marked read-only, block all commands
    if (profile.isReadOnly) return false;

    // 2. Reject safety-critical or unauthorized commands
    final lower = commandName.toLowerCase();
    if (lower.contains('ecu') || lower.contains('immobilizer') || lower.contains('throttle') || lower.contains('brake')) {
      return false;
    }

    // 3. Command must exist in explicit whitelist
    if (!profile.supportedCommands.contains(commandName)) {
      return false;
    }

    return true;
  }

  Future<void> disconnect() async {
    await _activeTransport?.disconnect();
    _updateState(UniversalConnectionState(
      phase: ConnectionLifecyclePhase.disconnected,
      activeProfile: _currentState.activeProfile,
      category: _currentState.category,
      transportType: _currentState.transportType,
    ));
  }

  void _updateState(UniversalConnectionState state) {
    _currentState = state;
    if (!_stateController.isClosed) {
      _stateController.add(_currentState);
    }
  }
}

extension UniversalConnectionStateCopyWith on UniversalConnectionState {
  UniversalConnectionState copyWith({
    ConnectionLifecyclePhase? phase,
    CompatibilityRegistryEntry? activeProfile,
    ConnectionCategory? category,
    VehicleTransportType? transportType,
    int? signalRssi,
    int? latencyMs,
    String? errorMessage,
    bool? isSimulated,
  }) {
    return UniversalConnectionState(
      phase: phase ?? this.phase,
      activeProfile: activeProfile ?? this.activeProfile,
      category: category ?? this.category,
      transportType: transportType ?? this.transportType,
      signalRssi: signalRssi ?? this.signalRssi,
      latencyMs: latencyMs ?? this.latencyMs,
      errorMessage: errorMessage ?? this.errorMessage,
      isSimulated: isSimulated ?? this.isSimulated,
    );
  }
}
