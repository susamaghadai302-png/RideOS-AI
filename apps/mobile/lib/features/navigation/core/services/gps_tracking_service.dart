import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../map_abstraction/map_engine_interface.dart';
import '../../../../core/contracts/navigation_models.dart';

class GpsTrackingService {
  StreamSubscription<Position>? _positionStreamSub;
  final _locationController = StreamController<RiderLocationFix>.broadcast();

  Stream<RiderLocationFix> get locationStream => _locationController.stream;

  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  void startTracking() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 2, // 2 meter threshold for motorcycle precision
    );

    _positionStreamSub = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        final fix = RiderLocationFix(
          coordinates: MapCoordinates(latitude: position.latitude, longitude: position.longitude),
          speedKmh: position.speed > 0 ? (position.speed * 3.6) : 0.0,
          headingDegree: position.heading,
          altitudeMeters: position.altitude,
          timestamp: position.timestamp,
        );
        _locationController.add(fix);
      },
      onError: (error) {
        // Safe stream catch on Web / desktop when browser GPS is unprompted
      },
      cancelOnError: false,
    );
  }

  void stopTracking() {
    _positionStreamSub?.cancel();
  }

  void dispose() {
    stopTracking();
    _locationController.close();
  }
}
