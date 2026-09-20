import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum ProtocolDetectionState {
  unknown,
  detected,
  supported,
  unsupported,
  ambiguous,
  error,
}

class ProtocolDetectionResult {
  final ProtocolDetectionState state;
  final String adapterId;
  final String protocolName;
  final double confidence; // 0.0 to 1.0
  final List<String> matchedServiceUuids;
  final String? manufacturerCode;
  final String explanation;

  const ProtocolDetectionResult({
    required this.state,
    required this.adapterId,
    required this.protocolName,
    required this.confidence,
    this.matchedServiceUuids = const [],
    this.manufacturerCode,
    required this.explanation,
  });

  bool get isSupported => state == ProtocolDetectionState.supported;
}

class ProtocolDetector {
  static final ProtocolDetector _instance = ProtocolDetector._internal();
  factory ProtocolDetector() => _instance;
  ProtocolDetector._internal();

  // Known Automotive & Motorcycle GATT Service UUIDs
  static const String uuidYamahaYConnect = '0000fee0';
  static const String uuidDucatiMultimedia = '000018f0';
  static const String uuidObd2Elm327 = '0000fff0';
  static const String uuidObd2Custom = '0000ffe0';
  static const String uuidBatteryService = '0000180f';
  static const String uuidDeviceInformation = '0000180a';

  /// Detects compatible protocol using advertised service UUIDs, manufacturer data, and device name
  ProtocolDetectionResult detectFromScan({
    required BluetoothDevice device,
    required AdvertisementData advertisementData,
  }) {
    final serviceUuids = advertisementData.serviceUuids.map((u) => u.str128.toLowerCase()).toList();
    final deviceName = advertisementData.advName.isNotEmpty ? advertisementData.advName : device.platformName;
    final nameLower = deviceName.toLowerCase();
    final mfgData = advertisementData.manufacturerData; debugPrint(mfgData.toString());

    // 1. Yamaha Y-Connect Protocol Match
    final hasYamahaUuid = serviceUuids.any((u) => u.contains(uuidYamahaYConnect));
    final hasYamahaName = nameLower.contains('ccu') || nameLower.contains('yamaha') || nameLower.contains('y-connect');
    if (hasYamahaUuid || (hasYamahaName && serviceUuids.isNotEmpty)) {
      return ProtocolDetectionResult(
        state: ProtocolDetectionState.supported,
        adapterId: 'yamaha_y_connect',
        protocolName: 'Yamaha Y-Connect CCU Protocol',
        confidence: hasYamahaUuid ? 0.98 : 0.75,
        matchedServiceUuids: serviceUuids.where((u) => u.contains(uuidYamahaYConnect)).toList(),
        explanation: 'Matched Yamaha Communication Control Unit (CCU) BLE GATT service.',
      );
    }

    // 2. Ducati Multimedia System Protocol Match
    final hasDucatiUuid = serviceUuids.any((u) => u.contains(uuidDucatiMultimedia));
    final hasDucatiName = nameLower.contains('dms') || nameLower.contains('ducati');
    if (hasDucatiUuid || (hasDucatiName && serviceUuids.isNotEmpty)) {
      return ProtocolDetectionResult(
        state: ProtocolDetectionState.supported,
        adapterId: 'ducati_multimedia',
        protocolName: 'Ducati Multimedia System (DMS)',
        confidence: hasDucatiUuid ? 0.98 : 0.75,
        matchedServiceUuids: serviceUuids.where((u) => u.contains(uuidDucatiMultimedia)).toList(),
        explanation: 'Matched Ducati Multimedia System GATT interface.',
      );
    }

    // 3. Standard OBD-II / ELM327 Protocol Match
    final hasObdUuid = serviceUuids.any((u) => u.contains(uuidObd2Elm327) || u.contains(uuidObd2Custom));
    final hasObdName = nameLower.contains('obd') || nameLower.contains('elm327') || nameLower.contains('vgate') || nameLower.contains('obdlink');
    if (hasObdUuid || hasObdName) {
      return ProtocolDetectionResult(
        state: ProtocolDetectionState.supported,
        adapterId: 'obd2_standard',
        protocolName: 'SAE J1979 OBD-II / CAN-BUS Protocol',
        confidence: (hasObdUuid && hasObdName) ? 0.99 : 0.85,
        matchedServiceUuids: serviceUuids.where((u) => u.contains(uuidObd2Elm327) || u.contains(uuidObd2Custom)).toList(),
        explanation: 'Matched standard ELM327 / OBD-II transparent serial GATT profile.',
      );
    }

    // 4. Generic BLE Battery / Device Info
    final hasBattery = serviceUuids.any((u) => u.contains(uuidBatteryService));
    if (hasBattery) {
      return const ProtocolDetectionResult(
        state: ProtocolDetectionState.supported,
        adapterId: 'generic_ble',
        protocolName: 'Generic BLE Telemetry (Read-Only)',
        confidence: 0.60,
        explanation: 'Discovered standard Battery Service. Supports read-only 12V telemetry.',
      );
    }

    // 5. Ambiguous or Unsupported
    if (serviceUuids.isNotEmpty) {
      return ProtocolDetectionResult(
        state: ProtocolDetectionState.ambiguous,
        adapterId: 'generic_ble',
        protocolName: 'Unknown GATT Profile',
        confidence: 0.20,
        matchedServiceUuids: serviceUuids,
        explanation: 'Discovered non-standard service UUIDs. Manual identification required.',
      );
    }

    return const ProtocolDetectionResult(
      state: ProtocolDetectionState.unknown,
      adapterId: 'unknown',
      protocolName: 'Unknown Device',
      confidence: 0.0,
      explanation: 'No recognized automotive GATT service UUIDs detected.',
    );
  }
}
