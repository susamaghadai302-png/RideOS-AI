import 'package:equatable/equatable.dart';

class AiMessageEntity extends Equatable {
  final String id;
  final String text;
  final bool isUser;
  final String? suggestedAction;
  final DateTime timestamp;
  final double? confidence;
  final String? language;
  final List<String>? citations;

  const AiMessageEntity({
    required this.id,
    required this.text,
    required this.isUser,
    this.suggestedAction,
    required this.timestamp,
    this.confidence,
    this.language,
    this.citations,
  });

  @override
  List<Object?> get props => [
        id,
        text,
        isUser,
        suggestedAction,
        timestamp,
        confidence,
        language,
        citations,
      ];
}
