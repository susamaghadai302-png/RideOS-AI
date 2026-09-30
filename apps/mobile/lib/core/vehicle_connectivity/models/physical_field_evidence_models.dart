import 'package:flutter/foundation.dart';
import '../transports/vehicle_transport.dart';

enum FieldEvidenceLevel {
  benchTest,
  realDevicePending,
  realDeviceVerified;

  String get label {
    switch (this) {
      case FieldEvidenceLevel.benchTest:
        return 'BENCH TEST';
      case FieldEvidenceLevel.realDevicePending:
        return 'REAL DEVICE PENDING';
      case FieldEvidenceLevel.realDeviceVerified:
        return 'REAL DEVICE VERIFIED';
    }
  }
}

@immutable
class PhysicalTestEvidenceRecord {
  final String evidenceId;
  final DateTime recordTimestamp;
  final String deviceName;
  final String privacySafeMac; // e.g. "AA:BB:CC:XX:XX:FF"
  final String manufacturer;
  final String modelName;
  final String variantTrim;
  final String modelYear;
  final VehicleTransportType transport;
  final String protocolName;
  final int negotiatedMtu;
  final List<int> rssiSamples;
  final int totalPacketsCaptured;
  final int checksumFailures;
  final int malformedPackets;
  final int reconnectEvents;
  final Duration testDuration;
  final double averageNotificationFrequencyHz;
  final FieldEvidenceLevel evidenceLevel;
  final List<String> warnings;
  final List<String> verifiedCapabilities;

  const PhysicalTestEvidenceRecord({
    required this.evidenceId,
    required this.recordTimestamp,
    required this.deviceName,
    required this.privacySafeMac,
    required this.manufacturer,
    required this.modelName,
    required this.variantTrim,
    required this.modelYear,
    required this.transport,
    required this.protocolName,
    required this.negotiatedMtu,
    this.rssiSamples = const [],
    required this.totalPacketsCaptured,
    required this.checksumFailures,
    required this.malformedPackets,
    required this.reconnectEvents,
    required this.testDuration,
    required this.averageNotificationFrequencyHz,
    required this.evidenceLevel,
    this.warnings = const [],
    this.verifiedCapabilities = const [],
  });

  double get packetLossPercent {
    final total = totalPacketsCaptured + checksumFailures + malformedPackets;
    if (total == 0) return 0.0;
    return ((checksumFailures + malformedPackets) / total) * 100.0;
  }

  double get averageRssi {
    if (rssiSamples.isEmpty) return -65.0;
    return rssiSamples.reduce((a, b) => a + b) / rssiSamples.length;
  }

  Map<String, dynamic> toJson() => {
    'evidenceId': evidenceId,
    'recordTimestamp': recordTimestamp.toIso8601String(),
    'evidenceLevel': evidenceLevel.label,
    'testDurationSeconds': testDuration.inSeconds,
    'vehicleInfo': {
      'manufacturer': manufacturer,
      'model': modelName,
      'variant': variantTrim,
      'year': modelYear,
      'protocol': protocolName,
    },
    'device': {
      'deviceName': deviceName,
      'macMasked': privacySafeMac,
      'transport': transport.name,
      'negotiatedMtu': negotiatedMtu,
    },
    'bleMetrics': {
      'averageRssi': averageRssi,
      'rssiSamplesCount': rssiSamples.length,
      'notificationFrequencyHz': averageNotificationFrequencyHz,
    },
    'packetStatistics': {
      'totalCaptured': totalPacketsCaptured,
      'checksumFailures': checksumFailures,
      'malformedPackets': malformedPackets,
      'packetLossPercent': packetLossPercent,
      'reconnectEvents': reconnectEvents,
    },
    'verifiedCapabilities': verifiedCapabilities,
    'warnings': warnings,
    'disclaimer': 'Physical validation pending until verified against physical motorcycle/scooter hardware.',
  };
}
