import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/network/api_client.dart';
import 'package:rideos_mobile/core/storage/token_storage.dart';
import 'package:rideos_mobile/features/sos_safety/presentation/bloc/sos_bloc.dart';
import 'package:rideos_mobile/features/sos_safety/presentation/bloc/sos_event.dart';
import 'package:rideos_mobile/features/sos_safety/presentation/bloc/sos_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ApiClient apiClient;
  late SosBloc sosBloc;

  setUp(() {
    apiClient = ApiClient(tokenStorage: TokenStorage());
    sosBloc = SosBloc(apiClient: apiClient);
  });

  tearDown(() {
    sosBloc.close();
  });

  test('initial state is SosIdleState', () {
    expect(sosBloc.state, isA<SosIdleState>());
  });

  test('emits SosCountdownState on TriggerSosEvent', () async {
    expectLater(
      sosBloc.stream,
      emits(isA<SosCountdownState>()),
    );

    sosBloc.add(
      const TriggerSosEvent(
        lat: 37.7749,
        lng: -122.4194,
        triggerType: 'MANUAL',
      ),
    );
  });

  test('cancels countdown on CancelSosEvent', () async {
    sosBloc.add(
      const TriggerSosEvent(
        lat: 37.7749,
        lng: -122.4194,
        triggerType: 'MANUAL',
      ),
    );

    sosBloc.add(CancelSosEvent());

    expectLater(
      sosBloc.stream,
      emitsThrough(isA<SosIdleState>()),
    );
  });
}
