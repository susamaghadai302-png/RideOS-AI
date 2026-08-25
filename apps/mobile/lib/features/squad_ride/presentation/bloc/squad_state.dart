import 'package:equatable/equatable.dart';
import '../../domain/entities/squad_entity.dart';

abstract class SquadState extends Equatable {
  const SquadState();

  @override
  List<Object?> get props => [];
}

class SquadInitialState extends SquadState {}

class SquadLoadingState extends SquadState {}

class SquadActiveState extends SquadState {
  final SquadRoomEntity squad;

  const SquadActiveState({required this.squad});

  @override
  List<Object?> get props => [squad];
}

class SquadFailureState extends SquadState {
  final String errorMessage;

  const SquadFailureState({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}
