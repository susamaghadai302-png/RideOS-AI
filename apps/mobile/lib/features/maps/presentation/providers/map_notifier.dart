import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'map_state.dart';
import '../../domain/entities/poi_entity.dart';

class MapNotifier extends StateNotifier<MapState> {
  MapNotifier() : super(const MapState());

  void updateLocation(double lat, double lng) {
    state = state.copyWith(userLat: lat, userLng: lng);
  }

  void setZoom(double newZoom) {
    state = state.copyWith(zoom: newZoom);
  }

  Future<void> loadNearbyPois() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 500));
    state = state.copyWith(
      isLoading: false,
      pois: const [
        PoiEntity(
          id: 'poi-1',
          category: 'GAS_STATION',
          title: 'HP Auto Fuel Station - Patia',
          lat: 20.3540,
          lng: 85.8180,
          rating: 4.8,
        ),
        PoiEntity(
          id: 'poi-2',
          category: 'SCENIC_LOOKOUT',
          title: 'Nandankanan Lake Overlook',
          lat: 20.3955,
          lng: 85.8250,
          rating: 4.9,
        ),
      ],
    );
  }
}

final mapNotifierProvider = StateNotifierProvider<MapNotifier, MapState>((ref) {
  return MapNotifier();
});
