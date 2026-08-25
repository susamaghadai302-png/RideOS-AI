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
          title: 'Shell High Octane Station',
          lat: 37.7749,
          lng: -122.4194,
          rating: 4.8,
        ),
        PoiEntity(
          id: 'poi-2',
          category: 'SCENIC_LOOKOUT',
          title: 'Skyline Ridge Overlook',
          lat: 37.7833,
          lng: -122.4167,
          rating: 4.9,
        ),
      ],
    );
  }
}

final mapNotifierProvider = StateNotifierProvider<MapNotifier, MapState>((ref) {
  return MapNotifier();
});
