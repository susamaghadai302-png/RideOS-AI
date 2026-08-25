import 'dart:async';
import 'dart:math';
import '../logging/enterprise_logger.dart';

class RetryPolicy {
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffFactor;
  final bool addJitter;

  const RetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 5),
    this.backoffFactor = 2.0,
    this.addJitter = true,
  });

  static const RetryPolicy bluetooth = RetryPolicy(
    maxAttempts: 3,
    initialDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 4),
  );

  static const RetryPolicy network = RetryPolicy(
    maxAttempts: 3,
    initialDelay: Duration(milliseconds: 600),
    maxDelay: Duration(seconds: 3),
  );

  static const RetryPolicy threeD = RetryPolicy(
    maxAttempts: 2,
    initialDelay: Duration(milliseconds: 300),
    maxDelay: Duration(seconds: 1),
  );
}

class SafeRetryEngine {
  static final SafeRetryEngine _instance = SafeRetryEngine._internal();
  factory SafeRetryEngine() => _instance;
  SafeRetryEngine._internal();

  /// Runs an async task with exponential backoff and capped attempts
  Future<T> run<T>({
    required Future<T> Function() action,
    required String taskName,
    RetryPolicy policy = const RetryPolicy(),
    void Function(int attempt, dynamic error)? onRetry,
  }) async {
    int attempt = 0;
    Duration currentDelay = policy.initialDelay;
    final random = Random();

    while (true) {
      attempt++;
      try {
        return await action();
      } catch (error) {
        if (attempt >= policy.maxAttempts) {
          EnterpriseLogger().error(
            'SafeRetryEngine',
            'Task "$taskName" failed after $attempt attempts: $error',
          );
          rethrow;
        }

        onRetry?.call(attempt, error);

        final jitter = policy.addJitter ? Duration(milliseconds: random.nextInt(200)) : Duration.zero;
        final sleepDuration = currentDelay + jitter;

        EnterpriseLogger().warning(
          'SafeRetryEngine',
          'Task "$taskName" failed on attempt $attempt/$policy.maxAttempts. Retrying in ${sleepDuration.inMilliseconds}ms...',
        );

        await Future.delayed(sleepDuration);

        // Exponential backoff capped at maxDelay
        final nextMs = (currentDelay.inMilliseconds * policy.backoffFactor).toInt();
        currentDelay = Duration(milliseconds: min(nextMs, policy.maxDelay.inMilliseconds));
      }
    }
  }
}
