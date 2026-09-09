import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/ai_assistant/presentation/bloc/ai_assistant_bloc.dart';
import 'package:rideos_mobile/features/ai_assistant/presentation/bloc/ai_assistant_event.dart';
import 'package:rideos_mobile/features/ai_assistant/presentation/bloc/ai_assistant_state.dart';
import 'package:rideos_mobile/core/contracts/ai_models.dart';
import 'package:rideos_mobile/core/contracts/ai_provider_gateway.dart';
import 'package:rideos_mobile/features/ai_assistant/domain/services/ai_intent_resolver.dart';

class MockAIProviderGateway implements AIProviderGateway {
  bool shouldThrow = false;

  @override
  AiProviderType get activeProviderType => AiProviderType.mockTest;

  @override
  Future<AIResponse> processQuery(AIRequest request) async {
    if (shouldThrow) {
      throw Exception('Network Error');
    }
    return const AIResponse(
      text: 'Mock Response',
      intent: AIIntent.informational,
      timestamp: '2026-09-06T10:00:00.000Z',
    );
  }
}

class MockAiIntentResolver implements AiIntentResolver {
  bool resolveCalled = false;

  @override
  get navigationGateway => throw UnimplementedError();

  @override
  Future<void> resolveAndExecute(AIResponse response) async {
    resolveCalled = true;
  }
}

void main() {
  late AiAssistantBloc bloc;
  late MockAIProviderGateway mockGateway;
  late MockAiIntentResolver mockIntentResolver;

  setUp(() {
    mockGateway = MockAIProviderGateway();
    mockIntentResolver = MockAiIntentResolver();
    bloc = AiAssistantBloc(
      gateway: mockGateway,
      intentResolver: mockIntentResolver,
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state is AiAssistantInitialState', () {
    expect(bloc.state, isA<AiAssistantInitialState>());
  });

  test('emits [AiAssistantLoadingState, AiAssistantLoadedState] on SendAiPromptEvent success', () async {
    final expectedStates = [
      isA<AiAssistantLoadingState>(),
      isA<AiAssistantLoadedState>(),
    ];

    expectLater(bloc.stream, emitsInOrder(expectedStates)).then((_) {
      expect(mockIntentResolver.resolveCalled, isTrue);
    });

    bloc.add(const SendAiPromptEvent(prompt: 'Hello!'));
  });

  test('emits [AiAssistantLoadingState, AiAssistantErrorState] on SendAiPromptEvent error', () async {
    mockGateway.shouldThrow = true;

    final expectedStates = [
      isA<AiAssistantLoadingState>(),
      isA<AiAssistantErrorState>(),
    ];

    expectLater(bloc.stream, emitsInOrder(expectedStates));

    bloc.add(const SendAiPromptEvent(prompt: 'Hello!'));
  });
}
