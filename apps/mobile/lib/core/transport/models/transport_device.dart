import 'package:flutter/foundation.dart';
import 'transport_types.dart';

/// Normalized transport device model.
/// Never exposes platform-specific raw objects to the diagnostic engine.
@immutable
class TransportDevice {
  /// Unique identifier scoped to the transport type.
  final String deviceId;

  /// Human-readable display name.
  final String displayName;

  /// Platform-level address (MAC, IP:port, USB path, etc.).
  final String address;

  /// Transport over which this device was discovered.
  final TransportType transportType;

  /// Device manufacturer, if available.
  final String? manufacturer;

  /// Device model identifier, if available.
  final String? model;

  /// RSSI or signal quality (dBm for BLE, null for USB/Wi-Fi).
  final int? signalStrengthDbm;

  /// Current connection state for this device.
  final TransportState connectionState;

  /// Whether the device requires pairing / permissions.
  final TransportPermissionState permissionState;

  /// When was this device last seen during scanning.
  final DateTime lastSeen;

  /// Diagnostic protocol capabilities advertised or detected.
  final List<String> supportedProtocols;

  /// Adapter-supplied metadata (firmware version, etc.).
  final Map<String, String> metadata;

  const TransportDevice({
    required this.deviceId,
    required this.displayName,
    required this.address,
    required this.transportType,
    this.manufacturer,
    this.model,
    this.signalStrengthDbm,
    this.connectionState = TransportState.disconnected,
    this.permissionState = TransportPermissionState.notRequested,
    required this.lastSeen,
    this.supportedProtocols = const [],
    this.metadata = const {},
  });

  /// Returns a copy with modified fields.
  TransportDevice copyWith({
    String? deviceId,
    String? displayName,
    String? address,
    TransportType? transportType,
    String? manufacturer,
    String? model,
    int? signalStrengthDbm,
    TransportState? connectionState,
    TransportPermissionState? permissionState,
    DateTime? lastSeen,
    List<String>? supportedProtocols,
    Map<String, String>? metadata,
  }) {
    return TransportDevice(
      deviceId: deviceId ?? this.deviceId,
      displayName: displayName ?? this.displayName,
      address: address ?? this.address,
      transportType: transportType ?? this.transportType,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      signalStrengthDbm: signalStrengthDbm ?? this.signalStrengthDbm,
      connectionState: connectionState ?? this.connectionState,
      permissionState: permissionState ?? this.permissionState,
      lastSeen: lastSeen ?? this.lastSeen,
      supportedProtocols: supportedProtocols ?? this.supportedProtocols,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Signal quality classification.
  String get signalQuality {
    if (signalStrengthDbm == null) return 'N/A';
    final rssi = signalStrengthDbm!;
    if (rssi >= -50) return 'Excellent';
    if (rssi >= -60) return 'Good';
    if (rssi >= -70) return 'Fair';
    if (rssi >= -80) return 'Weak';
    return 'Very Weak';
  }

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'displayName': displayName,
        'address': address,
        'transportType': transportType.name,
        'manufacturer': manufacturer,
        'model': model,
        'signalStrengthDbm': signalStrengthDbm,
        'connectionState': connectionState.name,
        'permissionState': permissionState.name,
        'lastSeen': lastSeen.toIso8601String(),
        'supportedProtocols': supportedProtocols,
        'metadata': metadata,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransportDevice &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId &&
          transportType == other.transportType;

  @override
  int get hashCode => Object.hash(deviceId, transportType);

  @override
  String toString() =>
      'TransportDevice($displayName [$transportType] $address state=$connectionState)';
}

/// A data packet sent/received through the transport layer.
@immutable
class TransportPacket {
  final List<int> payload;
  final TransportType sourceTransport;
  final DateTime timestamp;
  final bool isResponse;
  final String? commandTag;

  TransportPacket({
    required this.payload,
    required this.sourceTransport,
    DateTime? timestamp,
    this.isResponse = false,
    this.commandTag,
  }) : timestamp = timestamp ?? DateTime.now();

  int get length => payload.length;
  bool get isEmpty => payload.isEmpty;
  bool get isNotEmpty => payload.isNotEmpty;

  @override
  String toString() =>
      'TransportPacket(${payload.length} bytes, $sourceTransport, tag=$commandTag)';
}

/// Active transport connection handle.
@immutable
class TransportConnection {
  final String connectionId;
  final TransportDevice device;
  final TransportState state;
  final DateTime connectedAt;
  final TransportCapabilities capabilities;
  final int bytesRead;
  final int bytesWritten;
  final String? errorMessage;

  const TransportConnection({
    required this.connectionId,
    required this.device,
    required this.state,
    required this.connectedAt,
    required this.capabilities,
    this.bytesRead = 0,
    this.bytesWritten = 0,
    this.errorMessage,
  });

  bool get isActive => state.isActive;
  bool get hasError => state == TransportState.error;

  TransportConnection copyWith({
    TransportState? state,
    int? bytesRead,
    int? bytesWritten,
    String? errorMessage,
  }) {
    return TransportConnection(
      connectionId: connectionId,
      device: device,
      state: state ?? this.state,
      connectedAt: connectedAt,
      capabilities: capabilities,
      bytesRead: bytesRead ?? this.bytesRead,
      bytesWritten: bytesWritten ?? this.bytesWritten,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() =>
      'TransportConnection($connectionId → ${device.displayName}, state=$state)';
}
