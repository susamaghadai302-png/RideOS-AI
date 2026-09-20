import 'dart:async';

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/platform_web_helper.dart';

import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../maps/core/services/google_maps_platform_service.dart';
import '../../../maps/core/services/india_places_search_engine.dart';
import '../../../maps/core/services/road_os_routing_engine.dart';
import '../../../maps/core/services/saved_places_manager.dart';
import '../../../maps/domain/entities/poi_entity.dart';
import '../../../sos_safety/presentation/widgets/sos_countdown_modal.dart';
import '../../core/services/voice_guidance_service.dart';
import '../../domain/entities/place_search_entity.dart';
import 'destination_search_screen.dart';
import '../../../../core/design_system/premium_navigation.dart';

enum MapTileTheme {
  darkHud('Dark Cyber HUD', 'High-contrast dark mode with glowing roads'),
  satellite('Satellite HD', 'Esri high-resolution photographic imagery'),
  street('Street & Buildings', 'Detailed street footprints & landmarks'),
  terrain('Topographic Terrain', 'Elevation contours and mountain passes'),
  transit('Public Transit & Rail', 'Railway & urban transport corridors');

  final String label;
  final String description;
  const MapTileTheme(this.label, this.description);
}

class ThreeDNavigationScreen extends StatefulWidget {
  final PlaceSearchResultEntity? preselectedDestination;

  const ThreeDNavigationScreen({super.key, this.preselectedDestination});

  @override
  State<ThreeDNavigationScreen> createState() => _ThreeDNavigationScreenState();
}

class _ThreeDNavigationScreenState extends State<ThreeDNavigationScreen> with TickerProviderStateMixin {
  final Completer<gm.GoogleMapController> _mapController = Completer<gm.GoogleMapController>();
  final VoiceGuidanceService _voiceService = VoiceGuidanceService();

  // Location & Vehicle Marker State (Default anchor: Odisha / India)
  LatLng _currentPosition = const LatLng(20.2961, 85.8245);
  double _vehicleHeading = 42.0;
  double _currentSpeedKmh = 58.0;
  double _gpsAccuracyMeters = 2.8;
  bool _isGpsSignalStrong = true;
  StreamSubscription<Position>? _positionSubscription;
  bool _isFollowingVehicle = true;
  double _currentZoom = 15.5;

  // Active Destination & Multi-Route State
  PlaceSearchResultEntity? _activeDestination;
  final List<PlaceSearchResultEntity> _intermediateWaypoints = [];
  MultiRouteCalculationResult? _multiRouteResult;
  RouteCalculationResult? _activeRoute;
  RouteOptionType _selectedRouteOption = RouteOptionType.fastestHighway;

  bool _isNavigating = false;
  // _isRidePaused is reserved for future ride-pause feature
  bool _isRidePaused = false;
  int _secondsElapsed = 0;
  Timer? _rideTimer;

  // Live Navigation Metrics
  double _activeRouteDistanceKm = 12.4;
  int _activeRouteDurationMin = 18;
  String _activeRouteEta = '18:45';
  List<RouteStepManeuver> _activeRouteSteps = [];
  int _currentStepIndex = 0;
  int _offRoutePingsCount = 0;

  // Pin Drop & Area Search State
  bool _isPinDropMode = false;
  LatLng? _manualDroppedPin;
  bool _showSearchThisArea = false;

  // Map Tile Theme & Traffic (Defaults to Dark Cyber HUD)
  MapTileTheme _selectedTileTheme = MapTileTheme.darkHud;
  bool _isTrafficEnabled = true;

  // Markers & Polylines
  final Set<gm.Marker> _poiMarkers = {};
  final List<LatLng> _routePoints = [];
  NearbyCategory? _activeNearbyCategory;
  PoiEntity? _selectedPoiDetail;
  List<SavedPlaceEntity> _savedPlaces = [];

  @override
  void initState() {
    super.initState();
    _activeDestination = widget.preselectedDestination;
    _initLocationTracking();
    _loadSavedPlaces();
    if (_activeDestination != null) {
      _calculateAndDrawRoute(_activeDestination!);
    }
  }

  Future<void> _loadSavedPlaces() async {
    final places = await SavedPlacesManager.instance.getSavedPlaces();
    if (mounted) {
      setState(() => _savedPlaces = places);
    }
  }

  Future<void> _initLocationTracking() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position? initialPos = await Geolocator.getLastKnownPosition();
      initialPos ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 4),
      );

      final pos = initialPos;
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(pos.latitude, pos.longitude);
          _vehicleHeading = pos.heading > 0 ? pos.heading : 45.0;
          _currentSpeedKmh = math.max(24.0, pos.speed * 3.6);
          _gpsAccuracyMeters = pos.accuracy;
          _isGpsSignalStrong = pos.accuracy < 15.0;
        });
        _mapController.future.then((c) {
          c.animateCamera(gm.CameraUpdate.newLatLngZoom(
            gm.LatLng(_currentPosition.latitude, _currentPosition.longitude),
            _currentZoom,
          ));
        });
      }
    } catch (_) {}

    // Subscribe to live GPS stream safely with error boundary
    try {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
      );
      _positionSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        (pos) {
          if (!mounted) return;
          setState(() {
            _currentPosition = LatLng(pos.latitude, pos.longitude);
            if (pos.heading > 0) _vehicleHeading = pos.heading;
            if (pos.speed > 0) _currentSpeedKmh = pos.speed * 3.6;
            _gpsAccuracyMeters = pos.accuracy;
            _isGpsSignalStrong = pos.accuracy < 15.0;
          });

          if (_isFollowingVehicle) {
            _mapController.future.then((c) {
              c.animateCamera(gm.CameraUpdate.newLatLng(
                gm.LatLng(_currentPosition.latitude, _currentPosition.longitude),
              ));
            });
          }

          // Off-Route Check during active navigation
          if (_isNavigating && _routePoints.isNotEmpty && _activeDestination != null) {
            final isOff = RoadOsRoutingEngine.instance.isOffRoute(_currentPosition, _routePoints, thresholdMeters: 45.0);
            if (isOff) {
              _offRoutePingsCount++;
              if (_offRoutePingsCount >= 2) {
                _offRoutePingsCount = 0;
                _handleAutoReroute();
              }
            } else {
              _offRoutePingsCount = 0;
            }

            // Arrival Check (<30 meters from destination)
            final distToDest = IndiaPlacesSearchEngine.calculateDistanceKm(
              _currentPosition,
              LatLng((_activeDestination!.latitude ?? 0.0), (_activeDestination!.longitude ?? 0.0)),
            );
            if (distToDest < 0.035 && _isNavigating) {
              _endTrip(isArrival: true);
            }
          }
        },
        onError: (err) {
          debugPrint('[GPS Stream Notice]: $err');
          if (mounted) {
            setState(() {
              _isGpsSignalStrong = false;
            });
          }
        },
        cancelOnError: false,
      );
    } catch (_) {}
  }

  /// Calculates primary route and all available alternative routes via Google Directions API
  Future<void> _calculateAndDrawRoute(PlaceSearchResultEntity destination) async {
    _activeDestination = destination;
    final start = _currentPosition;
    final end = LatLng(destination.latitude ?? 0.0, destination.longitude ?? 0.0);

    final multiResult = await GoogleMapsPlatformService.instance.calculateDirections(
      origin: start,
      destination: end,
      waypoints: _intermediateWaypoints.map((w) => LatLng(w.latitude ?? 0.0, w.longitude ?? 0.0)).toList(),
      selectedOption: _selectedRouteOption,
    );

    if (mounted) {
      setState(() {
        _multiRouteResult = multiResult;
        _activeRoute = multiResult.activeRoute;
        _routePoints.clear();
        _routePoints.addAll(multiResult.activeRoute.polylinePoints);
        _manualDroppedPin = null;
        _isPinDropMode = false;
        _activeRouteSteps = multiResult.activeRoute.steps;
        _activeRouteDistanceKm = multiResult.activeRoute.distanceKm;
        _activeRouteDurationMin = multiResult.activeRoute.durationMinutes;
        _activeRouteEta = multiResult.activeRoute.estimatedArrival;
        _currentStepIndex = 0;
      });

      _fitBounds(start, end);
    }
  }

  /// Switches active route to a selected alternative route
  void _selectAlternativeRoute(RouteCalculationResult route) {
    LuxAudioHapticsService.selectionClick();
    setState(() {
      _activeRoute = route;
      _selectedRouteOption = route.routeType;
      _routePoints.clear();
      _routePoints.addAll(route.polylinePoints);
      _activeRouteSteps = route.steps;
      _activeRouteDistanceKm = route.distanceKm;
      _activeRouteDurationMin = route.durationMinutes;
      _activeRouteEta = route.estimatedArrival;
      _currentStepIndex = 0;
    });

    showLuxSnack(context, '⚡ Switched to ${route.routeName} (${route.distanceKm} km | ${route.durationMinutes} min)', variant: LuxSnackVariant.info);
  }

  /// Automated instant reroute when rider deviates from corridor
  Future<void> _handleAutoReroute() async {
    _voiceService.speak(_voiceService.getRerouteMessage());
    showLuxSnack(context, '🔄 Off route detected. Recalculating path...', variant: LuxSnackVariant.info);

    if (_activeDestination != null) {
      await _calculateAndDrawRoute(_activeDestination!);
    }
  }

  void _addStopWaypoint() async {
    LuxAudioHapticsService.selectionClick();
    final selected = await Navigator.push<PlaceSearchResultEntity>(
      context,
      premiumRoute(const DestinationSearchScreen()),
    );
    if (selected != null) {
      setState(() {
        _intermediateWaypoints.add(selected);
      });
      if (_activeDestination != null) {
        _calculateAndDrawRoute(_activeDestination!);
      }
    }
  }

  void _removeStopWaypoint(int index) {
    LuxAudioHapticsService.lightImpact();
    setState(() {
      _intermediateWaypoints.removeAt(index);
    });
    if (_activeDestination != null) {
      _calculateAndDrawRoute(_activeDestination!);
    }
  }

  void _fitBounds(LatLng p1, LatLng p2) {
    final lat1 = p1.latitude;
    final lat2 = p2.latitude;
    final lng1 = p1.longitude;
    final lng2 = p2.longitude;

    final bounds = gm.LatLngBounds(
      southwest: gm.LatLng(math.min(lat1, lat2), math.min(lng1, lng2)),
      northeast: gm.LatLng(math.max(lat1, lat2), math.max(lng1, lng2)),
    );

    _mapController.future.then((c) {
      c.animateCamera(gm.CameraUpdate.newLatLngBounds(bounds, 50.0));
    });
  }

  String? get _activeMapStyle {
    switch (_selectedTileTheme) {
      case MapTileTheme.darkHud:
        return _darkMapStyle;
      default:
        return null;
    }
  }

  static const String _darkMapStyle = '''[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#070B14"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#8ec3b9"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#1a3646"}]
  },
  {
    "featureType": "administrative.country",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#4b6878"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#162331"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#213645"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#9ca5b3"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#203a4c"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#294d62"}]
  }
]''';

  void _cycleTileTheme() {
    LuxAudioHapticsService.selectionClick();
    setState(() {
      final nextIndex = (_selectedTileTheme.index + 1) % MapTileTheme.values.length;
      _selectedTileTheme = MapTileTheme.values[nextIndex];
    });

    showLuxSnack(context, '🗺️ Layer: ${_selectedTileTheme.label} Activated', variant: LuxSnackVariant.info);
  }

  void _toggleTraffic() {
    LuxAudioHapticsService.selectionClick();
    setState(() => _isTrafficEnabled = !_isTrafficEnabled);
    showLuxSnack(context, _isTrafficEnabled ? 'Live Road Traffic: ACTIVE' : 'Live Road Traffic: OFF', variant: LuxSnackVariant.info);
  }

  void _togglePinDropMode() {
    LuxAudioHapticsService.heavyImpact();
    setState(() {
      _isPinDropMode = !_isPinDropMode;
      if (_isPinDropMode) {
        _manualDroppedPin = _currentPosition;
      }
    });
    showLuxSnack(context, _isPinDropMode ? 'Pin Drop Mode: Tap anywhere on map to drop destination' : 'Pin Drop Mode: OFF', variant: LuxSnackVariant.info);
  }

  void _shareCurrentLocation() {
    LuxAudioHapticsService.selectionClick();
    final text = '📍 Live GPS Location: [${_currentPosition.latitude.toStringAsFixed(4)}, ${_currentPosition.longitude.toStringAsFixed(4)}]';
    showLuxSnack(context, text, variant: LuxSnackVariant.info);
  }

  void _resetCompassNorth() {
    LuxAudioHapticsService.selectionClick();
    _mapController.future.then((c) {
      c.animateCamera(gm.CameraUpdate.newCameraPosition(
        gm.CameraPosition(target: gm.LatLng(_currentPosition.latitude, _currentPosition.longitude), zoom: _currentZoom, bearing: 0)
      ));
    });
    showLuxSnack(context, '🧭 Compass reset to True North (0 deg)', variant: LuxSnackVariant.info);
  }

  void _zoomIn() {
    LuxAudioHapticsService.lightImpact();
    setState(() => _currentZoom = math.min(20.0, _currentZoom + 1.0));
    _mapController.future.then((c) => c.animateCamera(gm.CameraUpdate.zoomIn()));
  }

  void _zoomOut() {
    LuxAudioHapticsService.lightImpact();
    setState(() => _currentZoom = math.max(3.0, _currentZoom - 1.0));
    _mapController.future.then((c) => c.animateCamera(gm.CameraUpdate.zoomOut()));
  }

  void _recenterToUser() {
    LuxAudioHapticsService.heavyImpact();
    setState(() {
      _isFollowingVehicle = true;
      _showSearchThisArea = false;
      _currentZoom = 16.0;
    });
    _mapController.future.then((c) {
      c.animateCamera(gm.CameraUpdate.newLatLngZoom(
        gm.LatLng(_currentPosition.latitude, _currentPosition.longitude), _currentZoom
      ));
    });
  }

  void _handleSearchThisArea() async {
    LuxAudioHapticsService.heavyImpact();
    setState(() => _showSearchThisArea = false);

    final controller = await _mapController.future;
    final bounds = await controller.getVisibleRegion();
    final pois = await IndiaPlacesSearchEngine.instance.searchInBoundingBox(
      southLat: bounds.southwest.latitude,
      westLng: bounds.southwest.longitude,
      northLat: bounds.northeast.latitude,
      eastLng: bounds.northeast.longitude,
      query: _activeNearbyCategory?.label ?? 'attraction',
    );

    final Set<gm.Marker> newMarkers = {};
    for (final p in pois) {
      newMarkers.add(
        gm.Marker(
          markerId: gm.MarkerId('search_poi_${p.id}'),
          position: gm.LatLng(p.latitude ?? 0.0, p.longitude ?? 0.0),
          icon: gm.BitmapDescriptor.defaultMarkerWithHue(gm.BitmapDescriptor.hueOrange),
          onTap: () {
            LuxAudioHapticsService.selectionClick();
            setState(() {
              _selectedPoiDetail = PoiEntity(
                id: p.id,
                category: p.category,
                title: p.title,
                address: p.subtitle,
                lat: p.latitude ?? 0.0,
                lng: p.longitude ?? 0.0,
                rating: p.rating ?? 4.8,
                distanceKm: p.distanceKm,
              );
            });
          },
        ),
      );
    }

    setState(() {
      _poiMarkers.clear();
      _poiMarkers.addAll(newMarkers);
    });

    if (mounted) {
      showLuxSnack(context, '🔍 Found ${pois.length} places in this area!', variant: LuxSnackVariant.info);
    }
  }

  void _selectNearbyCategory(NearbyCategory cat) async {
    LuxAudioHapticsService.selectionClick();
    setState(() {
      _activeNearbyCategory = cat;
      _selectedPoiDetail = null;
    });

    final pois = await GoogleMapsPlatformService.instance.searchNearbyPlaces(
      location: _currentPosition,
      category: cat,
    );

    final Set<gm.Marker> newMarkers = {};
    for (final poi in pois) {
      newMarkers.add(
        gm.Marker(
          markerId: gm.MarkerId('nearby_poi_${poi.id}'),
          position: gm.LatLng(poi.lat, poi.lng),
          icon: gm.BitmapDescriptor.defaultMarkerWithHue(
            cat == NearbyCategory.petrolPumps ? gm.BitmapDescriptor.hueOrange : gm.BitmapDescriptor.hueCyan
          ),
          onTap: () {
            LuxAudioHapticsService.selectionClick();
            setState(() => _selectedPoiDetail = poi);
          },
        ),
      );
    }

    setState(() {
      _poiMarkers.clear();
      _poiMarkers.addAll(newMarkers);
    });
  }

  void _startNavigation() {
    if (_activeDestination == null) return;
    LuxAudioHapticsService.heavyImpact();
    setState(() {
      _isNavigating = true;
      _isFollowingVehicle = true;
      _currentZoom = 17.5;
      _secondsElapsed = 0;
      _currentStepIndex = 0;
    });

    _mapController.future.then((c) {
      c.animateCamera(gm.CameraUpdate.newCameraPosition(
        gm.CameraPosition(
          target: gm.LatLng(_currentPosition.latitude, _currentPosition.longitude),
          zoom: _currentZoom,
          bearing: _vehicleHeading,
          tilt: 45.0,
        )
      ));
    });
    _voiceService.speakGuidance(
      _activeRouteSteps.isNotEmpty ? _activeRouteSteps[0].instruction : 'Starting navigation to ${_activeDestination!.title}',
    );

    _rideTimer?.cancel();
    _rideTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isRidePaused && mounted) {
        setState(() => _secondsElapsed++);
      }
    });
  }

  Future<void> _endTrip({bool isArrival = false}) async {
    LuxAudioHapticsService.heavyImpact();
    _rideTimer?.cancel();
    final mins = math.max(1, (_secondsElapsed / 60).ceil());
    final dist = _activeRouteDistanceKm;

    // Persist completed trip to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingHistory = prefs.getStringList('trip_history_logs') ?? [];
      final tripRecord = jsonEncode({
        'title': _activeDestination?.title ?? 'Custom Route Ride',
        'date': 'Just now',
        'distance': '$dist km',
        'duration': '$mins min',
        'avgSpeed': '${_currentSpeedKmh.round()} km/h',
        'maxLean': 'UNAVAILABLE',
        'score': 'UNAVAILABLE',
        'lat': _activeDestination?.latitude ?? 20.2961,
        'lng': _activeDestination?.longitude ?? 85.8245,
      });
      existingHistory.insert(0, tripRecord);
      await prefs.setStringList('trip_history_logs', existingHistory);
    } catch (_) {}

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0C101D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(isArrival ? Icons.flag_rounded : Icons.check_circle_rounded, color: RoadOSColors.apexEmerald, size: 24),
            const SizedBox(width: 8),
            Text(isArrival ? 'DESTINATION ARRIVED' : 'TRIP COMPLETED', style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Destination: ${_activeDestination?.title ?? "Arrival Point"}', style: const TextStyle(color: RoadOSColors.cyberCyan, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTripStat('DISTANCE', '$dist km'),
                _buildTripStat('RIDE TIME', '$mins min'),
                _buildTripStat('AVG SPEED', '${_currentSpeedKmh.round()} km/h'),
              ],
            ),
            const SizedBox(height: 12),
            const Text('✅ Saved to Trip History with 1-Tap Repeat Route', style: TextStyle(color: RoadOSColors.apexEmerald, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: RoadOSColors.cyberCyan, foregroundColor: Colors.black),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _isNavigating = false;
                _activeDestination = null;
                _routePoints.clear();
                _poiMarkers.clear();
              });
            },
            child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTripStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: RoadOSColors.platinumWhite, fontSize: 14, fontWeight: FontWeight.w900)),
      ],
    );
  }

  void _showLanguageSelector() {
    LuxAudioHapticsService.selectionClick();
    showLuxSheet(
                context: context,
                title: '',
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('VOICE GUIDANCE LANGUAGE', style: TextStyle(color: RoadOSColors.cyberCyan, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 16),
            ...NavigationLanguage.values.map((lang) => ListTile(
                  leading: Text(lang.flag, style: const TextStyle(fontSize: 22)),
                  title: Text(lang.label, style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold)),
                  trailing: _voiceService.currentLanguage == lang ? const Icon(Icons.check_rounded, color: RoadOSColors.cyberCyan) : null,
                  onTap: () {
                    setState(() => _voiceService.setLanguage(lang));
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _rideTimer?.cancel();
    _mapController.future.then((c) => c.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allMarkers = <gm.Marker>{
      // 1. Live Rider Vehicle Marker
      gm.Marker(
        markerId: const gm.MarkerId('vehicle'),
        position: gm.LatLng(_currentPosition.latitude, _currentPosition.longitude),
        rotation: _vehicleHeading,
        icon: gm.BitmapDescriptor.defaultMarkerWithHue(gm.BitmapDescriptor.hueCyan),
        anchor: const Offset(0.5, 0.5),
        zIndexInt: 100,
      ),

      // 2. Intermediate Waypoint Stops Markers
      ..._intermediateWaypoints.asMap().entries.map((entry) {
        final wp = entry.value;
        return gm.Marker(
          markerId: gm.MarkerId('wp_${entry.key}'),
          position: gm.LatLng((wp.latitude ?? 0.0), (wp.longitude ?? 0.0)),
          icon: gm.BitmapDescriptor.defaultMarkerWithHue(gm.BitmapDescriptor.hueOrange),
        );
      }),

      // 3. Destination Pin Marker
      if (_activeDestination != null)
        gm.Marker(
          markerId: const gm.MarkerId('destination'),
          position: gm.LatLng((_activeDestination!.latitude ?? 0.0), (_activeDestination!.longitude ?? 0.0)),
          icon: gm.BitmapDescriptor.defaultMarkerWithHue(gm.BitmapDescriptor.hueRed),
          zIndexInt: 90,
        ),

      // 4. Manual Dropped Pin Marker
      if (_manualDroppedPin != null)
        gm.Marker(
          markerId: const gm.MarkerId('dropped_pin'),
          position: gm.LatLng(_manualDroppedPin!.latitude, _manualDroppedPin!.longitude),
          icon: gm.BitmapDescriptor.defaultMarkerWithHue(gm.BitmapDescriptor.hueYellow),
        ),

      // 5. Dynamic Nearby POI Markers
      ..._poiMarkers,
    };

    Set<gm.Polyline> allPolylines = {};

    if (_multiRouteResult != null && _multiRouteResult!.alternativeRoutes.isNotEmpty) {
      for (int i = 0; i < _multiRouteResult!.alternativeRoutes.length; i++) {
        final alt = _multiRouteResult!.alternativeRoutes[i];
        allPolylines.add(gm.Polyline(
          polylineId: gm.PolylineId('alt_$i'),
          points: alt.polylinePoints.map((p) => gm.LatLng(p.latitude, p.longitude)).toList(),
          color: const Color(0x99546E7A),
          width: 6,
          zIndex: 1,
        ));
      }
    }

    if (_routePoints.isNotEmpty) {
      allPolylines.add(gm.Polyline(
        polylineId: const gm.PolylineId('active_route_glow'),
        points: _routePoints.map((p) => gm.LatLng(p.latitude, p.longitude)).toList(),
        color: _selectedRouteOption.accentColor.withValues(alpha: 0.4),
        width: 11,
        zIndex: 2,
      ));
      allPolylines.add(gm.Polyline(
        polylineId: const gm.PolylineId('active_route_core'),
        points: _routePoints.map((p) => gm.LatLng(p.latitude, p.longitude)).toList(),
        color: _selectedRouteOption.accentColor,
        width: 6,
        zIndex: 3,
      ));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Stack(
        children: [
          // 1. Map: Google Maps (Native and Web)
          gm.GoogleMap(
              mapType: _selectedTileTheme == MapTileTheme.satellite ? gm.MapType.satellite : gm.MapType.normal,
              style: _activeMapStyle,
              initialCameraPosition: gm.CameraPosition(
                target: gm.LatLng(_currentPosition.latitude, _currentPosition.longitude),
                zoom: _currentZoom,
              ),
              onMapCreated: (gm.GoogleMapController controller) {
                if (!_mapController.isCompleted) {
                  _mapController.complete(controller);
                }
              },
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              compassEnabled: true,
              trafficEnabled: _isTrafficEnabled,
              buildingsEnabled: true,
              onCameraMoveStarted: () {
                if (_isFollowingVehicle) {
                  setState(() {
                    _isFollowingVehicle = false;
                    _showSearchThisArea = true;
                  });
                }
              },
              onTap: (point) async {
                if (_isPinDropMode) {
                  LuxAudioHapticsService.heavyImpact();
                  setState(() => _manualDroppedPin = LatLng(point.latitude, point.longitude));
                  final pinPlace = await GoogleMapsPlatformService.instance.reverseGeocode(LatLng(point.latitude, point.longitude));
                  if (mounted) {
                    _calculateAndDrawRoute(pinPlace);
                  }
                }
              },
              markers: allMarkers,
              polylines: allPolylines,
            ),

          // 2. Top Header HUD / Search Bar Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _isNavigating ? _buildActiveTurnByTurnHud() : _buildTopSearchCard(),
                  const SizedBox(height: 6),
                  // GPS Status & SOS Emergency Action Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isGpsSignalStrong ? RoadOSColors.apexEmerald : RoadOSColors.warningAmber,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isGpsSignalStrong ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
                              color: _isGpsSignalStrong ? RoadOSColors.apexEmerald : RoadOSColors.warningAmber,
                              size: 12,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isGpsSignalStrong
                                  ? 'GPS (+/-${_gpsAccuracyMeters.toStringAsFixed(1)}m)'
                                  : 'WEAK GPS SIGNAL',
                              style: TextStyle(
                                color: _isGpsSignalStrong ? RoadOSColors.apexEmerald : RoadOSColors.warningAmber,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          LuxAudioHapticsService.heavyImpact();
                          showDialog(
                            context: context,
                            builder: (_) => const SosCountdownModal(),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: RoadOSColors.errorCrimson.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.redAccent, width: 1.2),
                            boxShadow: [
                              BoxShadow(color: Colors.red.withValues(alpha: 0.4), blurRadius: 8),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.emergency_rounded, color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'SOS',
                                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 3. Floating "Search This Area" Pill (When Map is panned)
          if (_showSearchThisArea)
            Positioned(
              top: 105,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _handleSearchThisArea,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C101D),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: RoadOSColors.cyberCyan, width: 1.5),
                      boxShadow: [
                        BoxShadow(color: RoadOSColors.cyberCyan.withValues(alpha: 0.4), blurRadius: 14),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_rounded, color: RoadOSColors.cyberCyan, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'SEARCH THIS AREA',
                          style: TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.8),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 4. Floating Quick Action Controls (Right-Hand Stack)
          Positioned(
            right: 16,
            bottom: _isNavigating ? 180 : 210,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFloatingButton(
                  icon: Icons.explore_rounded,
                  tooltip: 'Reset Compass North',
                  onTap: _resetCompassNorth,
                ),
                const SizedBox(height: 10),
                _buildFloatingButton(
                  icon: Icons.layers_rounded,
                  tooltip: 'Map Tile Switcher',
                  onTap: _cycleTileTheme,
                ),
                const SizedBox(height: 10),
                _buildFloatingButton(
                  icon: Icons.traffic_rounded,
                  tooltip: 'Toggle Live Traffic',
                  color: _isTrafficEnabled ? RoadOSColors.apexEmerald : Colors.white70,
                  onTap: _toggleTraffic,
                ),
                const SizedBox(height: 10),
                _buildFloatingButton(
                  icon: Icons.pin_drop_rounded,
                  tooltip: 'Drop Pin Mode',
                  color: _isPinDropMode ? RoadOSColors.hyperOrange : Colors.white,
                  onTap: _togglePinDropMode,
                ),
                const SizedBox(height: 10),
                _buildFloatingButton(
                  icon: Icons.share_location_rounded,
                  tooltip: 'Share Live Location',
                  onTap: _shareCurrentLocation,
                ),
                const SizedBox(height: 10),
                _buildFloatingButton(
                  icon: Icons.translate_rounded,
                  tooltip: 'Voice Language',
                  onTap: _showLanguageSelector,
                ),
                const SizedBox(height: 10),
                _buildFloatingButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Zoom In',
                  onTap: _zoomIn,
                ),
                const SizedBox(height: 10),
                _buildFloatingButton(
                  icon: Icons.remove_rounded,
                  tooltip: 'Zoom Out',
                  onTap: _zoomOut,
                ),
                const SizedBox(height: 10),
                _buildFloatingButton(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Recenter to Vehicle',
                  color: _isFollowingVehicle ? RoadOSColors.cyberCyan : Colors.white,
                  onTap: _recenterToUser,
                ),
              ],
            ),
          ),

          // 5. Bottom Navigation / Discovery Drawer
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _isNavigating ? _buildActiveRideControlsCard() : _buildDiscoveryAndNearbyDrawer(),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color color = RoadOSColors.platinumWhite,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF0C101D).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  Widget _buildTopSearchCard() {
    return RoadOSCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: RoadOSColors.platinumWhite, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final selected = await Navigator.push<PlaceSearchResultEntity>(
                  context,
                  premiumRoute(const DestinationSearchScreen()),
                );
                if (selected != null) {
                  _calculateAndDrawRoute(selected);
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _activeDestination?.title ?? 'Where do you want to ride in India / Odisha?',
                    style: TextStyle(
                      color: _activeDestination != null ? RoadOSColors.cyberCyan : RoadOSColors.platinumWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _activeDestination?.subtitle ?? 'Search address, station, airport, hospital...',
                    style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded, color: RoadOSColors.cyberCyan, size: 22),
            onPressed: () async {
              final selected = await Navigator.push<PlaceSearchResultEntity>(
                context,
                premiumRoute(const DestinationSearchScreen()),
              );
              if (selected != null) {
                _calculateAndDrawRoute(selected);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTurnByTurnHud() {
    final activeStep = _activeRouteSteps.isNotEmpty && _currentStepIndex < _activeRouteSteps.length
        ? _activeRouteSteps[_currentStepIndex]
        : null;

    final instruction = activeStep?.instruction ?? 'Proceed to ${_activeDestination?.title ?? "Destination"}';
    final roadName = activeStep?.roadName ?? (_activeDestination?.title ?? 'Main Highway / City Corridor');
    final distM = activeStep != null ? 'IN ${activeStep.distanceMeters.round()} METERS' : 'IN 350 METERS';

    return RoadOSCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              gradient: LuxGradients.quantumCyan,
              shape: BoxShape.circle,
            ),
            child: Icon(
              activeStep?.iconType == 'left'
                  ? Icons.turn_left_rounded
                  : activeStep?.iconType == 'right'
                      ? Icons.turn_right_rounded
                      : activeStep?.iconType == 'arrive'
                          ? Icons.flag_rounded
                          : Icons.straight_rounded,
              color: Colors.black,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        distM,
                        style: const TextStyle(
                          color: RoadOSColors.cyberCyan,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 1.0,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: RoadOSColors.warningAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: RoadOSColors.warningAmber.withValues(alpha: 0.4)),
                      ),
                      child: const Text(
                        'LIMIT 60 KM/H',
                        style: TextStyle(
                          color: RoadOSColors.warningAmber,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  instruction,
                  style: const TextStyle(
                    color: RoadOSColors.platinumWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  roadName,
                  style: const TextStyle(
                    color: RoadOSColors.textMuted,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _voiceService.isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: _voiceService.isMuted ? RoadOSColors.errorCrimson : RoadOSColors.cyberCyan,
            ),
            onPressed: () {
              setState(() => _voiceService.toggleMute());
              if (!_voiceService.isMuted) {
                _voiceService.speakGuidance(instruction);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryAndNearbyDrawer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xEE090D18),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.white12, width: 1.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 10),

          // 13 Nearby Places Horizontal Filter Bar
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: NearbyCategory.values.map((cat) {
                final isSelected = _activeNearbyCategory == cat;
                return GestureDetector(
                  onTap: () => _selectNearbyCategory(cat),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? RoadOSColors.cyberCyan.withValues(alpha: 0.25) : Colors.black45,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? RoadOSColors.cyberCyan : Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cat.emoji, style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          cat.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? RoadOSColors.cyberCyan : RoadOSColors.platinumWhite,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Saved Places Bar
          if (_savedPlaces.isNotEmpty && _activeDestination == null)
            SizedBox(
              height: 30,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: _savedPlaces.map((sp) {
                  return GestureDetector(
                    onTap: () {
                      LuxAudioHapticsService.lightImpact();
                      _calculateAndDrawRoute(
                        PlaceSearchResultEntity(
                          id: sp.id,
                          title: sp.title,
                          subtitle: sp.address,
                          category: sp.type.name.toUpperCase(),
                          latitude: sp.latitude,
                          longitude: sp.longitude,
                          distanceKm: 4.5,
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141C2E),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(sp.type.emoji, style: const TextStyle(fontSize: 11)),
                          const SizedBox(width: 4),
                          Text(
                            sp.title.split(' (')[0],
                            style: const TextStyle(fontSize: 10, color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 8),

          // Rich Selected Place Sheet (with Call, Website, Save, Share, Route)
          if (_selectedPoiDetail != null) ...[
            RoadOSCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(_selectedPoiDetail!.title, style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(width: 6),
                                const Icon(Icons.verified_rounded, color: RoadOSColors.cyberCyan, size: 14),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(_selectedPoiDetail!.address, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: RoadOSColors.apexEmerald.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '★ ${_selectedPoiDetail!.rating?.toStringAsFixed(1) ?? "4.8"} (${_selectedPoiDetail!.reviewCount})',
                          style: const TextStyle(color: RoadOSColors.apexEmerald, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedPoiDetail!.distanceKm} km | ~${_selectedPoiDetail!.etaMinutes} mins ride',
                        style: const TextStyle(color: RoadOSColors.hyperOrange, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.phone_rounded, color: RoadOSColors.platinumWhite, size: 18),
                            tooltip: 'Call Phone',
                            onPressed: () {
                              PlatformWebHelper.openUrl('tel:${_selectedPoiDetail!.phoneNumber}');
                              showLuxSnack(context, 'Calling ${_selectedPoiDetail!.phoneNumber}...', variant: LuxSnackVariant.info);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.language_rounded, color: RoadOSColors.platinumWhite, size: 18),
                            tooltip: 'Visit Website',
                            onPressed: () {
                              PlatformWebHelper.openUrl(_selectedPoiDetail!.websiteUrl);
                              showLuxSnack(context, 'Opening ${_selectedPoiDetail!.websiteUrl}...', variant: LuxSnackVariant.info);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.bookmark_border_rounded, color: RoadOSColors.cyberCyan, size: 18),
                            tooltip: 'Save to Favorites',
                            onPressed: () async {
                              await SavedPlacesManager.instance.savePlace(
                                SavedPlaceEntity(
                                  id: _selectedPoiDetail!.id,
                                  title: _selectedPoiDetail!.title,
                                  address: _selectedPoiDetail!.address,
                                  latitude: _selectedPoiDetail!.lat,
                                  longitude: _selectedPoiDetail!.lng,
                                  type: SavedPlaceType.favorite,
                                  savedAt: DateTime.now(),
                                ),
                              );
                              _loadSavedPlaces();
                              if (mounted) {
                                showLuxSnack(context, '⭐ Saved ${_selectedPoiDetail!.title} to Favorite Places!', variant: LuxSnackVariant.info);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.share_rounded, color: RoadOSColors.platinumWhite, size: 18),
                            tooltip: 'Share Place',
                            onPressed: () {
                              showLuxSnack(context, '📍 Copied link for ${_selectedPoiDetail!.title}!', variant: LuxSnackVariant.info);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: RoadOSColors.hyperOrange, foregroundColor: Colors.black),
                      icon: const Icon(Icons.navigation_rounded, size: 16),
                      label: const Text('ROUTE TO PLACE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () {
                        _calculateAndDrawRoute(
                          PlaceSearchResultEntity(
                            id: _selectedPoiDetail!.id,
                            title: _selectedPoiDetail!.title,
                            subtitle: _selectedPoiDetail!.address,
                            category: _selectedPoiDetail!.category,
                            latitude: _selectedPoiDetail!.lat,
                            longitude: _selectedPoiDetail!.lng,
                            distanceKm: _selectedPoiDetail!.distanceKm,
                            tags: const ['poi'],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Multi-Route Options & Start Navigation Action
          if (_activeDestination != null) ...[
            // Alternative Route Cards (Fastest vs Alternatives)
            if (_multiRouteResult != null && _multiRouteResult!.allRoutes.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _multiRouteResult!.allRoutes.map((route) {
                    final isSelected = _activeRoute?.id == route.id;
                    return GestureDetector(
                      onTap: () => _selectAlternativeRoute(route),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? route.routeColor.withValues(alpha: 0.25) : Colors.black45,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? route.routeColor : Colors.white12, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              route.routeName,
                              style: TextStyle(
                                color: isSelected ? route.routeColor : RoadOSColors.platinumWhite,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${route.distanceKm} km | ${route.durationMinutes} min (${route.estimatedArrival})',
                              style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 9.5),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 12),

            // Waypoints Chips & "+ Add Stop"
            if (_intermediateWaypoints.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    ..._intermediateWaypoints.asMap().entries.map((e) {
                      return Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: RoadOSColors.warningAmber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: RoadOSColors.warningAmber),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Stop ${e.key + 1}: ${e.value.title.split(' ')[0]}', style: const TextStyle(fontSize: 10, color: Colors.white)),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _removeStopWaypoint(e.key),
                              child: const Icon(Icons.close_rounded, size: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_activeRouteDistanceKm.toStringAsFixed(1)} KM | $_activeRouteDurationMin MIN (ETA $_activeRouteEta)',
                        style: const TextStyle(color: RoadOSColors.platinumWhite, fontSize: 15, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_selectedRouteOption.title} | Live Road Corridor',
                        style: TextStyle(color: _selectedRouteOption.accentColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add_location_alt_rounded, color: RoadOSColors.warningAmber, size: 16),
                  label: const Text('Add Stop', style: TextStyle(color: RoadOSColors.warningAmber, fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: _addStopWaypoint,
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RoadOSColors.cyberCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.navigation_rounded, size: 18),
                  label: const Text('START RIDE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  onPressed: _startNavigation,
                ),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('READY TO NAVIGATE', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  icon: const Icon(Icons.search_rounded, color: RoadOSColors.cyberCyan, size: 16),
                  label: const Text('Search Destination', style: TextStyle(color: RoadOSColors.cyberCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    final selected = await Navigator.push<PlaceSearchResultEntity>(
                      context,
                      premiumRoute(const DestinationSearchScreen()),
                    );
                    if (selected != null) {
                      _calculateAndDrawRoute(selected);
                    }
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveRideControlsCard() {
    final mins = (_secondsElapsed / 60).floor();
    final secs = _secondsElapsed % 60;
    final timeStr = '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xEE090D18),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.white12, width: 1.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_currentSpeedKmh KM/H',
                    style: const TextStyle(color: RoadOSColors.cyberCyan, fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  Text(
                    'DURATION: $timeStr',
                    style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _isRidePaused ? Icons.play_circle_filled_rounded : Icons.pause_circle_filled_rounded,
                  color: _isRidePaused ? RoadOSColors.hyperOrange : RoadOSColors.cyberCyan,
                  size: 32,
                ),
                tooltip: _isRidePaused ? 'Resume Ride' : 'Pause Ride',
                onPressed: () {
                  LuxAudioHapticsService.selectionClick();
                  setState(() => _isRidePaused = !_isRidePaused);
                  showLuxSnack(context, _isRidePaused ? '⏸️ Navigation Paused' : '▶️ Navigation Resumed', variant: LuxSnackVariant.info);
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: RoadOSColors.errorCrimson,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.stop_rounded, size: 18),
                label: const Text('END', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: () => _endTrip(isArrival: false),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
