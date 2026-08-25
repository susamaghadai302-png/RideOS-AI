import 'package:flutter/foundation.dart';

enum ErrorCategory {
  network,
  authentication,
  authorization,
  validation,
  database,
  vehicleConnection,
  bluetooth,
  telemetry,
  navigation,
  ai,
  permission,
  storage,
  timeout,
  configuration,
  unknown,
}

@immutable
class AppError implements Exception {
  final String code;
  final ErrorCategory category;
  final String userMessage;
  final String technicalMessage;
  final bool isRetryable;
  final DateTime timestamp;
  final Map<String, dynamic> context;

  const AppError({
    required this.code,
    required this.category,
    required this.userMessage,
    required this.technicalMessage,
    this.isRetryable = false,
    required this.timestamp,
    this.context = const {},
  });

  factory AppError.network({
    String code = 'NET_001',
    String userMessage = 'Unable to connect to the network. Please check your internet connection.',
    String technicalMessage = 'Network unreachable or socket closed',
    bool retryable = true,
    Map<String, dynamic> context = const {},
  }) {
    return AppError(
      code: code,
      category: ErrorCategory.network,
      userMessage: userMessage,
      technicalMessage: technicalMessage,
      isRetryable: retryable,
      timestamp: DateTime.now(),
      context: context,
    );
  }

  factory AppError.vehicleConnection({
    String code = 'VEH_001',
    String userMessage = 'Vehicle connection interrupted. Reconnecting in background...',
    String technicalMessage = 'GATT connection lost or CCU out of range',
    bool retryable = true,
    Map<String, dynamic> context = const {},
  }) {
    return AppError(
      code: code,
      category: ErrorCategory.vehicleConnection,
      userMessage: userMessage,
      technicalMessage: technicalMessage,
      isRetryable: retryable,
      timestamp: DateTime.now(),
      context: context,
    );
  }

  factory AppError.telemetry({
    String code = 'TEL_001',
    String userMessage = 'Vehicle telemetry packet corrupted or out-of-range.',
    String technicalMessage = 'CRC mismatch or sensor value out of physical bounds',
    bool retryable = false,
    Map<String, dynamic> context = const {},
  }) {
    return AppError(
      code: code,
      category: ErrorCategory.telemetry,
      userMessage: userMessage,
      technicalMessage: technicalMessage,
      isRetryable: retryable,
      timestamp: DateTime.now(),
      context: context,
    );
  }

  factory AppError.authentication({
    String code = 'AUTH_001',
    String userMessage = 'Your session has expired. Please sign in again.',
    String technicalMessage = 'JWT signature expired or refresh token revoked',
    bool retryable = false,
    Map<String, dynamic> context = const {},
  }) {
    return AppError(
      code: code,
      category: ErrorCategory.authentication,
      userMessage: userMessage,
      technicalMessage: technicalMessage,
      isRetryable: retryable,
      timestamp: DateTime.now(),
      context: context,
    );
  }

  factory AppError.ai({
    String code = 'AI_001',
    String userMessage = 'AI assistant is currently operating in offline mode.',
    String technicalMessage = 'Cloud LLM endpoint timeout or token quota exceeded',
    bool retryable = true,
    Map<String, dynamic> context = const {},
  }) {
    return AppError(
      code: code,
      category: ErrorCategory.ai,
      userMessage: userMessage,
      technicalMessage: technicalMessage,
      isRetryable: retryable,
      timestamp: DateTime.now(),
      context: context,
    );
  }

  factory AppError.permission({
    String code = 'PERM_001',
    String userMessage = 'Bluetooth or Location permission is required for vehicle telemetry.',
    String technicalMessage = 'OS permission denied by user',
    bool retryable = false,
    Map<String, dynamic> context = const {},
  }) {
    return AppError(
      code: code,
      category: ErrorCategory.permission,
      userMessage: userMessage,
      technicalMessage: technicalMessage,
      isRetryable: retryable,
      timestamp: DateTime.now(),
      context: context,
    );
  }

  factory AppError.unknown({
    String code = 'ERR_UNKNOWN',
    String userMessage = 'An unexpected error occurred.',
    required String technicalMessage,
    bool retryable = false,
    Map<String, dynamic> context = const {},
  }) {
    return AppError(
      code: code,
      category: ErrorCategory.unknown,
      userMessage: userMessage,
      technicalMessage: technicalMessage,
      isRetryable: retryable,
      timestamp: DateTime.now(),
      context: context,
    );
  }

  @override
  String toString() => '[$code][$category] $userMessage (Tech: $technicalMessage)';
}
