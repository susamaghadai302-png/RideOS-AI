import 'package:flutter/foundation.dart';
import '../models/packet_capture_models.dart';
import '../../vehicle_capabilities/models/universal_protocol_detection_models.dart';

enum PipelineLifecycleState {
  idle,
  permissionCheck,
  bluetoothCheck,
  scanning,
  deviceFound,
  identification,
  capabilityDiscovery,
  compatibilityCheck,
  userConfirmation,
  connecting,
  connected,
  streaming,
  error;

  String get stepDescription {
    switch (this) {
      case PipelineLifecycleState.idle:
        return 'System initialized. Ready for scan.';
      case PipelineLifecycleState.permissionCheck:
        return 'Verifying Nearby Devices and Bluetooth permissions...';
      case PipelineLifecycleState.bluetoothCheck:
        return 'Checking Bluetooth radio adapter availability...';
      case PipelineLifecycleState.scanning:
        return 'Scanning for nearby two-wheeler Bluetooth/BLE signals...';
      case PipelineLifecycleState.deviceFound:
        return 'Vehicle peripheral detected. Reading advertisement packet...';
      case PipelineLifecycleState.identification:
        return 'Analyzing GATT UUID signatures and manufacturer metadata...';
      case PipelineLifecycleState.capabilityDiscovery:
        return 'Resolving telemetry, display, and diagnostic characteristics...';
      case PipelineLifecycleState.compatibilityCheck:
        return 'Evaluating capability matrix and generating compatibility report...';
      case PipelineLifecycleState.userConfirmation:
        return 'Awaiting rider connection confirmation...';
      case PipelineLifecycleState.connecting:
        return 'Initiating secure GATT connection handshake...';
      case PipelineLifecycleState.connected:
        return 'GATT link active. Subscribing to telemetry streams...';
      case PipelineLifecycleState.streaming:
        return 'Live vehicle telemetry streaming active.';
      case PipelineLifecycleState.error:
        return 'Pipeline halted due to error.';
    }
  }
}

enum DisplayIntegrationType {
  tftMirror,
  segmentedLcd,
  tripperPod,
  companionAppOnly,
  none;

  String get label {
    switch (this) {
      case DisplayIntegrationType.tftMirror:
        return 'Full TFT Display Mirroring';
      case DisplayIntegrationType.segmentedLcd:
        return 'Segmented LCD HUD Icons';
      case DisplayIntegrationType.tripperPod:
        return 'Dedicated Navigation Pod';
      case DisplayIntegrationType.companionAppOnly:
        return 'Companion App Telemetry Only';
      case DisplayIntegrationType.none:
        return 'No Connected Display';
    }
  }
}

@immutable
class PipelineDiscoveryResult {
  final String deviceName;
  final String deviceMac;
  final int rssi;
  final DetailedCompatibilityBreakdown compatibility;
  final DisplayIntegrationType displayType;
  final HardwareBenchVerificationStatus verificationStatus;
  final bool isUserConfirmed;

  const PipelineDiscoveryResult({
    required this.deviceName,
    required this.deviceMac,
    required this.rssi,
    required this.compatibility,
    required this.displayType,
    required this.verificationStatus,
    this.isUserConfirmed = false,
  });

  Map<String, dynamic> toJson() => {
    'deviceName': deviceName,
    'deviceMac': deviceMac,
    'rssi': rssi,
    'displayType': displayType.label,
    'verificationStatus': verificationStatus.label,
    'isUserConfirmed': isUserConfirmed,
    'compatibility': compatibility.toJson(),
  };
}
