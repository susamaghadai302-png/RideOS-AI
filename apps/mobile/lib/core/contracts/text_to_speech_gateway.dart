abstract class TextToSpeechGateway {
  /// Speaks the given text using the platform's TTS engine.
  Future<void> speak(String text);

  /// Stops any ongoing TTS playback.
  Future<void> stop();

  /// Returns a stream of TTS playback state (e.g. true when speaking, false when idle).
  Stream<bool> get isSpeaking;
}
