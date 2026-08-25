import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/network/api_client.dart';
import 'package:rideos_mobile/features/squad_ride/domain/entities/squad_entity.dart';
import 'package:rideos_mobile/features/squad_ride/presentation/bloc/squad_bloc.dart';
import 'package:rideos_mobile/features/squad_ride/presentation/bloc/squad_event.dart';
import 'package:rideos_mobile/features/squad_ride/presentation/bloc/squad_state.dart';
import 'package:rideos_mobile/features/squad_ride/data/datasources/squad_remote_datasource.dart';

class MockSquadRemoteDatasource implements SquadRemoteDatasource {
  @override
  ApiClient get apiClient => throw UnimplementedError();

  @override
  Future<SquadRoomEntity> createSquad(String title) async {
    return SquadRoomEntity(
      id: 'squad_room_101',
      squadCode: 'APEX89',
      title: title,
      creatorId: 'rider_creator_01',
      members: const [
        SquadMemberEntity(
          riderId: 'rider_creator_01',
          fullName: 'Squad Leader',
          isCreator: true,
          lat: 20.2961,
          lng: 85.8245,
          speedKmh: 45.0,
        ),
      ],
      isActive: true,
    );
  }

  @override
  Future<SquadRoomEntity> joinSquad(String squadCode) async {
    if (squadCode == 'INVALID') {
      throw Exception('Squad code not found');
    }
    return SquadRoomEntity(
      id: 'squad_room_102',
      squadCode: squadCode,
      title: 'Joined Apex Squad',
      creatorId: 'rider_leader_99',
      members: const [
        SquadMemberEntity(
          riderId: 'rider_leader_99',
          fullName: 'Leader One',
          isCreator: true,
          lat: 20.3000,
          lng: 85.8300,
          speedKmh: 60.0,
        ),
        SquadMemberEntity(
          riderId: 'rider_me_01',
          fullName: 'Joined Rider',
          isCreator: false,
          lat: 20.2961,
          lng: 85.8245,
          speedKmh: 58.0,
        ),
      ],
      isActive: true,
    );
  }

  @override
  Future<SquadRoomEntity> getSquad(String squadId) async {
    return const SquadRoomEntity(
      id: 'squad_room_101',
      squadCode: 'APEX89',
      title: 'Squad',
      creatorId: 'c1',
      members: [],
      isActive: true,
    );
  }
}

void main() {
  group('Phase 2 - Squad Ride & Real-time Coordination Tests', () {
    late MockSquadRemoteDatasource mockDatasource;
    late SquadBloc squadBloc;

    setUp(() {
      mockDatasource = MockSquadRemoteDatasource();
      squadBloc = SquadBloc(remoteDatasource: mockDatasource);
    });

    tearDown(() {
      squadBloc.close();
    });

    test('Initial state is SquadInitialState', () {
      expect(squadBloc.state, isA<SquadInitialState>());
    });

    test('Create squad emits [SquadLoadingState, SquadActiveState] with valid room code', () async {
      squadBloc.add(const CreateSquadEvent(title: 'Sunday Canyon Blast'));

      await expectLater(
        squadBloc.stream,
        emitsInOrder([
          isA<SquadLoadingState>(),
          predicate<SquadState>((s) => s is SquadActiveState && s.squad.squadCode == 'APEX89' && s.squad.members.length == 1),
        ]),
      );
    });

    test('Join squad with valid 6-character code emits SquadActiveState', () async {
      squadBloc.add(const JoinSquadEvent(squadCode: 'MOTO77'));

      await expectLater(
        squadBloc.stream,
        emitsInOrder([
          isA<SquadLoadingState>(),
          predicate<SquadState>((s) => s is SquadActiveState && s.squad.squadCode == 'MOTO77' && s.squad.members.length == 2),
        ]),
      );
    });

    test('Join squad failure emits SquadFailureState', () async {
      squadBloc.add(const JoinSquadEvent(squadCode: 'INVALID'));

      await expectLater(
        squadBloc.stream,
        emitsInOrder([
          isA<SquadLoadingState>(),
          isA<SquadFailureState>(),
        ]),
      );
    });
  });
}
