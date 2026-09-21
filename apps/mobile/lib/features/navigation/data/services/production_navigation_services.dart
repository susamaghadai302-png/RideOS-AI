import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../domain/repositories/navigation_repository.dart';
import '../../domain/services/route_service.dart';
import '../../domain/services/location_service.dart';
import '../../domain/services/traffic_service.dart';
import '../../domain/services/navigation_voice_service.dart';
import '../../domain/entities/route_entity.dart';
import '../../core/map_abstraction/map_engine_interface.dart';
import '../../../../core/contracts/navigation_models.dart';

class ProductionRouteService implements RouteService {
  final NavigationRepository repository;

  ProductionRouteService({required this.repository});

  @override
  Future<NavigationRouteEntity> calculateRoute({
    required MapCoordinates origin,
    required MapCoordinates destination,
    List<MapCoordinates>? waypoints,
    VehicleRoutingProfile? vehicleProfile,
    String? preference,
  }) async {
    return await repository.calculateRoute(
      origin: origin,
      destination: destination,
      waypoints: waypoints,
      preference: preference ?? (vehicleProfile?.isEv == true ? 'EV' : null),
    );
  }

  @override
  Future<NavigationRouteEntity> recalculateRoute({
    required MapCoordinates currentLocation,
    required NavigationRouteEntity currentRoute,
    required String reason,
  }) async {
    if (currentRoute.waypoints.isEmpty) {
      throw RouteCalculationException('Cannot recalculate route: no waypoints available in current route.');
    }
    final destination = currentRoute.waypoints.last;
    return await repository.calculateRoute(
      origin: currentLocation,
      destination: destination,
    );
  }
}

class ProductionLocationService implements LocationService {
  @override
  Stream<RiderLocationFix> get locationStream {
    return Geolocator.getPositionStream().map((Position pos) => RiderLocationFix(
      coordinates: MapCoordinates(
        latitude: pos.latitude,
        longitude: pos.longitude,
      ),
      speedMetersPerSecond: pos.speed,
      headingDegree: pos.heading,
      accuracyMeters: pos.accuracy,
      altitudeMeters: pos.altitude,
      timestamp: pos.timestamp,
    ));
  }

  @override
  Future<MapCoordinates> getCurrentLocation() async {
    final pos = await Geolocator.getCurrentPosition();
    return MapCoordinates(
      latitude: pos.latitude,
      longitude: pos.longitude,
    );
  }

  @override
  Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  @override
  Future<bool> isGpsEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
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
  VoiceState _state = VoiceState.enabled;
  final FlutterTts _tts = FlutterTts();

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
    _updateState(VoiceState.enabled);
  }

  @override
  Future<void> disable() async {
    _updateState(VoiceState.disabled);
    await _tts.stop();
  }

  @override
  Future<void> speak(String instruction) async {
    if (_state == VoiceState.enabled) {
      await _tts.speak(instruction);
    }
  }
}
