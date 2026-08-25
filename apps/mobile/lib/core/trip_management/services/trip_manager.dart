import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../location/services/vehicle_location_manager.dart';
import '../../bluetooth/bluetooth_engine.dart';
import '../models/trip_state.dart';
import '../models/trip_model.dart';
import '../../utils/constants.dart';

final tripLifecycleProvider = StateNotifierProvider<TripLifecycleNotifier, TripLifecycleState>((ref) {
  return TripLifecycleNotifier();
});

class TripLifecycleNotifier extends StateNotifier<TripLifecycleState> {
  TripLifecycleNotifier() : super(TripLifecycleState.idle);

  void updateState(TripLifecycleState newState) {
    state = newState;
  }
}

class TripManager {
  static final TripManager _instance = TripManager._internal();
  factory TripManager() => _instance;
  TripManager._internal();

  final _tripStateController = StreamController<TripLifecycleState>.broadcast();
  Stream<TripLifecycleState> get tripStateStream => _tripStateController.stream;

  final _activeTripController = StreamController<TripRecord?>.broadcast();
  Stream<TripRecord?> get activeTripStream => _activeTripController.stream;

  TripLifecycleState _currentState = TripLifecycleState.idle;
  TripLifecycleState get currentState => _currentState;

  TripRecord? _currentTrip;
  TripRecord? get currentTrip => _currentTrip;

  Timer? _durationTimer;
  StreamSubscription<VehicleLocationData>? _locationSubscription;
  StreamSubscription? _telemetrySubscription;

  TripPointModel? _lastRecordedPoint;
  DateTime? _lastPointTimestamp;
  WidgetRef? _ref;

  void initialize(WidgetRef ref) {
    _ref = ref;
    VehicleLocationManager().initialize();
  }

  /// Starts recording a real ride
  Future<TripRecord> startRide({
    required String vehicleId,
    required String vehicleName,
    String? title,
  }) async {
    final tripId = 'trip_${DateTime.now().millisecondsSinceEpoch}';
    final initialLoc = VehicleLocationManager().currentLocation;

    final initialPoint = initialLoc.isAvailable
        ? TripPointModel(
            lat: initialLoc.latitude,
            lng: initialLoc.longitude,
            altitude: initialLoc.altitude,
            speedKmh: initialLoc.speedKmh,
            accuracyMeters: initialLoc.accuracyMeters,
            timestamp: DateTime.now(),
          )
        : null;

    _currentTrip = TripRecord(
      tripId: tripId,
      vehicleId: vehicleId,
      vehicleName: vehicleName,
      title: title ?? 'Motorcycle Ride',
      startTime: DateTime.now(),
      distanceKm: 0.0,
      durationSeconds: 0,
      avgSpeedKmh: 0.0,
      maxSpeedKmh: initialLoc.speedKmh ?? 0.0,
      points: initialPoint != null ? [initialPoint] : [],
      events: [
        TripEventModel(
          eventType: 'TRIP_STARTED',
          timestamp: DateTime.now(),
          description: 'Live trip recording initiated',
          lat: initialPoint?.lat,
          lng: initialPoint?.lng,
        ),
      ],
      gpsSource: initialLoc.source.label,
      telemetrySource: 'BLUETOOTH_BLE',
      isSynced: false,
    );

    _lastRecordedPoint = initialPoint;
    _lastPointTimestamp = DateTime.now();
    _setState(TripLifecycleState.active);

    _startTrackingSubscriptions();
    _startDurationTimer();

    return _currentTrip!;
  }

  void pauseRide() {
    if (_currentState == TripLifecycleState.active) {
      _setState(TripLifecycleState.paused);
      _durationTimer?.cancel();
      _addEvent('TRIP_PAUSED', 'Rider paused trip');
    }
  }

  void resumeRide() {
    if (_currentState == TripLifecycleState.paused) {
      _setState(TripLifecycleState.resumed);
      _startDurationTimer();
      _addEvent('TRIP_RESUMED', 'Rider resumed trip');
    }
  }

  Future<TripRecord?> stopRide() async {
    if (_currentTrip == null) return null;

    _durationTimer?.cancel();
    _locationSubscription?.cancel();
    _telemetrySubscription?.cancel();

    _addEvent('TRIP_COMPLETED', 'Ride completed successfully');

    final completedTrip = _currentTrip!.copyWith(
      endTime: DateTime.now(),
      isSynced: false,
    );

    _currentTrip = completedTrip;
    _setState(TripLifecycleState.completed);

    // Persist locally
    await _saveTripLocally(completedTrip);

    // Trigger async sync to backend
    unawaited(syncPendingTrips());

    final finalTrip = _currentTrip;
    _currentTrip = null;
    _lastRecordedPoint = null;
    _setState(TripLifecycleState.idle);

    return finalTrip;
  }

  void _startTrackingSubscriptions() {
    _locationSubscription?.cancel();
    _locationSubscription = VehicleLocationManager().locationStream.listen((loc) {
      if (!_currentState.isRecording || !loc.isAvailable) return;

      // Filter out low accuracy jitter (>35m)
      if (loc.accuracyMeters != null && loc.accuracyMeters! > 35.0) return;

      final now = DateTime.now();
      final newPoint = TripPointModel(
        lat: loc.latitude,
        lng: loc.longitude,
        altitude: loc.altitude,
        speedKmh: loc.speedKmh,
        accuracyMeters: loc.accuracyMeters,
        timestamp: now,
      );

      if (_lastRecordedPoint == null) {
        _recordPoint(newPoint);
        return;
      }

      final distMeters = _calculateDistanceMeters(
        _lastRecordedPoint!.lat,
        _lastRecordedPoint!.lng,
        newPoint.lat,
        newPoint.lng,
      );

      final timeDiffSec = _lastPointTimestamp != null ? now.difference(_lastPointTimestamp!).inSeconds : 0;

      // Spatial and temporal sampling (Record if moved > 6m or every 8s)
      if (distMeters >= 6.0 || timeDiffSec >= 8) {
        _recordPoint(newPoint, incrementalDistanceMeters: distMeters);
      }
    });

    _telemetrySubscription?.cancel();
    _telemetrySubscription = BluetoothEngine().telemetryStream.listen((telemetry) {
      if (!_currentState.isRecording || _currentTrip == null) return;

      // If live vehicle speed is higher than current maxSpeed
      if (telemetry.speed.available && (telemetry.speed.value ?? 0) > _currentTrip!.maxSpeedKmh) {
        _currentTrip = _currentTrip!.copyWith(maxSpeedKmh: telemetry.speed.value!);
        _activeTripController.add(_currentTrip);
      }
    });
  }

  void _recordPoint(TripPointModel pt, {double incrementalDistanceMeters = 0.0}) {
    if (_currentTrip == null) return;

    final updatedPoints = List<TripPointModel>.from(_currentTrip!.points)..add(pt);
    final newDistKm = _currentTrip!.distanceKm + (incrementalDistanceMeters / 1000.0);

    double newMaxSpeed = _currentTrip!.maxSpeedKmh;
    if (pt.speedKmh != null && pt.speedKmh! > newMaxSpeed) {
      newMaxSpeed = pt.speedKmh!;
    }

    double avgSpeed = 0.0;
    if (_currentTrip!.durationSeconds > 0) {
      avgSpeed = (newDistKm / (_currentTrip!.durationSeconds / 3600.0));
    }

    _currentTrip = _currentTrip!.copyWith(
      distanceKm: double.parse(newDistKm.toStringAsFixed(2)),
      points: updatedPoints,
      maxSpeedKmh: double.parse(newMaxSpeed.toStringAsFixed(1)),
      avgSpeedKmh: double.parse(avgSpeed.toStringAsFixed(1)),
    );

    _lastRecordedPoint = pt;
    _lastPointTimestamp = pt.timestamp;
    _activeTripController.add(_currentTrip);
  }

  void _addEvent(String eventType, String description) {
    if (_currentTrip == null) return;
    final event = TripEventModel(
      eventType: eventType,
      timestamp: DateTime.now(),
      description: description,
      lat: _lastRecordedPoint?.lat,
      lng: _lastRecordedPoint?.lng,
    );
    final updatedEvents = List<TripEventModel>.from(_currentTrip!.events)..add(event);
    _currentTrip = _currentTrip!.copyWith(events: updatedEvents);
    _activeTripController.add(_currentTrip);
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentTrip != null && _currentState.isRecording) {
        final newDuration = _currentTrip!.durationSeconds + 1;
        double avgSpeed = _currentTrip!.avgSpeedKmh;
        if (newDuration > 0 && _currentTrip!.distanceKm > 0) {
          avgSpeed = double.parse((_currentTrip!.distanceKm / (newDuration / 3600.0)).toStringAsFixed(1));
        }

        _currentTrip = _currentTrip!.copyWith(
          durationSeconds: newDuration,
          avgSpeedKmh: avgSpeed,
        );
        _activeTripController.add(_currentTrip);
      }
    });
  }

  void _setState(TripLifecycleState state) {
    _currentState = state;
    _tripStateController.add(state);
    _ref?.read(tripLifecycleProvider.notifier).updateState(state);
  }

  double _calculateDistanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742000 * math.asin(math.sqrt(a));
  }

  Future<void> _saveTripLocally(TripRecord trip) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tripsJson = prefs.getStringList('local_trip_history') ?? [];
      tripsJson.insert(0, jsonEncode(trip.toJson()));
      await prefs.setStringList('local_trip_history', tripsJson);
    } catch (e) {
      debugPrint('[TripManager] Local storage save error: $e');
    }
  }

  Future<List<TripRecord>> getLocalTrips() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tripsJson = prefs.getStringList('local_trip_history') ?? [];
      return tripsJson.map((str) => TripRecord.fromJson(jsonDecode(str) as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> syncPendingTrips() async {
    try {
      final trips = await getLocalTrips();
      final pending = trips.where((t) => !t.isSynced).toList();

      for (final trip in pending) {
        try {
          final response = await http.post(
            Uri.parse('${ApiConstants.baseUrl}/trips'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(trip.toJson()),
          );
          if (response.statusCode == 200 || response.statusCode == 201) {
            debugPrint('[TripManager] Synced trip ${trip.tripId} with backend.');
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[TripManager] Pending sync notice: $e');
    }
  }
}
