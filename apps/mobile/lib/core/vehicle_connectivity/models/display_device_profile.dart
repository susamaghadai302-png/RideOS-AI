import 'package:flutter/foundation.dart';
import 'display_capability.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DISPLAY DEVICE PROFILE — Identity + negotiated capabilities of a target
//
//  Built after discovery + capability negotiation.  Immutable once created.
// ─────────────────────────────────────────────────────────────────────────────

/// Classification assigned by the scanner to every discovered Bluetooth device.
enum DeviceClassification {
  unknown,
  genericBle,
  genericClassic,
  rideosDisplay,
  knownOemDisplay,
  projectionDevice,
  phoneOrPc,
  unsupported,
}

/// The display mode the device operates in.
enum DisplayMode {
  /// MODE A — Native OEM protocol
  nativeOem,
  /// MODE B — RideOS-owned receiver protocol
  rideosReceiver,
  /// MODE C — Projection / screen mirroring (AA, CarPlay, proprietary)
  projection,
}

/// Verification level for compatibility claims.
enum VerificationStatus {
  unverified,
  softwareOnly,
  protocolVerified,
  hardwareVerified,
}

@immutable
class DisplayDeviceProfile {
  final String manufacturer;
  final String model;
  final String transportType;        // 'BLE' | 'BT_CLASSIC' | 'WIFI'
  final String protocolType;         // e.g. 'RIDEOS_NATIVE', 'GENERIC_BLE', 'GENERIC_CLASSIC'
  final DeviceClassification classification;
  final DisplayMode displayMode;
  final List<String> serviceUuids;
  final List<String> characteristics;
  final Set<DisplayCapability> supportedCapabilities;
  final String? firmwareVersion;
  final String? macAddress;
  final VerificationStatus verificationStatus;

  const DisplayDeviceProfile({
    required this.manufacturer,
    required this.model,
    required this.transportType,
    required this.protocolType,
    this.classification = DeviceClassification.unknown,
    this.displayMode = DisplayMode.rideosReceiver,
    this.serviceUuids = const [],
    this.characteristics = const [],
    this.supportedCapabilities = const {},
    this.firmwareVersion,
    this.macAddress,
    this.verificationStatus = VerificationStatus.unverified,
  });

  /// Whether this profile has a specific capability negotiated.
  bool supports(DisplayCapability cap) => supportedCapabilities.contains(cap);

  /// Creates a copy with updated capabilities (after negotiation).
  DisplayDeviceProfile withCapabilities(Set<DisplayCapability> caps) {
    return DisplayDeviceProfile(
      manufacturer: manufacturer,
      model: model,
      transportType: transportType,
      protocolType: protocolType,
      classification: classification,
      displayMode: displayMode,
      serviceUuids: serviceUuids,
      characteristics: characteristics,
      supportedCapabilities: caps,
      firmwareVersion: firmwareVersion,
      macAddress: macAddress,
      verificationStatus: verificationStatus,
    );
  }

  Map<String, dynamic> toJson() => {
    'manufacturer': manufacturer,
    'model': model,
    'transportType': transportType,
    'protocolType': protocolType,
    'classification': classification.name,
    'displayMode': displayMode.name,
    'serviceUuids': serviceUuids,
    'characteristics': characteristics,
    'supportedCapabilities': supportedCapabilities.map((c) => c.name).toList(),
    'firmwareVersion': firmwareVersion,
    'macAddress': macAddress,
    'verificationStatus': verificationStatus.name,
  };
}
