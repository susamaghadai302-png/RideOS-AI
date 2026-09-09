import 'package:equatable/equatable.dart';
import '../../../../core/contracts/voice_models.dart';

class VoiceState extends Equatable {
  final VoiceInputState inputState;
  final VoiceTranscript? currentTranscript;
  final VoiceRecognitionError? error;

  const VoiceState({
    this.inputState = VoiceInputState.idle,
    this.currentTranscript,
    this.error,
  });

  VoiceState copyWith({
    VoiceInputState? inputState,
    VoiceTranscript? currentTranscript,
    VoiceRecognitionError? error,
  }) {
    return VoiceState(
      inputState: inputState ?? this.inputState,
      currentTranscript: currentTranscript ?? this.currentTranscript,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [inputState, currentTranscript, error];
}
