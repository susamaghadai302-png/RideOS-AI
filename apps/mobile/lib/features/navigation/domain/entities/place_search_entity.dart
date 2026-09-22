import 'package:equatable/equatable.dart';

class PlaceSearchResultEntity extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;
  final double? rating;
  final List<String> tags;

  const PlaceSearchResultEntity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.rating,
    this.tags = const [],
  });

  factory PlaceSearchResultEntity.fromJson(Map<String, dynamic> json) {
    return PlaceSearchResultEntity(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      category: json['category'] ?? 'DESTINATION',
      latitude: (json['lat'] as num?)?.toDouble(),
      longitude: (json['lng'] as num?)?.toDouble(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble(),
      tags: (json['tags'] as List<dynamic>?)?.map((t) => t.toString()).toList() ?? [],
    );
  }

  @override
  List<Object?> get props => [id, title, subtitle, category, latitude, longitude, distanceKm, rating, tags];
}
