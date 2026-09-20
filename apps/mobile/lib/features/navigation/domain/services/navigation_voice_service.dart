enum VoiceState {
  enabled,
  disabled,
  unavailable,
  error,
}

abstract class NavigationVoiceService {
  VoiceState get currentState;
  Stream<VoiceState> get stateStream;
  
  Future<void> enable();
  Future<void> disable();
  Future<void> speak(String instruction);
}
