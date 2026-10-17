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
//  BIKE MODE HUD — Rider-first design
//  • HUGE turn card readable at speed
//  • Real GPS, real routing, real voice guidance
//  • 64dp minimum touch targets
//  • SOS always one tap
// ─────────────────────────────────────────────────────────────────────────────

class BikeModeScreen extends ConsumerStatefulWidget {
  const BikeModeScreen({super.key});

  @override
  ConsumerState<BikeModeScreen> createState() => _BikeModeScreenState();
}

class _BikeModeScreenState extends ConsumerState<BikeModeScreen> {
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
          zoom: 16.5, bearing: _currentHeading, tilt: 55,
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
          zoom: _isNavigating ? 17.0 : 16.0, bearing: _currentHeading, tilt: _isNavigating ? 60 : 45,
        ))));
        if (_isNavigating && _activeRoute != null) {
          final off = RoadOsRoutingEngine.instance.isOffRoute(_currentPosition, _activeRoute!.polylinePoints, thresholdMeters: 35);
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
    final dist = IndiaPlacesSearchEngine.calculateDistanceKm(_currentPosition, LatLng((_destination!.latitude ?? 0.0), (_destination!.longitude ?? 0.0)));
    if (dist < 0.025 && _isNavigating) {
      setState(() => _isNavigating = false);
      _voice.speak('You have arrived at your destination.');
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
          color: RoadOSColors.neonViolet, width: 6,
        ));
        _markers.add(gm.Marker(markerId: const gm.MarkerId('dest'), position: gm.LatLng((dest.latitude ?? 0.0), (dest.longitude ?? 0.0))));
      });
      _voice.speak(best.steps.isNotEmpty ? best.steps.first.instruction : 'Route calculated. Start riding.');
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
  }

  void _showSos() => showDialog(context: context, barrierDismissible: false, builder: (_) => const SosCountdownModal());

  @override
  Widget build(BuildContext context) {
    final connState = ref.watch(vehicleConnectionManagerProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: Stack(
        children: [
          Positioned.fill(child: _buildMap()),
          Positioned(top: 0, left: 0, right: 0, child: _buildTopOverlay(connState)),
          if (_isNavigating && _activeRoute != null)
            Positioned(top: 100, left: 12, right: 12, child: _buildHugeTurnCard()),
          if (!_isGpsActive)
            Positioned(top: 100, left: 12, right: 12, child: _buildGpsBanner()),
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomBar()),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return gm.GoogleMap(
      initialCameraPosition: gm.CameraPosition(
        target: gm.LatLng(_currentPosition.latitude, _currentPosition.longitude), zoom: 16.0, tilt: 50,
      ),
      mapType: gm.MapType.normal,
      myLocationEnabled: !kIsWeb,
      myLocationButtonEnabled: false,
      trafficEnabled: true,
      compassEnabled: false,
      zoomControlsEnabled: false,
      polylines: _polylines,
      markers: _markers,
      style: _kBikeMapStyle,
      onMapCreated: (c) { if (!_mapController.isCompleted) _mapController.complete(c); },
    );
  }

  Widget _buildTopOverlay(VehicleConnectionState connState) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Speed pod — BIG
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: RoadOSColors.glassCardDecoration(glowColor: RoadOSColors.neonViolet, radius: 14, borderWidth: 1.5),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_isGpsActive ? '${_currentSpeedKmh.round()}' : '--',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, height: 1.0)),
                Text('KM/H', style: GoogleFonts.outfit(color: RoadOSColors.textSecondary, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
              ]),
            ),
            const Spacer(),
            // Mode + connection pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: RoadOSColors.glassCardDecoration(radius: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.two_wheeler_rounded, color: RoadOSColors.neonViolet, size: 14),
                  const SizedBox(width: 6),
                  Text('BIKE MODE', style: GoogleFonts.outfit(color: RoadOSColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                ]),
                const SizedBox(height: 4),
                _connChip(connState),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _connChip(VehicleConnectionState state) {
    final isConn = state.status.isActive;
    final color = isConn ? RoadOSColors.apexEmerald : RoadOSColors.textMuted;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(state.status.displayLabel, style: GoogleFonts.outfit(color: color, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
    ]);
  }

  Widget _buildHugeTurnCard() {
    final route = _activeRoute!;
    final steps = route.steps;
    if (steps.isEmpty) return const SizedBox.shrink();
    final step = _currentStepIndex < steps.length ? steps[_currentStepIndex] : steps.last;
    final distKm = (step.distanceMeters / 1000).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: RoadOSColors.glassCardDecoration(glowColor: RoadOSColors.neonViolet, radius: 20, borderWidth: 2.0),
      child: Column(
        children: [
          Row(children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: RoadOSColors.neonViolet.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: RoadOSColors.neonViolet.withValues(alpha: 0.5), width: 2),
              ),
              child: Icon(_maneuverIcon(step.iconType), color: RoadOSColors.neonViolet, size: 44),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(step.instruction.replaceAll(RegExp(r'<[^>]*>'), ''),
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900, height: 1.2),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Text('In $distKm km', style: GoogleFonts.outfit(color: RoadOSColors.neonViolet, fontSize: 22, fontWeight: FontWeight.w900)),
            ])),
          ]),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _metricRow('ETA', route.estimatedArrival, Icons.schedule_rounded),
            _metricRow('DIST', '${route.distanceKm.toStringAsFixed(1)} km', Icons.straighten_rounded),
            GestureDetector(
              onTap: _endNavigation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3344).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFF3344).withValues(alpha: 0.5)),
                ),
                child: Text('END', style: GoogleFonts.outfit(color: const Color(0xFFFF3344), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _metricRow(String label, String value, IconData icon) {
    return Row(children: [
      Icon(icon, color: RoadOSColors.textSecondary, size: 14),
      const SizedBox(width: 6),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.outfit(color: RoadOSColors.textMuted, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1)),
        Text(value, style: GoogleFonts.outfit(color: RoadOSColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
      ]),
    ]);
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF8C00).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFF8C00).withValues(alpha: 0.5)),
      ),
      child: Row(children: [
        const Icon(Icons.gps_off_rounded, color: Color(0xFFFF8C00), size: 24),
        const SizedBox(width: 12),
        Expanded(child: Text('GPS UNAVAILABLE\nEnable location services to start navigation',
            style: GoogleFonts.outfit(color: const Color(0xFFFF8C00), fontSize: 13, fontWeight: FontWeight.w700))),
      ]),
    );
  }

  Widget _buildBottomBar() {
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
        color: const Color(0xFF060A18).withValues(alpha: 0.97),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.07), width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.7), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(children: [
            _RiderBtn(icon: Icons.sos_rounded, label: 'SOS', color: const Color(0xFFFF3344), onTap: _showSos),
            const SizedBox(width: 8),
            _RiderBtn(
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
                  height: 64,
                  decoration: RoadOSColors.glassCardDecoration(glowColor: RoadOSColors.neonViolet, radius: 14),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.search_rounded, color: RoadOSColors.neonViolet, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      _destination != null ? _destination!.title : 'WHERE TO?',
                      style: GoogleFonts.outfit(
                        color: _destination != null ? Colors.white : RoadOSColors.neonViolet,
                        fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1,
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _RiderBtn(
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

class _RiderBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _RiderBtn({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64, height: 64,
        decoration: RoadOSColors.glassCardDecoration(glowColor: color, radius: 14, borderWidth: 1.5),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 3),
          Text(label, style: GoogleFonts.outfit(color: color, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
        ]),
      ),
    );
  }
}

const String _kBikeMapStyle = '''[
  {"elementType":"geometry","stylers":[{"color":"#05091A"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#5A6A8A"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#05091A"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#141F35"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#1A2B48"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#1E3355"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#7B2DFF"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#081020"}]},
  {"featureType":"poi","elementType":"all","stylers":[{"visibility":"off"}]}
]''';
