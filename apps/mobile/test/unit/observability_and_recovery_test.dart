import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/error/app_error.dart';
import 'package:rideos_mobile/core/error/safe_retry_engine.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/telemetry_health_monitor.dart';
import 'package:rideos_mobile/core/location/services/gps_health_monitor.dart';
import 'package:rideos_mobile/core/graphics/three_d_health_monitor.dart';
import 'package:rideos_mobile/core/vehicle_protocols/models/normalized_telemetry.dart';
import 'package:rideos_mobile/core/vehicle_protocols/models/telemetry_value.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppError & Classification Tests', () {
    test('Generates structured correlation ID in standard format', () {
      final error = AppError(
        category: ErrorCategory.uiError,
        userTitle: 'Test Title',
        userMessage: 'Test Message',
      );

      expect(error.errorId.startsWith('RID-2026-'), isTrue);
      expect(error.dataSafetyNote.isNotEmpty, isTrue);
    });

    test('Classifies Bluetooth exceptions gracefully with user guidance', () {
      final error = AppError.fromException('BluetoothGattException: Connection timeout');
      expect(error.category, ErrorCategory.bluetoothError);
      expect(error.userTitle.contains('Connection'), isTrue);
      expect(error.dataSafetyNote.contains('GPS'), isTrue);
    });

    test('Classifies Network and Offline exceptions gracefully', () {
      final error = AppError.fromException('SocketException: Failed host lookup');
      expect(error.category, ErrorCategory.networkError);
      expect(error.userTitle.contains('Network Unavailable'), isTrue);
      expect(error.dataSafetyNote.contains('sync'), isTrue);
    });
  });

  group('SafeRetryEngine Tests', () {
    test('Retries failing task up to max attempts and recovers', () async {
      final retryEngine = SafeRetryEngine();
      int counter = 0;

      final result = await retryEngine.run(
        taskName: 'test_flaky_task',
        policy: const RetryPolicy(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10),
          maxDelay: Duration(milliseconds: 50),
          addJitter: false,
        ),
        action: () async {
          counter++;
          if (counter < 2) {
            throw Exception('Temporary timeout');
          }
          return 'SUCCESS';
        },
      );

      expect(result, 'SUCCESS');
      expect(counter, 2);
    });

    test('Throws exception when max retry attempts are exhausted', () async {
      final retryEngine = SafeRetryEngine();
      int counter = 0;

      await expectLater(
        () async => await retryEngine.run(
          taskName: 'test_fatal_task',
          policy: const RetryPolicy(
            maxAttempts: 2,
            initialDelay: Duration(milliseconds: 10),
            maxDelay: Duration(milliseconds: 30),
            addJitter: false,
          ),
          action: () async {
            counter++;
            throw Exception('Fatal hardware error');
          },
        ),
        throwsA(isA<Exception>()),
      );

      expect(counter, 2);
    });
  });

  group('TelemetryHealthMonitor Range Validation Tests', () {
    test('Validates realistic telemetry values as healthy', () {
      final monitor = TelemetryHealthMonitor();
      final validTelemetry = NormalizedTelemetry.empty().copyWith(
        speed: TelemetryValue.live(85.0, 'km/h'),
        rpm: TelemetryValue.live(6500, 'RPM'),
        batteryVoltage: TelemetryValue.live(12.6, 'V'),
        engineTemperature: TelemetryValue.live(88, '°C'),
      );

      final result = monitor.validate(validTelemetry);
      expect(result.isValid, isTrue);
      expect(result.anomalies, isEmpty);
    });

    test('Discards and flags anomalous values out of motorcycle physical bounds', () {
      final monitor = TelemetryHealthMonitor();
      final invalidTelemetry = NormalizedTelemetry.empty().copyWith(
        speed: TelemetryValue.live(-12.0, 'km/h'), // Negative speed
        rpm: TelemetryValue.live(45000, 'RPM'), // Impossible RPM
        batteryVoltage: TelemetryValue.live(1.2, 'V'), // Impossible 12V bus voltage
      );

      final result = monitor.validate(invalidTelemetry);
      expect(result.isValid, isFalse);
      expect(result.anomalies.length, 3);
    });
  });

  group('GpsHealthMonitor & ThreeDHealthMonitor Tests', () {
    test('GpsHealthMonitor classifies low precision and stale fixes', () {
      final monitor = GpsHealthMonitor();

      final lowPrecision = monitor.evaluate(
        hasPermission: true,
        isServiceEnabled: true,
        accuracyMeters: 45.0,
        lastFixTime: DateTime.now(),
      );
      expect(lowPrecision.state, GpsHealthState.lowAccuracy);

      final stale = monitor.evaluate(
        hasPermission: true,
        isServiceEnabled: true,
        accuracyMeters: 5.0,
        lastFixTime: DateTime.now().subtract(const Duration(seconds: 10)),
      );
      expect(stale.state, GpsHealthState.stale);
    });

    test('ThreeDHealthMonitor evaluates WebGL and missing model fallback states', () {
      final monitor = ThreeDHealthMonitor();

      final noWebGl = monitor.evaluate(
        isWebGLAvailable: false,
        isModelAvailable: true,
        isLoaded: false,
        lastError: null,
      );
      expect(noWebGl.state, ThreeDHealthState.unavailable);

      final modelMissing = monitor.evaluate(
        isWebGLAvailable: true,
        isModelAvailable: false,
        isLoaded: false,
        lastError: null,
      );
      expect(modelMissing.state, ThreeDHealthState.unavailable);

      final ready = monitor.evaluate(
        isWebGLAvailable: true,
        isModelAvailable: true,
        isLoaded: true,
        lastError: null,
      );
      expect(ready.state, ThreeDHealthState.rendering);
    });
  });
}
