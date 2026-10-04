// ─────────────────────────────────────────────────────────────────────────────
//  PRODUCT FEATURE MATRIX — Machine-readable capability registry
//
//  For each feature, stores: supported, transport, protocol,
//  verification status, evidence/source, and notes.
//
//  TRUTH RULE: No feature may claim HARDWARE_VERIFIED without actual
//  captured evidence from a real device.
// ─────────────────────────────────────────────────────────────────────────────

import 'display_device_profile.dart';

class FeatureEntry {
  final String featureId;
  final String featureName;
  final bool supported;
  final String transport;          // 'BLE', 'BT_CLASSIC', 'WIFI', 'N/A'
  final String protocol;           // Protocol ID or 'N/A'
  final VerificationStatus verification;
  final String evidence;           // 'public_docs', 'captured_packet', 'none'
  final String notes;

  const FeatureEntry({
    required this.featureId,
    required this.featureName,
    required this.supported,
    required this.transport,
    required this.protocol,
    required this.verification,
    required this.evidence,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
    'featureId': featureId,
    'featureName': featureName,
    'supported': supported,
    'transport': transport,
    'protocol': protocol,
    'verification': verification.name,
    'evidence': evidence,
    'notes': notes,
  };
}

/// Returns the complete product feature matrix.
/// This is the single source of truth for what RideOS Smart Display supports.
List<FeatureEntry> buildFeatureMatrix() => const [
  // ── Navigation ─────────────────────────────────────────────────────────
  FeatureEntry(
    featureId: 'navigation',
    featureName: 'Turn-by-Turn Navigation',
    supported: true,
    transport: 'BLE / BT_CLASSIC',
    protocol: 'rideos_native_v1 / generic_ble_json_v1 / bt_classic_spp_v1',
    verification: VerificationStatus.softwareOnly,
    evidence: 'unit_tests + protocol_implementation',
    notes: 'Requires real display device to reach HARDWARE_VERIFIED',
  ),
  FeatureEntry(
    featureId: 'weather',
    featureName: 'Weather Condition',
    supported: true,
    transport: 'BLE / BT_CLASSIC',
    protocol: 'rideos_native_v1 / generic_ble_json_v1 / bt_classic_spp_v1',
    verification: VerificationStatus.softwareOnly,
    evidence: 'unit_tests',
    notes: 'Only sent when negotiated by target device',
  ),
  FeatureEntry(
    featureId: 'clock',
    featureName: 'Current Time',
    supported: true,
    transport: 'BLE / BT_CLASSIC',
    protocol: 'rideos_native_v1 / generic_ble_json_v1 / bt_classic_spp_v1',
    verification: VerificationStatus.softwareOnly,
    evidence: 'unit_tests',
  ),
  FeatureEntry(
    featureId: 'speed',
    featureName: 'GPS-derived Speed',
    supported: true,
    transport: 'BLE / BT_CLASSIC',
    protocol: 'rideos_native_v1 / generic_ble_json_v1 / bt_classic_spp_v1',
    verification: VerificationStatus.softwareOnly,
    evidence: 'unit_tests',
    notes: 'Speed is from phone GPS, not from vehicle ECU',
  ),
  FeatureEntry(
    featureId: 'calls',
    featureName: 'Incoming Call Notification',
    supported: true,
    transport: 'BLE / BT_CLASSIC',
    protocol: 'rideos_native_v1 / generic_ble_json_v1 / bt_classic_spp_v1',
    verification: VerificationStatus.softwareOnly,
    evidence: 'unit_tests',
  ),
  FeatureEntry(
    featureId: 'messages',
    featureName: 'Message Notification',
    supported: true,
    transport: 'BLE / BT_CLASSIC',
    protocol: 'rideos_native_v1',
    verification: VerificationStatus.softwareOnly,
    evidence: 'unit_tests',
  ),
  FeatureEntry(
    featureId: 'music',
    featureName: 'Music Control',
    supported: true,
    transport: 'BLE / BT_CLASSIC',
    protocol: 'rideos_native_v1',
    verification: VerificationStatus.softwareOnly,
    evidence: 'unit_tests',
    notes: 'Play/pause/skip — target must negotiate musicControl',
  ),
  FeatureEntry(
    featureId: 'phone_battery',
    featureName: 'Phone Battery Level',
    supported: true,
    transport: 'BLE / BT_CLASSIC',
    protocol: 'rideos_native_v1 / generic_ble_json_v1 / bt_classic_spp_v1',
    verification: VerificationStatus.softwareOnly,
    evidence: 'unit_tests',
  ),
  FeatureEntry(
    featureId: 'sos',
    featureName: 'Emergency SOS Alert',
    supported: true,
    transport: 'BLE / BT_CLASSIC',
    protocol: 'rideos_native_v1',
    verification: VerificationStatus.softwareOnly,
    evidence: 'unit_tests',
  ),
  FeatureEntry(
    featureId: 'route_deviation',
    featureName: 'Route Deviation Warning',
    supported: true,
    transport: 'BLE / BT_CLASSIC',
    protocol: 'rideos_native_v1',
    verification: VerificationStatus.softwareOnly,
    evidence: 'unit_tests',
  ),
  FeatureEntry(
    featureId: 'trip_data',
    featureName: 'Trip Distance & Duration',
    supported: true,
    transport: 'BLE / BT_CLASSIC',
    protocol: 'rideos_native_v1',
    verification: VerificationStatus.softwareOnly,
    evidence: 'unit_tests',
  ),
  FeatureEntry(
    featureId: 'parking_location',
    featureName: 'Parking Location',
    supported: false,
    transport: 'N/A',
    protocol: 'N/A',
    verification: VerificationStatus.unverified,
    evidence: 'none',
    notes: 'Planned for future release',
  ),
  FeatureEntry(
    featureId: 'notifications',
    featureName: 'Generic App Notifications',
    supported: true,
    transport: 'BLE / BT_CLASSIC',
    protocol: 'rideos_native_v1',
    verification: VerificationStatus.softwareOnly,
    evidence: 'unit_tests',
  ),
  FeatureEntry(
    featureId: 'display_projection',
    featureName: 'Screen Projection (Android Auto / CarPlay)',
    supported: false,
    transport: 'BLE + WIFI',
    protocol: 'N/A',
    verification: VerificationStatus.unverified,
    evidence: 'none',
    notes: 'MODE B — Architecture prepared but not implemented. '
        'Requires BLE for initial handshake + Wi-Fi for video stream. '
        'Kept separate from native BLE display protocol.',
  ),
];
