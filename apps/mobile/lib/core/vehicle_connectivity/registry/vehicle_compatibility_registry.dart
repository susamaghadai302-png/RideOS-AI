import 'package:flutter/foundation.dart';
import '../../transport/models/transport_types.dart';
import '../../vehicle_capabilities/models/universal_vehicle_capability_models.dart';

enum VehicleCompatibilityStatus {
  supported,
  partiallySupported,
  detectedButUnverified,
  unsupported,
  unknown,
}

@immutable
class CompatibilityRegistryEntry {
  final String entryId;
  final String manufacturer;
  final String brand;
  final String model;
  final String modelYearRange;
  final VariantTrimLevel variantTrim;
  final String region;
  final String displayGeneration;
  final String ecuGatewayGeneration;
  final TransportType primaryTransport;
  final List<String> supportedProtocols;
  final List<String> supportedTelemetry;
  final List<String> supportedCommands;
  final String pairingRequirements;
  final bool isReadOnly;
  final String safetyRestrictions;
  final String protocolVersion;
  final VehicleCompatibilityStatus status;

  const CompatibilityRegistryEntry({
    required this.entryId,
    required this.manufacturer,
    required this.brand,
    required this.model,
    required this.modelYearRange,
    required this.variantTrim,
    required this.region,
    required this.displayGeneration,
    required this.ecuGatewayGeneration,
    required this.primaryTransport,
    required this.supportedProtocols,
    required this.supportedTelemetry,
    this.supportedCommands = const [],
    required this.pairingRequirements,
    this.isReadOnly = true,
    required this.safetyRestrictions,
    required this.protocolVersion,
    required this.status,
  });
}

class VehicleCompatibilityRegistry {
  static final VehicleCompatibilityRegistry _instance = VehicleCompatibilityRegistry._internal();
  factory VehicleCompatibilityRegistry() => _instance;

  final List<CompatibilityRegistryEntry> _entries = [];
  List<CompatibilityRegistryEntry> get entries => List.unmodifiable(_entries);

  VehicleCompatibilityRegistry._internal() {
    _populateDefaultRegistry();
  }

  void registerProfile(CompatibilityRegistryEntry entry) {
    final existingIdx = _entries.indexWhere((e) => e.entryId == entry.entryId);
    if (existingIdx != -1) {
      _entries[existingIdx] = entry;
    } else {
      _entries.add(entry);
    }
  }

  CompatibilityRegistryEntry matchDeviceSignature({
    required String deviceName,
    required List<String> advertisedServices,
  }) {
    final lowerName = deviceName.toLowerCase();

    if (lowerName.contains('yamaha') || advertisedServices.any((s) => s.toLowerCase().contains('fee0'))) {
      return _entries.firstWhere((e) => e.entryId == 'yamaha_r15m_ccu');
    }

    if (lowerName.contains('tripper') || lowerName.contains('re_') || advertisedServices.any((s) => s.toLowerCase().contains('fe50'))) {
      return _entries.firstWhere((e) => e.entryId == 're_himalayan_tripper');
    }

    if (lowerName.contains('ather') || advertisedServices.any((s) => s.toLowerCase().contains('18f0'))) {
      return _entries.firstWhere((e) => e.entryId == 'ather_450x_pro');
    }

    // Default unverified / generic diagnostic entry
    return _entries.firstWhere((e) => e.entryId == 'generic_obd_gateway');
  }

  void _populateDefaultRegistry() {
    // 1. Yamaha R15M CCU
    _entries.add(const CompatibilityRegistryEntry(
      entryId: 'yamaha_r15m_ccu',
      manufacturer: 'Yamaha Motor Co.',
      brand: 'Yamaha',
      model: 'YZF-R15M / MT-15 V2',
      modelYearRange: '2021-Present',
      variantTrim: VariantTrimLevel.topPremium,
      region: 'Global / APAC / EU',
      displayGeneration: 'Gen 3 Full Color TFT',
      ecuGatewayGeneration: 'Yamaha CCU BLE v2.1',
      primaryTransport: TransportType.bluetoothLowEnergy,
      supportedProtocols: ['Yamaha Y-Connect GATT', 'OBD-II Passthrough'],
      supportedTelemetry: ['speed', 'rpm', 'fuelLevel', 'batteryVoltage', 'coolantTemp', 'absStatus'],
      supportedCommands: ['WRITE_TBT_NAVIGATION_ARROW', 'WRITE_CALLER_ID_ALERT'],
      pairingRequirements: 'BLE Secure Simple Pairing (Numeric Comparison)',
      isReadOnly: false,
      safetyRestrictions: 'Read-only engine sensors. Write operations strictly restricted to Turn-by-Turn display HUD frame.',
      protocolVersion: 'Y-Connect v2.1',
      status: VehicleCompatibilityStatus.supported,
    ));

    // 2. Royal Enfield Himalayan 450 Tripper
    _entries.add(const CompatibilityRegistryEntry(
      entryId: 're_himalayan_tripper',
      manufacturer: 'Royal Enfield',
      brand: 'Royal Enfield',
      model: 'Himalayan 450 / Guerrilla 450',
      modelYearRange: '2023-Present',
      variantTrim: VariantTrimLevel.topPremium,
      region: 'Global / EU / India',
      displayGeneration: 'Round 4-inch TFT Tripper Dash',
      ecuGatewayGeneration: 'RE Sherpa BLE Gateway',
      primaryTransport: TransportType.bluetoothLowEnergy,
      supportedProtocols: ['RE Tripper Navigation GATT', 'Sherpa Telematics'],
      supportedTelemetry: ['speed', 'rpm', 'gear', 'fuelLevel', 'absStatus'],
      supportedCommands: ['WRITE_TBT_NAVIGATION_ARROW'],
      pairingRequirements: 'BLE JustWorks / PIN Authentication',
      isReadOnly: false,
      safetyRestrictions: 'Display mirroring only. No powertrain or brake actuation permitted.',
      protocolVersion: 'TripperOS v3.0',
      status: VehicleCompatibilityStatus.supported,
    ));

    // 3. Ather 450X Pro
    _entries.add(const CompatibilityRegistryEntry(
      entryId: 'ather_450x_pro',
      manufacturer: 'Ather Energy',
      brand: 'Ather',
      model: '450X Gen 3 / 450 Apex',
      modelYearRange: '2022-Present',
      variantTrim: VariantTrimLevel.topPremium,
      region: 'India / Global',
      displayGeneration: '7-inch Android Touchscreen TFT',
      ecuGatewayGeneration: 'AtherStack 5.0 Cloud Telematics Gateway',
      primaryTransport: TransportType.wifiTcp, // Placeholder for oemApi
      supportedProtocols: ['Ather Connect Cloud REST API', 'Local BLE Gateway'],
      supportedTelemetry: ['speed', 'batterySoc', 'batteryVoltage', 'motorTemp', 'tpms', 'chargingStatus'],
      supportedCommands: [],
      pairingRequirements: 'OAuth 2.0 Authorization Code Flow',
      isReadOnly: true,
      safetyRestrictions: 'Strictly passive cloud telemetry. Commands disabled on mobile client.',
      protocolVersion: 'AtherStack v5.2',
      status: VehicleCompatibilityStatus.supported,
    ));

    // 4. Generic SAE J1979 OBD-II Gateway
    _entries.add(const CompatibilityRegistryEntry(
      entryId: 'generic_obd_gateway',
      manufacturer: 'Universal Standards',
      brand: 'Universal Two-Wheeler',
      model: 'Euro 4/5/6 & BS-VI Compliant',
      modelYearRange: '2015-Present',
      variantTrim: VariantTrimLevel.base,
      region: 'Global',
      displayGeneration: 'Analog / Segment LCD',
      ecuGatewayGeneration: 'Standard 4-pin / 6-pin Diagnostic Port',
      primaryTransport: TransportType.usbOtgSerial, // Placeholder for obdGateway
      supportedProtocols: ['ISO 15765-4 (CAN 11/500)', 'SAE J1979 Standard PIDs'],
      supportedTelemetry: ['speed', 'rpm', 'coolantTemp', 'batteryVoltage'],
      supportedCommands: [],
      pairingRequirements: 'Bluetooth Classic PIN / BLE Dongle Discovery',
      isReadOnly: true,
      safetyRestrictions: 'Diagnostic query only (Service 01). ECU flashing (Service 34/36) is strictly prohibited.',
      protocolVersion: 'SAE J1979 Rev 2017',
      status: VehicleCompatibilityStatus.partiallySupported,
    ));
  }
}
