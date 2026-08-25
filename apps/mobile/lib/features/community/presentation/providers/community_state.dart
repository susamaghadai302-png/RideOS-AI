import 'package:equatable/equatable.dart';
import '../../domain/entities/squad_ride_entity.dart';

class CommunityState extends Equatable {
  final SquadRideEntity? activeSquad;
  final List<SquadRideEntity> mySquads;
  final bool isLoading;

  const CommunityState({
    this.activeSquad,
    this.mySquads = const [],
    this.isLoading = false,
  });

  CommunityState copyWith({
    SquadRideEntity? activeSquad,
    List<SquadRideEntity>? mySquads,
    bool? isLoading,
  }) {
    return CommunityState(
      activeSquad: activeSquad ?? this.activeSquad,
      mySquads: mySquads ?? this.mySquads,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [activeSquad, mySquads, isLoading];
}
