import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'community_state.dart';
import '../../domain/entities/squad_ride_entity.dart';

class CommunityNotifier extends StateNotifier<CommunityState> {
  CommunityNotifier() : super(const CommunityState());

  Future<void> createSquad(String title) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 600));

    final newSquad = SquadRideEntity(
      id: 'squad-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      squadCode: 'RD8K9P',
      memberCount: 1,
      isLeader: true,
    );

    state = state.copyWith(
      activeSquad: newSquad,
      mySquads: [...state.mySquads, newSquad],
      isLoading: false,
    );
  }

  Future<void> joinSquad(String code) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 600));

    final joinedSquad = SquadRideEntity(
      id: 'squad-${DateTime.now().millisecondsSinceEpoch}',
      title: 'California Coast Riders',
      squadCode: code.toUpperCase(),
      memberCount: 4,
      isLeader: false,
    );

    state = state.copyWith(
      activeSquad: joinedSquad,
      mySquads: [...state.mySquads, joinedSquad],
      isLoading: false,
    );
  }
}

final communityNotifierProvider =
    StateNotifierProvider<CommunityNotifier, CommunityState>((ref) {
  return CommunityNotifier();
});
