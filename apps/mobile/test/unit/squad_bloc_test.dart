import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/network/api_client.dart';
import 'package:rideos_mobile/core/storage/token_storage.dart';
import 'package:rideos_mobile/features/squad_ride/data/datasources/squad_remote_datasource.dart';
import 'package:rideos_mobile/features/squad_ride/domain/entities/squad_entity.dart';
import 'package:rideos_mobile/features/squad_ride/presentation/bloc/squad_bloc.dart';
import 'package:rideos_mobile/features/squad_ride/presentation/bloc/squad_event.dart';
import 'package:rideos_mobile/features/squad_ride/presentation/bloc/squad_state.dart';

class MockSquadRemoteDS extends SquadRemoteDatasource {
  MockSquadRemoteDS() : super(apiClient: ApiClient(tokenStorage: TokenStorage()));

  @override
  Future<SquadRoomEntity> createSquad(String title) async {
    return const SquadRoomEntity(
      id: 'squad-1',
      squadCode: 'AB12CD',
      title: 'Weekend Canyon Run',
      creatorId: 'rider-1',
      members: [
        SquadMemberEntity(riderId: 'rider-1', fullName: 'Jane Doe', isCreator: true),
      ],
    );
  }

  @override
  Future<SquadRoomEntity> joinSquad(String squadCode) async {
    return const SquadRoomEntity(
      id: 'squad-1',
      squadCode: 'AB12CD',
      title: 'Weekend Canyon Run',
      creatorId: 'rider-1',
      members: [
        SquadMemberEntity(riderId: 'rider-1', fullName: 'Jane Doe', isCreator: true),
        SquadMemberEntity(riderId: 'rider-2', fullName: 'Alex Smith', isCreator: false),
      ],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSquadRemoteDS mockDS;
  late SquadBloc bloc;

  setUp(() {
    mockDS = MockSquadRemoteDS();
    bloc = SquadBloc(remoteDatasource: mockDS);
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state is SquadInitialState', () {
    expect(bloc.state, isA<SquadInitialState>());
  });

  test('emits [SquadLoadingState, SquadActiveState] on CreateSquadEvent', () async {
    expectLater(
      bloc.stream,
      emitsInOrder([
        isA<SquadLoadingState>(),
        isA<SquadActiveState>(),
      ]),
    );

    bloc.add(const CreateSquadEvent(title: 'Weekend Canyon Run'));
  });

  test('emits [SquadLoadingState, SquadActiveState] on JoinSquadEvent', () async {
    expectLater(
      bloc.stream,
      emitsInOrder([
        isA<SquadLoadingState>(),
        isA<SquadActiveState>(),
      ]),
    );

    bloc.add(const JoinSquadEvent(squadCode: 'AB12CD'));
  });
}
