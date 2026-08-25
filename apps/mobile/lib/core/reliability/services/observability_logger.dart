import 'package:flutter/foundation.dart';
import '../models/app_error.dart';

enum LogSeverity {
  debug,
  info,
  warning,
  error,
  critical,
}

class ObservabilityLogger {
  static final ObservabilityLogger _instance = ObservabilityLogger._internal();
  factory ObservabilityLogger() => _instance;

  final List<String> _recentLogs = [];
  List<String> get recentLogs => List.unmodifiable(_recentLogs);

  ObservabilityLogger._internal();

  void log({
    required LogSeverity severity,
    required String message,
    String? subsystem,
    Map<String, dynamic>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final now = DateTime.now().toIso8601String();
    final sanitizedContext = _sanitizeMap(context);
    final logEntry = '[$now][${severity.name.toUpperCase()}][${subsystem ?? 'CORE'}] $message ${sanitizedContext.isNotEmpty ? sanitizedContext : ''}';

    _recentLogs.add(logEntry);
    if (_recentLogs.length > 500) {
      _recentLogs.removeAt(0);
    }

    if (kDebugMode) {
      debugPrint(logEntry);
      if (error != null) debugPrint('Error detail: $error');
      if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
    }
  }

  void logError(AppError appError, {String? subsystem, StackTrace? stackTrace}) {
    log(
      severity: LogSeverity.error,
      message: '${appError.code}: ${appError.technicalMessage}',
      subsystem: subsystem ?? appError.category.name,
      context: appError.context,
      error: appError,
      stackTrace: stackTrace,
    );
  }

  Map<String, dynamic> _sanitizeMap(Map<String, dynamic>? map) {
    if (map == null) return {};
    final sanitized = <String, dynamic>{};
    final sensitiveKeys = ['token', 'password', 'jwt', 'secret', 'key', 'credential', 'auth', 'bearer'];

    map.forEach((k, v) {
      final isSensitive = sensitiveKeys.any((s) => k.toLowerCase().contains(s));
      if (isSensitive) {
        sanitized[k] = '[REDACTED]';
      } else if (v is Map<String, dynamic>) {
        sanitized[k] = _sanitizeMap(v);
      } else {
        sanitized[k] = v;
      }
    });

    return sanitized;
  }
}
