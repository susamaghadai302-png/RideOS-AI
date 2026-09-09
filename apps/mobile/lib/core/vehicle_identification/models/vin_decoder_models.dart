import 'package:flutter/foundation.dart';
import '../../ecosystem/rideos_master_architecture.dart';

enum VinValidationStatus {
  valid,
  invalidLength,
  invalidCharacters,
  invalidCheckDigit,
  unrecognizedWmi,
  emptyInput;

  String get userMessage {
    switch (this) {
      case VinValidationStatus.valid:
        return 'Standard 17-character ISO 3779 VIN format verified.';
      case VinValidationStatus.invalidLength:
        return 'VIN must be exactly 17 characters in length.';
      case VinValidationStatus.invalidCharacters:
        return 'VIN contains invalid letters (I, O, Q are prohibited per ISO 3779).';
      case VinValidationStatus.invalidCheckDigit:
        return 'VIN mathematical check digit (position 9) verification failed.';
      case VinValidationStatus.unrecognizedWmi:
        return 'World Manufacturer Identifier (WMI) code unrecognized.';
      case VinValidationStatus.emptyInput:
        return 'Please provide a 17-character VIN.';
    }
  }
}

@immutable
class WmiRegionData {
  final String wmiPrefix;
  final String country;
  final String manufacturerName;
  final VehicleDomainType typicalDomain;

  const WmiRegionData({
    required this.wmiPrefix,
    required this.country,
    required this.manufacturerName,
    required this.typicalDomain,
  });
}

@immutable
class VinDecodedDetails {
  final String normalizedVin;
  final String wmi; // World Manufacturer Identifier (chars 1-3)
  final String vds; // Vehicle Descriptor Section (chars 4-8)
  final String checkDigit; // Check digit (char 9)
  final String vis; // Vehicle Identifier Section (chars 10-17)
  final int modelYear;
  final String assemblyPlant;
  final int serialNumber;
  final String countryOfOrigin;
  final String manufacturer;
  final VehicleDomainType domainType;
  final bool hasExactCatalogMatch;

  const VinDecodedDetails({
    required this.normalizedVin,
    required this.wmi,
    required this.vds,
    required this.checkDigit,
    required this.vis,
    required this.modelYear,
    required this.assemblyPlant,
    required this.serialNumber,
    required this.countryOfOrigin,
    required this.manufacturer,
    required this.domainType,
    required this.hasExactCatalogMatch,
  });

  Map<String, dynamic> toJson() => {
        'normalizedVin': normalizedVin,
        'wmi': wmi,
        'vds': vds,
        'checkDigit': checkDigit,
        'vis': vis,
        'modelYear': modelYear,
        'assemblyPlant': assemblyPlant,
        'serialNumber': serialNumber,
        'countryOfOrigin': countryOfOrigin,
        'manufacturer': manufacturer,
        'domainType': domainType.name,
        'hasExactCatalogMatch': hasExactCatalogMatch,
      };
}

@immutable
class VinIdentificationResult {
  final String rawInput;
  final String? normalizedVin;
  final VinValidationStatus validationStatus;
  final bool isValid;
  final VinDecodedDetails? decodedDetails;
  final String? resolvedVehicleModel;
  final double confidenceScore;
  final String? unresolvedReason;

  const VinIdentificationResult({
    required this.rawInput,
    this.normalizedVin,
    required this.validationStatus,
    required this.isValid,
    this.decodedDetails,
    this.resolvedVehicleModel,
    required this.confidenceScore,
    this.unresolvedReason,
  });

  static VinIdentificationResult invalid({
    required String rawInput,
    required VinValidationStatus status,
    String? reason,
  }) =>
      VinIdentificationResult(
        rawInput: rawInput,
        validationStatus: status,
        isValid: false,
        confidenceScore: 0.0,
        unresolvedReason: reason ?? status.userMessage,
      );
}
