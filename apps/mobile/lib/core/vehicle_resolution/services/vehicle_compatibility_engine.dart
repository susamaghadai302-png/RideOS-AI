import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../vehicle_protocols/protocol_detector.dart';
import '../../vehicle_protocols/protocol_adapter_manager.dart';
import '../../vehicle_protocols/protocol_adapter.dart';
import '../models/vehicle_profile.dart';
import 'vehicle_registry.dart';
import 'vehicle_model_registry.dart';

enum CompatibilityStatus {
  supported,
  partiallySupported,
  identificationRequired,
  protocolNotSupported,
  connected,
}

class CompatibilityReport {
  final CompatibilityStatus status;
  final VehicleProfile profile;
  final ProtocolDetectionResult detection;
  final List<String> supportedCapabilities;
  final List<String> unsupportedCapabilities;
  final bool has3DModel;
  final bool allowsWriteControls;
  final String explanation;

  const CompatibilityReport({
    required this.status,
    required this.profile,
    required this.detection,
    required this.supportedCapabilities,
    required this.unsupportedCapabilities,
    required this.has3DModel,
    required this.allowsWriteControls,
    required this.explanation,
  });
}

class VehicleCompatibilityEngine {
  static final VehicleCompatibilityEngine _instance = VehicleCompatibilityEngine._internal();
  factory VehicleCompatibilityEngine() => _instance;
  VehicleCompatibilityEngine._internal();

  final ProtocolDetector _detector = ProtocolDetector();
  final VehicleRegistry _registry = VehicleRegistry();
  final VehicleModelRegistry _modelRegistry = VehicleModelRegistry();
  final ProtocolAdapterManager _adapterManager = ProtocolAdapterManager();

  /// Evaluates device scan advertisement data against protocol adapters and vehicle registry
  CompatibilityReport evaluateDevice({
    required BluetoothDevice device,
    required AdvertisementData advertisementData,
  }) {
    final detection = _detector.detectFromScan(
      device: device,
      advertisementData: advertisementData,
    );

    // 1. Check Protocol Support
    if (!detection.isSupported) {
      final defaultProfile = _registry.defaultProfile;
      return CompatibilityReport(
        status: detection.state == ProtocolDetectionState.ambiguous
            ? CompatibilityStatus.identificationRequired
            : CompatibilityStatus.protocolNotSupported,
        profile: defaultProfile,
        detection: detection,
        supportedCapabilities: const [],
        unsupportedCapabilities: const [
          'READ_SPEED',
          'READ_RPM',
          'READ_BATTERY',
          'READ_DIAGNOSTICS',
          'CONTROL_LIGHTS',
        ],
        has3DModel: false,
        allowsWriteControls: false,
        explanation: detection.explanation,
      );
    }

    // 2. Resolve Vehicle Profile
    final deviceName = advertisementData.advName.isNotEmpty ? advertisementData.advName : device.platformName;
    final matchedProfile = _registry.findProfileByBluetoothName(deviceName) ?? _registry.defaultProfile;

    // 3. Resolve Capabilities from Protocol Adapter
    final adapter = _adapterManager.getAdapter(detection.adapterId) ?? _adapterManager.getAdapter('generic_ble')!;
    final capabilities = adapter.getSupportedFeatures();

    // 4. Resolve 3D Model Config
    final modelConfig = _modelRegistry.getModelConfig(matchedProfile.id);

    final isFullySupported = detection.isSupported && (capabilities.contains('speed') || capabilities.contains('readSpeed'));

    return CompatibilityReport(
      status: isFullySupported ? CompatibilityStatus.supported : CompatibilityStatus.partiallySupported,
      profile: matchedProfile,
      detection: detection,
      supportedCapabilities: capabilities,
      unsupportedCapabilities: _getUnsupportedCapabilities(capabilities),
      has3DModel: modelConfig.modelAvailable,
      allowsWriteControls: capabilities.any((c) => c.startsWith('control')),
      explanation: isFullySupported
          ? 'Fully verified automotive protocol with bidirectional telemetry.'
          : 'Partially supported: basic telemetry available; advanced ECU write controls disabled.',
    );
  }

  List<String> _getUnsupportedCapabilities(List<String> active) {
    const allPossible = [
      'readSpeed',
      'readRpm',
      'readBattery',
      'readFuel',
      'readTemperature',
      'readOdometer',
      'readDiagnostics',
      'controlLights',
      'controlHorn',
      'controlLock',
      'controlRidingMode',
    ];
    return allPossible.where((c) => !active.contains(c)).toList();
  }
}
