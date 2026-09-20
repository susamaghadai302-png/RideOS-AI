import 'dart:async';
import '../../domain/services/route_service.dart';
import '../../domain/services/location_service.dart';
import '../../domain/services/traffic_service.dart';
import '../../domain/services/navigation_voice_service.dart';
import '../../domain/entities/route_entity.dart';
import '../../core/map_abstraction/map_engine_interface.dart';

class ProductionRouteService implements RouteService {
  @override
  Future<NavigationRouteEntity> calculateRoute({
    required MapCoordinates origin,
    required MapCoordinates destination,
    List<MapCoordinates>? waypoints,
    VehicleRoutingProfile? vehicleProfile,
    String? preference,
  }) async {
    // Real implementation would call Google Maps Directions API here.
    // For now, per the Real Data Rule, we do not fake a route if we don't have the real API integrated yet.
    throw RouteCalculationException('Production Routing API not fully integrated in Phase 8 boundary.');
  }

  @override
  Future<NavigationRouteEntity> recalculateRoute({
    required MapCoordinates currentLocation,
    required NavigationRouteEntity currentRoute,
    required String reason,
  }) async {
    throw RouteCalculationException('Production Rerouting API not fully integrated in Phase 8 boundary.');
  }
}

class ProductionLocationService implements LocationService {
  final _controller = StreamController<MapCoordinates>.broadcast();
  
  @override
  Stream<MapCoordinates> get locationStream => _controller.stream;

  @override
  Future<MapCoordinates> getCurrentLocation() async {
    // Ideally calls Geolocator.getCurrentPosition()
    throw Exception('Location unavailable in production boundary without real GPS fix.');
  }

  @override
  Future<bool> hasLocationPermission() async => false;

  @override
  Future<bool> isGpsEnabled() async => false;
}

class ProductionTrafficService implements TrafficService {
  @override
  Future<Map<String, dynamic>> getTrafficData(MapCoordinates location, double radiusKm) async {
    throw TrafficDataUnavailableException('Live traffic data is currently unavailable.');
  }

  @override
  Future<bool> isTrafficAvailable() async => false;
}

class ProductionVoiceService implements NavigationVoiceService {
  final _stateController = StreamController<VoiceState>.broadcast();
  VoiceState _state = VoiceState.unavailable;

  @override
  VoiceState get currentState => _state;

  @override
  Stream<VoiceState> get stateStream => _stateController.stream;

  void _updateState(VoiceState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  @override
  Future<void> enable() async {
    _updateState(VoiceState.unavailable);
  }

  @override
  Future<void> disable() async {
    _updateState(VoiceState.unavailable);
  }

  @override
  Future<void> speak(String instruction) async {
    throw Exception('Voice synthesis is unavailable in this production boundary.');
  }
}
