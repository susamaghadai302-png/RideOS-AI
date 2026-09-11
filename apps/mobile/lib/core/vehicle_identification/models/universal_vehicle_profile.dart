import 'package:flutter/foundation.dart';
import '../../ecosystem/rideos_master_architecture.dart';

enum IdentificationSource {
  vinOcrScan('VIN CAMERA OCR'),
  vinManualInput('VIN MANUAL INPUT'),
  obdEcuQuery('OBD-II / CAN ECU MODE 09'),
  bleGattSignature('BLE GATT SIGNATURE'),
  manualCatalogSelection('MANUAL CATALOG SELECTION');

  final String label;
  const IdentificationSource(this.label);
}

enum UniversalIdentificationConfidence {
  exactVinMatch(1.0, 'EXACT VIN MATCH', 'Authoritative ISO 3779 VIN and factory record match verified.'),
  vinPlusEcuMatch(0.95, 'VIN + ECU MATCH', 'VIN decoded and matching ECU Calibration ID confirmed.'),
  modelYearPlusEcuMatch(0.80, 'MODEL/YEAR + ECU MATCH', 'Model family and ECU firmware signature resolved.'),
  partialMatch(0.50, 'PARTIAL MATCH', 'Manufacturer and segment identified; variant confirmation required.'),
  manualSelection(1.0, 'MANUAL VERIFIED', 'User-selected and verified from manufacturer catalog.'),
  unresolved(0.0, 'UNRESOLVED', 'Vehicle hardware or VIN unverified.');

  final double score;
  final String label;
  final String explanation;
  const UniversalIdentificationConfidence(this.score, this.label, this.explanation);

  bool get isHighConfidence => score >= 0.80;
}

enum VehicleCapabilitySupport {
  supported,
  partiallySupported,
  unsupported,
  requiresHardwareAdapter,
  requiresOemCloudApi;
}

@immutable
class UniversalVehicleCapabilities {
  final VehicleCapabilitySupport diagnostics;
  final VehicleCapabilitySupport liveTelemetry;
  final VehicleCapabilitySupport turnByTurnNavigation;
  final VehicleCapabilitySupport clusterScreenProjection;
  final VehicleCapabilitySupport handsFreeCalling;
  final VehicleCapabilitySupport androidAutoMirroring;
  final VehicleCapabilitySupport bleGattStreaming;
  final VehicleCapabilitySupport bluetoothClassicSpp;
  final VehicleCapabilitySupport usbOtgDirectTether;
  final VehicleCapabilitySupport wifiSocket;

  const UniversalVehicleCapabilities({
    this.diagnostics = VehicleCapabilitySupport.supported,
    this.liveTelemetry = VehicleCapabilitySupport.supported,
    this.turnByTurnNavigation = VehicleCapabilitySupport.supported,
    this.clusterScreenProjection = VehicleCapabilitySupport.supported,
    this.handsFreeCalling = VehicleCapabilitySupport.supported,
    this.androidAutoMirroring = VehicleCapabilitySupport.partiallySupported,
    this.bleGattStreaming = VehicleCapabilitySupport.supported,
    this.bluetoothClassicSpp = VehicleCapabilitySupport.supported,
    this.usbOtgDirectTether = VehicleCapabilitySupport.supported,
    this.wifiSocket = VehicleCapabilitySupport.supported,
  });

  bool get supportsDiagnostics => diagnostics == VehicleCapabilitySupport.supported || diagnostics == VehicleCapabilitySupport.partiallySupported;
  bool get supportsTelemetry => liveTelemetry == VehicleCapabilitySupport.supported;
  bool get supportsNavigation => turnByTurnNavigation == VehicleCapabilitySupport.supported;
  bool get supportsScreenProjection => clusterScreenProjection == VehicleCapabilitySupport.supported;
  bool get supportsCalling => handsFreeCalling == VehicleCapabilitySupport.supported;
  bool get supportsBluetooth => bleGattStreaming == VehicleCapabilitySupport.supported || bluetoothClassicSpp == VehicleCapabilitySupport.supported;
  bool get supportsBLE => bleGattStreaming == VehicleCapabilitySupport.supported;
  bool get supportsUSB => usbOtgDirectTether == VehicleCapabilitySupport.supported;
  bool get supportsWiFi => wifiSocket == VehicleCapabilitySupport.supported;
  bool get supportsAndroidAuto => androidAutoMirroring == VehicleCapabilitySupport.supported;

  Map<String, dynamic> toJson() => {
        'diagnostics': diagnostics.name,
        'liveTelemetry': liveTelemetry.name,
        'turnByTurnNavigation': turnByTurnNavigation.name,
        'clusterScreenProjection': clusterScreenProjection.name,
        'handsFreeCalling': handsFreeCalling.name,
        'androidAutoMirroring': androidAutoMirroring.name,
        'bleGattStreaming': bleGattStreaming.name,
        'bluetoothClassicSpp': bluetoothClassicSpp.name,
        'usbOtgDirectTether': usbOtgDirectTether.name,
        'wifiSocket': wifiSocket.name,
      };

  factory UniversalVehicleCapabilities.fromJson(Map<String, dynamic> json) => UniversalVehicleCapabilities(
        diagnostics: VehicleCapabilitySupport.values.firstWhere(
          (e) => e.name == json['diagnostics'],
          orElse: () => VehicleCapabilitySupport.supported,
        ),
        liveTelemetry: VehicleCapabilitySupport.values.firstWhere(
          (e) => e.name == json['liveTelemetry'],
          orElse: () => VehicleCapabilitySupport.supported,
        ),
        turnByTurnNavigation: VehicleCapabilitySupport.values.firstWhere(
          (e) => e.name == json['turnByTurnNavigation'],
          orElse: () => VehicleCapabilitySupport.supported,
        ),
        clusterScreenProjection: VehicleCapabilitySupport.values.firstWhere(
          (e) => e.name == json['clusterScreenProjection'],
          orElse: () => VehicleCapabilitySupport.supported,
        ),
        handsFreeCalling: VehicleCapabilitySupport.values.firstWhere(
          (e) => e.name == json['handsFreeCalling'],
          orElse: () => VehicleCapabilitySupport.supported,
        ),
        androidAutoMirroring: VehicleCapabilitySupport.values.firstWhere(
          (e) => e.name == json['androidAutoMirroring'],
          orElse: () => VehicleCapabilitySupport.partiallySupported,
        ),
        bleGattStreaming: VehicleCapabilitySupport.values.firstWhere(
          (e) => e.name == json['bleGattStreaming'],
          orElse: () => VehicleCapabilitySupport.supported,
        ),
        bluetoothClassicSpp: VehicleCapabilitySupport.values.firstWhere(
          (e) => e.name == json['bluetoothClassicSpp'],
          orElse: () => VehicleCapabilitySupport.supported,
        ),
        usbOtgDirectTether: VehicleCapabilitySupport.values.firstWhere(
          (e) => e.name == json['usbOtgDirectTether'],
          orElse: () => VehicleCapabilitySupport.supported,
        ),
        wifiSocket: VehicleCapabilitySupport.values.firstWhere(
          (e) => e.name == json['wifiSocket'],
          orElse: () => VehicleCapabilitySupport.supported,
        ),
      );
}

@immutable
class UniversalVehicleProfile {
  final String vehicleId;
  final String? vin;
  final VehicleDomainType domain;
  final String manufacturer;
  final String model;
  final String generation;
  final int year;
  final String variant;
  final PropulsionType propulsionType;
  final String engineOrMotorCode;
  final FuelType fuelType;
  final TransmissionType transmission;
  final int displacementCc;
  final double maxPowerHp;
  final double maxTorqueNm;
  final double tankOrBatteryCapacity;
  final String ecuProfileId;
  final String diagnosticProfileId;
  final List<PhysicalTransportType> supportedTransports;
  final List<DiagnosticProtocolType> supportedProtocols;
  final UniversalVehicleCapabilities capabilities;
  final Map<String, dynamic> maintenanceProfile;
  final String model3dAssetPath;
  final UniversalIdentificationConfidence identificationConfidence;
  final IdentificationSource identificationSource;
  final bool isVerified;
  final DateTime identifiedAt;

  const UniversalVehicleProfile({
    required this.vehicleId,
    this.vin,
    required this.domain,
    required this.manufacturer,
    required this.model,
    required this.generation,
    required this.year,
    required this.variant,
    required this.propulsionType,
    required this.engineOrMotorCode,
    required this.fuelType,
    required this.transmission,
    required this.displacementCc,
    required this.maxPowerHp,
    required this.maxTorqueNm,
    required this.tankOrBatteryCapacity,
    required this.ecuProfileId,
    required this.diagnosticProfileId,
    required this.supportedTransports,
    required this.supportedProtocols,
    required this.capabilities,
    this.maintenanceProfile = const {},
    required this.model3dAssetPath,
    required this.identificationConfidence,
    required this.identificationSource,
    this.isVerified = true,
    required this.identifiedAt,
  });

  Map<String, dynamic> toJson() => {
        'vehicleId': vehicleId,
        'vin': vin,
        'domain': domain.name,
        'manufacturer': manufacturer,
        'model': model,
        'generation': generation,
        'year': year,
        'variant': variant,
        'propulsionType': propulsionType.name,
        'engineOrMotorCode': engineOrMotorCode,
        'fuelType': fuelType.name,
        'transmission': transmission.name,
        'displacementCc': displacementCc,
        'maxPowerHp': maxPowerHp,
        'maxTorqueNm': maxTorqueNm,
        'tankOrBatteryCapacity': tankOrBatteryCapacity,
        'ecuProfileId': ecuProfileId,
        'diagnosticProfileId': diagnosticProfileId,
        'supportedTransports': supportedTransports.map((e) => e.name).toList(),
        'supportedProtocols': supportedProtocols.map((e) => e.name).toList(),
        'capabilities': capabilities.toJson(),
        'maintenanceProfile': maintenanceProfile,
        'model3dAssetPath': model3dAssetPath,
        'identificationConfidence': identificationConfidence.name,
        'identificationSource': identificationSource.name,
        'isVerified': isVerified,
        'identifiedAt': identifiedAt.toIso8601String(),
      };

  factory UniversalVehicleProfile.fromJson(Map<String, dynamic> json) => UniversalVehicleProfile(
        vehicleId: json['vehicleId'] ?? '',
        vin: json['vin'],
        domain: VehicleDomainType.values.firstWhere(
          (e) => e.name == json['domain'],
          orElse: () => VehicleDomainType.motorcycle,
        ),
        manufacturer: json['manufacturer'] ?? 'Unknown',
        model: json['model'] ?? 'Unknown Model',
        generation: json['generation'] ?? 'Gen 1',
        year: json['year'] ?? DateTime.now().year,
        variant: json['variant'] ?? 'Standard',
        propulsionType: PropulsionType.values.firstWhere(
          (e) => e.name == json['propulsionType'],
          orElse: () => PropulsionType.internalCombustion,
        ),
        engineOrMotorCode: json['engineOrMotorCode'] ?? 'STD-ENG',
        fuelType: FuelType.values.firstWhere(
          (e) => e.name == json['fuelType'],
          orElse: () => FuelType.petrol95,
        ),
        transmission: TransmissionType.values.firstWhere(
          (e) => e.name == json['transmission'],
          orElse: () => TransmissionType.manual,
        ),
        displacementCc: json['displacementCc'] ?? 0,
        maxPowerHp: (json['maxPowerHp'] as num?)?.toDouble() ?? 0.0,
        maxTorqueNm: (json['maxTorqueNm'] as num?)?.toDouble() ?? 0.0,
        tankOrBatteryCapacity: (json['tankOrBatteryCapacity'] as num?)?.toDouble() ?? 15.0,
        ecuProfileId: json['ecuProfileId'] ?? 'ISO_15765_4',
        diagnosticProfileId: json['diagnosticProfileId'] ?? 'OBD2_STANDARD',
        supportedTransports: (json['supportedTransports'] as List<dynamic>?)
                ?.map((e) => PhysicalTransportType.values.firstWhere((t) => t.name == e, orElse: () => PhysicalTransportType.bluetoothLowEnergy))
                .toList() ??
            [PhysicalTransportType.bluetoothLowEnergy],
        supportedProtocols: (json['supportedProtocols'] as List<dynamic>?)
                ?.map((e) => DiagnosticProtocolType.values.firstWhere((p) => p.name == e, orElse: () => DiagnosticProtocolType.iso15765_4_Can_11bit_500k))
                .toList() ??
            [DiagnosticProtocolType.iso15765_4_Can_11bit_500k],
        capabilities: json['capabilities'] != null
            ? UniversalVehicleCapabilities.fromJson(json['capabilities'])
            : const UniversalVehicleCapabilities(),
        maintenanceProfile: json['maintenanceProfile'] ?? {},
        model3dAssetPath: json['model3dAssetPath'] ?? 'assets/3d/generic_motorcycle.glb',
        identificationConfidence: UniversalIdentificationConfidence.values.firstWhere(
          (e) => e.name == json['identificationConfidence'],
          orElse: () => UniversalIdentificationConfidence.unresolved,
        ),
        identificationSource: IdentificationSource.values.firstWhere(
          (e) => e.name == json['identificationSource'],
          orElse: () => IdentificationSource.manualCatalogSelection,
        ),
        isVerified: json['isVerified'] ?? true,
        identifiedAt: json['identifiedAt'] != null ? DateTime.parse(json['identifiedAt']) : DateTime.now(),
      );
}
