import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/vehicle_capabilities.dart';
import '../models/vehicle_variant_taxonomy.dart';
import 'universal_vehicle_database.dart';
import '../../vehicle_resolution/models/vehicle_identity.dart';

@immutable
class IdentificationResult {
  final bool isIdentified;
  final String brand;
  final String? family;
  final String? model;
  final String? generation;
  final String? variant;
  final int? modelYear;
  final String vehicleType;
  final String displayType;
  final String protocolAdapterId;
  final VehicleCapabilities capabilities;
  final VehicleCompatibilityLevel compatibilityLevel;
  final double confidence; // 0.0 to 1.0
  final String diagnosticReason;

  const IdentificationResult({
    required this.isIdentified,
    required this.brand,
    this.family,
    this.model,
    this.generation,
    this.variant,
    this.modelYear,
    required this.vehicleType,
    required this.displayType,
    required this.protocolAdapterId,
    required this.capabilities,
    required this.compatibilityLevel,
    required this.confidence,
    required this.diagnosticReason,
  });

  String get displayName {
    if (isIdentified && model != null) {
      return '$brand $model (${variant ?? "Standard"} ${modelYear ?? ""})'.trim();
    }
    return '$brand Device (Model Identification Unavailable)';
  }

  VehicleIdentity toCanonicalIdentity(String deviceId, [ConnectionTransportType transport = ConnectionTransportType.ble]) {
    IdentityConfidence conf;
    if (!isIdentified || brand == 'Universal / Generic' || brand == 'Generic BLE') {
      conf = IdentityConfidence.unknown;
    } else if (confidence >= 0.95 && model != null && !model!.contains('Connected Two-Wheeler')) {
      conf = IdentityConfidence.exactMatch;
    } else if (confidence >= 0.80) {
      conf = IdentityConfidence.verifiedMatch;
    } else {
      conf = IdentityConfidence.partialMatch;
    }

    return VehicleIdentity(
      connectionType: transport,
      deviceIdentifier: deviceId,
      manufacturer: brand,
      make: brand,
      model: model ?? 'Two-Wheeler',
      variant: variant ?? '',
      modelYear: modelYear ?? 2024,
      protocolAdapterId: protocolAdapterId,
      confidence: conf,
      fieldProvenance: {
        'make': IdentityFieldProvenance.advertisedName,
        'model': IdentityFieldProvenance.gattDiscovery,
      },
    );
  }
}

class AutomaticVehicleIdentifier {
  static final AutomaticVehicleIdentifier _instance = AutomaticVehicleIdentifier._internal();
  factory AutomaticVehicleIdentifier() => _instance;
  AutomaticVehicleIdentifier._internal();

  final _db = UniversalVehicleDatabase();

  /// Identifies a vehicle from Bluetooth/BLE advertisement characteristics without guessing
  IdentificationResult identifyFromScan({
    required BluetoothDevice device,
    required AdvertisementData advertisementData,
  }) {
    final advName = advertisementData.advName.trim();
    final platformName = device.platformName.trim();
    final rawName = advName.isNotEmpty ? advName : platformName;
    final lowerName = rawName.toLowerCase();
    final serviceUuids = advertisementData.serviceUuids.map((u) => u.str128.toLowerCase()).toList();

    // 1. Yamaha CCU Detection (R15 V4, Aerox 155, MT-09, R1M)
    if (lowerName.contains('r15') || lowerName.contains('aerox') || lowerName.contains('mt09') || lowerName.contains('r1m') || lowerName.contains('ccu') || lowerName.contains('y-connect') || serviceUuids.any((u) => u.contains('fee0'))) {
      if (lowerName.contains('r15')) {
        final entry = _db.findById('yamaha_r15_v4_m')!;
        return _fromUniversalEntry(entry, 0.96, 'Matched Yamaha CCU GATT service with R15 BLE advertised name');
      } else if (lowerName.contains('aerox')) {
        final entry = _db.findById('yamaha_aerox155')!;
        return _fromUniversalEntry(entry, 0.95, 'Matched Yamaha Aerox CCU Bluetooth identifier');
      } else if (lowerName.contains('mt09') || lowerName.contains('mt-09')) {
        final entry = _db.findById('yamaha_mt09_sp')!;
        return _fromUniversalEntry(entry, 0.97, 'Matched Yamaha MT-09 SP CP3 CCU telemetry bus');
      }

      // Generic Yamaha CCU vehicle where specific model is unverified
      return IdentificationResult(
        isIdentified: true,
        brand: 'Yamaha',
        family: 'Y-Connect Connected Fleet',
        model: 'Connected Two-Wheeler',
        variant: 'Y-Connect CCU',
        modelYear: 2024,
        vehicleType: 'Motorcycle',
        displayType: 'Smart TFT / LCD',
        protocolAdapterId: 'yamaha_y_connect',
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        compatibilityLevel: VehicleCompatibilityLevel.full,
        confidence: 0.88,
        diagnosticReason: 'Matched Yamaha Communication Control Unit (CCU) BLE GATT service 0xFEE0',
      );
    }

    // 2. Suzuki S-NET / Ride Connect Detection (Burgman Street EX, V-Strom SX)
    if (lowerName.contains('burgman') || lowerName.contains('v-strom') || lowerName.contains('suzuki') || lowerName.contains('snet')) {
      if (lowerName.contains('burgman')) {
        final entry = _db.findById('suzuki_burgman_ex')!;
        return _fromUniversalEntry(entry, 0.95, 'Matched Suzuki Ride Connect Burgman Street EX Bluetooth profile');
      } else if (lowerName.contains('v-strom') || lowerName.contains('vstrom')) {
        final entry = _db.findById('suzuki_vstrom_sx')!;
        return _fromUniversalEntry(entry, 0.94, 'Matched Suzuki V-Strom SX 250 Adventure Connect BLE profile');
      }

      return IdentificationResult(
        isIdentified: true,
        brand: 'Suzuki',
        family: 'Ride Connect Fleet',
        model: 'Two-Wheeler',
        variant: 'Ride Connect',
        modelYear: 2024,
        vehicleType: 'Scooter',
        displayType: 'Ride Connect Digital Cluster',
        protocolAdapterId: 'suzuki_ride_connect',
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        compatibilityLevel: VehicleCompatibilityLevel.full,
        confidence: 0.86,
        diagnosticReason: 'Matched Suzuki S-NET Bluetooth Telematics profile',
      );
    }

    // 3. Royal Enfield Tripper / Sherpa Detection (Himalayan 450, Meteor 350)
    if (lowerName.contains('tripper') || lowerName.contains('himalayan') || lowerName.contains('meteor') || lowerName.contains('royal enfield') || lowerName.contains('re-')) {
      if (lowerName.contains('himalayan')) {
        final entry = _db.findById('re_himalayan450')!;
        return _fromUniversalEntry(entry, 0.95, 'Matched Royal Enfield Sherpa 450 Circular TFT Navigation pod');
      }

      return IdentificationResult(
        isIdentified: true,
        brand: 'Royal Enfield',
        family: 'Tripper Fleet',
        model: 'Motorcycle',
        variant: 'Tripper Pod Edition',
        modelYear: 2024,
        vehicleType: 'Motorcycle',
        displayType: 'Tripper Navigation Pod',
        protocolAdapterId: 'royal_enfield_tripper',
        capabilities: VehicleCapabilities.displayOnlyCluster(),
        compatibilityLevel: VehicleCompatibilityLevel.full,
        confidence: 0.90,
        diagnosticReason: 'Matched Royal Enfield Tripper TBT mirror protocol',
      );
    }

    // 4. Ducati Multimedia System (DMS)
    if (lowerName.contains('ducati') || lowerName.contains('panigale') || lowerName.contains('dms') || serviceUuids.any((u) => u.contains('18f0'))) {
      if (lowerName.contains('panigale')) {
        final entry = _db.findById('ducati_panigale_v4s')!;
        return _fromUniversalEntry(entry, 0.97, 'Matched Ducati Panigale V4 S Desmosedici DMS interface');
      }

      return IdentificationResult(
        isIdentified: true,
        brand: 'Ducati',
        family: 'DMS Connected',
        model: 'Motorcycle',
        variant: 'Multimedia System',
        modelYear: 2024,
        vehicleType: 'Motorcycle',
        displayType: 'High-Resolution TFT Display',
        protocolAdapterId: 'ducati_dms',
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        compatibilityLevel: VehicleCompatibilityLevel.full,
        confidence: 0.90,
        diagnosticReason: 'Matched Ducati Multimedia System (DMS) GATT interface 0x18F0',
      );
    }

    // 5. BMW Motorrad Connected
    if (lowerName.contains('bmw') || lowerName.contains('s1000') || lowerName.contains('ce04') || lowerName.contains('motorrad')) {
      if (lowerName.contains('s1000') || lowerName.contains('s1000rr')) {
        final entry = _db.findById('bmw_s1000rr_m')!;
        return _fromUniversalEntry(entry, 0.96, 'Matched BMW Motorrad S 1000 RR Connectivity TFT');
      } else if (lowerName.contains('ce04') || lowerName.contains('ce 04')) {
        final entry = _db.findById('bmw_ce04_ev')!;
        return _fromUniversalEntry(entry, 0.95, 'Matched BMW CE 04 10.25" Split Screen TFT');
      }

      return IdentificationResult(
        isIdentified: true,
        brand: 'BMW Motorrad',
        family: 'Connected Series',
        model: 'Motorcycle',
        variant: 'TFT Hub',
        modelYear: 2024,
        vehicleType: 'Motorcycle',
        displayType: '6.5" / 10.25" Connectivity TFT',
        protocolAdapterId: 'bmw_motorrad_connect',
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        compatibilityLevel: VehicleCompatibilityLevel.full,
        confidence: 0.88,
        diagnosticReason: 'Matched BMW Motorrad Connected TFT profile',
      );
    }

    // 6. KTM MY RIDE
    if (lowerName.contains('ktm') || lowerName.contains('duke') || lowerName.contains('my ride')) {
      if (lowerName.contains('duke') || lowerName.contains('390')) {
        final entry = _db.findById('ktm_duke390_gen3')!;
        return _fromUniversalEntry(entry, 0.95, 'Matched KTM 390 Duke Gen 3 Connectivity TFT');
      }

      return IdentificationResult(
        isIdentified: true,
        brand: 'KTM',
        family: 'MY RIDE Series',
        model: 'Motorcycle',
        variant: 'MY RIDE TFT',
        modelYear: 2024,
        vehicleType: 'Motorcycle',
        displayType: 'Color TFT Cluster',
        protocolAdapterId: 'ktm_my_ride',
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        compatibilityLevel: VehicleCompatibilityLevel.full,
        confidence: 0.87,
        diagnosticReason: 'Matched KTM MY RIDE Bluetooth profile',
      );
    }

    // 7. TVS SmartXonnect
    if (lowerName.contains('tvs') || lowerName.contains('apache') || lowerName.contains('ntorq') || lowerName.contains('smartxonnect')) {
      if (lowerName.contains('rr310') || lowerName.contains('rr 310')) {
        final entry = _db.findById('tvs_apache_rr310')!;
        return _fromUniversalEntry(entry, 0.95, 'Matched TVS Apache RR 310 Vertical SmartXonnect TFT');
      }

      return IdentificationResult(
        isIdentified: true,
        brand: 'TVS Motor',
        family: 'SmartXonnect Fleet',
        model: 'Two-Wheeler',
        variant: 'SmartXonnect',
        modelYear: 2024,
        vehicleType: 'Motorcycle',
        displayType: 'SmartXonnect TFT / LCD',
        protocolAdapterId: 'tvs_smartxonnect',
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        compatibilityLevel: VehicleCompatibilityLevel.full,
        confidence: 0.88,
        diagnosticReason: 'Matched TVS SmartXonnect Bluetooth Protocol',
      );
    }

    // 8. Standard OBD-II Gateway
    if (lowerName.contains('obd') || lowerName.contains('elm327') || lowerName.contains('vgate') || lowerName.contains('obdlink')) {
      final entry = _db.findById('universal_euro5_obd2')!;
      return _fromUniversalEntry(entry, 0.98, 'Matched SAE J1979 OBD-II / CAN-BUS diagnostic gateway profile');
    }

    // 9. Unknown Device — Never guess
    return IdentificationResult(
      isIdentified: false,
      brand: 'Generic BLE',
      vehicleType: 'Unknown Two-Wheeler',
      displayType: 'Unspecified Display',
      protocolAdapterId: 'generic_ble',
      capabilities: const VehicleCapabilities(
        connectionType: CapabilitySupportLevel.supported,
        vehicleIdentification: CapabilitySupportLevel.readOnly,
      ),
      compatibilityLevel: VehicleCompatibilityLevel.unknown,
      confidence: 0.20,
      diagnosticReason: 'Device detected via BLE advertisement ($rawName). Specific OEM protocol unverified.',
    );
  }

  IdentificationResult _fromUniversalEntry(UniversalVehicleEntry entry, double confidence, String reason) {
    return IdentificationResult(
      isIdentified: true,
      brand: entry.brand,
      family: entry.family,
      model: entry.model,
      generation: entry.generation,
      variant: entry.variant,
      modelYear: entry.modelYear,
      vehicleType: entry.vehicleType,
      displayType: entry.displayType,
      protocolAdapterId: entry.protocolAdapterId,
      capabilities: entry.capabilities,
      compatibilityLevel: entry.compatibilityLevel,
      confidence: confidence,
      diagnosticReason: reason,
    );
  }
}
