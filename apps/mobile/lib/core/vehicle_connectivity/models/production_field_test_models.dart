import 'package:flutter/foundation.dart';
import '../transports/vehicle_transport.dart';

enum FieldConnectionState {
  idle,
  permissionRequired,
  bluetoothUnavailable,
  scanning,
  deviceFound,
  connecting,
  discoveringServices,
  discoveringCharacteristics,
  subscribing,
  connected,
  identifying,
  identified,
  streaming,
  reconnecting,
  disconnected,
  error;

  String get userMessage {
    switch (this) {
      case FieldConnectionState.idle:
        return 'Ready to scan for nearby motorcycles/scooters.';
      case FieldConnectionState.permissionRequired:
        return 'Bluetooth & Location permissions required.';
      case FieldConnectionState.bluetoothUnavailable:
        return 'Bluetooth is turned off on this device.';
      case FieldConnectionState.scanning:
        return 'Scanning for compatible two-wheeler Bluetooth/BLE signals...';
      case FieldConnectionState.deviceFound:
        return 'Device detected. Preparing connection handshake...';
      case FieldConnectionState.connecting:
        return 'Establishing secure transport connection...';
      case FieldConnectionState.discoveringServices:
        return 'Discovering vehicle GATT services...';
      case FieldConnectionState.discoveringCharacteristics:
        return 'Resolving telemetry & diagnostic characteristics...';
      case FieldConnectionState.subscribing:
        return 'Subscribing to real-time notification streams...';
      case FieldConnectionState.connected:
        return 'Physical link established.';
      case FieldConnectionState.identifying:
        return 'Querying vehicle model and firmware version...';
      case FieldConnectionState.identified:
        return 'Vehicle profile identified.';
      case FieldConnectionState.streaming:
        return 'Live telemetry active. Monitoring link metrics...';
      case FieldConnectionState.reconnecting:
        return 'Connection interrupted. Attempting automatic reconnect...';
      case FieldConnectionState.disconnected:
        return 'Vehicle disconnected.';
      case FieldConnectionState.error:
        return 'Connection failure encountered.';
    }
  }
}

enum FieldVerificationLevel {
  supported,
  benchVerified,
  realDeviceVerified,
  detectedProtocolNotVerified,
  unsupported;

  String get badgeLabel {
    switch (this) {
      case FieldVerificationLevel.supported:
        return 'SUPPORTED';
      case FieldVerificationLevel.benchVerified:
        return 'BENCH VERIFIED';
      case FieldVerificationLevel.realDeviceVerified:
        return 'REAL DEVICE VERIFIED';
      case FieldVerificationLevel.detectedProtocolNotVerified:
        return 'DETECTED — PROTOCOL NOT VERIFIED';
      case FieldVerificationLevel.unsupported:
        return 'UNSUPPORTED';
    }
  }
}

@immutable
class FieldTestSessionLog {
  final String sessionId;
  final DateTime startTime;
  final DateTime? endTime;
  final String deviceName;
  final String deviceMac;
  final VehicleTransportType transport;
  final String matchedProfile;
  final FieldVerificationLevel verificationLevel;
  final int rssi;
  final int mtu;
  final int totalPacketsReceived;
  final int totalPacketsLost;
  final int reconnectCount;
  final double notificationFrequencyHz;
  final String? disconnectReason;
  final double estimatedBatteryImpactPercent;

  const FieldTestSessionLog({
    required this.sessionId,
    required this.startTime,
    this.endTime,
    required this.deviceName,
    required this.deviceMac,
    required this.transport,
    required this.matchedProfile,
    required this.verificationLevel,
    this.rssi = -60,
    this.mtu = 185,
    this.totalPacketsReceived = 0,
    this.totalPacketsLost = 0,
    this.reconnectCount = 0,
    this.notificationFrequencyHz = 0.0,
    this.disconnectReason,
    this.estimatedBatteryImpactPercent = 0.5,
  });

  Duration get connectionDuration => (endTime ?? DateTime.now()).difference(startTime);

  double get packetLossPercent {
    final total = totalPacketsReceived + totalPacketsLost;
    if (total == 0) return 0.0;
    return (totalPacketsLost / total) * 100.0;
  }

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'durationSeconds': connectionDuration.inSeconds,
    'device': {
      'name': deviceName,
      'mac': deviceMac,
      'transport': transport.name,
      'profile': matchedProfile,
      'verification': verificationLevel.badgeLabel,
    },
    'linkMetrics': {
      'rssi': rssi,
      'mtu': mtu,
      'packetsReceived': totalPacketsReceived,
      'packetsLost': totalPacketsLost,
      'packetLossPercent': packetLossPercent,
      'notificationFrequencyHz': notificationFrequencyHz,
      'reconnectCount': reconnectCount,
    },
    'disconnectReason': disconnectReason,
    'estimatedBatteryImpactPercent': estimatedBatteryImpactPercent,
    'disclaimer': 'Physical validation pending until verified against physical motorcycle/scooter hardware.',
  };
}
