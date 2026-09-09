import 'dart:async';
import 'package:rideos_mobile/core/contracts/voice_gateway.dart';
import 'package:rideos_mobile/core/contracts/voice_models.dart';

class FakeVoiceInputAdapter implements VoiceGateway {
  final StreamController<VoiceInputState> _stateController = StreamController<VoiceInputState>.broadcast();
  final StreamController<VoiceTranscript> _transcriptController = StreamController<VoiceTranscript>.broadcast();

  VoiceInputState _currentState = VoiceInputState.idle;

  FakeVoiceInputAdapter() {
    _stateController.add(VoiceInputState.idle);
  }

  @override
  Stream<VoiceInputState> get state => _stateController.stream;

  @override
  Stream<VoiceTranscript> get onTranscript => _transcriptController.stream;

  @override
  Future<void> startListening(VoiceRequest request) async {
    _currentState = VoiceInputState.permissionRequired;
    _stateController.add(_currentState);
    await Future.delayed(const Duration(milliseconds: 50));
    
    _currentState = VoiceInputState.listening;
    _stateController.add(_currentState);
  }

  @override
  Future<void> stopListening() async {
    if (_currentState == VoiceInputState.listening) {
      _currentState = VoiceInputState.idle;
      _stateController.add(_currentState);
    }
  }

  @override
  Future<void> cancelListening() async {
    if (_currentState == VoiceInputState.listening) {
      _currentState = VoiceInputState.idle;
      _stateController.add(_currentState);
    }
  }

  // Method to simulate results from test cases
  void simulateResult(String text, {bool isFinal = true}) {
    if (_currentState == VoiceInputState.listening) {
      _transcriptController.add(VoiceTranscript(
        text: text,
        isFinal: isFinal,
        confidence: 1.0,
      ));
      if (isFinal) {
        _currentState = VoiceInputState.processing;
        _stateController.add(_currentState);
        Future.delayed(const Duration(milliseconds: 50), () {
          _currentState = VoiceInputState.idle;
          _stateController.add(_currentState);
        });
      }
    }
  }

  void dispose() {
    _stateController.close();
    _transcriptController.close();
  }
}
