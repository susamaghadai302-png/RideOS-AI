import 'package:equatable/equatable.dart';

class SquadMemberEntity extends Equatable {
  final String riderId;
  final String fullName;
  final double? lat;
  final double? lng;
  final double? speedKmh;
  final bool isCreator;

  const SquadMemberEntity({
    required this.riderId,
    required this.fullName,
    this.lat,
    this.lng,
    this.speedKmh,
    this.isCreator = false,
  });

  @override
  List<Object?> get props => [riderId, fullName, lat, lng, speedKmh, isCreator];
}

class SquadRoomEntity extends Equatable {
  final String id;
  final String squadCode;
  final String title;
  final String creatorId;
  final List<SquadMemberEntity> members;
  final bool isActive;

  const SquadRoomEntity({
    required this.id,
    required this.squadCode,
    required this.title,
    required this.creatorId,
    required this.members,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, squadCode, title, creatorId, members, isActive];
}
