import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/reliability/models/app_error.dart';
import 'package:rideos_mobile/core/reliability/services/safe_retry_engine.dart';
import 'package:rideos_mobile/core/reliability/services/data_validator.dart';
import 'package:rideos_mobile/core/reliability/services/observability_logger.dart';
import 'package:rideos_mobile/core/reliability/services/system_health_center_service.dart';
import 'package:rideos_mobile/core/reliability/presentation/widgets/reliability_state_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RideOS Production Reliability & Error Recovery Tests', () {
    late SafeRetryEngine retryEngine;
    late ObservabilityLogger logger;
    late SystemHealthCenterService healthService;

    setUp(() {
      retryEngine = SafeRetryEngine();
      logger = ObservabilityLogger();
      healthService = SystemHealthCenterService();
    });

    test('AppError categorizes errors and protects sensitive technical messages', () {
      final err = AppError.network(
        code: 'NET_TIMEOUT',
        userMessage: 'Unable to connect to server',
        technicalMessage: 'TCP Socket Timeout on port 3000',
      );

      expect(err.category, equals(ErrorCategory.network));
      expect(err.isRetryable, isTrue);
      expect(err.userMessage, equals('Unable to connect to server'));
      expect(err.technicalMessage, contains('TCP Socket Timeout'));
    });

    test('SafeRetryEngine executes exponential backoff and succeeds upon transient recovery', () async {
      int attempts = 0;
      final result = await retryEngine.executeWithRetry<String>(
        operation: () async {
          attempts++;
          if (attempts < 2) {
            throw AppError.network(technicalMessage: 'Temporary glitch');
          }
          return 'SUCCESS_AFTER_RETRY';
        },
        maxAttempts: 3,
        initialDelay: const Duration(milliseconds: 10),
      );

      expect(attempts, equals(2));
      expect(result, equals('SUCCESS_AFTER_RETRY'));
    });

    test('SafeRetryEngine throws unretryable error immediately without wasted attempts', () async {
      int attempts = 0;
      expect(
        () async => await retryEngine.executeWithRetry<void>(
          operation: () async {
            attempts++;
            throw const AppError(
              code: 'AUTH_REVOKED',
              category: ErrorCategory.authentication,
              userMessage: 'Session revoked',
              technicalMessage: 'JWT Invalid',
              isRetryable: false,
              timestamp: _StaticDate(),
            );
          },
          maxAttempts: 3,
          initialDelay: const Duration(milliseconds: 10),
        ),
        throwsA(isA<AppError>()),
      );
      expect(attempts, equals(1));
    });

    test('DataValidator rejects corrupted or impossible physical sensor values', () {
      // Speed bounds
      expect(DataValidator.isValidSpeed(72.5), isTrue);
      expect(DataValidator.isValidSpeed(-5.0), isFalse);
      expect(DataValidator.isValidSpeed(520.0), isFalse);

      // Battery voltage
      expect(DataValidator.isValidBatteryVoltage(12.6), isTrue);
      expect(DataValidator.isValidBatteryVoltage(3.0), isFalse);

      // Coordinates
      expect(DataValidator.isValidCoordinates(12.9716, 77.5946), isTrue);
      expect(DataValidator.isValidCoordinates(195.0, 77.0), isFalse);

      // Timestamp sanity
      expect(DataValidator.isValidTimestamp(DateTime.now()), isTrue);
      expect(DataValidator.isValidTimestamp(DateTime(1990, 1, 1)), isFalse);
    });

    test('ObservabilityLogger redacts tokens and sensitive authentication fields', () {
      logger.log(
        severity: LogSeverity.info,
        message: 'User authentication request',
        context: {
          'user_id': 'user_123',
          'access_token': 'secret_jwt_token_9999',
          'password': 'mypassword123',
        },
      );

      final lastLog = logger.recentLogs.last;
      expect(lastLog, contains('user_123'));
      expect(lastLog, contains('[REDACTED]'));
      expect(lastLog.contains('secret_jwt_token_9999'), isFalse);
      expect(lastLog.contains('mypassword123'), isFalse);
    });

    test('SystemHealthCenterService evaluates all 10 core subsystems', () async {
      final reports = await healthService.runFullSystemAudit();
      expect(reports.length, equals(10));
      expect(reports.any((r) => r.subsystemName == 'Authentication'), isTrue);
      expect(reports.any((r) => r.subsystemName == 'Telemetry Engine'), isTrue);
      expect(reports.any((r) => r.subsystemName == 'AI Ride Assistant'), isTrue);
    });

    testWidgets('ReliabilityStateView renders accessible error states with retry button', (tester) async {
      bool retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReliabilityStateView(
              state: ReliabilityViewState.error,
              title: 'Connection Lost',
              message: 'Unable to reach backend gateway.',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Connection Lost'), findsOneWidget);
      expect(find.text('Unable to reach backend gateway.'), findsOneWidget);
      expect(find.text('RETRY NOW'), findsOneWidget);

      await tester.tap(find.text('RETRY NOW'));
      expect(retried, isTrue);
    });
  });
}

class _StaticDate implements DateTime {
  const _StaticDate();

  @override
  int get year => 2026;
  @override
  int get month => 1;
  @override
  int get day => 1;
  @override
  int get hour => 0;
  @override
  int get minute => 0;
  @override
  int get second => 0;
  @override
  int get millisecond => 0;
  @override
  int get microsecond => 0;
  @override
  int get weekday => 4;
  @override
  int get millisecondsSinceEpoch => 0;
  @override
  int get microsecondsSinceEpoch => 0;
  @override
  String get timeZoneName => 'UTC';
  @override
  Duration get timeZoneOffset => Duration.zero;
  @override
  bool get isUtc => true;

  @override
  DateTime add(Duration duration) => DateTime.fromMillisecondsSinceEpoch(0).add(duration);
  @override
  DateTime subtract(Duration duration) => DateTime.fromMillisecondsSinceEpoch(0).subtract(duration);
  @override
  Duration difference(DateTime other) => DateTime.fromMillisecondsSinceEpoch(0).difference(other);
  @override
  int compareTo(DateTime other) => DateTime.fromMillisecondsSinceEpoch(0).compareTo(other);
  @override
  bool isAfter(DateTime other) => DateTime.fromMillisecondsSinceEpoch(0).isAfter(other);
  @override
  bool isBefore(DateTime other) => DateTime.fromMillisecondsSinceEpoch(0).isBefore(other);
  @override
  bool isAtSameMomentAs(DateTime other) => DateTime.fromMillisecondsSinceEpoch(0).isAtSameMomentAs(other);
  @override
  String toIso8601String() => '2026-01-01T00:00:00.000Z';
  @override
  DateTime toLocal() => DateTime.fromMillisecondsSinceEpoch(0).toLocal();
  @override
  DateTime toUtc() => this;
}
