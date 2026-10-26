import 'package:flutter/foundation.dart';
import '../../vehicle_connectivity/models/vehicle_capabilities.dart';
import '../../vehicle_connectivity/models/vehicle_variant_taxonomy.dart';

enum VerificationSource {
  verified,
  documented,
  userConfigured,
  experimental,
  unknown;

  String get label {
    switch (this) {
      case VerificationSource.verified:
        return 'OEM VERIFIED';
      case VerificationSource.documented:
        return 'DOCUMENTED SPEC';
      case VerificationSource.userConfigured:
        return 'USER CONFIGURED';
      case VerificationSource.experimental:
        return 'EXPERIMENTAL';
      case VerificationSource.unknown:
        return 'UNVERIFIED PROTOCOL';
    }
  }
}

@immutable
class DisplaySystem {
  final String displayType; // 5-inch TFT, 7-inch Touchscreen, Split TFT, Segmented LCD, Tripper Pod, Analogue
  final bool hasTurnByTurnNav;
  final bool hasCallerId;
  final bool hasMediaControl;
  final bool isTouchscreen;

  const DisplaySystem({
    required this.displayType,
    this.hasTurnByTurnNav = false,
    this.hasCallerId = false,
    this.hasMediaControl = false,
    this.isTouchscreen = false,
  });

  Map<String, dynamic> toJson() => {
        'displayType': displayType,
        'hasTurnByTurnNav': hasTurnByTurnNav,
        'hasCallerId': hasCallerId,
        'hasMediaControl': hasMediaControl,
        'isTouchscreen': isTouchscreen,
      };

  factory DisplaySystem.fromJson(Map<String, dynamic> json) => DisplaySystem(
        displayType: json['displayType'] ?? 'Segmented LCD',
        hasTurnByTurnNav: json['hasTurnByTurnNav'] ?? false,
        hasCallerId: json['hasCallerId'] ?? false,
        hasMediaControl: json['hasMediaControl'] ?? false,
        isTouchscreen: json['isTouchscreen'] ?? false,
      );
}

@immutable
class ConnectivityProfile {
  final List<VehicleConnectivityType> supportedMethods;
  final String primaryProtocolAdapterId;
  final String adapterVersion;
  final bool requiresExternalGateway;
  final String? gatewayType; // 4-Pin OBD-II, 6-Pin Euro 5, CAN Gateway
  final bool requiresOemAuth;

  const ConnectivityProfile({
    required this.supportedMethods,
    required this.primaryProtocolAdapterId,
    this.adapterVersion = '2.4.0',
    this.requiresExternalGateway = false,
    this.gatewayType,
    this.requiresOemAuth = false,
  });

  Map<String, dynamic> toJson() => {
        'supportedMethods': supportedMethods.map((e) => e.name).toList(),
        'primaryProtocolAdapterId': primaryProtocolAdapterId,
        'adapterVersion': adapterVersion,
        'requiresExternalGateway': requiresExternalGateway,
        'gatewayType': gatewayType,
        'requiresOemAuth': requiresOemAuth,
      };

  factory ConnectivityProfile.fromJson(Map<String, dynamic> json) {
    final rawMethods = (json['supportedMethods'] as List<dynamic>?) ?? [];
    return ConnectivityProfile(
      supportedMethods: rawMethods
          .map((m) => VehicleConnectivityType.values.firstWhere(
                (e) => e.name == m,
                orElse: () => VehicleConnectivityType.none,
              ))
          .toList(),
      primaryProtocolAdapterId: json['primaryProtocolAdapterId'] ?? 'generic_ble',
      adapterVersion: json['adapterVersion'] ?? '2.4.0',
      requiresExternalGateway: json['requiresExternalGateway'] ?? false,
      gatewayType: json['gatewayType'],
      requiresOemAuth: json['requiresOemAuth'] ?? false,
    );
  }
}

@immutable
class UniversalVehicleProfile {
  final String id;
  final String brand;
  final String family;
  final String generation;
  final String model;
  final String variant;
  final int modelYear;
  final String vehicleType; // Motorcycle, Scooter, ElectricMotorcycle, ElectricScooter
  final String fuelType; // Petrol, Electric, Hybrid
  final DisplaySystem displaySystem;
  final ConnectivityProfile connectivity;
  final VehicleCapabilities capabilities;
  final VehicleCompatibilityLevel compatibility;
  final VerificationSource verification;
  final Map<String, dynamic> specifications;
  final String? model3DUrl;
  final String? thumbnailUrl;

  const UniversalVehicleProfile({
    required this.id,
    required this.brand,
    required this.family,
    required this.generation,
    required this.model,
    required this.variant,
    required this.modelYear,
    required this.vehicleType,
    required this.fuelType,
    required this.displaySystem,
    required this.connectivity,
    required this.capabilities,
    required this.compatibility,
    this.verification = VerificationSource.verified,
    this.specifications = const {},
    this.model3DUrl,
    this.thumbnailUrl,
  });

  String get fullName {
    final baseName = [brand.trim(), model.trim()]
        .where((part) => part.isNotEmpty)
        .join(' ');
    final variantAndYear = [
      if (variant.trim().isNotEmpty) variant.trim(),
      if (modelYear > 0) modelYear.toString(),
    ].join(' ');
    return variantAndYear.isEmpty
        ? baseName
        : '$baseName ($variantAndYear)';
  }

  bool get isElectric =>
      fuelType.toLowerCase() == 'electric' ||
      vehicleType.toLowerCase().contains('electric');

  Map<String, dynamic> toJson() => {
        'id': id,
        'brand': brand,
        'family': family,
        'generation': generation,
        'model': model,
        'variant': variant,
        'modelYear': modelYear,
        'vehicleType': vehicleType,
        'fuelType': fuelType,
        'displaySystem': displaySystem.toJson(),
        'connectivity': connectivity.toJson(),
        'capabilities': capabilities.toJson(),
        'compatibility': compatibility.name,
        'verification': verification.name,
        'specifications': specifications,
        'model3DUrl': model3DUrl,
        'thumbnailUrl': thumbnailUrl,
      };

  factory UniversalVehicleProfile.fromJson(Map<String, dynamic> json) => UniversalVehicleProfile(
        id: json['id'] ?? '',
        brand: json['brand'] ?? '',
        family: json['family'] ?? '',
        generation: json['generation'] ?? '',
        model: json['model'] ?? '',
        variant: json['variant'] ?? 'Standard',
        modelYear: json['modelYear'] ?? 0,
        vehicleType: json['vehicleType'] ?? 'Motorcycle',
        fuelType: json['fuelType'] ?? 'Unknown',
        displaySystem: DisplaySystem.fromJson(json['displaySystem'] ?? {}),
        connectivity: ConnectivityProfile.fromJson(json['connectivity'] ?? {}),
        capabilities: VehicleCapabilities.fromJson(json['capabilities'] ?? {}),
        compatibility: VehicleCompatibilityLevel.values.firstWhere(
          (e) => e.name == json['compatibility'],
          orElse: () => VehicleCompatibilityLevel.unknown,
        ),
        verification: VerificationSource.values.firstWhere(
          (e) => e.name == json['verification'],
          orElse: () => VerificationSource.documented,
        ),
        specifications: json['specifications'] ?? {},
        model3DUrl: json['model3DUrl'],
        thumbnailUrl: json['thumbnailUrl'],
      );
}
