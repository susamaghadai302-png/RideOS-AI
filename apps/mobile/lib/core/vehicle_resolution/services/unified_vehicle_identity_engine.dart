import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/vehicle_identity.dart';

/// Unified Engine to extract vehicle identity from real BLE GATT DIS or OBD Mode 09 data
class UnifiedVehicleIdentityEngine {
  static final UnifiedVehicleIdentityEngine _instance = UnifiedVehicleIdentityEngine._internal();
  factory UnifiedVehicleIdentityEngine() => _instance;
  UnifiedVehicleIdentityEngine._internal();

  /// Standard BLE Device Information Service UUIDs (0x180A)
  static const String disServiceUuid = '180a';
  static const String manufacturerNameCharUuid = '2a29';
  static const String modelNumberCharUuid = '2a24';
  static const String serialNumberCharUuid = '2a25';
  static const String firmwareRevisionCharUuid = '2a26';
  static const String hardwareRevisionCharUuid = '2a27';

  /// Standard WMI (World Manufacturer Identifier) Decoders
  static final Map<String, String> _wmiToManufacturer = {
    'JY4': 'Yamaha',
    'JY1': 'Yamaha',
    'ZDM': 'Ducati',
    'WB1': 'BMW',
    'JS1': 'Suzuki',
    'ME4': 'Royal Enfield',
    'MD2': 'Bajaj Auto',
    'MLH': 'Honda',
    'JK1': 'Kawasaki',
    'VBK': 'KTM',
    'SMT': 'Triumph',
    '1HD': 'Harley-Davidson',
  };

  /// Extracts VehicleIdentity from real BLE GATT services and advertisement data
  Future<VehicleIdentity> extractFromBle({
    required BluetoothDevice device,
    required AdvertisementData advertisementData,
    List<BluetoothService>? services,
  }) async {
    final advName = advertisementData.advName.trim();
    final platformName = device.platformName.trim();
    final rawName = advName.isNotEmpty ? advName : platformName;
    final deviceId = device.remoteId.str;

    String? manufacturer;
    String? model;
    String? serialNumber;
    String? firmwareRevision;
    final provenance = <String, IdentityFieldProvenance>{};

    // 1. Inspect GATT Device Information Service if services are provided
    if (services != null && services.isNotEmpty) {
      for (final service in services) {
        final sUuid = service.uuid.str128.toLowerCase();
        if (sUuid.contains(disServiceUuid)) {
          for (final characteristic in service.characteristics) {
            final cUuid = characteristic.uuid.str128.toLowerCase();
            try {
              if (cUuid.contains(manufacturerNameCharUuid)) {
                final val = await characteristic.read();
                manufacturer = String.fromCharCodes(val).trim();
                provenance['manufacturer'] = IdentityFieldProvenance.gattDiscovery;
              } else if (cUuid.contains(modelNumberCharUuid)) {
                final val = await characteristic.read();
                model = String.fromCharCodes(val).trim();
                provenance['model'] = IdentityFieldProvenance.gattDiscovery;
              } else if (cUuid.contains(serialNumberCharUuid)) {
                final val = await characteristic.read();
                serialNumber = String.fromCharCodes(val).trim();
                provenance['serialNumber'] = IdentityFieldProvenance.gattDiscovery;
              } else if (cUuid.contains(firmwareRevisionCharUuid)) {
                final val = await characteristic.read();
                firmwareRevision = String.fromCharCodes(val).trim();
                provenance['firmwareVersion'] = IdentityFieldProvenance.gattDiscovery;
              }
            } catch (e) {
              debugPrint('UnifiedVehicleIdentityEngine: Error reading DIS characteristic $cUuid: $e');
            }
          }
        }
      }
    }

    // 2. If GATT DIS was not present or partial, evaluate advertised signature
    final lowerName = rawName.toLowerCase();
    if (manufacturer == null || manufacturer.isEmpty) {
      if (lowerName.contains('yamaha') || lowerName.contains('r15') || lowerName.contains('r1m') || lowerName.contains('mt09') || lowerName.contains('aerox')) {
        manufacturer = 'Yamaha';
        provenance['manufacturer'] = IdentityFieldProvenance.advertisedName;
      } else if (lowerName.contains('ducati') || lowerName.contains('panigale')) {
        manufacturer = 'Ducati';
        provenance['manufacturer'] = IdentityFieldProvenance.advertisedName;
      } else if (lowerName.contains('bmw') || lowerName.contains('m1000') || lowerName.contains('s1000')) {
        manufacturer = 'BMW';
        provenance['manufacturer'] = IdentityFieldProvenance.advertisedName;
      } else if (lowerName.contains('suzuki') || lowerName.contains('burgman')) {
        manufacturer = 'Suzuki';
        provenance['manufacturer'] = IdentityFieldProvenance.advertisedName;
      }
    }

    if (model == null || model.isEmpty) {
      if (lowerName.contains('r1m')) {
        model = 'YZF-R1M';
        provenance['model'] = IdentityFieldProvenance.advertisedName;
      } else if (lowerName.contains('mt09') || lowerName.contains('mt-09')) {
        model = 'MT-09 SP';
        provenance['model'] = IdentityFieldProvenance.advertisedName;
      } else if (lowerName.contains('panigale')) {
        model = 'Panigale V4 S';
        provenance['model'] = IdentityFieldProvenance.advertisedName;
      } else if (lowerName.contains('m1000') || lowerName.contains('m 1000')) {
        model = 'M 1000 RR';
        provenance['model'] = IdentityFieldProvenance.advertisedName;
      } else if (lowerName.contains('burgman')) {
        model = 'Burgman Street 125';
        provenance['model'] = IdentityFieldProvenance.advertisedName;
      } else if (lowerName.contains('r15')) {
        model = 'YZF-R15 V4';
        provenance['model'] = IdentityFieldProvenance.advertisedName;
      }
    }

    // 3. Determine Confidence
    IdentityConfidence confidence;
    if (manufacturer != null && model != null) {
      confidence = IdentityConfidence.exactMatch;
    } else if (manufacturer != null) {
      confidence = IdentityConfidence.partialMatch;
    } else {
      confidence = IdentityConfidence.unknown;
    }

    return VehicleIdentity(
      connectionType: ConnectionTransportType.ble,
      deviceIdentifier: deviceId,
      manufacturer: manufacturer ?? 'Unknown Manufacturer',
      make: manufacturer ?? 'Unknown',
      model: model ?? (rawName.isNotEmpty ? rawName : 'Unknown Two-Wheeler'),
      variant: model != null && model.contains('SP') ? 'SP' : (model != null && model.contains('V4 S') ? 'V4 S' : ''),
      modelYear: 2024,
      firmwareVersion: firmwareRevision,
      protocolAdapterId: 'ble_ccu_${(manufacturer ?? "generic").toLowerCase()}',
      confidence: confidence,
      fieldProvenance: provenance,
      metadata: {
        'serialNumber': serialNumber,
        'rawAdvertisementName': rawName,
      },
    );
  }

  /// Extracts VehicleIdentity from real USB / OBD / CAN Gateway Mode 09 Data
  VehicleIdentity extractFromObd({
    required String deviceIdentifier,
    String? rawVin,
    String? rawEcuCalibrationId,
    String? rawEcuName,
    String protocolId = 'obd2_iso15765',
  }) {
    String? manufacturer;
    String? model;
    String? variant;
    int modelYear = 2024;
    final provenance = <String, IdentityFieldProvenance>{};

    if (rawVin != null && rawVin.length >= 3) {
      provenance['vin'] = IdentityFieldProvenance.vinDecode;
      final wmi = rawVin.substring(0, 3).toUpperCase();
      manufacturer = _wmiToManufacturer[wmi];
      if (manufacturer != null) {
        provenance['manufacturer'] = IdentityFieldProvenance.vinDecode;
      }

      // Decode Model Year from VIN 10th character (Standard ISO 3779)
      if (rawVin.length >= 10) {
        final yearChar = rawVin[9].toUpperCase();
        modelYear = _decodeVinYear(yearChar);
        provenance['modelYear'] = IdentityFieldProvenance.vinDecode;
      }
    }

    if (rawEcuCalibrationId != null && rawEcuCalibrationId.isNotEmpty) {
      provenance['ecuIdentifier'] = IdentityFieldProvenance.ecuCalibrationQuery;
      final calId = rawEcuCalibrationId.toUpperCase();
      if (calId.contains('R1M') || calId.contains('2CR-8591A')) {
        model = 'YZF-R1M';
        variant = 'Carbon';
        manufacturer ??= 'Yamaha';
      } else if (calId.contains('MT09') || calId.contains('B7N-8591A')) {
        model = 'MT-09 SP';
        variant = 'SP';
        manufacturer ??= 'Yamaha';
      } else if (calId.contains('PANIGALE') || calId.contains('V4S-DMS')) {
        model = 'Panigale V4 S';
        variant = 'V4 S';
        manufacturer ??= 'Ducati';
      } else if (calId.contains('M1000RR') || calId.contains('BMS-MP-COMP')) {
        model = 'M 1000 RR';
        variant = 'M Competition';
        manufacturer ??= 'BMW';
      } else if (calId.contains('BURGMAN') || calId.contains('SUZ-EX125')) {
        model = 'Burgman Street 125';
        variant = 'EX';
        manufacturer ??= 'Suzuki';
      }
      if (model != null) {
        provenance['model'] = IdentityFieldProvenance.ecuCalibrationQuery;
      }
    }

    IdentityConfidence confidence;
    if (manufacturer != null && model != null) {
      confidence = IdentityConfidence.exactMatch;
    } else if (manufacturer != null) {
      confidence = IdentityConfidence.partialMatch;
    } else {
      confidence = IdentityConfidence.unknown;
    }

    return VehicleIdentity(
      connectionType: ConnectionTransportType.obdGateway,
      deviceIdentifier: deviceIdentifier,
      manufacturer: manufacturer ?? 'Generic OBD Vehicle',
      make: manufacturer ?? 'Generic',
      model: model ?? 'OBD-II Diagnostic Client',
      variant: variant ?? '',
      modelYear: modelYear,
      vin: rawVin,
      ecuIdentifier: rawEcuCalibrationId,
      protocolAdapterId: protocolId,
      confidence: confidence,
      fieldProvenance: provenance,
      metadata: {
        'ecuName': rawEcuName,
      },
    );
  }

  int _decodeVinYear(String yearChar) {
    const yearMap = {
      'P': 2023,
      'R': 2024,
      'S': 2025,
      'T': 2026,
      'N': 2022,
      'M': 2021,
      'L': 2020,
      'K': 2019,
    };
    return yearMap[yearChar] ?? 2024;
  }
}
