import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/network/api_client.dart';
import 'package:rideos_mobile/core/storage/token_storage.dart';
import 'package:rideos_mobile/features/ai_assistant/data/datasources/ai_assistant_remote_datasource.dart';
import 'package:rideos_mobile/features/ai_assistant/presentation/bloc/ai_assistant_bloc.dart';
import 'package:rideos_mobile/features/ai_assistant/presentation/bloc/ai_assistant_event.dart';
import 'package:rideos_mobile/features/ai_assistant/presentation/bloc/ai_assistant_state.dart';

class MockAiRemoteDatasource extends AiAssistantRemoteDatasource {
  MockAiRemoteDatasource() : super(apiClient: ApiClient(tokenStorage: TokenStorage()));

  @override
  Future<AiChatMessage> sendQuery(String prompt) async {
    return AiChatMessage(
      text: 'Shell station is 4.2 km ahead on your route.',
      isUser: false,
      timestamp: DateTime.now().toIso8601String(),
      action: 'NAVIGATE_FUEL',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAiRemoteDatasource mockDatasource;
  late AiAssistantBloc bloc;

  setUp(() {
    mockDatasource = MockAiRemoteDatasource();
    bloc = AiAssistantBloc(remoteDatasource: mockDatasource);
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state is AiAssistantInitialState', () {
    expect(bloc.state, isA<AiAssistantInitialState>());
  });

  test('emits [AiAssistantLoadingState, AiAssistantLoadedState] on prompt', () async {
    expectLater(
      bloc.stream,
      emitsInOrder([
        isA<AiAssistantLoadingState>(),
        isA<AiAssistantLoadedState>(),
      ]),
    );

    bloc.add(const SendAiPromptEvent(prompt: 'Where is gas?'));
  });
}
