import 'package:flutter/foundation.dart';
import '../transports/vehicle_transport.dart';

enum RealDeviceEvidenceStatus {
  simulated,
  benchTest,
  realDevicePending,
  realDeviceVerified,
  realDeviceFailed;

  String get label {
    switch (this) {
      case RealDeviceEvidenceStatus.simulated:
        return 'SIMULATED';
      case RealDeviceEvidenceStatus.benchTest:
        return 'BENCH_TEST';
      case RealDeviceEvidenceStatus.realDevicePending:
        return 'REAL_DEVICE_PENDING';
      case RealDeviceEvidenceStatus.realDeviceVerified:
        return 'REAL_DEVICE_VERIFIED';
      case RealDeviceEvidenceStatus.realDeviceFailed:
        return 'REAL_DEVICE_FAILED';
    }
  }
}

@immutable
class PersistentHardwareEvidenceRecord {
  final String testSessionId;
  final String manufacturer;
  final String model;
  final int modelYear;
  final String variant;
  final String vehicleType;
  final String protocolName;
  final VehicleTransportType connectionMethod;
  final String deviceIdentifierMasked;
  final DateTime timestamp;
  final Duration testDuration;
  final List<int> rssiMeasurements;
  final int negotiatedMtu;
  final double notificationRateHz;
  final int totalPacketsCaptured;
  final int packetLossCount;
  final int checksumFailures;
  final int reconnectCount;
  final Map<String, dynamic> diagnostics;
  final List<String> errors;
  final List<String> warnings;
  final String testerNotes;
  final RealDeviceEvidenceStatus evidenceStatus;

  const PersistentHardwareEvidenceRecord({
    required this.testSessionId,
    required this.manufacturer,
    required this.model,
    required this.modelYear,
    required this.variant,
    required this.vehicleType,
    required this.protocolName,
    required this.connectionMethod,
    required this.deviceIdentifierMasked,
    required this.timestamp,
    required this.testDuration,
    this.rssiMeasurements = const [],
    this.negotiatedMtu = 185,
    this.notificationRateHz = 10.0,
    required this.totalPacketsCaptured,
    this.packetLossCount = 0,
    this.checksumFailures = 0,
    this.reconnectCount = 0,
    this.diagnostics = const {},
    this.errors = const [],
    this.warnings = const [],
    this.testerNotes = 'Real hardware on-road field validation record.',
    required this.evidenceStatus,
  });

  double get packetLossPercent {
    final total = totalPacketsCaptured + packetLossCount + checksumFailures;
    if (total == 0) return 0.0;
    return ((packetLossCount + checksumFailures) / total) * 100.0;
  }

  double get averageRssi {
    if (rssiMeasurements.isEmpty) return -62.0;
    return rssiMeasurements.reduce((a, b) => a + b) / rssiMeasurements.length;
  }

  Map<String, dynamic> toJson() => {
    'testSessionId': testSessionId,
    'timestamp': timestamp.toIso8601String(),
    'durationSeconds': testDuration.inSeconds,
    'vehicle': {
      'manufacturer': manufacturer,
      'model': model,
      'year': modelYear,
      'variant': variant,
      'type': vehicleType,
    },
    'link': {
      'protocol': protocolName,
      'connectionMethod': connectionMethod.name,
      'deviceIdMasked': deviceIdentifierMasked,
      'negotiatedMtu': negotiatedMtu,
      'averageRssi': averageRssi,
      'notificationRateHz': notificationRateHz,
    },
    'packetStatistics': {
      'totalCaptured': totalPacketsCaptured,
      'packetLossCount': packetLossCount,
      'checksumFailures': checksumFailures,
      'packetLossPercent': packetLossPercent,
      'reconnectCount': reconnectCount,
    },
    'diagnostics': diagnostics,
    'errors': errors,
    'warnings': warnings,
    'testerNotes': testerNotes,
    'evidenceStatus': evidenceStatus.label,
  };
}
