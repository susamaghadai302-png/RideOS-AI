import 'package:equatable/equatable.dart';

class DiscoveryRouteEntity extends Equatable {
  final String id;
  final String title;
  final String locationName;
  final double distanceKm;
  final int twistyRating;
  final String difficulty;

  const DiscoveryRouteEntity({
    required this.id,
    required this.title,
    required this.locationName,
    required this.distanceKm,
    required this.twistyRating,
    required this.difficulty,
  });

  @override
  List<Object?> get props => [id, title, locationName, distanceKm, twistyRating, difficulty];
}
