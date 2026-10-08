import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/intelligence/services/ride_ai_policy_engine.dart';
import 'package:rideos_mobile/core/intelligence/models/ride_ai_tool_layer.dart';
import 'package:rideos_mobile/core/intelligence/services/telemetry_quality_engine.dart';
import 'package:rideos_mobile/core/hardware/telemetry/vehicle_telemetry.dart';

void main() {
  group('Phase 6 — AI Policy & Tool Boundary Tests', () {
    test('1. Policy Engine explicitly blocks vehicle control requests', () {
      final intent1 = RideAIPolicyEngine.classifyIntent('start the engine');
      final intent2 = RideAIPolicyEngine.classifyIntent('turn off the lights');
      final intent3 = RideAIPolicyEngine.classifyIntent('apply the brake');

      expect(intent1, AIRequestClassification.vehicleControl);
      expect(intent2, AIRequestClassification.vehicleControl);
      expect(intent3, AIRequestClassification.vehicleControl);

      expect(RideAIPolicyEngine.isExecutionAllowed(intent1), isFalse);
    });

    test('2. Policy Engine permits safe diagnostic reasoning', () {
      final intent = RideAIPolicyEngine.classifyIntent('Is the bike overheating?');
      
      expect(intent, AIRequestClassification.diagnostic);
      expect(RideAIPolicyEngine.isExecutionAllowed(intent), isTrue);
    });

    test('3. RideAIResponse returns blocked action gracefully', () {
      final response = RideAIResponse.blockedAction();
      
      expect(response.answer, contains('cannot directly control vehicle hardware'));
      expect(response.confidence, 1.0);
      expect(response.warnings, contains('Vehicle control actions are explicitly blocked by policy.'));
    });

    test('4. TelemetryQualityEngine marks absent data as unavailable', () {
      final point = TelemetryQualityEngine.evaluateQuality<int>(
        value: null,
        unit: 'RPM',
        source: 'SYSTEM',
        timestamp: null,
        isHardwareConnected: false,
      );

      expect(point.quality, TelemetryQuality.unavailable);
      expect(point.value, isNull);
    });

    test('5. TelemetryQualityEngine marks old data as stale', () {
      final oldDate = DateTime.now().subtract(const Duration(seconds: 15));
      final point = TelemetryQualityEngine.evaluateQuality<int>(
        value: 3000,
        unit: 'RPM',
        source: 'OBD',
        timestamp: oldDate,
        isHardwareConnected: true,
      );

      expect(point.quality, TelemetryQuality.stale);
      expect(point.value, 3000);
      expect(point.confidence, 0.7);
    });
    
    test('6. TelemetryQualityEngine gracefully handles stale data when disconnected', () {
      final recentDate = DateTime.now().subtract(const Duration(seconds: 2));
      final point = TelemetryQualityEngine.evaluateQuality<int>(
        value: 3000,
        unit: 'RPM',
        source: 'OBD',
        timestamp: recentDate,
        isHardwareConnected: false,
      );

      expect(point.quality, TelemetryQuality.stale);
      expect(point.confidence, 0.5);
    });

    test('7. RideAIResponse handles insufficient data dynamically', () {
      final response = RideAIResponse.insufficientData(missingFields: ['RPM', 'CoolantTemp']);
      
      expect(response.answer, contains('unavailable or stale'));
      expect(response.unavailableData, containsAll(['RPM', 'CoolantTemp']));
      expect(response.confidence, 0.0);
    });
  });
}
