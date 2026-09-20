import '../../core/map_abstraction/map_engine_interface.dart';

abstract class LocationService {
  Stream<MapCoordinates> get locationStream;
  Future<MapCoordinates> getCurrentLocation();
  Future<bool> hasLocationPermission();
  Future<bool> isGpsEnabled();
}
