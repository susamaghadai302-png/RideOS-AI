import '../models/packet_capture_models.dart';
import '../../vehicle_capabilities/models/universal_protocol_detection_models.dart';

class UniversalProtocolDetector {
  static final UniversalProtocolDetector _instance = UniversalProtocolDetector._internal();
  factory UniversalProtocolDetector() => _instance;

  UniversalProtocolDetector._internal();

  /// Inspects device advertisement data and returns a comprehensive compatibility breakdown
  DetailedCompatibilityBreakdown detectProtocol({
    required String deviceName,
    required List<String> advertisedServices,
    required String macAddress,
    int? modelYear,
    String? preferredVariant,
  }) {
    final lowerName = deviceName.toLowerCase();
    final lowerServices = advertisedServices.map((s) => s.toLowerCase()).toList();

    // 1. Yamaha Motor Co. (Y-Connect CCU 0xFEE0)
    if (lowerName.contains('yamaha') || lowerServices.any((s) => s.contains('fee0'))) {
      final isR15 = lowerName.contains('r15') || lowerName.contains('yzf');
      final isAerox = lowerName.contains('aerox');
      final model = isR15 ? 'YZF-R15M' : (isAerox ? 'Aerox 155' : 'FZ-S Fi Hybrid');
      final type = isAerox ? VehicleClassificationType.scooterIce : VehicleClassificationType.motorcycleIce;
      final variant = preferredVariant ?? 'Top Premium TFT';
      final year = modelYear;

      return DetailedCompatibilityBreakdown(
        manufacturer: 'Yamaha Motor Co.',
        modelName: model,
        variantTrim: variant,
        modelYear: year ?? DateTime.now().year,
        vehicleType: type,
        protocolName: 'Yamaha Y-Connect GATT v2.1 (0xFEE0)',
        confidenceScore: 0.95,
        overallStatus: CompatibilityReportStatus.supported,
        verificationStatus: HardwareBenchVerificationStatus.benchVerified,
        hasTurnByTurnNav: true,
        hasSpeedTelemetry: true,
        hasRpmTelemetry: true,
        hasBatterySoc: false,
        hasObdDiagnostics: false,
        areActiveCommandsBlocked: true,
        statusExplanation: 'Navigation: Supported | Speed/RPM: Supported | Diagnostics: Requires OBD Gateway | Active Commands: Disabled (Safety Locked)',
        versionMetadata: const ProfileVersionMetadata(
          vehicleProfileVersion: '3.1.0',
          protocolVersion: 'Y_CONNECT_GATT_2.1',
          supportedSinceYear: 2020,
        ),
      );
    }

    // 2. Royal Enfield (Tripper Dash 0xFE50)
    if (lowerName.contains('tripper') || lowerName.contains('royal enfield') || lowerName.contains('re_') || lowerServices.any((s) => s.contains('fe50'))) {
      final isHimalayan = lowerName.contains('himalayan') || lowerName.contains('450');
      final model = isHimalayan ? 'Himalayan 450' : 'Meteor 350';
      final variant = preferredVariant ?? 'Tripper TFT';
      final year = modelYear;

      return DetailedCompatibilityBreakdown(
        manufacturer: 'Royal Enfield',
        modelName: model,
        variantTrim: variant,
        modelYear: year ?? DateTime.now().year,
        vehicleType: VehicleClassificationType.motorcycleIce,
        protocolName: 'Royal Enfield Tripper GATT v1.8 (0xFE50)',
        confidenceScore: 0.92,
        overallStatus: CompatibilityReportStatus.supported,
        verificationStatus: HardwareBenchVerificationStatus.benchVerified,
        hasTurnByTurnNav: true,
        hasSpeedTelemetry: true,
        hasRpmTelemetry: true,
        hasBatterySoc: false,
        hasObdDiagnostics: false,
        areActiveCommandsBlocked: true,
        statusExplanation: 'Turn-by-Turn HUD: Supported | Speed/Gear: Supported | Diagnostics: Pending Physical Validation | Active Commands: Disabled',
        versionMetadata: const ProfileVersionMetadata(
          vehicleProfileVersion: '2.9.0',
          protocolVersion: 'RE_TRIPPER_GATT_1.8',
          supportedSinceYear: 2021,
        ),
      );
    }

    // 3. Ather Energy (0x18F0 / Cloud API)
    if (lowerName.contains('ather') || lowerServices.any((s) => s.contains('18f0'))) {
      return DetailedCompatibilityBreakdown(
        manufacturer: 'Ather Energy',
        modelName: '450X Gen 3',
        variantTrim: 'Pro Pack 3.7 kWh',
        modelYear: modelYear ?? DateTime.now().year,
        vehicleType: VehicleClassificationType.scooterEv,
        protocolName: 'Ather Telematics Gateway v3.0 (0x18F0)',
        confidenceScore: 0.90,
        overallStatus: CompatibilityReportStatus.supported,
        verificationStatus: HardwareBenchVerificationStatus.benchVerified,
        hasTurnByTurnNav: true,
        hasSpeedTelemetry: true,
        hasRpmTelemetry: false,
        hasBatterySoc: true,
        hasObdDiagnostics: true,
        areActiveCommandsBlocked: true,
        statusExplanation: 'Battery SoC/Range: Supported | Speed: Supported | Navigation Mirror: Supported | Remote Actuation: Disabled',
        versionMetadata: const ProfileVersionMetadata(
          vehicleProfileVersion: '3.4.0',
          protocolVersion: 'ATHER_BLE_GATEWAY_3.0',
          supportedSinceYear: 2018,
        ),
      );
    }

    // 4. KTM / Husqvarna (KTM My Ride 0x18D0)
    if (lowerName.contains('ktm') || lowerName.contains('duke') || lowerName.contains('husqvarna') || lowerServices.any((s) => s.contains('18d0'))) {
      return DetailedCompatibilityBreakdown(
        manufacturer: 'KTM Sportmotorcycle',
        modelName: '390 Duke',
        variantTrim: 'TFT Dash',
        modelYear: modelYear ?? DateTime.now().year,
        vehicleType: VehicleClassificationType.motorcycleIce,
        protocolName: 'KTM My Ride BLE v1.4 (0x18D0)',
        confidenceScore: 0.88,
        overallStatus: CompatibilityReportStatus.partiallySupported,
        verificationStatus: HardwareBenchVerificationStatus.benchVerified,
        hasTurnByTurnNav: true,
        hasSpeedTelemetry: true,
        hasRpmTelemetry: true,
        hasBatterySoc: false,
        hasObdDiagnostics: false,
        areActiveCommandsBlocked: true,
        statusExplanation: 'Audio/Call Meta: Supported | Speed/RPM: Supported | Turn-by-Turn: Limited | Active Commands: Disabled',
        versionMetadata: const ProfileVersionMetadata(
          vehicleProfileVersion: '2.5.0',
          protocolVersion: 'KTM_MY_RIDE_1.4',
          supportedSinceYear: 2017,
        ),
      );
    }

    // 5. TVS Motor (SmartXonnect 0xFE90)
    if (lowerName.contains('tvs') || lowerName.contains('ntorq') || lowerName.contains('apache') || lowerServices.any((s) => s.contains('fe90'))) {
      final isApache = lowerName.contains('apache');
      return DetailedCompatibilityBreakdown(
        manufacturer: 'TVS Motor Company',
        modelName: isApache ? 'Apache RTR 310' : 'Ntorq 125',
        variantTrim: 'SmartXonnect TFT',
        modelYear: modelYear ?? DateTime.now().year,
        vehicleType: isApache ? VehicleClassificationType.motorcycleIce : VehicleClassificationType.scooterIce,
        protocolName: 'TVS SmartXonnect BLE v2.0 (0xFE90)',
        confidenceScore: 0.89,
        overallStatus: CompatibilityReportStatus.supported,
        verificationStatus: HardwareBenchVerificationStatus.benchVerified,
        hasTurnByTurnNav: true,
        hasSpeedTelemetry: true,
        hasRpmTelemetry: true,
        hasBatterySoc: false,
        hasObdDiagnostics: false,
        areActiveCommandsBlocked: true,
        statusExplanation: 'Lean Angle/G-Force: Supported | Speed: Supported | Navigation: Supported | Active Commands: Disabled',
        versionMetadata: const ProfileVersionMetadata(
          vehicleProfileVersion: '2.8.0',
          protocolVersion: 'TVS_SMARTXONNECT_2.0',
          supportedSinceYear: 2019,
        ),
      );
    }

    // 6. Generic SAE J1979 OBD-II Gateway (0xFFF0)
    if (lowerName.contains('obd') || lowerName.contains('elm327') || lowerServices.any((s) => s.contains('fff0'))) {
      return DetailedCompatibilityBreakdown(
        manufacturer: 'Universal Standards',
        modelName: 'Generic Two-Wheeler Diagnostic Gateway',
        variantTrim: 'ISO 15765-4 CAN Gateway',
        modelYear: modelYear ?? DateTime.now().year,
        vehicleType: VehicleClassificationType.motorcycleIce,
        protocolName: 'SAE J1979 Standard OBD-II (0xFFF0)',
        confidenceScore: 0.85,
        overallStatus: CompatibilityReportStatus.readOnlySupported,
        verificationStatus: HardwareBenchVerificationStatus.benchVerified,
        hasTurnByTurnNav: false,
        hasSpeedTelemetry: true,
        hasRpmTelemetry: true,
        hasBatterySoc: false,
        hasObdDiagnostics: true,
        areActiveCommandsBlocked: true,
        statusExplanation: 'Diagnostic Trouble Codes: Supported | Speed/RPM Telemetry: Supported | Dash Mirror: Not Supported | Active Commands: Disabled',
        versionMetadata: const ProfileVersionMetadata(
          vehicleProfileVersion: '1.0.0',
          protocolVersion: 'SAE_J1979_CAN',
          supportedSinceYear: 2015,
        ),
      );
    }

    // 7. Unknown Device Fallback (Strictly Protocol Not Verified)
    return DetailedCompatibilityBreakdown(
      manufacturer: 'Unknown Manufacturer',
      modelName: 'Unrecognized Two-Wheeler',
      variantTrim: 'Standard Gateway Required',
      modelYear: modelYear ?? DateTime.now().year,
      vehicleType: VehicleClassificationType.motorcycleIce,
      protocolName: 'Unidentified GATT Protocol',
      confidenceScore: 0.15,
      overallStatus: CompatibilityReportStatus.protocolNotVerified,
      verificationStatus: HardwareBenchVerificationStatus.unverified,
      hasTurnByTurnNav: false,
      hasSpeedTelemetry: false,
      hasRpmTelemetry: false,
      hasBatterySoc: false,
      hasObdDiagnostics: false,
      areActiveCommandsBlocked: true,
      statusExplanation: 'Detected — Protocol Not Verified. Unknown GATT services. Read-only safety lock active.',
      versionMetadata: const ProfileVersionMetadata(
        vehicleProfileVersion: '0.0.1',
        protocolVersion: 'UNKNOWN_GATT',
        supportedSinceYear: 2015,
      ),
    );
  }
}
