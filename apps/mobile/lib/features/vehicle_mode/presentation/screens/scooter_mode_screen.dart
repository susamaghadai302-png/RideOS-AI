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
import '../../../../core/vehicle_resolution/models/vehicle_profile.dart';
import '../../../../core/vehicle_resolution/providers/active_vehicle_context_provider.dart';
import '../../../maps/core/services/google_maps_platform_service.dart';
import '../../../maps/core/services/india_places_search_engine.dart';
import '../../../maps/core/services/road_os_routing_engine.dart';
import '../../../navigation/core/services/voice_guidance_service.dart';
import '../../../navigation/domain/entities/place_search_entity.dart';
import '../../../navigation/presentation/screens/destination_search_screen.dart';
import '../../../sos_safety/presentation/widgets/sos_countdown_modal.dart';
import '../../../voice_assistant/presentation/screens/voice_assistant_hud_screen.dart';
import '../../../../core/weather/weather_service.dart';


// ─────────────────────────────────────────────────────────────────────────────
//  SCOOTER MODE HUD
//  Extends Bike Mode with:
//  • EV vs Petrol awareness from real VehicleProfile
//  • Charging / Fuel nearby shortcut
//  • Battery/range badge if electric
//  • Emerald green identity
// ─────────────────────────────────────────────────────────────────────────────

class ScooterModeScreen extends ConsumerStatefulWidget {
  const ScooterModeScreen({super.key});

  @override
  ConsumerState<ScooterModeScreen> createState() => _ScooterModeScreenState();
}

class _ScooterModeScreenState extends ConsumerState<ScooterModeScreen> {
  final Completer<gm.GoogleMapController> _mapController = Completer();
  final VoiceGuidanceService _voice = VoiceGuidanceService();

  LatLng _currentPosition = const LatLng(20.2961, 85.8245);
  double _currentSpeedKmh = 0.0;
  double _currentHeading = 0.0;
  bool _isGpsActive = false;
  StreamSubscription<Position>? _posSub;

  PlaceSearchResultEntity? _destination;
  RouteCalculationResult? _activeRoute;
  bool _isNavigating = false;
  final Set<gm.Polyline> _polylines = {};
  final Set<gm.Marker> _markers = {};
  int _currentStepIndex = 0;
  int _offRouteCount = 0;

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
          zoom: 16.0, tilt: 40,
        ))));
      }

      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 3),
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
          zoom: _isNavigating ? 17.0 : 16.0, bearing: _currentHeading, tilt: _isNavigating ? 55 : 40,
        ))));
        if (_isNavigating && _activeRoute != null) {
          final off = RoadOsRoutingEngine.instance.isOffRoute(_currentPosition, _activeRoute!.polylinePoints, thresholdMeters: 40);
          if (off) { _offRouteCount++; if (_offRouteCount >= 2) { _offRouteCount = 0; _recalculate(); } } else { _offRouteCount = 0; }
          _advanceSteps();
          _checkArrival();
        }
      }, onError: (_) { if (mounted) setState(() => _isGpsActive = false); }, cancelOnError: false);
    } catch (_) { if (mounted) setState(() => _isGpsActive = false); }
  }

  void _advanceSteps() {
    final route = _activeRoute;
    if (route == null || route.steps.isEmpty) return;
    if (_currentStepIndex >= route.steps.length - 1) return;
    final step = route.steps[_currentStepIndex];
    if (step.stepCoordinates.isEmpty) return;
    final dist = IndiaPlacesSearchEngine.calculateDistanceKm(_currentPosition, step.stepCoordinates.first);
    if (dist < 0.04) {
      setState(() => _currentStepIndex++);
      _voice.speak(route.steps[_currentStepIndex].instruction);
    }
  }

  void _checkArrival() {
    if (_destination == null) return;
    final dist = IndiaPlacesSearchEngine.calculateDistanceKm(_currentPosition, LatLng(_destination!.latitude, _destination!.longitude));
    if (dist < 0.025 && _isNavigating) {
      setState(() => _isNavigating = false);
      _voice.speak('You have arrived.');
    }
  }

  Future<void> _calculateRoute(PlaceSearchResultEntity dest) async {
    setState(() { _destination = dest; _isNavigating = false; _currentStepIndex = 0; });
    try {
      final multi = await GoogleMapsPlatformService.instance.calculateDirections(
        origin: _currentPosition, destination: LatLng(dest.latitude, dest.longitude),
        waypoints: [], selectedOption: RouteOptionType.fastestHighway,
      );
      if (!mounted) return;
      final best = multi.activeRoute;
      setState(() {
        _activeRoute = best; _isNavigating = true;
        _polylines.clear(); _markers.clear();
        _polylines.add(gm.Polyline(
          polylineId: const gm.PolylineId('route'),
          points: best.polylinePoints.map((p) => gm.LatLng(p.latitude, p.longitude)).toList(),
          color: RoadOSColors.apexEmerald, width: 6,
        ));
        _markers.add(gm.Marker(markerId: const gm.MarkerId('dest'), position: gm.LatLng(dest.latitude, dest.longitude)));
      });
      _voice.speak(best.steps.isNotEmpty ? best.steps.first.instruction : 'Route ready. Start riding.');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Route error: $e'), backgroundColor: Colors.red.shade900));
    }
  }

  Future<void> _recalculate() async { if (_destination != null) await _calculateRoute(_destination!); }

  void _endNavigation() {
    setState(() { _isNavigating = false; _destination = null; _activeRoute = null; _polylines.clear(); _markers.clear(); _currentStepIndex = 0; });
  }

  void _showSos() => showDialog(context: context, barrierDismissible: false, builder: (_) => const SosCountdownModal());
  @override
  Widget build(BuildContext context) {
    final connState = ref.watch(vehicleConnectionManagerProvider);
    final vehicleCtx = ref.watch(activeVehicleContextProvider);
    final activeProfile = vehicleCtx.profile;
    final isElectric = activeProfile?.isElectric ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: Stack(
        children: [
          Positioned.fill(child: _buildMap()),
          Positioned(top: 0, left: 0, right: 0, child: _buildTopOverlay(connState, activeProfile, isElectric)),
          if (_isNavigating && _activeRoute != null)
            Positioned(top: 110, left: 12, right: 12, child: _buildTurnCard()),
          if (!_isGpsActive)
            Positioned(top: 110, left: 12, right: 12, child: _buildGpsBanner()),
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomBar(isElectric)),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return gm.GoogleMap(
      initialCameraPosition: gm.CameraPosition(
        target: gm.LatLng(_currentPosition.latitude, _currentPosition.longitude), zoom: 16.0, tilt: 40,
      ),
      mapType: gm.MapType.normal,
      myLocationEnabled: !kIsWeb,
      myLocationButtonEnabled: false,
      trafficEnabled: true,
      compassEnabled: false,
      zoomControlsEnabled: false,
      polylines: _polylines,
      markers: _markers,
      style: _kScooterMapStyle,
      onMapCreated: (c) { if (!_mapController.isCompleted) _mapController.complete(c); },
    );
  }

  Widget _buildTopOverlay(VehicleConnectionState connState, VehicleProfile? profile, bool isElectric) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Speed pod
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: RoadOSColors.glassCardDecoration(glowColor: RoadOSColors.apexEmerald, radius: 14, borderWidth: 1.5),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_isGpsActive ? '${_currentSpeedKmh.round()}' : '--',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, height: 1.0)),
                Text('KM/H', style: GoogleFonts.outfit(color: RoadOSColors.textSecondary, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
              ]),
            ),
            const SizedBox(width: 10),
            // EV/Petrol badge from real profile
            if (profile != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: RoadOSColors.glassCardDecoration(glowColor: isElectric ? RoadOSColors.apexEmerald : RoadOSColors.hyperOrange, radius: 14),
                child: Column(children: [
                  Icon(isElectric ? Icons.bolt_rounded : Icons.local_gas_station_rounded,
                      color: isElectric ? RoadOSColors.apexEmerald : RoadOSColors.hyperOrange, size: 20),
                  const SizedBox(height: 2),
                  Text(isElectric ? 'ELECTRIC' : 'PETROL',
                      style: GoogleFonts.outfit(color: isElectric ? RoadOSColors.apexEmerald : RoadOSColors.hyperOrange, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
                ]),
              )
            else
              // No profile — show setup prompt
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF080C1A).withValues(alpha: 0.80),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: RoadOSColors.textMuted.withValues(alpha: 0.2)),
                ),
                child: Column(children: [
                  const Icon(Icons.electric_scooter_rounded, color: RoadOSColors.textSecondary, size: 20),
                  const SizedBox(height: 2),
                  Text('NO PROFILE', style: GoogleFonts.outfit(color: RoadOSColors.textSecondary, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                ]),
              ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: RoadOSColors.glassCardDecoration(radius: 12),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.electric_scooter_rounded, color: RoadOSColors.apexEmerald, size: 14),
                const SizedBox(width: 6),
                Text('SCOOTER', style: GoogleFonts.outfit(color: RoadOSColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTurnCard() {
    final route = _activeRoute!;
    final steps = route.steps;
    if (steps.isEmpty) return const SizedBox.shrink();
    final step = _currentStepIndex < steps.length ? steps[_currentStepIndex] : steps.last;
    final distKm = (step.distanceMeters / 1000).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: RoadOSColors.glassCardDecoration(glowColor: RoadOSColors.apexEmerald, radius: 18, borderWidth: 2.0),
      child: Row(children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: RoadOSColors.apexEmerald.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14),
            border: Border.all(color: RoadOSColors.apexEmerald.withValues(alpha: 0.5), width: 2),
          ),
          child: Icon(_maneuverIcon(step.iconType), color: RoadOSColors.apexEmerald, size: 40),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(step.instruction.replaceAll(RegExp(r'<[^>]*>'), ''),
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900, height: 1.2),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Text('In $distKm km', style: GoogleFonts.outfit(color: RoadOSColors.apexEmerald, fontSize: 20, fontWeight: FontWeight.w900)),
        ])),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(route.estimatedArrival, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
          Text('${route.distanceKm.toStringAsFixed(1)} km', style: GoogleFonts.inter(color: RoadOSColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _endNavigation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: RoadOSColors.glassCardDecoration(glowColor: const Color(0xFFFF3344), radius: 8),
              child: Text('END', style: GoogleFonts.outfit(color: const Color(0xFFFF3344), fontSize: 10, fontWeight: FontWeight.w900)),
            ),
          ),
        ]),
      ]),
    );
  }

  IconData _maneuverIcon(String t) {
    final lower = t.toLowerCase();
    if (lower.contains('left')) return Icons.turn_left_rounded;
    if (lower.contains('right')) return Icons.turn_right_rounded;
    if (lower.contains('uturn') || lower.contains('u-turn')) return Icons.u_turn_right_rounded;
    if (lower.contains('roundabout')) return Icons.roundabout_right_rounded;
    if (lower.contains('arrive') || lower.contains('destination')) return Icons.flag_rounded;
    return Icons.straight_rounded;
  }

  Widget _buildGpsBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFF8C00).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFF8C00).withValues(alpha: 0.5)),
      ),
      child: Row(children: [
        const Icon(Icons.gps_off_rounded, color: Color(0xFFFF8C00), size: 22),
        const SizedBox(width: 10),
        Expanded(child: Text('GPS UNAVAILABLE — Enable location services',
            style: GoogleFonts.outfit(color: const Color(0xFFFF8C00), fontSize: 12, fontWeight: FontWeight.w700))),
      ]),
    );
  }

  Widget _buildBottomBar(bool isElectric) {
    final weatherState = ref.watch(weatherProvider);
    final isWeatherLoaded = weatherState is WeatherData;
    final isWeatherSetupReq = weatherState is WeatherSetupRequired;
    final weatherTemp = isWeatherLoaded ? weatherState.temperatureCelsius.round() : 0;
    final weatherIcon = isWeatherSetupReq ? Icons.settings_rounded :
                        isWeatherLoaded && weatherState.condition == WeatherCondition.rain ? Icons.water_drop :
                        isWeatherLoaded && weatherState.condition == WeatherCondition.cloudy ? Icons.cloud :
                        Icons.wb_sunny_rounded;
    final weatherLabel = isWeatherSetupReq ? 'SETUP REQ' : 
                         isWeatherLoaded ? '$weatherTemp°' : 'WEA';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF060A18).withValues(alpha: 0.98),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(children: [
            _ScooterBtn(icon: Icons.sos_rounded, label: 'SOS', color: const Color(0xFFFF3344), onTap: _showSos),
            const SizedBox(width: 8),
            _ScooterBtn(
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
            _ScooterBtn(
              icon: isElectric ? Icons.ev_station_rounded : Icons.local_gas_station_rounded,
              label: isElectric ? 'CHARGE' : 'FUEL',
              color: isElectric ? RoadOSColors.apexEmerald : RoadOSColors.hyperOrange,
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(isElectric ? 'Searching nearby EV charging stations...' : 'Searching nearby petrol stations...'),
              )),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () async {
                  final result = await Navigator.of(context).push<PlaceSearchResultEntity>(
                    MaterialPageRoute(builder: (_) => const DestinationSearchScreen()),
                  );
                  if (result != null) await _calculateRoute(result);
                },
                child: Container(
                  height: 60,
                  decoration: RoadOSColors.glassCardDecoration(glowColor: RoadOSColors.apexEmerald, radius: 14),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.search_rounded, color: RoadOSColors.apexEmerald, size: 20),
                    const SizedBox(width: 8),
                    Text(_destination != null ? _destination!.title : 'WHERE TO?',
                        style: GoogleFonts.outfit(
                          color: _destination != null ? Colors.white : RoadOSColors.apexEmerald,
                          fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1,
                        ),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ScooterBtn(
              icon: Icons.mic_rounded, 
              label: 'AI', 
              color: RoadOSColors.electricBlue,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VoiceAssistantHudScreen())),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ScooterBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _ScooterBtn({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60, height: 60,
        decoration: RoadOSColors.glassCardDecoration(glowColor: color, radius: 14, borderWidth: 1.5),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 3),
          Text(label, style: GoogleFonts.outfit(color: color, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
        ]),
      ),
    );
  }
}

const String _kScooterMapStyle = '''[
  {"elementType":"geometry","stylers":[{"color":"#050A14"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#4A6A5A"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#050A14"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#121E2A"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#182A38"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#1E3545"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#00CC66"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#08120A"}]},
  {"featureType":"poi","elementType":"all","stylers":[{"visibility":"off"}]}
]''';
