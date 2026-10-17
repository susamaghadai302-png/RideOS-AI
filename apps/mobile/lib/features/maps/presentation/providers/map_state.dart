import 'package:equatable/equatable.dart';
import '../../domain/entities/poi_entity.dart';

class MapState extends Equatable {
  final double userLat;
  final double userLng;
  final double zoom;
  final List<PoiEntity> pois;
  final bool isLoading;

  const MapState({
    this.userLat = 20.2961,
    this.userLng = 85.8245,
    this.zoom = 14.0,
    this.pois = const [],
    this.isLoading = false,
  });

  MapState copyWith({
    double? userLat,
    double? userLng,
    double? zoom,
    List<PoiEntity>? pois,
    bool? isLoading,
  }) {
    return MapState(
      userLat: userLat ?? this.userLat,
      userLng: userLng ?? this.userLng,
      zoom: zoom ?? this.zoom,
      pois: pois ?? this.pois,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [userLat, userLng, zoom, pois, isLoading];
}
