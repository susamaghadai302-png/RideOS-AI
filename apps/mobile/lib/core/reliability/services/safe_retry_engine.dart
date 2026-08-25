import 'dart:async';
import 'dart:math';
import '../models/app_error.dart';

class SafeRetryEngine {
  static final SafeRetryEngine _instance = SafeRetryEngine._internal();
  factory SafeRetryEngine() => _instance;

  final Random _random = Random();

  SafeRetryEngine._internal();

  /// Executes an async task with exponential backoff and jitter
  Future<T> executeWithRetry<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
    double backoffMultiplier = 2.0,
    bool Function(dynamic error)? shouldRetryPredicate,
    String? operationName,
  }) async {
    int attempt = 0;
    Duration currentDelay = initialDelay;

    while (true) {
      attempt++;
      try {
        return await operation();
      } catch (error) {
        if (attempt >= maxAttempts) {
          if (error is AppError) rethrow;
          throw AppError.network(
            code: 'RETRY_EXHAUSTED',
            userMessage: 'Operation failed after $maxAttempts attempts. Please try again.',
            technicalMessage: 'Max retry attempts ($maxAttempts) exhausted for $operationName: $error',
            retryable: false,
          );
        }

        final canRetry = shouldRetryPredicate != null
            ? shouldRetryPredicate(error)
            : (error is AppError ? error.isRetryable : true);

        if (!canRetry) {
          if (error is AppError) rethrow;
          throw AppError.unknown(
            userMessage: 'An unrecoverable error occurred.',
            technicalMessage: '$error',
          );
        }

        // Add 10-25% random jitter to avoid thundering herds
        final jitterFactor = 1.0 + (_random.nextDouble() * 0.15);
        final sleepDuration = Duration(milliseconds: (currentDelay.inMilliseconds * jitterFactor).toInt());

        await Future.delayed(sleepDuration);
        currentDelay = Duration(milliseconds: (currentDelay.inMilliseconds * backoffMultiplier).toInt());
      }
    }
  }
}
