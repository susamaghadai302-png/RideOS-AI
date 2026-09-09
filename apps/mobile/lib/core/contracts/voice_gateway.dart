import 'voice_models.dart';

/// The canonical provider-independent Voice Gateway interface.
/// Serves as the primary input modality boundary for voice requests.
abstract class VoiceGateway {
  /// Emits the current state of the voice input lifecycle (listening, processing, error, etc).
  Stream<VoiceInputState> get state;

  /// Emits transcripts (both partial and final) during an active voice session.
  Stream<VoiceTranscript> get onTranscript;

  /// Starts a new voice listening session.
  /// Throws [VoiceRecognitionError] if unavailable or permission denied.
  Future<void> startListening(VoiceRequest request);

  /// Stops the current listening session and processes the final transcript.
  Future<void> stopListening();

  /// Cancels the current listening session and discards any partial transcripts.
  Future<void> cancelListening();
}
