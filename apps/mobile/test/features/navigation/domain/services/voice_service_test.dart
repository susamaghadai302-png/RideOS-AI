import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/navigation/domain/services/navigation_voice_service.dart';

class MockVoiceService implements NavigationVoiceService {
  VoiceState _state = VoiceState.disabled;
  final _stateController = StreamController<VoiceState>.broadcast();

  @override
  VoiceState get currentState => _state;

  @override
  Stream<VoiceState> get stateStream => _stateController.stream;

  void _updateState(VoiceState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  @override
  Future<void> enable() async {
    if (_state == VoiceState.unavailable) return;
    _updateState(VoiceState.enabled);
  }

  @override
  Future<void> disable() async {
    if (_state == VoiceState.unavailable) return;
    _updateState(VoiceState.disabled);
  }

  @override
  Future<void> speak(String instruction) async {
    if (_state == VoiceState.unavailable || _state == VoiceState.error) {
      throw Exception('Voice unavailable or in error state');
    }
    // Simulate speaking
  }

  void simulateUnavailable() {
    _updateState(VoiceState.unavailable);
  }

  void simulateError() {
    _updateState(VoiceState.error);
  }
}

void main() {
  group('NavigationVoiceService (Phase 8 Domain)', () {
    late MockVoiceService voiceService;

    setUp(() {
      voiceService = MockVoiceService();
    });

    test('Initial state is disabled', () {
      expect(voiceService.currentState, VoiceState.disabled);
    });

    test('Enable transitions to enabled', () async {
      await voiceService.enable();
      expect(voiceService.currentState, VoiceState.enabled);
    });

    test('Speak throws if unavailable', () async {
      voiceService.simulateUnavailable();
      expect(
        () => voiceService.speak('Turn left'),
        throwsException,
      );
    });

    test('Speak throws if error', () async {
      voiceService.simulateError();
      expect(
        () => voiceService.speak('Turn right'),
        throwsException,
      );
    });
  });
}
