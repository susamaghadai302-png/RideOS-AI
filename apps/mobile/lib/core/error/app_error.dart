import 'dart:math';

enum ErrorCategory {
  uiError,
  bluetoothError,
  protocolError,
  telemetryError,
  gpsError,
  mapError,
  networkError,
  backendError,
  databaseError,
  threeDError,
  authError,
  permissionError,
  configurationError,
}

class AppError {
  final String errorId; // Safe correlation code (e.g. RID-2026-X8F2)
  final ErrorCategory category;
  final String userTitle;
  final String userMessage;
  final String dataSafetyNote;
  final bool canRetry;
  final DateTime timestamp;
  final dynamic originalError;

  AppError({
    String? errorId,
    required this.category,
    required this.userTitle,
    required this.userMessage,
    this.dataSafetyNote = 'Your locally cached trip and vehicle data is secure.',
    this.canRetry = true,
    DateTime? timestamp,
    this.originalError,
  })  : errorId = errorId ?? _generateCorrelationId(),
        timestamp = timestamp ?? DateTime.now();

  static String _generateCorrelationId() {
    final rand = Random();
    final hex = List.generate(4, (_) => rand.nextInt(16).toRadixString(16).toUpperCase()).join();
    return 'RID-2026-$hex';
  }

  factory AppError.fromException(dynamic error, [ErrorCategory fallbackCategory = ErrorCategory.uiError]) {
    final msg = error.toString().toLowerCase();

    if (msg.contains('bluetooth') || msg.contains('ble') || msg.contains('gatt')) {
      return AppError(
        category: ErrorCategory.bluetoothError,
        userTitle: 'Vehicle Connection Interrupted',
        userMessage: 'The Bluetooth connection to your vehicle was lost. Tap retry to reconnect.',
        dataSafetyNote: 'Your trip continues using GPS and cached vehicle telemetry.',
        originalError: error,
      );
    }

    if (msg.contains('socket') || msg.contains('network') || msg.contains('timeout') || msg.contains('connection refused')) {
      return AppError(
        category: ErrorCategory.networkError,
        userTitle: 'Network Unavailable',
        userMessage: 'Unable to reach the RideOS cloud servers. Offline mode is active.',
        dataSafetyNote: 'All ride and maintenance updates will automatically sync when connection returns.',
        originalError: error,
      );
    }

    if (msg.contains('location') || msg.contains('gps') || msg.contains('geolocator') || msg.contains('position update is unavailable') || msg.contains('position update')) {
      return AppError(
        category: ErrorCategory.gpsError,
        userTitle: 'GPS Signal Unavailable',
        userMessage: 'High-precision GNSS position is temporarily unavailable. Check location permissions.',
        dataSafetyNote: 'Vehicle telemetry from ECU continues to log normally.',
        originalError: error,
      );
    }

    if (msg.contains('webgl') || msg.contains('asset') || msg.contains('glb') || msg.contains('model')) {
      return AppError(
        category: ErrorCategory.threeDError,
        userTitle: '3D Asset Unavailable',
        userMessage: 'The 3D digital twin could not be loaded on this graphics adapter.',
        dataSafetyNote: 'All telemetry, diagnostics, and garage features remain fully functional.',
        originalError: error,
      );
    }

    if (msg.contains('unauthorized') || msg.contains('401') || msg.contains('token')) {
      return AppError(
        category: ErrorCategory.authError,
        userTitle: 'Session Expired',
        userMessage: 'Your authentication session has expired. Please sign in again.',
        dataSafetyNote: 'Your rider profile and vehicle history are securely preserved.',
        canRetry: false,
        originalError: error,
      );
    }

    return AppError(
      category: fallbackCategory,
      userTitle: 'Temporary Feature Issue',
      userMessage: 'This screen encountered an unexpected error. Tap below to reload.',
      dataSafetyNote: 'Your vehicle profile and rider data are safe.',
      originalError: error,
    );
  }
}
