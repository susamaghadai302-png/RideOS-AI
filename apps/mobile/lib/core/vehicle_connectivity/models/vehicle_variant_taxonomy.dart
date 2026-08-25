import 'package:flutter/foundation.dart';
import 'vehicle_capabilities.dart';

enum VehicleConnectivityType {
  ble,
  bluetoothClassic,
  wifiDirect,
  obd2Gateway,
  canGateway,
  manufacturerApi,
  smartDisplayMirror,
  none,
}

@immutable
class VehicleVariant {
  final String variantId;
  final String variantName; // Base, Mid, High, Carbon Edition, S, Pro, Plus
  final String displayType; // Analogue, Semi-Digital LCD, Full Color TFT, Touchscreen
  final bool hasBluetooth;
  final bool hasTelematicsUnit; // CCU / T-Box
  final bool hasTpms;
  final bool hasQuickshifter;
  final bool hasCorneringAbs;
  final VehicleConnectivityType primaryConnectivity;
  final String protocolAdapterId;
  final VehicleCapabilities capabilities;
  final VehicleCompatibilityLevel compatibilityLevel;

  const VehicleVariant({
    required this.variantId,
    required this.variantName,
    required this.displayType,
    required this.hasBluetooth,
    required this.hasTelematicsUnit,
    this.hasTpms = false,
    this.hasQuickshifter = false,
    this.hasCorneringAbs = false,
    required this.primaryConnectivity,
    required this.protocolAdapterId,
    required this.capabilities,
    required this.compatibilityLevel,
  });

  Map<String, dynamic> toJson() => {
        'variantId': variantId,
        'variantName': variantName,
        'displayType': displayType,
        'hasBluetooth': hasBluetooth,
        'hasTelematicsUnit': hasTelematicsUnit,
        'hasTpms': hasTpms,
        'hasQuickshifter': hasQuickshifter,
        'hasCorneringAbs': hasCorneringAbs,
        'primaryConnectivity': primaryConnectivity.name,
        'protocolAdapterId': protocolAdapterId,
        'capabilities': capabilities.toJson(),
        'compatibilityLevel': compatibilityLevel.name,
      };

  factory VehicleVariant.fromJson(Map<String, dynamic> json) => VehicleVariant(
        variantId: json['variantId'] ?? '',
        variantName: json['variantName'] ?? 'Standard',
        displayType: json['displayType'] ?? 'LCD',
        hasBluetooth: json['hasBluetooth'] ?? false,
        hasTelematicsUnit: json['hasTelematicsUnit'] ?? false,
        hasTpms: json['hasTpms'] ?? false,
        hasQuickshifter: json['hasQuickshifter'] ?? false,
        hasCorneringAbs: json['hasCorneringAbs'] ?? false,
        primaryConnectivity: VehicleConnectivityType.values.firstWhere(
          (e) => e.name == json['primaryConnectivity'],
          orElse: () => VehicleConnectivityType.none,
        ),
        protocolAdapterId: json['protocolAdapterId'] ?? 'generic_ble',
        capabilities: VehicleCapabilities.fromJson(json['capabilities'] ?? {}),
        compatibilityLevel: VehicleCompatibilityLevel.values.firstWhere(
          (e) => e.name == json['compatibilityLevel'],
          orElse: () => VehicleCompatibilityLevel.unknown,
        ),
      );
}

@immutable
class VehicleGeneration {
  final String generationCode; // Gen 1, Gen 2, 2024 Facelift, Euro 5
  final int startYear;
  final int? endYear;
  final List<VehicleVariant> variants;

  const VehicleGeneration({
    required this.generationCode,
    required this.startYear,
    this.endYear,
    required this.variants,
  });
}

@immutable
class VehicleModelFamily {
  final String familyId;
  final String manufacturer;
  final String familyName; // e.g. YZF-R1, Ninja, Duke, Burgman, Ather 450, Activa
  final String category; // Motorcycle, Scooter, ElectricMotorcycle, ElectricScooter
  final List<VehicleGeneration> generations;

  const VehicleModelFamily({
    required this.familyId,
    required this.manufacturer,
    required this.familyName,
    required this.category,
    required this.generations,
  });
}
