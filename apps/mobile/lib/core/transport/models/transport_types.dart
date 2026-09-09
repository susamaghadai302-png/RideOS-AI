import 'package:flutter/foundation.dart';

/// Supported physical transport types for diagnostic hardware communication.
enum TransportType {
  bluetoothClassicSpp('Bluetooth SPP', 'Classic Bluetooth Serial Port Profile'),
  bluetoothLowEnergy('BLE / GATT', 'Bluetooth Low Energy Generic Attribute Profile'),
  usbOtgSerial('USB OTG', 'USB On-The-Go Serial Connection'),
  wifiTcp('Wi-Fi TCP', 'Wi-Fi TCP/IP Socket Connection');

  final String displayName;
  final String description;
  const TransportType(this.displayName, this.description);
}

/// Deterministic connection state machine states.
enum TransportState {
  unavailable,
  initializing,
  scanning,
  deviceFound,
  connecting,
  connected,
  ready,
  transferring,
  disconnecting,
  disconnected,
  error;

  /// Valid state transitions — prevents invalid jumps.
  bool canTransitionTo(TransportState next) {
    switch (this) {
      case TransportState.unavailable:
        return next == TransportState.initializing || next == TransportState.error;
      case TransportState.initializing:
        return next == TransportState.scanning ||
            next == TransportState.disconnected ||
            next == TransportState.error ||
            next == TransportState.unavailable;
      case TransportState.scanning:
        return next == TransportState.deviceFound ||
            next == TransportState.disconnected ||
            next == TransportState.error ||
            next == TransportState.unavailable;
      case TransportState.deviceFound:
        return next == TransportState.connecting ||
            next == TransportState.scanning ||
            next == TransportState.disconnected ||
            next == TransportState.error;
      case TransportState.connecting:
        return next == TransportState.connected ||
            next == TransportState.disconnected ||
            next == TransportState.error;
      case TransportState.connected:
        return next == TransportState.ready ||
            next == TransportState.transferring ||
            next == TransportState.disconnecting ||
            next == TransportState.disconnected ||
            next == TransportState.error;
      case TransportState.ready:
        return next == TransportState.transferring ||
            next == TransportState.disconnecting ||
            next == TransportState.disconnected ||
            next == TransportState.error;
      case TransportState.transferring:
        return next == TransportState.ready ||
            next == TransportState.disconnecting ||
            next == TransportState.disconnected ||
            next == TransportState.error;
      case TransportState.disconnecting:
        return next == TransportState.disconnected ||
            next == TransportState.error;
      case TransportState.disconnected:
        return next == TransportState.initializing ||
            next == TransportState.scanning ||
            next == TransportState.connecting ||
            next == TransportState.error;
      case TransportState.error:
        return next == TransportState.initializing ||
            next == TransportState.scanning ||
            next == TransportState.disconnected ||
            next == TransportState.connecting ||
            next == TransportState.unavailable;
    }
  }

  bool get isTerminal =>
      this == TransportState.disconnected ||
      this == TransportState.error ||
      this == TransportState.unavailable;

  bool get isActive =>
      this == TransportState.connected ||
      this == TransportState.ready ||
      this == TransportState.transferring;
}

/// Structured transport error codes.
enum TransportErrorCode {
  permissionDenied('PERMISSION_DENIED', 'Required system permission not granted'),
  deviceNotFound('DEVICE_NOT_FOUND', 'Target device could not be found'),
  connectionTimeout('CONNECTION_TIMEOUT', 'Connection attempt timed out'),
  connectionRefused('CONNECTION_REFUSED', 'Target device refused the connection'),
  connectionLost('CONNECTION_LOST', 'Active connection was lost unexpectedly'),
  readTimeout('READ_TIMEOUT', 'Read operation timed out'),
  writeTimeout('WRITE_TIMEOUT', 'Write operation timed out'),
  malformedPacket('MALFORMED_PACKET', 'Received data failed integrity validation'),
  protocolError('PROTOCOL_ERROR', 'Transport-layer protocol error'),
  resourceBusy('RESOURCE_BUSY', 'Requested resource is already in use'),
  platformUnavailable('PLATFORM_UNAVAILABLE', 'Transport not supported on this platform'),
  adapterDisabled('ADAPTER_DISABLED', 'System adapter (Bluetooth/Wi-Fi) is turned off'),
  pairingFailed('PAIRING_FAILED', 'Device pairing could not be completed'),
  serviceNotFound('SERVICE_NOT_FOUND', 'Required GATT service was not found'),
  characteristicNotFound('CHARACTERISTIC_NOT_FOUND', 'Required GATT characteristic was not found'),
  unknown('UNKNOWN', 'An unknown transport error occurred');

  final String code;
  final String message;
  const TransportErrorCode(this.code, this.message);
}

/// Immutable transport error.
@immutable
class TransportError {
  final TransportErrorCode code;
  final String? details;
  final TransportType? transportType;
  final DateTime timestamp;

  TransportError({
    required this.code,
    this.details,
    this.transportType,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() =>
      'TransportError(${code.code}: ${details ?? code.message})';
}

/// Per-transport capability report.
@immutable
class TransportCapabilities {
  final TransportType transportType;
  final bool isAvailableOnPlatform;
  final bool isAdapterEnabled;
  final bool hasPermission;
  final int maxPayloadBytes;
  final bool supportsReconnection;
  final bool supportsSubscription;
  final bool supportsBidirectional;

  const TransportCapabilities({
    required this.transportType,
    this.isAvailableOnPlatform = false,
    this.isAdapterEnabled = false,
    this.hasPermission = false,
    this.maxPayloadBytes = 512,
    this.supportsReconnection = true,
    this.supportsSubscription = true,
    this.supportsBidirectional = true,
  });

  bool get isFullyReady =>
      isAvailableOnPlatform && isAdapterEnabled && hasPermission;
}

/// Permission state enumeration.
enum TransportPermissionState {
  granted,
  denied,
  notRequested,
  permanentlyDenied,
  restricted;

  bool get isGranted => this == TransportPermissionState.granted;
}

/// Retry/backoff policy for connection attempts.
@immutable
class TransportRetryPolicy {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;

  const TransportRetryPolicy({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
  });

  /// Computes the delay for a given retry attempt index.
  Duration delayForAttempt(int attempt) {
    if (attempt <= 0) return Duration.zero;
    final computed = initialDelay.inMilliseconds *
        _pow(backoffMultiplier, attempt - 1);
    final clamped = computed.clamp(0, maxDelay.inMilliseconds).toInt();
    return Duration(milliseconds: clamped);
  }

  static double _pow(double base, int exponent) {
    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }

  static const TransportRetryPolicy defaultPolicy = TransportRetryPolicy();
  static const TransportRetryPolicy aggressivePolicy = TransportRetryPolicy(
    maxRetries: 5,
    initialDelay: Duration(milliseconds: 500),
    backoffMultiplier: 1.5,
    maxDelay: Duration(seconds: 15),
  );
  static const TransportRetryPolicy noRetry = TransportRetryPolicy(maxRetries: 0);
}
