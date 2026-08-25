import 'dart:async';
import '../map_abstraction/map_engine_interface.dart';

class BackgroundLocationService {
  static final BackgroundLocationService _instance = BackgroundLocationService._internal();
  factory BackgroundLocationService() => _instance;
  BackgroundLocationService._internal();

  bool _isTrackingBackground = false;
  final _locationStreamController = StreamController<MapCoordinates>.broadcast();

  bool get isTrackingBackground => _isTrackingBackground;
  Stream<MapCoordinates> get locationStream => _locationStreamController.stream;

  Future<void> startBackgroundTracking() async {
    _isTrackingBackground = true;
    // Emit periodic background coordinates
    _locationStreamController.add(const MapCoordinates(latitude: 36.5785, longitude: -118.2920));
  }

  Future<void> stopBackgroundTracking() async {
    _isTrackingBackground = false;
  }

  void dispose() {
    _locationStreamController.close();
  }
}
