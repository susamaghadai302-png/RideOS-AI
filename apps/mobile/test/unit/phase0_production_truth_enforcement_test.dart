import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/config/production_firebase_guard.dart';
import 'package:rideos_mobile/features/obd_tpms/core/services/obd_full_telemetry_service.dart';
import 'package:rideos_mobile/core/vehicle_health/services/predictive_vehicle_health_engine.dart';
import 'package:rideos_mobile/core/vehicle_identification/services/smart_scan_orchestrator.dart';

Future<String> _readProductionDartSource() async {
  Directory? sourceRoot;
  for (final candidate in [Directory('lib'), Directory('apps/mobile/lib')]) {
    if (candidate.existsSync()) {
      sourceRoot = candidate;
      break;
    }
  }

  expect(
    sourceRoot,
    isNotNull,
    reason: 'Could not locate the mobile production lib/ directory.',
  );

  final source = StringBuffer();
  await for (final entity
      in sourceRoot!.list(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      source.writeln(await entity.readAsString());
    }
  }
  return source.toString();
}

FirebaseOptions _firebaseOptions({
  String projectId = 'rideos-production',
  String appId = '1:9876543210:android:rideosproduction',
  String apiKey = 'non-empty-test-api-key',
  String messagingSenderId = '9876543210',
}) {
  return FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
  );
}

void main() {
  group('Phase 0: Production Firebase bootstrap guard', () {
    test('release rejects a placeholder Firebase project', () {
      expect(
        () => ProductionFirebaseGuard.validate(
          _firebaseOptions(projectId: 'rideos-mock-project'),
          releaseMode: true,
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('release rejects the known placeholder app-id marker', () {
      expect(
        () => ProductionFirebaseGuard.validate(
          _firebaseOptions(appId: '1:1234567890:android:placeholder'),
          releaseMode: true,
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('release rejects incomplete required Firebase options', () {
      expect(
        () => ProductionFirebaseGuard.validate(
          _firebaseOptions(apiKey: '  '),
          releaseMode: true,
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('release accepts non-placeholder, complete Firebase options', () {
      expect(
        () => ProductionFirebaseGuard.validate(
          _firebaseOptions(),
          releaseMode: true,
        ),
        returnsNormally,
      );
    });

    test('debug mode permits placeholder options for local development', () {
      expect(
        () => ProductionFirebaseGuard.validate(
          _firebaseOptions(projectId: 'rideos-mock-project'),
          releaseMode: false,
        ),
        returnsNormally,
      );
    });

    test('production Firebase/App Check startup failures stop release startup', () async {
      final mainSource = await File(
        'lib/main.dart',
      ).exists()
          ? await File('lib/main.dart').readAsString()
          : await File('apps/mobile/lib/main.dart').readAsString();

      expect(mainSource, contains('if (kReleaseMode)'));
      expect(mainSource, contains('_ProductionBootstrapFailureApp()'));
      expect(mainSource, contains('runApp(const _ProductionBootstrapFailureApp())'));
      expect(mainSource, contains('return;'));
    });
  });

  group('Phase 0: Empty Garage Production-Truth', () {
    test('legacy mock vehicle seeding entry point is absent from production source', () async {
      final source = await _readProductionDartSource();
      expect(source, isNot(contains('seedMockVehiclesIfEmpty')));
    });
  });

  group('Phase 0: Telemetry Production-Truth', () {
    test('default telemetry state is unconnectedOffline', () {
      final service = ObdFullTelemetryService();
      final data = service.getLatestTelemetry();
      expect(data.source, equals(TelemetryDataSource.unconnectedOffline));
      expect(data.engineRpm, isNull);
    });

    test('unconnected telemetry is not simulated', () {
      final service = ObdFullTelemetryService();
      final data = service.getLatestTelemetry();
      expect(data.isSimulated, isFalse);
    });

    test('predictive health engine reports a result without requiring hardware', () {
      final engine = PredictiveVehicleHealthEngine();
      final report = engine.evaluateHealthReport();
      expect(report, isNotNull);
    });
  });

  group('Phase 0: Vehicle Identity Production-Truth', () {
    test('SmartScan orchestrator is available without asserting fake identity data', () {
      expect(SmartScanOrchestrator.instance, isNotNull);
    });
  });

  group('Phase 0: OTP Production-Truth', () {
    test('mobile production source contains no literal OTP code assignments', () async {
      final source = await _readProductionDartSource();
      final hardcodedOtpAssignment = RegExp(
        r'''(?:otp|verification[\w]*code)[\w]*\s*[:=]\s*(['"])\d{4,8}\1''',
        caseSensitive: false,
      );
      expect(hardcodedOtpAssignment.hasMatch(source), isFalse);
    });
  });

  group('Phase 0: AI Agent Production-Truth', () {
    test('legacy fallback-SLM marker is absent from production source', () async {
      final source = await _readProductionDartSource();
      expect(source, isNot(contains('FALLBACK_SLM')));
    });

    test('legacy demo rider identity is absent from production source', () async {
      final source = await _readProductionDartSource();
      expect(source, isNot(contains('rider_guest_demo_01')));
    });
  });
}
