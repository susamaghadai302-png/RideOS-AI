import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/map_provider.dart';
import '../domain/models/navigation_models.dart';
import 'astar_routing_engine.dart';

class TurnByTurnNavigationEngine {
  static final TurnByTurnNavigationEngine _instance = TurnByTurnNavigationEngine._internal();
  factory TurnByTurnNavigationEngine() => _instance;

  final _routingEngine = AStarRoutingEngine();

  NavigationSessionState _state = NavigationSessionState.idle;
  NavigationSessionState get state => _state;

  final _stateController = StreamController<NavigationSessionState>.broadcast();
  Stream<NavigationSessionState> get stateStream => _stateController.stream;

  CameraMode _cameraMode = CameraMode.followLocation;
  CameraMode get cameraMode => _cameraMode;

  RouteResult? _activeRoute;
  RouteResult? get activeRoute => _activeRoute;

  List<AlternativeRoute> _availableAlternatives = [];
  List<AlternativeRoute> get availableAlternatives => List.unmodifiable(_availableAlternatives);

  int _currentSegmentIndex = 0;
  int get currentSegmentIndex => _currentSegmentIndex;

  double _remainingDistanceKm = 0.0;
  double get remainingDistanceKm => _remainingDistanceKm;

  double _remainingDurationMinutes = 0.0;
  double get remainingDurationMinutes => _remainingDurationMinutes;

  double _distanceToNextManeuverMeters = 0.0;
  double get distanceToNextManeuverMeters => _distanceToNextManeuverMeters;

  String _currentInstruction = 'Prepare to ride';
  String get currentInstruction => _currentInstruction;

  final String _nextStreetName = '';
  String get nextStreetName => _nextStreetName;

  IconData _currentManeuverIcon = Icons.navigation_rounded;
  IconData get currentManeuverIcon => _currentManeuverIcon;

  LatLng? _currentGpsPosition;
  LatLng? get currentGpsPosition => _currentGpsPosition;

  double _currentHeadingDeg = 0.0;
  double get currentHeadingDeg => _currentHeadingDeg;

  double _currentSpeedKmh = 0.0;
  double get currentSpeedKmh => _currentSpeedKmh;

  int _offRouteSampleCount = 0;

  TurnByTurnNavigationEngine._internal();

  /// Starts route preview toward a target destination
  Future<void> selectDestination({
    required LatLng origin,
    required LatLng destination,
    RoutePreference preference = RoutePreference.fastest,
  }) async {
    _transitionTo(NavigationSessionState.destinationSelected);
    _currentGpsPosition = origin;

    _availableAlternatives = await _routingEngine.calculateRoutes(
      origin: origin,
      destination: destination,
      preference: preference,
    );

    if (_availableAlternatives.isNotEmpty) {
      _activeRoute = _availableAlternatives.first.routeResult;
      _remainingDistanceKm = _activeRoute!.totalDistanceKm;
      _remainingDurationMinutes = _activeRoute!.estimatedDurationMinutes;
      _transitionTo(NavigationSessionState.routePreview);
    }
  }

  /// Engages live turn-by-turn navigation
  void startNavigation({AlternativeRoute? selectedAlternative}) {
    if (selectedAlternative != null) {
      _activeRoute = selectedAlternative.routeResult;
    }
    if (_activeRoute == null) return;

    _currentSegmentIndex = 0;
    _remainingDistanceKm = _activeRoute!.totalDistanceKm;
    _remainingDurationMinutes = _activeRoute!.estimatedDurationMinutes;
    _cameraMode = CameraMode.navigation3D;
    _offRouteSampleCount = 0;

    _updateCurrentInstruction();
    _transitionTo(NavigationSessionState.navigating);
  }

  /// Cancels active navigation session
  void cancelNavigation() {
    _transitionTo(NavigationSessionState.cancelled);
    _activeRoute = null;
    _availableAlternatives = [];
    _cameraMode = CameraMode.followLocation;
    _currentSegmentIndex = 0;
    _transitionTo(NavigationSessionState.idle);
  }

  /// Updates current GPS position and checks off-route / arrival thresholds
  void updateGpsLocation({
    required LatLng position,
    required double speedKmh,
    required double headingDeg,
  }) {
    _currentGpsPosition = position;
    _currentSpeedKmh = speedKmh;
    _currentHeadingDeg = headingDeg;

    if (_state != NavigationSessionState.navigating || _activeRoute == null) return;

    // 1. Check Arrival at Destination (within 25 meters of destination)
    final distanceToDestMeters = _distanceBetweenMeters(position, _activeRoute!.waypoints.last);
    if (distanceToDestMeters < 25.0) {
      _currentInstruction = 'You have arrived at your destination';
      _currentManeuverIcon = Icons.flag_rounded;
      _remainingDistanceKm = 0.0;
      _remainingDurationMinutes = 0.0;
      _transitionTo(NavigationSessionState.arrived);
      return;
    }

    // 2. Evaluate closest point on active route
    final minDistanceToRouteMeters = _calculateDistanceToRoute(position, _activeRoute!.waypoints);

    // 3. Off-Route Detection (Threshold: > 35m for 3 consecutive samples)
    if (minDistanceToRouteMeters > 35.0) {
      _offRouteSampleCount++;
      if (_offRouteSampleCount >= 3 && _state != NavigationSessionState.offRoute) {
        _handleOffRoute(position);
      }
    } else {
      _offRouteSampleCount = 0;
      _progressAlongRoute(position);
    }
  }

  void setCameraMode(CameraMode mode) {
    _cameraMode = mode;
  }

  Future<void> _handleOffRoute(LatLng currentPos) async {
    _transitionTo(NavigationSessionState.offRoute);
    _currentInstruction = 'Off route — Recalculating directions...';
    _currentManeuverIcon = Icons.sync_rounded;

    await Future.delayed(const Duration(milliseconds: 600));
    _transitionTo(NavigationSessionState.rerouting);

    if (_activeRoute != null) {
      final destination = _activeRoute!.waypoints.last;
      _availableAlternatives = await _routingEngine.calculateRoutes(
        origin: currentPos,
        destination: destination,
      );

      if (_availableAlternatives.isNotEmpty) {
        _activeRoute = _availableAlternatives.first.routeResult;
        _currentSegmentIndex = 0;
        _remainingDistanceKm = _activeRoute!.totalDistanceKm;
        _remainingDurationMinutes = _activeRoute!.estimatedDurationMinutes;
        _offRouteSampleCount = 0;
        _updateCurrentInstruction();
        _transitionTo(NavigationSessionState.navigating);
      }
    }
  }

  void _progressAlongRoute(LatLng currentPos) {
    if (_activeRoute == null || _activeRoute!.segments.isEmpty) return;

    if (_currentSegmentIndex < _activeRoute!.segments.length) {
      final segment = _activeRoute!.segments[_currentSegmentIndex];
      _distanceToNextManeuverMeters = _distanceBetweenMeters(currentPos, segment.endPoint);

      // Advance to next segment if within 15 meters of junction waypoint
      if (_distanceToNextManeuverMeters < 15.0 && _currentSegmentIndex < _activeRoute!.segments.length - 1) {
        _currentSegmentIndex++;
        _updateCurrentInstruction();
      }
    }
  }

  void _updateCurrentInstruction() {
    if (_activeRoute != null && _currentSegmentIndex < _activeRoute!.segments.length) {
      final segment = _activeRoute!.segments[_currentSegmentIndex];
      _currentInstruction = segment.instruction;
      _distanceToNextManeuverMeters = segment.distanceMeters;

      if (_currentInstruction.toLowerCase().contains('turn left')) {
        _currentManeuverIcon = Icons.turn_left_rounded;
      } else if (_currentInstruction.toLowerCase().contains('turn right')) {
        _currentManeuverIcon = Icons.turn_right_rounded;
      } else if (_currentInstruction.toLowerCase().contains('destination') || _currentInstruction.toLowerCase().contains('approach')) {
        _currentManeuverIcon = Icons.place_rounded;
      } else {
        _currentManeuverIcon = Icons.straight_rounded;
      }
    }
  }

  void _transitionTo(NavigationSessionState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
  }

  double _calculateDistanceToRoute(LatLng pos, List<LatLng> waypoints) {
    double minDistance = double.infinity;
    for (final pt in waypoints) {
      final dist = _distanceBetweenMeters(pos, pt);
      if (dist < minDistance) minDistance = dist;
    }
    return minDistance;
  }

  double _distanceBetweenMeters(LatLng p1, LatLng p2) {
    const r = 6371000.0;
    final dLat = (p2.latitude - p1.latitude) * (math.pi / 180.0);
    final dLon = (p2.longitude - p1.longitude) * (math.pi / 180.0);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(p1.latitude * (math.pi / 180.0)) * math.cos(p2.latitude * (math.pi / 180.0)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }
}
