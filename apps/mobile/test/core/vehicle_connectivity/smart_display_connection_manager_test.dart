import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/services/smart_display_connection_manager.dart';

void main() {
  group('SmartDisplayConnectionManager Lifecycle', () {
    late SmartDisplayConnectionManager manager;

    setUp(() {
      // Re-initialize for tests
      manager = SmartDisplayConnectionManager();
    });

    test('initial state is idle', () {
      expect(manager.currentState, SmartDisplayState.idle);
    });

    test('autoConnect starts scanning', () async {
      // We aren't fully mocking flutter_blue_plus here, 
      // but we can verify it immediately enters scanning state.
      // Since autoConnect involves real plugin calls, we just start it
      // and assert the synchronous state transition.
      manager.autoConnect();
      expect(manager.currentState, SmartDisplayState.scanning);
    });

    test('disconnect resets state to disconnected', () async {
      await manager.disconnect();
      expect(manager.currentState, SmartDisplayState.disconnected);
    });
  });
}
