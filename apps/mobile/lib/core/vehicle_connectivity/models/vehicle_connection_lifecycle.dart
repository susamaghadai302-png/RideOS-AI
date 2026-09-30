import 'package:flutter/foundation.dart';
import '../../vehicle_capabilities/models/universal_vehicle_capability_models.dart';

enum ConnectionLifecycleState {
  idle,
  scanning,
  deviceFound,
  identifying,
  pairing,
  connecting,
  authenticating,
  capabilityDiscovery,
  connected,
  telemetryActive,
  // Failure / Terminating States
  permissionDenied,
  pairingFailed,
  connectionFailed,
  unsupportedDevice,
  protocolUnavailable,
  hardwareRequired,
  timeout,
  disconnected,
}

@immutable
class ConnectionDiagnosticsSession {
  final ConnectionLifecycleState state;
  final String? deviceName;
  final String? macAddress;
  final ModelVariant? resolvedVariant;
  final String protocolName;
  final int rssi;
  final int latencyMs;
  final int packetsReceived;
  final int reconnectAttempts;
  final DateTime? lastPacketTimestamp;
  final String? failureReason;
  final bool isWebSandbox;

  const ConnectionDiagnosticsSession({
    required this.state,
    this.deviceName,
    this.macAddress,
    this.resolvedVariant,
    this.protocolName = 'None',
    this.rssi = 0,
    this.latencyMs = 0,
    this.packetsReceived = 0,
    this.reconnectAttempts = 0,
    this.lastPacketTimestamp,
    this.failureReason,
    this.isWebSandbox = false,
  });

  bool get isConnected => state == ConnectionLifecycleState.connected || state == ConnectionLifecycleState.telemetryActive;
}
