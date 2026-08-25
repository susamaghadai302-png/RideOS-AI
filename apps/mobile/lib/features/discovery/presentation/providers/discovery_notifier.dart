import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'discovery_state.dart';
import '../../domain/entities/discovery_route_entity.dart';

class DiscoveryNotifier extends StateNotifier<DiscoveryState> {
  DiscoveryNotifier() : super(const DiscoveryState());

  void loadCuratedRoutes() {
    state = state.copyWith(
      routes: const [
        DiscoveryRouteEntity(
          id: 'route-1',
          title: 'Tail of the Dragon (Deals Gap)',
          locationName: 'North Carolina / Tennessee, USA',
          distanceKm: 18.0,
          twistyRating: 5,
          difficulty: 'TECHNICAL',
        ),
        DiscoveryRouteEntity(
          id: 'route-2',
          title: 'Pacific Coast Highway (Big Sur)',
          locationName: 'California, USA',
          distanceKm: 145.0,
          twistyRating: 4,
          difficulty: 'INTERMEDIATE',
        ),
        DiscoveryRouteEntity(
          id: 'route-3',
          title: 'Stelvio Pass Alpine Route',
          locationName: 'Eastern Alps, Italy',
          distanceKm: 47.0,
          twistyRating: 5,
          difficulty: 'TECHNICAL',
        ),
      ],
    );
  }
}

final discoveryNotifierProvider =
    StateNotifierProvider<DiscoveryNotifier, DiscoveryState>((ref) {
  return DiscoveryNotifier();
});
