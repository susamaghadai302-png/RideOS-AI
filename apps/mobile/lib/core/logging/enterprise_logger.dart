import 'dart:developer' as developer;

enum LogLevel { debug, info, warning, error, critical }

class LogEntry {
  final LogLevel level;
  final String category;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const LogEntry({
    required this.level,
    required this.category,
    required this.message,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'level': level.name,
        'category': category,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };
}

class EnterpriseLogger {
  static final EnterpriseLogger _instance = EnterpriseLogger._internal();
  factory EnterpriseLogger() => _instance;
  EnterpriseLogger._internal();

  final List<LogEntry> _recentLogs = [];

  List<LogEntry> get recentLogs => List.unmodifiable(_recentLogs);

  void log({
    required LogLevel level,
    required String category,
    required String message,
    Map<String, dynamic>? metadata,
  }) {
    final entry = LogEntry(
      level: level,
      category: category,
      message: message,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    _recentLogs.add(entry);
    if (_recentLogs.length > 500) {
      _recentLogs.removeAt(0);
    }

    developer.log(
      '[${category.toUpperCase()}] $message',
      name: 'RideOS.${category.toLowerCase()}',
      time: entry.timestamp,
      error: level == LogLevel.error || level == LogLevel.critical ? message : null,
    );
  }

  void debug(String category, String message, [Map<String, dynamic>? meta]) =>
      log(level: LogLevel.debug, category: category, message: message, metadata: meta);

  void info(String category, String message, [Map<String, dynamic>? meta]) =>
      log(level: LogLevel.info, category: category, message: message, metadata: meta);

  void warning(String category, String message, [Map<String, dynamic>? meta]) =>
      log(level: LogLevel.warning, category: category, message: message, metadata: meta);

  void error(String category, String message, [Map<String, dynamic>? meta]) =>
      log(level: LogLevel.error, category: category, message: message, metadata: meta);
}
