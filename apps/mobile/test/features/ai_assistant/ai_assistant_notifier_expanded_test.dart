import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/contracts/ai_models.dart';
import 'package:rideos_mobile/core/contracts/ai_provider_gateway.dart';
import 'package:rideos_mobile/features/ai_assistant/data/datasources/ai_assistant_remote_datasource.dart';
import 'package:rideos_mobile/features/ai_assistant/domain/entities/ai_conversation_entity.dart';
import 'package:rideos_mobile/features/ai_assistant/domain/entities/ai_memory_entity.dart';
import 'package:rideos_mobile/features/ai_assistant/domain/entities/ai_message_entity.dart';
import 'package:rideos_mobile/features/ai_assistant/domain/entities/ai_provider_status_entity.dart';
import 'package:rideos_mobile/features/ai_assistant/presentation/providers/ai_assistant_notifier.dart';

class FakeAiGateway implements AIProviderGateway {
  String responseText = 'Telemetry nominal. Speed is 60 km/h.';
  String? actionPayload = 'SHOW_DIAGNOSTICS';
  String? returnConvId = 'conv-session-1';
  List<String>? citations = ['Vehicle Telemetry Stream'];
  bool shouldThrow = false;

  @override
  AiProviderType get activeProviderType => AiProviderType.cloudRemote;

  @override
  Future<AIResponse> processQuery(AIRequest request) async {
    if (shouldThrow) {
      throw Exception('Gateway timeout');
    }
    return AIResponse(
      text: responseText,
      intent: AIIntent.telemetry,
      confidence: AIConfidence.high,
      timestamp: DateTime.now().toIso8601String(),
      modelUsed: 'gemini-1.5-flash',
      isOfflineFallback: false,
      suggestedActionPayload: actionPayload,
      conversationId: returnConvId,
      citations: citations,
    );
  }
}

class FakeRemoteDatasource implements AiAssistantRemoteDatasource {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  AiProviderStatusEntity statusToReturn = const AiProviderStatusEntity(
    provider: 'Google Gemini AI',
    model: 'gemini-1.5-flash',
    status: 'CONNECTED',
    supportedLanguages: ['en', 'hi', 'hinglish', 'or'],
    toolsRegistered: ['check_tire_pressure', 'find_fuel_stations'],
    securityPolicies: ['PROMPT_INJECTION_FILTER'],
    timestamp: '2026-11-15T12:00:00.000Z',
  );

  List<AiConversationEntity> conversationsList = [
    AiConversationEntity(
      conversationId: 'conv-session-1',
      title: 'Previous Ride Check',
      isActive: true,
      messages: [
        AiMessageEntity(
          id: 'm1',
          text: 'Is bike ready for highway?',
          isUser: true,
          timestamp: DateTime(2026, 11, 15, 10, 0),
        ),
        AiMessageEntity(
          id: 'm2',
          text: 'Tires and coolant are optimal. Ride safe.',
          isUser: false,
          suggestedAction: 'SHOW_DIAGNOSTICS',
          timestamp: DateTime(2026, 11, 15, 10, 1),
        ),
      ],
    ),
  ];

  List<AiMemoryEntity> memoriesList = [
    const AiMemoryEntity(
      memoryId: 'mem-10',
      key: 'rider_commute_style',
      value: 'SPORT_TOURING',
    ),
  ];

  @override
  Future<AiProviderStatusEntity> getProviderStatus() async => statusToReturn;

  @override
  Future<List<AiConversationEntity>> getConversations() async => conversationsList;

  @override
  Future<AiConversationEntity> getConversation(String id) async {
    return conversationsList.firstWhere((c) => c.conversationId == id);
  }

  @override
  Future<void> deleteConversation(String id) async {
    conversationsList.removeWhere((c) => c.conversationId == id);
  }

  @override
  Future<List<AiMemoryEntity>> getMemories() async => memoriesList;

  @override
  Future<AiMemoryEntity> saveMemory(
    String key,
    String value, {
    String category = 'GENERAL',
    String source = 'USER_EXPLICIT',
    bool isConsentGranted = true,
  }) async {
    final entry = AiMemoryEntity(
      memoryId: 'mem-${memoriesList.length + 1}',
      key: key,
      value: value,
      category: category,
      source: source,
      isConsentGranted: isConsentGranted,
    );
    memoriesList.add(entry);
    return entry;
  }

  @override
  Future<void> deleteMemory(String id) async {
    memoriesList.removeWhere((m) => m.memoryId == id);
  }

  @override
  Future<void> clearAllMemories() async {
    memoriesList.clear();
  }
}

void main() {
  group('AiAssistantNotifier Expanded Feature Tests', () {
    late FakeAiGateway fakeGateway;
    late FakeRemoteDatasource fakeRemote;
    late AiAssistantNotifier notifier;

    setUp(() {
      fakeGateway = FakeAiGateway();
      fakeRemote = FakeRemoteDatasource();
      notifier = AiAssistantNotifier(
        gateway: fakeGateway,
        remoteDatasource: fakeRemote,
      );
    });

    test('checkProviderStatus queries backend status and updates state', () async {
      expect(notifier.state.providerStatus, isNull);

      await notifier.checkProviderStatus();

      expect(notifier.state.providerStatus, isNotNull);
      expect(notifier.state.providerStatus!.provider, 'Google Gemini AI');
      expect(notifier.state.isCloudConnected, isTrue);
    });

    test('sendQuery sends prompt, tracks conversationId, and attaches citations', () async {
      await notifier.sendQuery('How is my speed?');

      expect(notifier.state.messages.length, 2);
      expect(notifier.state.messages[0].isUser, isTrue);
      expect(notifier.state.messages[0].text, 'How is my speed?');
      expect(notifier.state.messages[1].isUser, isFalse);
      expect(notifier.state.messages[1].text, contains('Telemetry nominal'));
      expect(notifier.state.messages[1].citations, contains('Vehicle Telemetry Stream'));
      expect(notifier.state.currentConversationId, 'conv-session-1');
      expect(notifier.state.lastSuggestedAction, 'SHOW_DIAGNOSTICS');
      expect(notifier.state.isProcessing, isFalse);
    });

    test('Conversation history loading, switching, and deletion', () async {
      await notifier.loadConversations();
      expect(notifier.state.conversations.length, 1);
      expect(notifier.state.conversations.first.conversationId, 'conv-session-1');

      // Load specific conversation
      await notifier.loadConversation('conv-session-1');
      expect(notifier.state.currentConversationId, 'conv-session-1');
      expect(notifier.state.messages.length, 2);
      expect(notifier.state.messages.first.text, 'Is bike ready for highway?');

      // Start new conversation
      notifier.startNewConversation();
      expect(notifier.state.currentConversationId, isNull);
      expect(notifier.state.messages, isEmpty);

      // Delete conversation
      await notifier.deleteConversation('conv-session-1');
      expect(notifier.state.conversations, isEmpty);
    });

    test('Memory management adds, reads, and deletes rider memories', () async {
      await notifier.loadMemories();
      expect(notifier.state.memories.length, 1);
      expect(notifier.state.memories.first.key, 'rider_commute_style');

      final success = await notifier.saveMemory('preferred_fuel', '95_OCTANE', category: 'PREFERENCE');
      expect(success, isTrue);
      expect(notifier.state.memories.length, 2);

      await notifier.deleteMemory('mem-10');
      expect(notifier.state.memories.any((m) => m.memoryId == 'mem-10'), isFalse);

      await notifier.clearAllMemories();
      expect(notifier.state.memories, isEmpty);
    });

    test('Language switching updates state for multi-language co-pilot', () {
      expect(notifier.state.activeLanguage, 'en');

      notifier.setLanguage('hi');
      expect(notifier.state.activeLanguage, 'hi');

      notifier.setLanguage('or');
      expect(notifier.state.activeLanguage, 'or');
    });

    test('Gateway failure triggers safe honest fallback message without crash', () async {
      fakeGateway.shouldThrow = true;

      await notifier.sendQuery('Test failure');

      expect(notifier.state.messages.length, 2);
      expect(notifier.state.messages[1].isUser, isFalse);
      expect(notifier.state.messages[1].text, contains('DATA_UNAVAILABLE'));
      expect(notifier.state.isProcessing, isFalse);
    });
  });
}
