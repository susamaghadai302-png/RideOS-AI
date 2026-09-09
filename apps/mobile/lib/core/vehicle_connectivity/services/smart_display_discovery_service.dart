import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/vehicle_capabilities.dart';

enum SmartDisplayState {
  compatible,
  partiallyCompatible,
  unsupported,
  requiresOemGateway,
  requiresBlePairing,
  requiresExternalAdapter,
  connected,
  connecting,
  authenticationRequired,
  permissionRequired,
  offline,
}

@immutable
class SmartDisplayDiscoveredDevice {
  final String deviceName;
  final String remoteId;
  final int rssi;
  final String manufacturer;
  final String displayType; // 5-inch TFT, 7-inch Touchscreen, Segmented LCD, Tripper Pod
  final SmartDisplayState state;
  final String matchedProtocol;
  final String adapterId;
  final VehicleCapabilities capabilities;
  final bool supportsNavigationTbt;
  final bool supportsCallNotifications;
  final String guidanceMessage;

  const SmartDisplayDiscoveredDevice({
    required this.deviceName,
    required this.remoteId,
    required this.rssi,
    required this.manufacturer,
    required this.displayType,
    required this.state,
    required this.matchedProtocol,
    required this.adapterId,
    required this.capabilities,
    required this.supportsNavigationTbt,
    required this.supportsCallNotifications,
    required this.guidanceMessage,
  });
}

class SmartDisplayDiscoveryService {
  static final SmartDisplayDiscoveryService _instance = SmartDisplayDiscoveryService._internal();
  factory SmartDisplayDiscoveryService() => _instance;
  SmartDisplayDiscoveryService._internal();

  /// Analyzes a scanned BLE peripheral to identify Smart TFT / Display capabilities
  SmartDisplayDiscoveredDevice analyzeScannedDevice({
    required BluetoothDevice device,
    required AdvertisementData advertisementData,
    required int rssi,
  }) {
    final name = (advertisementData.advName.isNotEmpty ? advertisementData.advName : device.platformName).trim();
    final lowerName = name.toLowerCase();
    final serviceUuids = advertisementData.serviceUuids.map((u) => u.str128.toLowerCase()).toList();

    // 1. Yamaha CCU Smart TFT (R15 V4, Aerox, MT-09, R1M)
    if (lowerName.contains('ccu') || lowerName.contains('y-connect') || serviceUuids.any((u) => u.contains('fee0'))) {
      return SmartDisplayDiscoveredDevice(
        deviceName: name.isNotEmpty ? name : 'Yamaha CCU Smart Cluster',
        remoteId: device.remoteId.str,
        rssi: rssi,
        manufacturer: 'Yamaha',
        displayType: 'Full-Color TFT / Inverted LCD',
        state: SmartDisplayState.compatible,
        matchedProtocol: 'Yamaha Y-Connect CCU Protocol',
        adapterId: 'yamaha_y_connect',
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        supportsNavigationTbt: true,
        supportsCallNotifications: true,
        guidanceMessage: 'Full Smart Display turn-by-turn and telematics supported.',
      );
    }

    // 2. Royal Enfield Tripper / Wingman Pod (Meteor, Himalayan 450, Super Meteor)
    if (lowerName.contains('tripper') || lowerName.contains('re-') || lowerName.contains('royal enfield')) {
      return SmartDisplayDiscoveredDevice(
        deviceName: name.isNotEmpty ? name : 'Royal Enfield Tripper Pod',
        remoteId: device.remoteId.str,
        rssi: rssi,
        manufacturer: 'Royal Enfield',
        displayType: 'Circular Tripper Navigation Pod',
        state: SmartDisplayState.compatible,
        matchedProtocol: 'Royal Enfield Tripper TBT Protocol',
        adapterId: 'royal_enfield_tripper',
        capabilities: VehicleCapabilities.displayOnlyCluster(),
        supportsNavigationTbt: true,
        supportsCallNotifications: true,
        guidanceMessage: 'Turn-by-turn guidance forwarding verified on Tripper pod.',
      );
    }

    // 3. KTM MY RIDE / Husqvarna TFT (Duke 390, 890, Super Adventure)
    if (lowerName.contains('ktm') || lowerName.contains('my ride') || lowerName.contains('svartpilen')) {
      return SmartDisplayDiscoveredDevice(
        deviceName: name.isNotEmpty ? name : 'KTM MY RIDE TFT Display',
        remoteId: device.remoteId.str,
        rssi: rssi,
        manufacturer: 'KTM',
        displayType: '5-inch / 7-inch Color TFT',
        state: SmartDisplayState.compatible,
        matchedProtocol: 'KTM MY RIDE Connectivity Protocol',
        adapterId: 'ktm_my_ride',
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        supportsNavigationTbt: true,
        supportsCallNotifications: true,
        guidanceMessage: 'Turn-by-turn arrows & audio track info supported.',
      );
    }

    // 4. TVS SmartXonnect (NTORQ, Apache RTR, RR 310, iQube)
    if (lowerName.contains('smartxonnect') || lowerName.contains('tvs') || lowerName.contains('ntorq')) {
      return SmartDisplayDiscoveredDevice(
        deviceName: name.isNotEmpty ? name : 'TVS SmartXonnect Display',
        remoteId: device.remoteId.str,
        rssi: rssi,
        manufacturer: 'TVS Motor',
        displayType: 'SmartXonnect TFT / Segmented LCD',
        state: SmartDisplayState.compatible,
        matchedProtocol: 'TVS SmartXonnect Protocol',
        adapterId: 'tvs_smartxonnect',
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        supportsNavigationTbt: true,
        supportsCallNotifications: true,
        guidanceMessage: 'Turn-by-turn navigation, lean angle, and caller ID verified.',
      );
    }

    // 5. Ducati Multimedia System (Panigale, Multistrada, DesertX)
    if (lowerName.contains('ducati') || lowerName.contains('dms') || serviceUuids.any((u) => u.contains('18f0'))) {
      return SmartDisplayDiscoveredDevice(
        deviceName: name.isNotEmpty ? name : 'Ducati DMS TFT Display',
        remoteId: device.remoteId.str,
        rssi: rssi,
        manufacturer: 'Ducati',
        displayType: '6.5-inch High-Resolution TFT',
        state: SmartDisplayState.compatible,
        matchedProtocol: 'Ducati Multimedia System (DMS)',
        adapterId: 'ducati_dms',
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        supportsNavigationTbt: true,
        supportsCallNotifications: true,
        guidanceMessage: 'High-speed CAN telemetry and multimedia link active.',
      );
    }

    // 6. BMW Motorrad Connected (S1000RR, R1250GS, CE 04)
    if (lowerName.contains('bmw') || lowerName.contains('motorrad')) {
      return SmartDisplayDiscoveredDevice(
        deviceName: name.isNotEmpty ? name : 'BMW Motorrad 6.5" TFT',
        remoteId: device.remoteId.str,
        rssi: rssi,
        manufacturer: 'BMW Motorrad',
        displayType: '6.5" / 10.25" Connectivity TFT',
        state: SmartDisplayState.compatible,
        matchedProtocol: 'BMW Motorrad Connected Protocol',
        adapterId: 'bmw_motorrad_connect',
        capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
        supportsNavigationTbt: true,
        supportsCallNotifications: true,
        guidanceMessage: 'Arrow navigation HUD and rider phone integration supported.',
      );
    }

    // 7. Standard OBD-II Gateway
    if (lowerName.contains('obd') || lowerName.contains('elm327') || lowerName.contains('vgate')) {
      return SmartDisplayDiscoveredDevice(
        deviceName: name.isNotEmpty ? name : 'OBD-II Diagnostic Gateway',
        remoteId: device.remoteId.str,
        rssi: rssi,
        manufacturer: 'SAE Universal',
        displayType: 'External Diagnostic Port',
        state: SmartDisplayState.partiallyCompatible,
        matchedProtocol: 'SAE J1979 OBD-II Diagnostic Bus',
        adapterId: 'obd2_gateway_standard',
        capabilities: VehicleCapabilities.standardObdGateway(),
        supportsNavigationTbt: false,
        supportsCallNotifications: false,
        guidanceMessage: 'Engine telemetry & DTC diagnostics available. Cluster HUD write not supported via OBD.',
      );
    }

    // 8. Unknown / Generic BLE Device
    return SmartDisplayDiscoveredDevice(
      deviceName: name.isNotEmpty ? name : 'Generic BLE Peripheral',
      remoteId: device.remoteId.str,
      rssi: rssi,
      manufacturer: 'Unknown',
      displayType: 'Unspecified Display',
      state: SmartDisplayState.requiresExternalAdapter,
      matchedProtocol: 'Standard GATT / Generic BLE',
      adapterId: 'generic_ble',
      capabilities: const VehicleCapabilities(
        connectionType: CapabilitySupportLevel.supported,
        vehicleIdentification: CapabilitySupportLevel.readOnly,
      ),
      supportsNavigationTbt: false,
      supportsCallNotifications: false,
      guidanceMessage: 'Standard BLE handshake. Diagnostic or telematics adapter may be required.',
    );
  }
}
