import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/universal_discovery_pipeline_models.dart';
import '../models/packet_capture_models.dart';
import '../transports/vehicle_transport.dart';
import 'universal_protocol_detector.dart';
import 'structured_hardware_diagnostic_logger.dart';

class UniversalVehicleDiscoveryPipeline {
  static final UniversalVehicleDiscoveryPipeline _instance = UniversalVehicleDiscoveryPipeline._internal();
  factory UniversalVehicleDiscoveryPipeline() => _instance;

  PipelineLifecycleState _currentState = PipelineLifecycleState.idle;
  PipelineLifecycleState get currentState => _currentState;

  final _stateController = StreamController<PipelineLifecycleState>.broadcast();
  Stream<PipelineLifecycleState> get stateStream => _stateController.stream;

  PipelineDiscoveryResult? _latestDiscovery;
  PipelineDiscoveryResult? get latestDiscovery => _latestDiscovery;

  final _detector = UniversalProtocolDetector();
  final _logger = StructuredHardwareDiagnosticLogger();
  bool _isCanceled = false;

  UniversalVehicleDiscoveryPipeline._internal();

  /// Runs the full 12-step discovery and connection flow
  Future<bool> runPipeline({
    required String deviceName,
    required String macAddress,
    required List<String> advertisedServices,
    required VehicleTransport transport,
    bool hasPermissions = true,
    bool isBluetoothEnabled = true,
    bool autoConfirm = true,
  }) async {
    _isCanceled = false;

    // 1. Permission Check
    _transitionTo(PipelineLifecycleState.permissionCheck, macAddress, 'Verifying Bluetooth and Nearby permissions');
    await Future.delayed(const Duration(milliseconds: 100));
    if (!hasPermissions) {
      _transitionTo(PipelineLifecycleState.error, macAddress, 'Bluetooth permissions denied');
      return false;
    }
    if (_isCanceled) return false;

    // 2. Bluetooth Check
    _transitionTo(PipelineLifecycleState.bluetoothCheck, macAddress, 'Checking Bluetooth radio state');
    await Future.delayed(const Duration(milliseconds: 100));
    if (!isBluetoothEnabled) {
      _transitionTo(PipelineLifecycleState.error, macAddress, 'Bluetooth adapter disabled');
      return false;
    }
    if (_isCanceled) return false;

    // 3. Scanning
    _transitionTo(PipelineLifecycleState.scanning, macAddress, 'Scanning nearby vehicle advertisements');
    await Future.delayed(const Duration(milliseconds: 150));
    if (_isCanceled) return false;

    // 4. Device Found
    _transitionTo(PipelineLifecycleState.deviceFound, macAddress, 'Device discovered: $deviceName');
    await Future.delayed(const Duration(milliseconds: 100));
    if (_isCanceled) return false;

    // 5. Identification
    _transitionTo(PipelineLifecycleState.identification, macAddress, 'Matching GATT UUID signatures');
    final compatibility = _detector.detectProtocol(
      deviceName: deviceName,
      advertisedServices: advertisedServices,
      macAddress: macAddress,
    );
    await Future.delayed(const Duration(milliseconds: 100));
    if (_isCanceled) return false;

    // 6. Capability Discovery
    _transitionTo(PipelineLifecycleState.capabilityDiscovery, macAddress, 'Resolving display and telemetry profiles');
    DisplayIntegrationType displayType = DisplayIntegrationType.none;
    if (compatibility.hasTurnByTurnNav) {
      displayType = compatibility.modelName.contains('Tripper') || compatibility.variantTrim.contains('Tripper')
          ? DisplayIntegrationType.tripperPod
          : DisplayIntegrationType.tftMirror;
    }
    await Future.delayed(const Duration(milliseconds: 100));
    if (_isCanceled) return false;

    // 7. Compatibility Check
    _transitionTo(PipelineLifecycleState.compatibilityCheck, macAddress, 'Compatibility status: ${compatibility.overallStatus.label}');
    _latestDiscovery = PipelineDiscoveryResult(
      deviceName: deviceName,
      deviceMac: macAddress,
      rssi: -58,
      compatibility: compatibility,
      displayType: displayType,
      verificationStatus: compatibility.verificationStatus,
      isUserConfirmed: autoConfirm,
    );
    await Future.delayed(const Duration(milliseconds: 100));
    if (_isCanceled) return false;

    // 8. User Confirmation
    if (!autoConfirm) {
      _transitionTo(PipelineLifecycleState.userConfirmation, macAddress, 'Awaiting user confirmation');
      return true; // Pauses at user confirmation
    }

    return await confirmAndConnect(transport: transport, macAddress: macAddress);
  }

  /// Continues pipeline from user confirmation to streaming
  Future<bool> confirmAndConnect({
    required VehicleTransport transport,
    required String macAddress,
  }) async {
    // 9. Connecting
    _transitionTo(PipelineLifecycleState.connecting, macAddress, 'Establishing secure GATT connection');
    final connected = await transport.connect(macAddress);
    if (!connected) {
      _transitionTo(PipelineLifecycleState.error, macAddress, 'GATT handshake failed');
      return false;
    }
    if (_isCanceled) return false;

    // 10. Connected
    _transitionTo(PipelineLifecycleState.connected, macAddress, 'Connected to peripheral');
    await Future.delayed(const Duration(milliseconds: 100));
    if (_isCanceled) return false;

    // 11. Streaming
    _transitionTo(PipelineLifecycleState.streaming, macAddress, 'Live telemetry streaming active');
    return true;
  }

  void cancel() {
    _isCanceled = true;
    _transitionTo(PipelineLifecycleState.idle, 'N/A', 'Discovery pipeline canceled by rider');
  }

  void _transitionTo(PipelineLifecycleState state, String deviceId, String message) {
    _currentState = state;
    _logger.log(
      eventType: DiagnosticEventType.connectionStateChange,
      severity: state == PipelineLifecycleState.error ? DiagnosticSeverity.error : DiagnosticSeverity.info,
      deviceId: deviceId,
      message: 'Pipeline step: ${state.name} ($message)',
      metadata: {'step': state.name},
    );

    if (!_stateController.isClosed) {
      _stateController.add(_currentState);
    }
  }
}
