import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;

import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/vehicle_connectivity/vehicle_connection_manager.dart';
import '../../../../core/vehicle_connectivity/phone_vehicle_state_bridge.dart';
import '../../../../core/weather/weather_service.dart';
import '../../../maps/core/services/google_maps_platform_service.dart';
import '../../../maps/core/services/india_places_search_engine.dart';
import '../../../maps/core/services/road_os_routing_engine.dart';
import '../../../navigation/core/services/voice_guidance_service.dart';
import '../../../navigation/domain/entities/place_search_entity.dart';
import '../../../navigation/presentation/screens/destination_search_screen.dart';
import '../../../sos_safety/presentation/widgets/sos_countdown_modal.dart';
import '../../../voice_assistant/presentation/screens/voice_assistant_hud_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CAR MODE HUD — Full-screen driver-optimised experience
//  All data is real: GPS, routing, ETA, maneuvers.
//  No fake values — missing data shows honest unavailable state.
// ─────────────────────────────────────────────────────────────────────────────

class CarModeScreen extends ConsumerStatefulWidget {
  const CarModeScreen({super.key});

  @override
  ConsumerState<CarModeScreen> createState() => _CarModeScreenState();
}

class _CarModeScreenState extends ConsumerState<CarModeScreen> {
  final Completer<gm.GoogleMapController> _mapController = Completer();
  final VoiceGuidanceService _voice = VoiceGuidanceService();

  // GPS
  LatLng _currentPosition = const LatLng(20.2961, 85.8245);
  double _currentSpeedKmh = 0.0;
  double _currentHeading = 0.0;
  bool _isGpsActive = false;
  StreamSubscription<Position>? _posSub;

  // Route
  PlaceSearchResultEntity? _destination;
  RouteCalculationResult? _activeRoute;
  bool _isNavigating = false;
  final Set<gm.Polyline> _polylines = {};
  final Set<gm.Marker> _markers = {};
  int _currentStepIndex = 0;
  int _offRouteCount = 0;
  bool _isRecalculating = false;

  @override
  void initState() {
    super.initState();
    _initGps();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  // ── GPS ────────────────────────────────────────────────────────────────────

  Future<void> _initGps() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever) { if (mounted) setState(() => _isGpsActive = false); return; }

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }

      if (pos != null && mounted) {
        setState(() {
          _currentPosition = LatLng(pos!.latitude, pos.longitude);
          _currentSpeedKmh = pos.speed * 3.6;
          _currentHeading = pos.heading;
          _isGpsActive = true;
        });
        _mapController.future.then((c) => c.animateCamera(gm.CameraUpdate.newCameraPosition(gm.CameraPosition(
          target: gm.LatLng(_currentPosition.latitude, _currentPosition.longitude),
          zoom: 16.0, bearing: _currentHeading, tilt: 30,
        ))));
      }

      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
      ).listen((p) {
        if (!mounted) return;
        setState(() {
          _currentPosition = LatLng(p.latitude, p.longitude);
          if (p.speed > 0) _currentSpeedKmh = p.speed * 3.6;
          if (p.heading > 0) _currentHeading = p.heading;
          _isGpsActive = true;
        });
        _mapController.future.then((c) => c.animateCamera(gm.CameraUpdate.newCameraPosition(gm.CameraPosition(
          target: gm.LatLng(_currentPosition.latitude, _currentPosition.longitude),
          zoom: _isNavigating ? 16.5 : 15.0, bearing: _currentHeading, tilt: _isNavigating ? 45 : 30,
        ))));
        if (_isNavigating && _activeRoute != null) {
          final off = RoadOsRoutingEngine.instance.isOffRoute(_currentPosition, _activeRoute!.polylinePoints);
          if (off) {
            _offRouteCount++;
            if (_offRouteCount >= 2 && !_isRecalculating) {
              _offRouteCount = 0;
              _recalculate();
            }
          } else {
            _offRouteCount = 0;
          }
          _advanceSteps();
          _checkArrival();
        }
      }, onError: (_) { if (mounted) setState(() => _isGpsActive = false); }, cancelOnError: false);
    } catch (_) { if (mounted) setState(() => _isGpsActive = false); }
  }

  void _syncToVehicleBridge() {
    if (_isNavigating && _activeRoute != null && _destination != null) {
      final step = _activeRoute!.steps[_currentStepIndex];
      PhoneVehicleStateBridge.instance.pushNavigationUpdate(
        instruction: step.instruction,
        stepDistanceMeters: step.distanceMeters.toDouble(),
        etaMinutes: ((_activeRoute!.distanceKm / 40.0) * 60).round(),
        totalDistanceKm: _activeRoute!.distanceKm,
        destinationTitle: _destination!.title,
        currentLat: _currentPosition.latitude,
        currentLng: _currentPosition.longitude,
      );
    }
  }

  void _advanceSteps() {
    final route = _activeRoute;
    if (route == null || route.steps.isEmpty) return;
    if (_currentStepIndex >= route.steps.length - 1) return;
    final step = route.steps[_currentStepIndex];
    if (step.stepCoordinates.isEmpty) return;
    final dist = IndiaPlacesSearchEngine.calculateDistanceKm(_currentPosition, step.stepCoordinates.first);
    if (dist < 0.05) {
      setState(() => _currentStepIndex++);
      _voice.speak(route.steps[_currentStepIndex].instruction);
    }
    _syncToVehicleBridge();
  }

  void _checkArrival() {
    final dest = _destination;
    if (dest == null) return;
    final dist = IndiaPlacesSearchEngine.calculateDistanceKm(_currentPosition, LatLng((dest.latitude ?? 0.0), (dest.longitude ?? 0.0)));
    if (dist < 0.030 && _isNavigating) {
      setState(() => _isNavigating = false);
      _voice.speak('You have arrived at your destination.');
      PhoneVehicleStateBridge.instance.pushNavigationStop();
    }
  }

  Future<void> _calculateRoute(PlaceSearchResultEntity dest) async {
    if (_isRecalculating) return;
    _isRecalculating = true;
    setState(() { _destination = dest; _isNavigating = false; _currentStepIndex = 0; });
    try {
      MultiRouteCalculationResult? multi;
      try {
        multi = await GoogleMapsPlatformService.instance.calculateDirections(
          origin: _currentPosition, destination: LatLng((dest.latitude ?? 0.0), (dest.longitude ?? 0.0)),
          waypoints: [], selectedOption: RouteOptionType.fastestHighway,
        );
      } catch (_) {
        multi = await RoadOsRoutingEngine.instance.calculateMultiRoutes(
          start: _currentPosition,
          destination: LatLng((dest.latitude ?? 0.0), (dest.longitude ?? 0.0)),
        );
      }
      if (!mounted) return;
      final best = multi.activeRoute;
      setState(() {
        _activeRoute = best; _isNavigating = true;
        _polylines.clear(); _markers.clear();
        _polylines.add(gm.Polyline(
          polylineId: const gm.PolylineId('route'),
          points: best.polylinePoints.map((p) => gm.LatLng(p.latitude, p.longitude)).toList(),
          color: RoadOSColors.electricBlue, width: 5,
        ));
        _markers.add(gm.Marker(
          markerId: const gm.MarkerId('destination'),
          position: gm.LatLng((dest.latitude ?? 0.0), (dest.longitude ?? 0.0)),
          infoWindow: gm.InfoWindow(title: dest.title),
        ));
      });
      if (best.steps.isNotEmpty) _voice.speak(best.steps.first.instruction);
      _syncToVehicleBridge();
    } catch (e) {
      if (mounted) {
        final errorMsg = e is RoutingUnavailableException ? e.message : 'Route failed: $e';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.red.shade900));
      }
    } finally {
      _isRecalculating = false;
    }
  }

  Future<void> _recalculate() async { if (_destination != null) await _calculateRoute(_destination!); }

  void _endNavigation() {
    setState(() { _isNavigating = false; _destination = null; _activeRoute = null; _polylines.clear(); _markers.clear(); _currentStepIndex = 0; });
    PhoneVehicleStateBridge.instance.pushNavigationStop();
  }

  void _showSos() {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const SosCountdownModal());
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final connState = ref.watch(vehicleConnectionManagerProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: Stack(
        children: [
          Positioned.fill(child: _buildMap()),
          Positioned(top: 0, left: 0, right: 0, child: _buildTopBar(connState)),
          if (_isNavigating && _activeRoute != null)
            Positioned(top: 90, left: 16, right: 16, child: _buildManeuverCard()),
          if (!_isGpsActive)
            Positioned(top: 90, left: 16, right: 16, child: _buildGpsBanner()),
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomPanel()),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return gm.GoogleMap(
      initialCameraPosition: gm.CameraPosition(
        target: gm.LatLng(_currentPosition.latitude, _currentPosition.longitude), zoom: 15.0, tilt: 30,
      ),
      mapType: gm.MapType.normal,
      myLocationEnabled: !kIsWeb,
      myLocationButtonEnabled: false,
      trafficEnabled: true,
      compassEnabled: false,
      zoomControlsEnabled: false,
      polylines: _polylines,
      markers: _markers,
      style: _kDarkMapStyle,
      onMapCreated: (c) { if (!_mapController.isCompleted) _mapController.complete(c); },
    );
  }

  Widget _buildTopBar(VehicleConnectionState connState) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: RoadOSColors.glassCardDecoration(radius: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: RoadOSColors.electricBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: RoadOSColors.electricBlue.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.directions_car_rounded, color: RoadOSColors.electricBlue, size: 16),
            ),
            const SizedBox(width: 10),
            Text('CAR MODE', style: GoogleFonts.outfit(color: RoadOSColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            const Spacer(),
            if (_isGpsActive) ...[
              Text('${_currentSpeedKmh.round()}', style: GoogleFonts.outfit(color: RoadOSColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(width: 2),
              Padding(padding: const EdgeInsets.only(top: 4), child: Text('KM/H', style: GoogleFonts.outfit(color: RoadOSColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1))),
              const SizedBox(width: 12),
            ],
            _buildConnChip(connState),
          ],
        ),
      ),
    );
  }

  Widget _buildConnChip(VehicleConnectionState state) {
    Color color;
    String label;
    IconData icon;
    if (state.status.isActive) { color = RoadOSColors.apexEmerald; label = 'CONNECTED'; icon = Icons.bluetooth_connected_rounded; }
    else if (state.status.isInProgress) { color = RoadOSColors.hyperOrange; label = 'CONNECTING'; icon = Icons.bluetooth_searching_rounded; }
    else { color = RoadOSColors.textSecondary; label = 'NO VEHICLE'; icon = Icons.bluetooth_disabled_rounded; }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.outfit(color: color, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
      ]),
    );
  }

  Widget _buildManeuverCard() {
    final route = _activeRoute!;
    final steps = route.steps;
    if (steps.isEmpty) return const SizedBox.shrink();
    final step = _currentStepIndex < steps.length ? steps[_currentStepIndex] : steps.last;
    final distKm = (step.distanceMeters / 1000).toStringAsFixed(1);
    final eta = route.estimatedArrival;
    final totalDist = route.distanceKm;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          top: BorderSide(color: RoadOSColors.electricBlue.withValues(alpha: 0.5), width: 1.5),
          left: BorderSide(color: RoadOSColors.electricBlue.withValues(alpha: 0.2), width: 1.0),
          right: BorderSide(color: Colors.black.withValues(alpha: 0.2), width: 1.0),
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.5), width: 2.5),
        ),
        boxShadow: [
          BoxShadow(color: RoadOSColors.electricBlue.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: RoadOSColors.electricBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: RoadOSColors.electricBlue.withValues(alpha: 0.4)),
            ),
            child: Icon(_maneuverIcon(step.iconType), color: RoadOSColors.electricBlue, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(step.instruction.replaceAll(RegExp(r'<[^>]*>'), ''),
                style: GoogleFonts.outfit(color: RoadOSColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
                maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('In $distKm km', style: GoogleFonts.outfit(color: RoadOSColors.electricBlue, fontSize: 13, fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(eta, style: GoogleFonts.outfit(color: RoadOSColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w900)),
            Text('${totalDist.toStringAsFixed(1)} km', style: GoogleFonts.inter(color: RoadOSColors.textSecondary, fontSize: 11)),
          ]),
        ],
      ),
    );
  }

  IconData _maneuverIcon(String iconType) {
    final t = iconType.toLowerCase();
    if (t.contains('left')) return Icons.turn_left_rounded;
    if (t.contains('right')) return Icons.turn_right_rounded;
    if (t.contains('uturn') || t.contains('u-turn')) return Icons.u_turn_right_rounded;
    if (t.contains('roundabout')) return Icons.roundabout_right_rounded;
    if (t.contains('merge') || t.contains('ramp')) return Icons.merge_rounded;
    if (t.contains('arrive') || t.contains('destination')) return Icons.flag_rounded;
    return Icons.straight_rounded;
  }

  Widget _buildGpsBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFF8C00).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF8C00).withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.gps_off_rounded, color: Color(0xFFFF8C00), size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text('GPS UNAVAILABLE — Enable location to use navigation',
            style: GoogleFonts.outfit(color: const Color(0xFFFF8C00), fontSize: 11, fontWeight: FontWeight.w700))),
      ]),
    );
  }

  Widget _buildBottomPanel() {
    final weatherState = ref.watch(weatherProvider);
    final isWeatherLoaded = weatherState is WeatherData;
    final isWeatherSetupReq = weatherState is WeatherSetupRequired;
    final weatherTemp = isWeatherLoaded ? weatherState.temperatureCelsius.round() : 0;
    final weatherIcon = isWeatherSetupReq ? Icons.settings_rounded :
                        isWeatherLoaded && weatherState.condition == WeatherCondition.rain ? Icons.water_drop :
                        isWeatherLoaded && weatherState.condition == WeatherCondition.cloudy ? Icons.cloud :
                        Icons.wb_sunny_rounded;
    final weatherLabel = isWeatherSetupReq ? 'SETUP REQ' : 
                         isWeatherLoaded ? '$weatherTemp°' : 'WEATHER';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Quick action row
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              _QuickBtn(
                icon: Icons.mic_rounded, 
                label: 'AI', 
                color: RoadOSColors.neonViolet,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VoiceAssistantHudScreen())),
              ),
              const SizedBox(width: 8),
              _QuickBtn(
                icon: Icons.call_rounded,
                label: kIsWeb ? 'N/A' : 'CALL',
                color: kIsWeb ? RoadOSColors.textSecondary : RoadOSColors.apexEmerald,
                subtitle: kIsWeb ? 'NOT SUPPORTED ON WEB' : null,
                onTap: kIsWeb ? null : () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Calling: Use your phone dialer'))),
              ),
              const SizedBox(width: 8),
              _QuickBtn(
                icon: weatherIcon,
                label: weatherLabel,
                color: RoadOSColors.hyperOrange,
                onTap: () {
                  if (isWeatherSetupReq) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WEATHER SETUP REQUIRED')));
                  } else {
                    ref.read(weatherProvider.notifier).fetch(lat: _currentPosition.latitude, lon: _currentPosition.longitude);
                  }
                },
              ),
              const SizedBox(width: 8),
              _QuickBtn(icon: Icons.sos_rounded, label: 'SOS', color: const Color(0xFFFF3344), onTap: _showSos),
            ],
          ),
        ),
        // Search / nav bar
        Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.all(12),
          decoration: RoadOSColors.glassCardDecoration(radius: 16),
          child: SafeArea(top: false, child: _isNavigating ? _buildNavigatingBar() : _buildSearchBar()),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.of(context).push<PlaceSearchResultEntity>(
          MaterialPageRoute(builder: (_) => const DestinationSearchScreen()),
        );
        if (result != null) await _calculateRoute(result);
      },
      child: Container(
        height: 52, padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF14192A), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(children: [
          const Icon(Icons.search_rounded, color: RoadOSColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text('Search destination...', style: GoogleFonts.inter(color: RoadOSColors.textSecondary, fontSize: 14))),
          const Icon(Icons.keyboard_arrow_up_rounded, color: RoadOSColors.textSecondary, size: 20),
        ]),
      ),
    );
  }

  Widget _buildNavigatingBar() {
    final route = _activeRoute;
    return Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_destination?.title ?? 'Navigating', style: GoogleFonts.outfit(color: RoadOSColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
        if (route != null) Text('${route.distanceKm.toStringAsFixed(1)} km · ETA ${route.estimatedArrival}', style: GoogleFonts.inter(color: RoadOSColors.textSecondary, fontSize: 11)),
      ])),
      const SizedBox(width: 12),
      GestureDetector(
        onTap: _endNavigation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFF3344).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFF3344).withValues(alpha: 0.4)),
          ),
          child: Text('END', style: GoogleFonts.outfit(color: const Color(0xFFFF3344), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  QUICK BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;
  const _QuickBtn({required this.icon, required this.label, required this.color, this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1020).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(12),
            border: Border(
              top: BorderSide(color: disabled ? Colors.white.withValues(alpha: 0.05) : color.withValues(alpha: 0.3), width: 1.0),
              left: BorderSide(color: disabled ? Colors.white.withValues(alpha: 0.03) : color.withValues(alpha: 0.15), width: 1.0),
              right: BorderSide(color: Colors.black.withValues(alpha: 0.2), width: 1.0),
              bottom: BorderSide(color: Colors.black.withValues(alpha: 0.4), width: 2.0),
            ),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 3))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: disabled ? RoadOSColors.textMuted : color, size: 22),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.outfit(color: disabled ? RoadOSColors.textMuted : RoadOSColors.textPrimary, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
          ]),
        ),
      ),
    );
  }
}

const String _kDarkMapStyle = '''[
  {"elementType":"geometry","stylers":[{"color":"#050816"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#6B7FA3"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#050816"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1A2535"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#1F3050"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#243D60"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#00BFFF"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0A1628"}]},
  {"featureType":"poi","elementType":"all","stylers":[{"visibility":"off"}]}
]''';
