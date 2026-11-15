import 'package:equatable/equatable.dart';
import 'ai_message_entity.dart';

/// Represents a persistent conversation session with AI Assistant
class AiConversationEntity extends Equatable {
  final String conversationId;
  final String title;
  final bool isActive;
  final List<AiMessageEntity> messages;
  final DateTime? updatedAt;

  const AiConversationEntity({
    required this.conversationId,
    required this.title,
    this.isActive = true,
    this.messages = const [],
    this.updatedAt,
  });

  factory AiConversationEntity.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'] as List<dynamic>? ?? [];
    final parsedMessages = rawMessages.map((m) {
      final map = m as Map<String, dynamic>;
      final isUser = map['role'] == 'user';
      return AiMessageEntity(
        id: map['id']?.toString() ?? '',
        text: map['text']?.toString() ?? '',
        isUser: isUser,
        suggestedAction: map['suggestedAction']?.toString(),
        timestamp: map['timestamp'] != null
            ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
            : DateTime.now(),
        confidence: (map['confidence'] as num?)?.toDouble(),
        language: map['language']?.toString(),
        citations: (map['citations'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
      );
    }).toList();

    return AiConversationEntity(
      conversationId: json['conversationId']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Conversation',
      isActive: json['isActive'] as bool? ?? true,
      messages: parsedMessages,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  @override
  List<Object?> get props => [conversationId, title, isActive, messages, updatedAt];
}
