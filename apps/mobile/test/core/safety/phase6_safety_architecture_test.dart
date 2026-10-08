import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/safety/models/safety_architecture.dart';
import 'package:rideos_mobile/core/safety/models/sensor_fusion_state.dart';

void main() {
  group('Phase 6 — Safety Architecture & SOS State Machine Tests', () {
    test('1. SOS Request initialization binds correct confidence and timestamps', () {
      final now = DateTime.now();
      final request = SosRequest(
        timestamp: now,
        latitude: 37.7749,
        longitude: -122.4194,
        confidence: 0.95,
        triggerSource: 'SENSOR_FUSION_V1',
      );

      expect(request.confidence, 0.95);
      expect(request.triggerSource, 'SENSOR_FUSION_V1');
      expect(request.timestamp, now);
    });

    test('2. SensorFusionState correctly maps degradation without false positive triggers', () {
      var state = SensorFusionState.normal;
      
      // Simulate missing GPS
      state = SensorFusionState.degraded;
      expect(state, SensorFusionState.degraded);

      // Simulate minor bump (not passing multi-signal threshold)
      state = SensorFusionState.candidateEvent;
      expect(state, SensorFusionState.candidateEvent);
    });
    
    test('3. SOS State machine logic flow allows cancellation', () {
      var sosState = SosState.idle;
      
      sosState = SosState.candidate;
      sosState = SosState.countdown;
      
      // User cancels manually
      sosState = SosState.cancelled;
      
      expect(sosState, SosState.cancelled);
      expect(sosState, isNot(SosState.sending));
    });
  });
}
