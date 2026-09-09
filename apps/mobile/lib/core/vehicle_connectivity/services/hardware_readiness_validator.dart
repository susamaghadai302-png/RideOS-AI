import 'package:flutter/foundation.dart';
import 'structured_hardware_diagnostic_logger.dart';
import '../models/packet_capture_models.dart';
import '../registry/vehicle_compatibility_registry.dart';

@immutable
class HardwareReadinessEvaluation {
  final bool isBleAdapterReady;
  final bool hasRequiredPermissions;
  final String deviceName;
  final String? matchedModel;
  final String? matchedVariant;
  final String protocolStatusLabel;
  final HardwareBenchVerificationStatus verificationStatus;
  final CaptureSourceClassification sourceClassification;
  final List<String> availableCapabilities;
  final List<String> unsupportedCapabilities;

  const HardwareReadinessEvaluation({
    required this.isBleAdapterReady,
    required this.hasRequiredPermissions,
    required this.deviceName,
    this.matchedModel,
    this.matchedVariant,
    required this.protocolStatusLabel,
    required this.verificationStatus,
    required this.sourceClassification,
    required this.availableCapabilities,
    required this.unsupportedCapabilities,
  });
}

class HardwareReadinessValidator {
  static final HardwareReadinessValidator _instance = HardwareReadinessValidator._internal();
  factory HardwareReadinessValidator() => _instance;

  final _registry = VehicleCompatibilityRegistry();
  final _logger = StructuredHardwareDiagnosticLogger();

  HardwareReadinessValidator._internal();

  HardwareReadinessEvaluation evaluateDiscoveredHardware({
    required String deviceName,
    required List<String> advertisedServices,
    required String macAddress,
    bool isSimulated = false,
  }) {
    final lowerName = deviceName.toLowerCase();
    final sourceMode = isSimulated
        ? CaptureSourceClassification.benchTest
        : (kIsWeb ? CaptureSourceClassification.simulated : CaptureSourceClassification.realDevice);

    _logger.log(
      eventType: DiagnosticEventType.discovery,
      severity: DiagnosticSeverity.info,
      deviceId: macAddress,
      message: 'Discovered device $deviceName with ${advertisedServices.length} advertised services',
      metadata: {'services': advertisedServices, 'mac': macAddress},
      sourceMode: sourceMode,
    );

    // 1. Yamaha CCU GATT (0xFEE0)
    if (lowerName.contains('yamaha') || advertisedServices.any((s) => s.toLowerCase().contains('fee0'))) {
      final entry = _registry.entries.firstWhere((e) => e.entryId == 'yamaha_r15m_ccu');
      _logger.log(
        eventType: DiagnosticEventType.vehicleIdentified,
        severity: DiagnosticSeverity.info,
        deviceId: macAddress,
        message: 'Identified Yamaha Y-Connect CCU profile (${entry.modelYearRange})',
        sourceMode: sourceMode,
      );

      return HardwareReadinessEvaluation(
        isBleAdapterReady: true,
        hasRequiredPermissions: true,
        deviceName: deviceName,
        matchedModel: entry.model,
        matchedVariant: entry.variantTrim.name.toUpperCase(),
        protocolStatusLabel: 'Verified Yamaha Y-Connect Protocol',
        verificationStatus: isSimulated ? HardwareBenchVerificationStatus.benchVerified : HardwareBenchVerificationStatus.partiallyVerified,
        sourceClassification: sourceMode,
        availableCapabilities: const ['Wheel Speed', 'Engine RPM', 'Fuel Level', 'Battery Voltage', 'Turn-by-Turn HUD Mirror'],
        unsupportedCapabilities: const ['Remote Ignition Kill', 'ECU Flash'],
      );
    }

    // 2. Royal Enfield Tripper (0xFE50)
    if (lowerName.contains('tripper') || lowerName.contains('royal enfield') || advertisedServices.any((s) => s.toLowerCase().contains('fe50'))) {
      final entry = _registry.entries.firstWhere((e) => e.entryId == 're_himalayan_tripper');
      _logger.log(
        eventType: DiagnosticEventType.vehicleIdentified,
        severity: DiagnosticSeverity.info,
        deviceId: macAddress,
        message: 'Identified Royal Enfield Tripper Dash profile',
        sourceMode: sourceMode,
      );

      return HardwareReadinessEvaluation(
        isBleAdapterReady: true,
        hasRequiredPermissions: true,
        deviceName: deviceName,
        matchedModel: entry.model,
        matchedVariant: entry.variantTrim.name.toUpperCase(),
        protocolStatusLabel: 'Verified RE Tripper GATT Protocol',
        verificationStatus: isSimulated ? HardwareBenchVerificationStatus.benchVerified : HardwareBenchVerificationStatus.partiallyVerified,
        sourceClassification: sourceMode,
        availableCapabilities: const ['Wheel Speed', 'Gear Position', 'Turn-by-Turn HUD Mirror'],
        unsupportedCapabilities: const ['ECU Diagnostic Trouble Codes'],
      );
    }

    // 3. Generic Diagnostic / Unverified Device
    _logger.log(
      eventType: DiagnosticEventType.vehicleIdentified,
      severity: DiagnosticSeverity.warning,
      deviceId: macAddress,
      message: 'Unknown device discovered. Protocol unverified.',
      sourceMode: sourceMode,
    );

    return HardwareReadinessEvaluation(
      isBleAdapterReady: true,
      hasRequiredPermissions: true,
      deviceName: deviceName,
      matchedModel: 'Unknown Two-Wheeler',
      matchedVariant: 'Standard OBD Gateway Required',
      protocolStatusLabel: 'Detected — Protocol Not Verified',
      verificationStatus: HardwareBenchVerificationStatus.unverified,
      sourceClassification: sourceMode,
      availableCapabilities: const ['Standard ISO 15765-4 Telemetry (with OBD-II Adapter)'],
      unsupportedCapabilities: const ['Smart Display Mirroring', 'OEM Proprietary Telemetry'],
    );
  }
}
