import 'dart:async';
import 'package:geolocator/geolocator.dart';

enum LocationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  backgroundGranted,
}

class LocationPermissionManager {
  static final LocationPermissionManager _instance = LocationPermissionManager._internal();
  factory LocationPermissionManager() => _instance;
  LocationPermissionManager._internal();

  LocationPermissionStatus _status = LocationPermissionStatus.denied;

  LocationPermissionStatus get currentStatus => _status;

  Future<LocationPermissionStatus> requestLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _status = LocationPermissionStatus.denied;
        return _status;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        _status = LocationPermissionStatus.granted;
      } else if (permission == LocationPermission.deniedForever) {
        _status = LocationPermissionStatus.permanentlyDenied;
      } else {
        _status = LocationPermissionStatus.denied;
      }
      return _status;
    } catch (_) {
      _status = LocationPermissionStatus.denied;
      return _status;
    }
  }

  Future<LocationPermissionStatus> requestBackgroundLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.always) {
        _status = LocationPermissionStatus.backgroundGranted;
      } else if (permission == LocationPermission.whileInUse) {
        _status = LocationPermissionStatus.granted;
      } else {
        _status = LocationPermissionStatus.denied;
      }
      return _status;
    } catch (_) {
      _status = LocationPermissionStatus.denied;
      return _status;
    }
  }

  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      return true;
    }
  }
}

