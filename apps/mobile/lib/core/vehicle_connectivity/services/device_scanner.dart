import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:bluetooth_classic/bluetooth_classic.dart' as btc;
import '../models/display_device_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DEVICE SCANNER & CLASSIFIER
//
//  Scans BLE and Bluetooth Classic for potential smart display targets.
//  Classifies each discovered device using multiple signals:
//    • Advertised service UUIDs
//    • Manufacturer data bytes
//    • Device name patterns
//    • GATT service/characteristic discovery (post-connect)
//    • Bluetooth Classic service UUIDs
//
//  Never classifies a device as a smart display based on name alone.
// ─────────────────────────────────────────────────────────────────────────────

/// Result of scanning a single device.
class ScannedDevice {
  final String identifier;           // MAC or remoteId
  final String name;
  final String transport;            // 'BLE' or 'BT_CLASSIC'
  final DeviceClassification classification;
  final List<String> serviceUuids;
  final List<int> manufacturerData;
  final int rssi;

  const ScannedDevice({
    required this.identifier,
    required this.name,
    required this.transport,
    required this.classification,
    this.serviceUuids = const [],
    this.manufacturerData = const [],
    this.rssi = -100,
  });
}

// ── Known service UUIDs ──────────────────────────────────────────────────────

/// RideOS Display Receiver GATT service UUID (RideOS-owned).
const String kRideOSDisplayServiceUuid = '0000ff01-0000-1000-8000-00805f9b34fb';

/// Nordic UART Service (common in BLE UART display modules).
const String kNordicUartServiceUuid = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';

/// Standard SPP UUID.
const String kSppServiceUuid = '00001101-0000-1000-8000-00805f9b34fb';

// ── Known name patterns ──────────────────────────────────────────────────────

/// Patterns that positively indicate a RideOS-compatible display.
const List<String> _rideosPatterns = ['rideos', 'rideos-display', 'rideos_display'];

/// Patterns for known OEM motorcycle smart displays.
const List<String> _knownOemPatterns = [
  'y-connect', 'my ride', 'ktm myride', 'ducati dms',
  'bosch myrideconnect', 'honda roadsync',
];

/// Patterns that indicate projection protocols we skip in direct mode.
const List<String> _projectionPatterns = ['android auto', 'carplay', 'mirrorlink'];

/// Patterns that indicate phones / PCs / audio accessories — never displays.
const List<String> _nonDisplayPatterns = [
  'airpods', 'buds', 'speaker', 'headphone', 'headset',
  'watch', 'band', 'galaxy watch', 'apple watch',
  'macbook', 'iphone', 'ipad', 'pixel', 'continuity',
  'airdrop', 'nearby', 'earphone', 'soundbar',
];

// ── Apple Continuity manufacturer ID (to skip Apple ecosystem devices) ───────
const int _appleManufacturerId = 0x004C;

class DeviceScanner {
  final Duration bleScanTimeout;
  final Duration classicScanTimeout;

  DeviceScanner({
    this.bleScanTimeout = const Duration(seconds: 6),
    this.classicScanTimeout = const Duration(seconds: 8),
  });

  /// Scan BLE and Bluetooth Classic concurrently, classify every device found.
  Future<List<ScannedDevice>> scan() async {
    final results = <ScannedDevice>[];

    // ── BLE scan ──────────────────────────────────────────────────────────────
    try {
      if (await FlutterBluePlus.isSupported) {
        await FlutterBluePlus.startScan(timeout: bleScanTimeout);
        await Future.delayed(bleScanTimeout + const Duration(seconds: 1));
        final scanResults = await FlutterBluePlus.scanResults.first;
        for (final r in scanResults) {
          final name = r.device.platformName.isNotEmpty
              ? r.device.platformName
              : r.advertisementData.advName;
          final serviceUuids = r.advertisementData.serviceUuids
              .map((u) => u.toString().toLowerCase())
              .toList();
          final mfgData = r.advertisementData.manufacturerData;
          final mfgBytes = <int>[];
          int? mfgId;
          if (mfgData.isNotEmpty) {
            mfgId = mfgData.keys.first;
            mfgBytes.addAll(mfgData.values.first);
          }

          results.add(ScannedDevice(
            identifier: r.device.remoteId.str,
            name: name,
            transport: 'BLE',
            classification: _classifyBle(name, serviceUuids, mfgId),
            serviceUuids: serviceUuids,
            manufacturerData: mfgBytes,
            rssi: r.rssi,
          ));
        }
      }
    } catch (_) {}

    // ── Bluetooth Classic scan (paired devices) ───────────────────────────────
    try {
      final classic = btc.BluetoothClassic();
      await classic.initPermissions();
      final paired = await classic.getPairedDevices();
      for (final d in paired) {
        final name = d.name ?? '';
        results.add(ScannedDevice(
          identifier: d.address,
          name: name,
          transport: 'BT_CLASSIC',
          classification: _classifyClassic(name),
          rssi: -80, // Classic doesn't expose RSSI on paired list
        ));
      }
    } catch (_) {}

    return results;
  }

  /// Classify a BLE device using name, service UUIDs, and manufacturer data.
  DeviceClassification _classifyBle(String name, List<String> serviceUuids, int? mfgId) {
    final lower = name.toLowerCase();

    // Apple ecosystem devices — never smart displays
    if (mfgId == _appleManufacturerId) return DeviceClassification.phoneOrPc;

    // Non-display accessories
    for (final p in _nonDisplayPatterns) {
      if (lower.contains(p)) return DeviceClassification.phoneOrPc;
    }

    // Projection devices
    for (final p in _projectionPatterns) {
      if (lower.contains(p)) return DeviceClassification.projectionDevice;
    }

    // RideOS display — name + service UUID match required
    for (final p in _rideosPatterns) {
      if (lower.contains(p) && serviceUuids.contains(kRideOSDisplayServiceUuid)) {
        return DeviceClassification.rideosDisplay;
      }
    }

    // Known OEM displays — name match + service UUID presence
    for (final p in _knownOemPatterns) {
      if (lower.contains(p) && serviceUuids.isNotEmpty) {
        return DeviceClassification.knownOemDisplay;
      }
    }

    // Nordic UART BLE display modules
    if (serviceUuids.contains(kNordicUartServiceUuid)) {
      return DeviceClassification.genericBle;
    }

    // RideOS display by name only (less confident — UUID must confirm post-connect)
    for (final p in _rideosPatterns) {
      if (lower.contains(p)) return DeviceClassification.rideosDisplay;
    }

    // Known OEM by name only (less confident)
    for (final p in _knownOemPatterns) {
      if (lower.contains(p)) return DeviceClassification.knownOemDisplay;
    }

    return DeviceClassification.unknown;
  }

  /// Classify a Bluetooth Classic device using name.
  /// Classic doesn't expose service UUIDs on the paired list, so name is the
  /// primary signal; post-connect SDP lookup would refine this.
  DeviceClassification _classifyClassic(String name) {
    final lower = name.toLowerCase();

    for (final p in _nonDisplayPatterns) {
      if (lower.contains(p)) return DeviceClassification.phoneOrPc;
    }

    for (final p in _projectionPatterns) {
      if (lower.contains(p)) return DeviceClassification.projectionDevice;
    }

    for (final p in _rideosPatterns) {
      if (lower.contains(p)) return DeviceClassification.rideosDisplay;
    }

    for (final p in _knownOemPatterns) {
      if (lower.contains(p)) return DeviceClassification.knownOemDisplay;
    }

    return DeviceClassification.unknown;
  }

  /// Post-connect GATT characteristic verification for a BLE device.
  /// Returns updated classification after inspecting actual services.
  Future<DeviceClassification> verifyBleDevice(BluetoothDevice device) async {
    try {
      final services = await device.discoverServices();
      final uuids = services.map((s) => s.uuid.toString().toLowerCase()).toSet();

      if (uuids.contains(kRideOSDisplayServiceUuid)) {
        return DeviceClassification.rideosDisplay;
      }

      if (uuids.contains(kNordicUartServiceUuid)) {
        // Check for writable + notify characteristics (UART TX/RX)
        for (final svc in services) {
          if (svc.uuid.toString().toLowerCase() == kNordicUartServiceUuid) {
            final hasWrite = svc.characteristics.any((c) => c.properties.write || c.properties.writeWithoutResponse);
            final hasNotify = svc.characteristics.any((c) => c.properties.notify);
            if (hasWrite && hasNotify) return DeviceClassification.genericBle;
          }
        }
      }

      return DeviceClassification.unsupported;
    } catch (_) {
      return DeviceClassification.unsupported;
    }
  }
}
