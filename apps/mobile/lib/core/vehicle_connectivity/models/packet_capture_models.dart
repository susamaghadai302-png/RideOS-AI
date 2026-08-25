import 'package:flutter/foundation.dart';
import '../transports/vehicle_transport.dart';

enum CaptureFrameDirection {
  inbound,
  outbound,
}

enum CaptureSourceClassification {
  simulated,
  benchTest,
  realDevice,
  verifiedRealDevice;

  String get label {
    switch (this) {
      case CaptureSourceClassification.simulated:
        return 'SIMULATED';
      case CaptureSourceClassification.benchTest:
        return 'BENCH_TEST';
      case CaptureSourceClassification.realDevice:
        return 'REAL_DEVICE';
      case CaptureSourceClassification.verifiedRealDevice:
        return 'VERIFIED_REAL_DEVICE';
    }
  }
}

enum HardwareBenchVerificationStatus {
  verifiedRealDevice,
  partiallyVerified,
  benchVerified,
  unverified,
  unsupported;

  String get label {
    switch (this) {
      case HardwareBenchVerificationStatus.verifiedRealDevice:
        return 'VERIFIED REAL DEVICE';
      case HardwareBenchVerificationStatus.partiallyVerified:
        return 'PARTIALLY VERIFIED';
      case HardwareBenchVerificationStatus.benchVerified:
        return 'BENCH VERIFIED';
      case HardwareBenchVerificationStatus.unverified:
        return 'UNVERIFIED (REQUIRES HARDWARE)';
      case HardwareBenchVerificationStatus.unsupported:
        return 'UNSUPPORTED VEHICLE';
    }
  }
}

@immutable
class CapturedDiagnosticFrame {
  final int frameIndex;
  final DateTime timestamp;
  final VehicleTransportType transport;
  final CaptureFrameDirection direction;
  final int lengthBytes;
  final String payloadHex;
  final bool isChecksumValid;
  final int sequenceNumber;
  final CaptureSourceClassification sourceClassification;

  const CapturedDiagnosticFrame({
    required this.frameIndex,
    required this.timestamp,
    required this.transport,
    required this.direction,
    required this.lengthBytes,
    required this.payloadHex,
    required this.isChecksumValid,
    required this.sequenceNumber,
    required this.sourceClassification,
  });

  Map<String, dynamic> toJson() => {
    'index': frameIndex,
    'timestamp': timestamp.toIso8601String(),
    'transport': transport.name,
    'direction': direction.name,
    'length': lengthBytes,
    'payload': payloadHex,
    'checksumValid': isChecksumValid,
    'seq': sequenceNumber,
    'source': sourceClassification.label,
  };
}

@immutable
class TestBenchSessionState {
  final bool isRecording;
  final bool isPaused;
  final String deviceId;
  final String deviceName;
  final String manufacturer;
  final int mtu;
  final int rssi;
  final List<String> discoveredServices;
  final List<String> discoveredCharacteristics;
  final int totalFramesCaptured;
  final int malformedFramesCount;
  final double notificationRateHz;
  final int roundTripLatencyMs;
  final HardwareBenchVerificationStatus verificationStatus;
  final CaptureSourceClassification sourceClassification;
  final List<CapturedDiagnosticFrame> frames;

  const TestBenchSessionState({
    this.isRecording = false,
    this.isPaused = false,
    this.deviceId = 'Unknown',
    this.deviceName = 'Awaiting Device',
    this.manufacturer = 'Unknown',
    this.mtu = 23,
    this.rssi = -60,
    this.discoveredServices = const [],
    this.discoveredCharacteristics = const [],
    this.totalFramesCaptured = 0,
    this.malformedFramesCount = 0,
    this.notificationRateHz = 0.0,
    this.roundTripLatencyMs = 0,
    this.verificationStatus = HardwareBenchVerificationStatus.unverified,
    this.sourceClassification = CaptureSourceClassification.simulated,
    this.frames = const [],
  });

  double get packetLossPercent {
    if (totalFramesCaptured == 0) return 0.0;
    return (malformedFramesCount / totalFramesCaptured) * 100.0;
  }
}
