import 'package:equatable/equatable.dart';
import '../../../../core/contracts/voice_models.dart';

abstract class VoiceEvent extends Equatable {
  const VoiceEvent();

  @override
  List<Object?> get props => [];
}

class StartVoiceListening extends VoiceEvent {}
class StopVoiceListening extends VoiceEvent {}
class CancelVoiceListening extends VoiceEvent {}

class VoiceStateUpdated extends VoiceEvent {
  final VoiceInputState inputState;
  const VoiceStateUpdated(this.inputState);
  @override
  List<Object?> get props => [inputState];
}

class VoiceTranscriptUpdated extends VoiceEvent {
  final VoiceTranscript transcript;
  const VoiceTranscriptUpdated(this.transcript);
  @override
  List<Object?> get props => [transcript];
}
