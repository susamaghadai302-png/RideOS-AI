import 'package:equatable/equatable.dart';

class SquadRideEntity extends Equatable {
  final String id;
  final String title;
  final String squadCode;
  final int memberCount;
  final bool isLeader;

  const SquadRideEntity({
    required this.id,
    required this.title,
    required this.squadCode,
    required this.memberCount,
    required this.isLeader,
  });

  @override
  List<Object?> get props => [id, title, squadCode, memberCount, isLeader];
}
