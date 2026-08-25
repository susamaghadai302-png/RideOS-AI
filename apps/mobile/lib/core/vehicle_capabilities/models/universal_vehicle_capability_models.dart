import 'package:flutter/foundation.dart';

enum CompatibilityLevel {
  fullySupported,
  partiallySupported,
  supportedWithGateway,
  supportedWithManufacturerApi,
  discoveredButNotSupported,
  permissionRequired,
  hardwareRequired,
  notConnected,
  unknown;

  String get label {
    switch (this) {
      case CompatibilityLevel.fullySupported:
        return 'FULLY SUPPORTED';
      case CompatibilityLevel.partiallySupported:
        return 'PARTIALLY SUPPORTED';
      case CompatibilityLevel.supportedWithGateway:
        return 'SUPPORTED WITH GATEWAY (OBD-II)';
      case CompatibilityLevel.supportedWithManufacturerApi:
        return 'SUPPORTED WITH OEM CLOUD API';
      case CompatibilityLevel.discoveredButNotSupported:
        return 'DISCOVERED (PROTOCOL UNSUPPORTED)';
      case CompatibilityLevel.permissionRequired:
        return 'PERMISSION REQUIRED';
      case CompatibilityLevel.hardwareRequired:
        return 'HARDWARE / CCU ADAPTER REQUIRED';
      case CompatibilityLevel.notConnected:
        return 'NOT CONNECTED';
      case CompatibilityLevel.unknown:
        return 'UNKNOWN COMPATIBILITY';
    }
  }

  String get explanation {
    switch (this) {
      case CompatibilityLevel.fullySupported:
        return 'Native factory BLE / TFT integration with direct speed, RPM, telemetry, and display mirroring.';
      case CompatibilityLevel.partiallySupported:
        return 'Standard telemetry supported over generic diagnostic stream; display mirroring unavailable.';
      case CompatibilityLevel.supportedWithGateway:
        return 'Vehicle requires a 4-pin/6-pin Euro 4/5/6 or BS-VI OBD-II Bluetooth diagnostic adapter.';
      case CompatibilityLevel.supportedWithManufacturerApi:
        return 'Telematics streamed securely via official manufacturer cloud API integration.';
      case CompatibilityLevel.discoveredButNotSupported:
        return 'Bluetooth device discovered but vehicle ECU protocol is proprietary or unsupported.';
      case CompatibilityLevel.permissionRequired:
        return 'Please grant Nearby Devices (Bluetooth) and Location permissions in system settings.';
      case CompatibilityLevel.hardwareRequired:
        return 'Base variant without factory CCU/TFT module. External adapter required.';
      case CompatibilityLevel.notConnected:
        return 'Vehicle radio in standby. Turn on motorcycle ignition to establish link.';
      case CompatibilityLevel.unknown:
        return 'Vehicle model identification unavailable. Manual variant selection required.';
    }
  }
}

enum VariantTrimLevel {
  base,
  mid,
  topPremium,
}

@immutable
class ConnectivityCapabilities {
  final bool hasBle;
  final bool hasBluetoothClassic;
  final bool hasWifi;
  final bool hasUsb;
  final bool hasManufacturerApi;
  final bool hasObdGateway;
  final bool hasCanGateway;

  const ConnectivityCapabilities({
    this.hasBle = true,
    this.hasBluetoothClassic = false,
    this.hasWifi = false,
    this.hasUsb = false,
    this.hasManufacturerApi = false,
    this.hasObdGateway = false,
    this.hasCanGateway = false,
  });
}

@immutable
class ProtocolCapabilities {
  final String protocolName;
  final String gattServiceUuid;
  final String readCharacteristicUuid;
  final String? writeCharacteristicUuid;
  final bool supportsTurnByTurnMirror;
  final bool supportsCallerIdAlerts;
  final bool supportsDtcDiagnostics;

  const ProtocolCapabilities({
    required this.protocolName,
    required this.gattServiceUuid,
    required this.readCharacteristicUuid,
    this.writeCharacteristicUuid,
    this.supportsTurnByTurnMirror = false,
    this.supportsCallerIdAlerts = false,
    this.supportsDtcDiagnostics = false,
  });
}

@immutable
class TelemetryCapabilities {
  final bool supportsSpeed;
  final bool supportsRpm;
  final bool supportsEngineStatus;
  final bool supportsFuelLevel;
  final bool supportsBatterySoc;
  final bool supportsBatteryVoltage;
  final bool supportsCoolantTemp;
  final bool supportsMotorTemp;
  final bool supportsOdometer;
  final bool supportsTripDistance;
  final bool supportsGearIndicator;
  final bool supportsTurnIndicators;
  final bool supportsHeadlightStatus;
  final bool supportsSideStand;
  final bool supportsBrakeStatus;
  final bool supportsAbsStatus;
  final bool supportsTractionControl;
  final bool supportsTpms;
  final bool supportsChargingStatus;

  const TelemetryCapabilities({
    this.supportsSpeed = true,
    this.supportsRpm = true,
    this.supportsEngineStatus = true,
    this.supportsFuelLevel = true,
    this.supportsBatterySoc = false,
    this.supportsBatteryVoltage = true,
    this.supportsCoolantTemp = true,
    this.supportsMotorTemp = false,
    this.supportsOdometer = true,
    this.supportsTripDistance = true,
    this.supportsGearIndicator = false,
    this.supportsTurnIndicators = false,
    this.supportsHeadlightStatus = false,
    this.supportsSideStand = false,
    this.supportsBrakeStatus = false,
    this.supportsAbsStatus = true,
    this.supportsTractionControl = false,
    this.supportsTpms = false,
    this.supportsChargingStatus = false,
  });
}

@immutable
class DisplayCapabilities {
  final String displayType; // e.g. "TFT 5-inch Full Color", "Segment LCD", "OLED Companion Display"
  final bool supportsNavigationArrows;
  final bool supportsStreetNameText;
  final bool supportsMediaPlaybackMetadata;
  final bool supportsIncomingCallNotification;
  final bool requiresDisplayGateway;

  const DisplayCapabilities({
    required this.displayType,
    this.supportsNavigationArrows = false,
    this.supportsStreetNameText = false,
    this.supportsMediaPlaybackMetadata = false,
    this.supportsIncomingCallNotification = false,
    this.requiresDisplayGateway = false,
  });
}

@immutable
class ModelVariant {
  final String variantId;
  final String variantName;
  final VariantTrimLevel trimLevel;
  final ConnectivityCapabilities connectivity;
  final ProtocolCapabilities protocol;
  final TelemetryCapabilities telemetry;
  final DisplayCapabilities display;
  final CompatibilityLevel compatibility;

  const ModelVariant({
    required this.variantId,
    required this.variantName,
    required this.trimLevel,
    required this.connectivity,
    required this.protocol,
    required this.telemetry,
    required this.display,
    required this.compatibility,
  });
}

@immutable
class VehicleModel {
  final String modelId;
  final String modelName;
  final int startYear;
  final int? endYear;
  final List<ModelVariant> variants;

  const VehicleModel({
    required this.modelId,
    required this.modelName,
    required this.startYear,
    this.endYear,
    required this.variants,
  });
}

@immutable
class VehicleFamily {
  final String familyId;
  final String familyName;
  final List<VehicleModel> models;

  const VehicleFamily({
    required this.familyId,
    required this.familyName,
    required this.models,
  });
}

@immutable
class VehicleManufacturer {
  final String manufacturerId;
  final String name;
  final String country;
  final List<VehicleFamily> families;

  const VehicleManufacturer({
    required this.manufacturerId,
    required this.name,
    required this.country,
    required this.families,
  });
}

@immutable
class VehicleCapabilityProfile {
  final VehicleManufacturer manufacturer;
  final VehicleFamily family;
  final VehicleModel model;
  final ModelVariant variant;
  final int modelYear;
  final ConnectivityCapabilities connectivity;
  final ProtocolCapabilities protocol;
  final TelemetryCapabilities telemetry;
  final DisplayCapabilities display;
  final CompatibilityLevel compatibilityLevel;

  const VehicleCapabilityProfile({
    required this.manufacturer,
    required this.family,
    required this.model,
    required this.variant,
    required this.modelYear,
    required this.connectivity,
    required this.protocol,
    required this.telemetry,
    required this.display,
    required this.compatibilityLevel,
  });

  String get fullDisplayName => '${manufacturer.name} ${model.modelName} ${variant.variantName} ($modelYear)';
}

