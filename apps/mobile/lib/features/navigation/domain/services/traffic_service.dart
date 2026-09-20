import '../../core/map_abstraction/map_engine_interface.dart';

class TrafficDataUnavailableException implements Exception {
  final String message;
  TrafficDataUnavailableException(this.message);
  @override
  String toString() => 'TrafficDataUnavailableException: $message';
}

abstract class TrafficService {
  Future<Map<String, dynamic>> getTrafficData(MapCoordinates location, double radiusKm);
  Future<bool> isTrafficAvailable();
}
