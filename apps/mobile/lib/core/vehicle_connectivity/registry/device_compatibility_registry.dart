import '../models/display_device_profile.dart';
import '../models/display_capability.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DEVICE COMPATIBILITY REGISTRY — Machine-readable compatibility matrix
//
//  Each entry describes a known motorcycle / scooter display, its transport,
//  protocol, and the exact set of capabilities it supports.
//
//  verificationStatus:
//    • UNVERIFIED       — Listed based on documentation; no testing done.
//    • SOFTWARE_ONLY    — Protocol encoder verified in unit tests.
//    • PROTOCOL_VERIFIED — Handshake successfully exchanged with real firmware.
//    • HARDWARE_VERIFIED — Full end-to-end test with physical hardware.
// ─────────────────────────────────────────────────────────────────────────────

class CompatibilityEntry {
  final String brand;
  final String model;
  final String displayType;           // 'TFT', 'LCD', 'LED', 'OLED', 'APP'
  final String transport;             // 'BLE', 'BT_CLASSIC', 'WIFI'
  final String protocol;              // Protocol ID from registry
  final String? serviceUuid;
  final String? characteristicUuid;
  final bool projectionSupported;
  final bool navigationSupported;
  final bool mapSupported;
  final bool weatherSupported;
  final bool clockSupported;
  final bool callNotifications;
  final VerificationStatus verificationStatus;
  final Set<DisplayCapability> capabilities;

  const CompatibilityEntry({
    required this.brand,
    required this.model,
    required this.displayType,
    required this.transport,
    required this.protocol,
    this.serviceUuid,
    this.characteristicUuid,
    this.projectionSupported = false,
    this.navigationSupported = false,
    this.mapSupported = false,
    this.weatherSupported = false,
    this.clockSupported = false,
    this.callNotifications = false,
    this.verificationStatus = VerificationStatus.unverified,
    this.capabilities = const {},
  });

  Map<String, dynamic> toJson() => {
    'brand': brand,
    'model': model,
    'display_type': displayType,
    'transport': transport,
    'protocol': protocol,
    'service_uuid': serviceUuid,
    'characteristic_uuid': characteristicUuid,
    'projection_supported': projectionSupported,
    'navigation_supported': navigationSupported,
    'map_supported': mapSupported,
    'weather_supported': weatherSupported,
    'clock_supported': clockSupported,
    'call_notifications': callNotifications,
    'verification_status': verificationStatus.name,
    'capabilities': capabilities.map((c) => c.name).toList(),
  };
}

class DeviceCompatibilityRegistry {
  static final DeviceCompatibilityRegistry _instance = DeviceCompatibilityRegistry._internal();
  factory DeviceCompatibilityRegistry() => _instance;
  DeviceCompatibilityRegistry._internal();

  /// The built-in compatibility matrix.
  ///
  /// Every entry here is SOFTWARE_ONLY or UNVERIFIED unless hardware testing
  /// has been conducted.  Never upgrade to HARDWARE_VERIFIED without physical
  /// test evidence.
  final List<CompatibilityEntry> entries = const [
    // ── RideOS Display Receiver ─────────────────────────────────────────────
    CompatibilityEntry(
      brand: 'RideOS',
      model: 'RideOS Display Receiver',
      displayType: 'APP',
      transport: 'BLE',
      protocol: 'rideos_native_v1',
      serviceUuid: '0000ff01-0000-1000-8000-00805f9b34fb',
      navigationSupported: true,
      weatherSupported: true,
      clockSupported: true,
      callNotifications: true,
      verificationStatus: VerificationStatus.softwareOnly,
      capabilities: {
        DisplayCapability.turnByTurnNavigation,
        DisplayCapability.nextTurn,
        DisplayCapability.distanceToTurn,
        DisplayCapability.distanceToDestination,
        DisplayCapability.eta,
        DisplayCapability.streetName,
        DisplayCapability.speed,
        DisplayCapability.compass,
        DisplayCapability.tripDistance,
        DisplayCapability.rideTime,
        DisplayCapability.clock,
        DisplayCapability.weather,
        DisplayCapability.temperature,
        DisplayCapability.rainWarning,
        DisplayCapability.dayNightMode,
        DisplayCapability.phoneBattery,
        DisplayCapability.callNotification,
        DisplayCapability.messageNotification,
        DisplayCapability.genericNotification,
        DisplayCapability.overspeedWarning,
        DisplayCapability.routeDeviation,
        DisplayCapability.arrivalAlert,
        DisplayCapability.rerouteAlert,
        DisplayCapability.emergencySos,
        DisplayCapability.connectionLostAlert,
      },
    ),

    // ── Generic Nordic UART BLE Display Module ──────────────────────────────
    CompatibilityEntry(
      brand: 'Generic',
      model: 'Nordic UART BLE Display Module',
      displayType: 'LCD',
      transport: 'BLE',
      protocol: 'generic_ble_json_v1',
      serviceUuid: '6e400001-b5a3-f393-e0a9-e50e24dcca9e',
      navigationSupported: true,
      clockSupported: true,
      verificationStatus: VerificationStatus.softwareOnly,
      capabilities: {
        DisplayCapability.turnByTurnNavigation,
        DisplayCapability.nextTurn,
        DisplayCapability.distanceToTurn,
        DisplayCapability.eta,
        DisplayCapability.streetName,
        DisplayCapability.speed,
        DisplayCapability.clock,
        DisplayCapability.phoneBattery,
        DisplayCapability.genericNotification,
      },
    ),

    // ── Generic Bluetooth Classic SPP Display ────────────────────────────────
    CompatibilityEntry(
      brand: 'Generic',
      model: 'Bluetooth Classic SPP Display',
      displayType: 'TFT',
      transport: 'BT_CLASSIC',
      protocol: 'bt_classic_spp_v1',
      serviceUuid: '00001101-0000-1000-8000-00805f9b34fb',
      navigationSupported: true,
      weatherSupported: true,
      clockSupported: true,
      callNotifications: true,
      verificationStatus: VerificationStatus.softwareOnly,
      capabilities: {
        DisplayCapability.turnByTurnNavigation,
        DisplayCapability.nextTurn,
        DisplayCapability.distanceToTurn,
        DisplayCapability.distanceToDestination,
        DisplayCapability.eta,
        DisplayCapability.streetName,
        DisplayCapability.speed,
        DisplayCapability.clock,
        DisplayCapability.weather,
        DisplayCapability.temperature,
        DisplayCapability.phoneBattery,
        DisplayCapability.callNotification,
        DisplayCapability.genericNotification,
      },
    ),

    // ── Yamaha Y-Connect ─────────────────────────────────────────────────────
    CompatibilityEntry(
      brand: 'Yamaha',
      model: 'Y-Connect TFT',
      displayType: 'TFT',
      transport: 'BLE',
      protocol: 'generic_ble_json_v1', // Proprietary protocol unknown — generic fallback
      navigationSupported: true,
      callNotifications: true,
      verificationStatus: VerificationStatus.unverified,
      capabilities: {
        DisplayCapability.turnByTurnNavigation,
        DisplayCapability.nextTurn,
        DisplayCapability.distanceToTurn,
        DisplayCapability.callNotification,
        DisplayCapability.messageNotification,
      },
    ),

    // ── KTM MY RIDE ──────────────────────────────────────────────────────────
    CompatibilityEntry(
      brand: 'KTM',
      model: 'MY RIDE TFT',
      displayType: 'TFT',
      transport: 'BLE',
      protocol: 'generic_ble_json_v1', // Proprietary — unverified
      navigationSupported: true,
      callNotifications: true,
      verificationStatus: VerificationStatus.unverified,
      capabilities: {
        DisplayCapability.turnByTurnNavigation,
        DisplayCapability.nextTurn,
        DisplayCapability.distanceToTurn,
        DisplayCapability.callNotification,
      },
    ),

    // ── Honda RoadSync ───────────────────────────────────────────────────────
    CompatibilityEntry(
      brand: 'Honda',
      model: 'RoadSync Display',
      displayType: 'TFT',
      transport: 'BLE',
      protocol: 'generic_ble_json_v1', // Proprietary — unverified
      navigationSupported: true,
      callNotifications: true,
      verificationStatus: VerificationStatus.unverified,
      capabilities: {
        DisplayCapability.turnByTurnNavigation,
        DisplayCapability.nextTurn,
        DisplayCapability.callNotification,
      },
    ),

    // ── Ducati DMS ───────────────────────────────────────────────────────────
    CompatibilityEntry(
      brand: 'Ducati',
      model: 'DMS Multistrada TFT',
      displayType: 'TFT',
      transport: 'BLE',
      protocol: 'generic_ble_json_v1', // Proprietary — unverified
      navigationSupported: true,
      verificationStatus: VerificationStatus.unverified,
      capabilities: {
        DisplayCapability.turnByTurnNavigation,
        DisplayCapability.nextTurn,
        DisplayCapability.distanceToTurn,
      },
    ),
  ];

  /// Find all compatible entries for a given brand (case-insensitive).
  List<CompatibilityEntry> findByBrand(String brand) {
    final lower = brand.toLowerCase();
    return entries.where((e) => e.brand.toLowerCase() == lower).toList();
  }

  /// Find an entry by model name (case-insensitive, partial match).
  CompatibilityEntry? findByModel(String model) {
    final lower = model.toLowerCase();
    for (final e in entries) {
      if (e.model.toLowerCase().contains(lower)) return e;
    }
    return null;
  }

  /// All entries as JSON for export / display.
  List<Map<String, dynamic>> toJson() => entries.map((e) => e.toJson()).toList();
}
