import 'package:equatable/equatable.dart';

abstract class SquadEvent extends Equatable {
  const SquadEvent();

  @override
  List<Object?> get props => [];
}

class CreateSquadEvent extends SquadEvent {
  final String title;

  const CreateSquadEvent({required this.title});

  @override
  List<Object?> get props => [title];
}

class JoinSquadEvent extends SquadEvent {
  final String squadCode;

  const JoinSquadEvent({required this.squadCode});

  @override
  List<Object?> get props => [squadCode];
}

class LeaveSquadEvent extends SquadEvent {}
