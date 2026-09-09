import '../models/vin_decoder_models.dart';
import '../../ecosystem/rideos_master_architecture.dart';

class VinIdentificationEngine {
  static final VinIdentificationEngine instance = VinIdentificationEngine._internal();
  factory VinIdentificationEngine() => instance;
  VinIdentificationEngine._internal();

  static const Map<String, int> _charTransliterationValues = {
    'A': 1, 'B': 2, 'C': 3, 'D': 4, 'E': 5, 'F': 6, 'G': 7, 'H': 8,
    'J': 1, 'K': 2, 'L': 3, 'M': 4, 'N': 5, 'P': 7, 'R': 9,
    'S': 2, 'T': 3, 'U': 4, 'V': 5, 'W': 6, 'X': 7, 'Y': 8, 'Z': 9,
    '0': 0, '1': 1, '2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7, '8': 8, '9': 9,
  };

  static const List<int> _positionWeights = [
    8, 7, 6, 5, 4, 3, 2, 10, 0, 9, 8, 7, 6, 5, 4, 3, 2,
  ];

  static const Map<String, WmiRegionData> _wmiCatalog = {
    'JYA': WmiRegionData(wmiPrefix: 'JYA', country: 'Japan', manufacturerName: 'Yamaha Motor Co.', typicalDomain: VehicleDomainType.motorcycle),
    'ZDM': WmiRegionData(wmiPrefix: 'ZDM', country: 'Italy', manufacturerName: 'Ducati Motor Holding', typicalDomain: VehicleDomainType.motorcycle),
    'WB1': WmiRegionData(wmiPrefix: 'WB1', country: 'Germany', manufacturerName: 'BMW Motorrad', typicalDomain: VehicleDomainType.motorcycle),
    'WBA': WmiRegionData(wmiPrefix: 'WBA', country: 'Germany', manufacturerName: 'BMW AG', typicalDomain: VehicleDomainType.car),
    'WBS': WmiRegionData(wmiPrefix: 'WBS', country: 'Germany', manufacturerName: 'BMW M GmbH', typicalDomain: VehicleDomainType.car),
    'JH2': WmiRegionData(wmiPrefix: 'JH2', country: 'Japan', manufacturerName: 'Honda Motor Co. (Motorcycles)', typicalDomain: VehicleDomainType.motorcycle),
    '1HF': WmiRegionData(wmiPrefix: '1HF', country: 'United States', manufacturerName: 'Honda of America', typicalDomain: VehicleDomainType.car),
    'JS1': WmiRegionData(wmiPrefix: 'JS1', country: 'Japan', manufacturerName: 'Suzuki Motor Corporation', typicalDomain: VehicleDomainType.motorcycle),
    'JK1': WmiRegionData(wmiPrefix: 'JK1', country: 'Japan', manufacturerName: 'Kawasaki Heavy Industries', typicalDomain: VehicleDomainType.motorcycle),
    'WP0': WmiRegionData(wmiPrefix: 'WP0', country: 'Germany', manufacturerName: 'Porsche AG (Sports Cars)', typicalDomain: VehicleDomainType.car),
    'WP1': WmiRegionData(wmiPrefix: 'WP1', country: 'Germany', manufacturerName: 'Porsche AG (SUV/Sedans)', typicalDomain: VehicleDomainType.car),
    '5YJ': WmiRegionData(wmiPrefix: '5YJ', country: 'United States', manufacturerName: 'Tesla, Inc.', typicalDomain: VehicleDomainType.electricVehicle),
    'XP7': WmiRegionData(wmiPrefix: 'XP7', country: 'Germany', manufacturerName: 'Tesla Gigafactory Berlin', typicalDomain: VehicleDomainType.electricVehicle),
    'ME4': WmiRegionData(wmiPrefix: 'ME4', country: 'India', manufacturerName: 'Royal Enfield Motors', typicalDomain: VehicleDomainType.motorcycle),
    'MD6': WmiRegionData(wmiPrefix: 'MD6', country: 'India', manufacturerName: 'TVS Motor Company', typicalDomain: VehicleDomainType.scooter),
    'MD2': WmiRegionData(wmiPrefix: 'MD2', country: 'India', manufacturerName: 'Bajaj Auto Ltd.', typicalDomain: VehicleDomainType.motorcycle),
    '1FA': WmiRegionData(wmiPrefix: '1FA', country: 'United States', manufacturerName: 'Ford Motor Company', typicalDomain: VehicleDomainType.car),
    '1GC': WmiRegionData(wmiPrefix: '1GC', country: 'United States', manufacturerName: 'General Motors / Chevrolet', typicalDomain: VehicleDomainType.commercialFleet),
  };

  static const Map<String, int> _modelYearCharMap = {
    'A': 2010, 'B': 2011, 'C': 2012, 'D': 2013, 'E': 2014, 'F': 2015, 'G': 2016, 'H': 2017,
    'J': 2018, 'K': 2019, 'L': 2020, 'M': 2021, 'N': 2022, 'P': 2023, 'R': 2024, 'S': 2025,
    'T': 2026, 'V': 2027, 'W': 2028, 'X': 2029, 'Y': 2030,
    '1': 2001, '2': 2002, '3': 2003, '4': 2004, '5': 2005, '6': 2006, '7': 2007, '8': 2008, '9': 2009,
  };

  /// Normalizes arbitrary raw text input into a candidate VIN string.
  String normalizeVin(String raw) {
    return raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '').trim();
  }

  /// Validates standard ISO 3779 mathematical structure.
  VinValidationStatus validateVinStructure(String vin) {
    if (vin.isEmpty) return VinValidationStatus.emptyInput;
    if (vin.length != 17) return VinValidationStatus.invalidLength;
    if (vin.contains(RegExp(r'[IOQ]'))) return VinValidationStatus.invalidCharacters;

    // Check digit calculation (ISO 3779 / 49 CFR 565)
    final calculatedCheckDigit = computeCheckDigit(vin);
    final actualCheckDigit = vin[8];

    if (calculatedCheckDigit != actualCheckDigit) {
      return VinValidationStatus.invalidCheckDigit;
    }

    return VinValidationStatus.valid;
  }

  /// Computes standard ISO 3779 Check Digit (position 9)
  String computeCheckDigit(String vin) {
    if (vin.length != 17) return '';
    int total = 0;

    for (int i = 0; i < 17; i++) {
      if (i == 8) continue; // Check digit position
      final char = vin[i];
      final val = _charTransliterationValues[char];
      if (val == null) return '';
      total += val * _positionWeights[i];
    }

    final remainder = total % 11;
    return remainder == 10 ? 'X' : remainder.toString();
  }

  /// Decodes a verified 17-character VIN.
  VinIdentificationResult decodeVin(String rawInput) {
    final normalized = normalizeVin(rawInput);
    final status = validateVinStructure(normalized);

    if (status != VinValidationStatus.valid) {
      return VinIdentificationResult.invalid(
        rawInput: rawInput,
        status: status,
        reason: status.userMessage,
      );
    }

    final wmi = normalized.substring(0, 3);
    final vds = normalized.substring(3, 8);
    final checkDigit = normalized.substring(8, 9);
    final yearChar = normalized.substring(9, 10);
    final plantChar = normalized.substring(10, 11);
    final serialSub = normalized.substring(11, 17);
    final serial = int.tryParse(serialSub) ?? 0;

    final wmiData = _wmiCatalog[wmi];
    final modelYear = _modelYearCharMap[yearChar] ?? 2024;

    if (wmiData == null) {
      // WMI unrecognized: Return partially decoded without fabricating false vehicle identity
      final decoded = VinDecodedDetails(
        normalizedVin: normalized,
        wmi: wmi,
        vds: vds,
        checkDigit: checkDigit,
        vis: normalized.substring(9),
        modelYear: modelYear,
        assemblyPlant: plantChar,
        serialNumber: serial,
        countryOfOrigin: 'International / Unknown Region',
        manufacturer: 'Unregistered WMI ($wmi)',
        domainType: VehicleDomainType.unknown,
        hasExactCatalogMatch: false,
      );

      return VinIdentificationResult(
        rawInput: rawInput,
        normalizedVin: normalized,
        validationStatus: VinValidationStatus.unrecognizedWmi,
        isValid: true,
        decodedDetails: decoded,
        resolvedVehicleModel: null,
        confidenceScore: 0.50, // Partial confidence
        unresolvedReason: 'VIN structure valid, but manufacturer code $wmi is not registered in authoritative local catalog.',
      );
    }

    // Resolve exact model based on WMI + VDS descriptors
    final resolvedModel = _resolveCatalogModel(wmi, vds, modelYear);

    final decoded = VinDecodedDetails(
      normalizedVin: normalized,
      wmi: wmi,
      vds: vds,
      checkDigit: checkDigit,
      vis: normalized.substring(9),
      modelYear: modelYear,
      assemblyPlant: plantChar,
      serialNumber: serial,
      countryOfOrigin: wmiData.country,
      manufacturer: wmiData.manufacturerName,
      domainType: wmiData.typicalDomain,
      hasExactCatalogMatch: resolvedModel != null,
    );

    return VinIdentificationResult(
      rawInput: rawInput,
      normalizedVin: normalized,
      validationStatus: VinValidationStatus.valid,
      isValid: true,
      decodedDetails: decoded,
      resolvedVehicleModel: resolvedModel,
      confidenceScore: resolvedModel != null ? 1.0 : 0.85,
    );
  }

  String? _resolveCatalogModel(String wmi, String vds, int year) {
    if (wmi == 'JYA') {
      if (vds.startsWith('RN39') || vds.startsWith('RN49') || vds.startsWith('RN65')) return 'Yamaha YZF-R1M';
      if (vds.startsWith('RN70') || vds.startsWith('RN57')) return 'Yamaha MT-09 SP';
      if (vds.startsWith('RN29') || vds.startsWith('RN43')) return 'Yamaha MT-09';
      return 'Yamaha High-Performance Motorcycle';
    }
    if (wmi == 'ZDM') {
      if (vds.startsWith('1DA') || vds.startsWith('3DA') || vds.startsWith('V4S')) return 'Ducati Panigale V4 S';
      if (vds.startsWith('V2')) return 'Ducati Panigale V2';
      if (vds.startsWith('MS')) return 'Ducati Multistrada V4';
      return 'Ducati Superbike / Naked';
    }
    if (wmi == 'WB1') {
      if (vds.startsWith('0E51') || vds.startsWith('0E61') || vds.startsWith('0R11')) return 'BMW M1000RR';
      if (vds.startsWith('0E21') || vds.startsWith('0E31')) return 'BMW S1000RR';
      return 'BMW Motorrad Motorcycle';
    }
    if (wmi == '5YJ' || wmi == 'XP7') {
      if (vds.startsWith('S') || vds.startsWith('5')) return 'Tesla Model S Plaid';
      if (vds.startsWith('Y') || vds.startsWith('3')) return 'Tesla Model Y Performance';
      return 'Tesla Electric Vehicle';
    }
    if (wmi == 'WP0' || wmi == 'WP1') {
      if (vds.startsWith('992') || vds.startsWith('GT3')) return 'Porsche 911 GT3 (992)';
      return 'Porsche Sports Car';
    }
    if (wmi == 'ME4') {
      return 'Royal Enfield Himalayan 450';
    }
    if (wmi == 'MD6') {
      return 'TVS Apache RR 310';
    }
    return null;
  }
}
