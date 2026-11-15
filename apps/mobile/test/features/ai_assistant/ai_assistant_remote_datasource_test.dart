import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:rideos_mobile/core/network/api_client.dart';
import 'package:rideos_mobile/core/storage/token_storage.dart';
import 'package:rideos_mobile/features/ai_assistant/data/datasources/ai_assistant_remote_datasource.dart';

class MockTokenStorage implements TokenStorage {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  Future<String?> getAccessToken() async => 'test-token';
}

void main() {
  group('AiAssistantRemoteDatasource Tests', () {
    late Dio dio;
    late ApiClient apiClient;
    late AiAssistantRemoteDatasource datasource;

    setUp(() {
      apiClient = ApiClient(tokenStorage: MockTokenStorage());
      dio = apiClient.dio;
      datasource = AiAssistantRemoteDatasource(apiClient: apiClient);
    });

    test('sendQuery sends prompt and parses AiChatMessage with citations', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/ai/assistant/query') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'response': 'Tire pressures are nominal at 32 PSI and 36 PSI.',
                    'suggestedAction': 'CHECK_TIRES',
                    'confidence': 100,
                    'language': 'en',
                    'conversationId': 'conv-456',
                    'citations': ['Vehicle Owner Manual Sec 4'],
                    'timestamp': '2026-11-15T12:00:00.000Z',
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final result = await datasource.sendQuery(
        'check tires',
        {'speedKmh': 45.0},
        'conv-456',
        'en',
      );

      expect(result.text, contains('Tire pressures are nominal'));
      expect(result.action, 'CHECK_TIRES');
      expect(result.confidence, 100.0);
      expect(result.conversationId, 'conv-456');
      expect(result.citations, contains('Vehicle Owner Manual Sec 4'));
      expect(result.isUser, isFalse);
    });

    test('getProviderStatus parses connected provider status', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/ai/assistant/status') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'provider': 'Google Gemini AI',
                    'model': 'gemini-1.5-flash',
                    'status': 'CONNECTED',
                    'supportedLanguages': ['en', 'hi', 'hinglish', 'or'],
                    'toolsRegistered': ['check_tire_pressure', 'find_fuel_stations'],
                    'securityPolicies': ['PROMPT_INJECTION_FILTER'],
                    'timestamp': '2026-11-15T12:00:00.000Z',
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final status = await datasource.getProviderStatus();

      expect(status.provider, 'Google Gemini AI');
      expect(status.model, 'gemini-1.5-flash');
      expect(status.isCloudConnected, isTrue);
      expect(status.supportedLanguages, contains('or'));
      expect(status.toolsRegistered, contains('check_tire_pressure'));
    });

    test('getConversations and getConversation parse message history', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/ai/assistant/conversations') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: [
                    {
                      'conversationId': 'conv-101',
                      'title': 'Tire pressure inquiry',
                      'isActive': true,
                      'updatedAt': '2026-11-15T11:00:00.000Z',
                      'messages': [
                        {
                          'id': 'msg-1',
                          'role': 'user',
                          'text': 'check tires',
                          'timestamp': '2026-11-15T11:00:00.000Z',
                        },
                        {
                          'id': 'msg-2',
                          'role': 'assistant',
                          'text': '32 PSI front, 36 PSI rear.',
                          'suggestedAction': 'CHECK_TIRES',
                          'timestamp': '2026-11-15T11:00:01.000Z',
                        },
                      ],
                    },
                  ],
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final conversations = await datasource.getConversations();

      expect(conversations.length, 1);
      expect(conversations.first.conversationId, 'conv-101');
      expect(conversations.first.title, 'Tire pressure inquiry');
      expect(conversations.first.messages.length, 2);
      expect(conversations.first.messages.first.isUser, isTrue);
      expect(conversations.first.messages.last.isUser, isFalse);
    });

    test('getMemories, saveMemory, deleteMemory, and clearAllMemories execute correctly', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/ai/assistant/memories' && options.method == 'GET') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: [
                    {
                      'memoryId': 'mem-001',
                      'key': 'favorite_riding_mode',
                      'value': 'DYNAMIC_PRO',
                      'category': 'PREFERENCE',
                      'isConsentGranted': true,
                    },
                  ],
                ),
              );
            }
            if (options.path == '/ai/assistant/memories' && options.method == 'POST') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 201,
                  data: {
                    'memoryId': 'mem-002',
                    'key': options.data['key'],
                    'value': options.data['value'],
                    'category': options.data['category'],
                    'isConsentGranted': options.data['isConsentGranted'],
                  },
                ),
              );
            }
            if (options.path == '/ai/assistant/memories/mem-001' && options.method == 'DELETE') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'success': true, 'memoryId': 'mem-001'},
                ),
              );
            }
            if (options.path == '/ai/assistant/memories' && options.method == 'DELETE') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'success': true, 'count': 2},
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final memories = await datasource.getMemories();
      expect(memories.length, 1);
      expect(memories.first.key, 'favorite_riding_mode');
      expect(memories.first.value, 'DYNAMIC_PRO');

      final saved = await datasource.saveMemory('commute_route', 'Expressway', category: 'ROUTES');
      expect(saved.memoryId, 'mem-002');
      expect(saved.key, 'commute_route');
      expect(saved.value, 'Expressway');

      await expectLater(datasource.deleteMemory('mem-001'), completes);
      await expectLater(datasource.clearAllMemories(), completes);
    });
  });
}
