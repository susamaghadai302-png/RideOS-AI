import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../bluetooth/bluetooth_engine.dart';

enum VehicleLocationSource {
  vehicleGps('Vehicle GPS'),
  phoneGps('Phone GPS'),
  unavailable('Unavailable');

  final String label;
  const VehicleLocationSource(this.label);
}

enum LocationPermissionState {
  unknown,
  serviceDisabled,
  denied,
  deniedForever,
  granted;

  bool get isGranted => this == LocationPermissionState.granted;
}

class VehicleLocationData {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? speedKmh;
  final double? headingDegrees;
  final double? accuracyMeters;
  final VehicleLocationSource source;
  final bool isAvailable;
  final DateTime timestamp;

  const VehicleLocationData({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.speedKmh,
    this.headingDegrees,
    this.accuracyMeters,
    required this.source,
    this.isAvailable = true,
    required this.timestamp,
  });

  const VehicleLocationData.unavailable()
      : latitude = 0.0,
        longitude = 0.0,
        altitude = null,
        speedKmh = null,
        headingDegrees = null,
        accuracyMeters = null,
        source = VehicleLocationSource.unavailable,
        isAvailable = false,
        timestamp = const _StaticDateTime();

  String get accuracyLabel {
    if (!isAvailable || accuracyMeters == null) return 'GPS Unavailable';
    return '±${accuracyMeters!.toStringAsFixed(0)} m';
  }
}

class _StaticDateTime implements DateTime {
  const _StaticDateTime();
  @override
  dynamic noSuchMethod(Invocation invocation) => DateTime.now();
}

class VehicleLocationManager {
  static final VehicleLocationManager _instance = VehicleLocationManager._internal();
  factory VehicleLocationManager() => _instance;
  VehicleLocationManager._internal();

  final _locationStreamController = StreamController<VehicleLocationData>.broadcast();
  Stream<VehicleLocationData> get locationStream => _locationStreamController.stream;

  final _permissionStreamController = StreamController<LocationPermissionState>.broadcast();
  Stream<LocationPermissionState> get permissionStateStream => _permissionStreamController.stream;

  LocationPermissionState _currentPermissionState = LocationPermissionState.unknown;
  LocationPermissionState get currentPermissionState => _currentPermissionState;

  StreamSubscription<Position>? _phoneGpsSubscription;
  StreamSubscription? _telemetrySubscription;

  VehicleLocationData _currentLocation = const VehicleLocationData.unavailable();
  VehicleLocationData get currentLocation => _currentLocation;

  bool _isInitialized = false;

  void updateLocationForTesting(VehicleLocationData data) {
    _updateLocation(data);
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    _listenToVehicleTelemetry();
    await _startPhoneGpsTracking();
  }

  void _listenToVehicleTelemetry() {
    _telemetrySubscription?.cancel();
    _telemetrySubscription = BluetoothEngine().telemetryStream.listen((telemetry) {
      // If connected vehicle provides verified GPS coordinates string (format: "lat,lng")
      if (telemetry.gps.available && telemetry.gps.value != null && telemetry.gps.value!.contains(',')) {
        try {
          final parts = telemetry.gps.value!.split(',');
          if (parts.length >= 2) {
            final lat = double.tryParse(parts[0].trim());
            final lng = double.tryParse(parts[1].trim());

            if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
              final loc = VehicleLocationData(
                latitude: lat,
                longitude: lng,
                speedKmh: telemetry.speed.available ? telemetry.speed.value : null,
                headingDegrees: telemetry.heading.available ? telemetry.heading.value : null,
                accuracyMeters: 2.0, // High-precision vehicle GNSS antenna
                source: VehicleLocationSource.vehicleGps,
                isAvailable: true,
                timestamp: DateTime.now(),
              );
              _updateLocation(loc);
            }
          }
        } catch (_) {}
      }
    });
  }

  void _setPermissionState(LocationPermissionState pState) {
    _currentPermissionState = pState;
    _permissionStreamController.add(pState);
  }

  Future<void> _startPhoneGpsTracking() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationManager] Location services are disabled.');
        _setPermissionState(LocationPermissionState.serviceDisabled);
        _updateLocation(const VehicleLocationData.unavailable());
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setPermissionState(LocationPermissionState.denied);
          _updateLocation(const VehicleLocationData.unavailable());
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setPermissionState(LocationPermissionState.deniedForever);
        _updateLocation(const VehicleLocationData.unavailable());
        return;
      }

      _setPermissionState(LocationPermissionState.granted);

      // Initial position fetch
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null && _currentLocation.source != VehicleLocationSource.vehicleGps) {
        _updateLocation(_fromPosition(lastPos));
      }

      // Continuous high-precision GPS stream
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3, // Update every 3 meters
      );

      _phoneGpsSubscription?.cancel();
      _phoneGpsSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        (position) {
          // Only update from phone GPS if vehicle GPS is not currently active
          if (_currentLocation.source != VehicleLocationSource.vehicleGps) {
            _updateLocation(_fromPosition(position));
          }
        },
        onError: (err) {
          debugPrint('[LocationManager] GPS error: $err');
          if (_currentLocation.source != VehicleLocationSource.vehicleGps) {
            _updateLocation(const VehicleLocationData.unavailable());
          }
        },
      );
    } catch (e) {
      debugPrint('[LocationManager] Initialization error: $e');
    }
  }

  VehicleLocationData _fromPosition(Position pos) {
    return VehicleLocationData(
      latitude: pos.latitude,
      longitude: pos.longitude,
      altitude: pos.altitude,
      speedKmh: pos.speed > 0 ? pos.speed * 3.6 : 0.0,
      headingDegrees: pos.heading > 0 ? pos.heading : null,
      accuracyMeters: pos.accuracy,
      source: VehicleLocationSource.phoneGps,
      isAvailable: true,
      timestamp: pos.timestamp,
    );
  }

  void _updateLocation(VehicleLocationData data) {
    _currentLocation = data;
    _locationStreamController.add(data);
  }

  void dispose() {
    _phoneGpsSubscription?.cancel();
    _telemetrySubscription?.cancel();
  }
}
