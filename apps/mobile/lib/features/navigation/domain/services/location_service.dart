import '../../core/map_abstraction/map_engine_interface.dart';

import '../../../../core/contracts/navigation_models.dart';

abstract class LocationService {
  Stream<RiderLocationFix> get locationStream;
  Future<MapCoordinates> getCurrentLocation();
  Future<bool> hasLocationPermission();
  Future<bool> isGpsEnabled();
}
