import 'package:equatable/equatable.dart';

class VoiceCommandEntity extends Equatable {
  final String rawTranscript;
  final String intent;
  final DateTime timestamp;

  const VoiceCommandEntity({
    required this.rawTranscript,
    required this.intent,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [rawTranscript, intent, timestamp];
}
