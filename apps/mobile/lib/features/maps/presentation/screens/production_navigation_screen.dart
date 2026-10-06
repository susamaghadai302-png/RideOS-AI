import 'package:flutter/material.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import 'package:latlong2/latlong.dart' as ll2;
import '../../core/map_provider.dart';
import '../../core/map_provider_factory.dart';
import '../../domain/models/navigation_models.dart';
import '../../domain/models/ride_route_models.dart';
import '../../services/turn_by_turn_navigation_engine.dart';
import '../../../../core/widgets/cinematic_background.dart';

class ProductionNavigationScreen extends StatefulWidget {
  const ProductionNavigationScreen({super.key});

  @override
  State<ProductionNavigationScreen> createState() => _ProductionNavigationScreenState();
}

class _ProductionNavigationScreenState extends State<ProductionNavigationScreen> {
  final _navEngine = TurnByTurnNavigationEngine();
  MapProvider get _mapProvider => MapProviderFactory().activeProvider;

  final _origin = const LatLng(12.9716, 77.5946); // Downtown Center
  final _destination = const LatLng(12.9352, 77.6245); // Tech Park Hub

  ll2.LatLng get _originLl2 => ll2.LatLng(_origin.latitude, _origin.longitude);
  ll2.LatLng get _destinationLl2 => ll2.LatLng(_destination.latitude, _destination.longitude);

  PoiCategory? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _navEngine.updateGpsLocation(
      position: _originLl2,
      speedKmh: 0.0,
      headingDeg: 45.0,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onCategorySelected(PoiCategory cat) {
    setState(() {
      _selectedCategory = _selectedCategory == cat ? null : cat;
    });
  }

  void _previewRoute() {
    _navEngine.selectDestination(origin: _originLl2, destination: _destinationLl2);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<NavigationSessionState>(
      stream: _navEngine.stateStream,
      initialData: _navEngine.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? NavigationSessionState.idle;

        return Scaffold(
          backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
          body: CinematicBackground(child: Stack(
            children: [
              // 1. Primary Fullscreen Vector Map Layer
              Positioned.fill(
                child: _mapProvider.buildMapView(
                  options: MapOptions(
                    initialCenter: _navEngine.currentGpsPosition != null ? LatLng(_navEngine.currentGpsPosition!.latitude, _navEngine.currentGpsPosition!.longitude) : _origin,
                    initialZoom: 16.0,
                    showTraffic: true,
                    enableTilt: _navEngine.cameraMode == CameraMode.navigation3D,
                  ),
                  markers: [
                    MapMarker(
                      id: 'origin_pin',
                      position: _origin,
                      title: 'Current Position',
                      icon: Icons.two_wheeler_rounded,
                      color: RoadOSColors.apexEmerald,
                    ),
                    if (state != NavigationSessionState.idle)
                      MapMarker(
                        id: 'dest_pin',
                        position: _destination,
                        title: 'Destination',
                        icon: Icons.place_rounded,
                        color: RoadOSColors.errorCrimson,
                      ),
                  ],
                  polylinePoints: _navEngine.activeRoute?.fullPolyline.map((p) => LatLng(p.latitude, p.longitude)).toList(),
                ),
              ),

              // 2. Top Maneuver Instruction Banner (Active when Navigating or Preview)
              if (state == NavigationSessionState.navigating || state == NavigationSessionState.offRoute || state == NavigationSessionState.rerouting)
                Positioned(
                  top: 50,
                  left: 16,
                  right: 16,
                  child: _buildTurnInstructionBanner(state),
                ),

              // 3. Top Search & POI Bar (Active when Idle)
              if (state == NavigationSessionState.idle)
                Positioned(
                  top: 50,
                  left: 16,
                  right: 16,
                  child: _buildSearchAndCategoryBar(),
                ),

              // 4. Floating Camera Perspective Mode Switcher & Compass
              Positioned(
                right: 16,
                top: state == NavigationSessionState.idle ? 180 : 160,
                child: _buildCameraModeControls(),
              ),

              // 5. Speedometer & Traffic Badge HUD
              Positioned(
                left: 16,
                bottom: state == NavigationSessionState.navigating ? 140 : 120,
                child: _buildSpeedAndTrafficHud(),
              ),

              // 6. Bottom Navigation Cockpit Card
              Positioned(
                bottom: 20,
                left: 16,
                right: 16,
                child: _buildBottomCockpitCard(state),
              ),
            ],
          )),
        );
      },
    );
  }

  Widget _buildTurnInstructionBanner(NavigationSessionState state) {
    final isAlert = state == NavigationSessionState.offRoute || state == NavigationSessionState.rerouting;
    final proximity = _navEngine.proximityState;

    Color bannerColor = const Color(0xFF070B18).withValues(alpha: 0.95);
    Color borderColor = RoadOSColors.borderTranslucent;
    Color iconColor = RoadOSColors.electricBlue;
    Color iconBgColor = RoadOSColors.electricBlue.withValues(alpha: 0.15);

    if (isAlert || proximity == ManeuverProximityState.rerouting) {
      bannerColor = RoadOSColors.errorCrimson.withValues(alpha: 0.95);
      borderColor = Colors.redAccent;
      iconColor = Colors.white;
      iconBgColor = Colors.white.withValues(alpha: 0.2);
    } else if (proximity == ManeuverProximityState.immediate) {
      bannerColor = RoadOSColors.hyperOrange.withValues(alpha: 0.95);
      borderColor = RoadOSColors.hyperOrange;
      iconColor = Colors.white;
      iconBgColor = Colors.white.withValues(alpha: 0.2);
    } else if (proximity == ManeuverProximityState.approaching) {
      bannerColor = RoadOSColors.apexEmerald.withValues(alpha: 0.95);
      borderColor = RoadOSColors.apexEmerald;
      iconColor = Colors.white;
      iconBgColor = Colors.white.withValues(alpha: 0.2);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_navEngine.currentManeuverIcon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _navEngine.currentInstruction,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  isAlert ? 'Recalculating alternative path...' : 'In ${_navEngine.distanceToNextManeuverMeters.toStringAsFixed(0)} meters',
                  style: TextStyle(color: (isAlert || proximity == ManeuverProximityState.immediate || proximity == ManeuverProximityState.approaching) ? Colors.white70 : RoadOSColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndCategoryBar() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF070B18).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1A2035)),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: RoadOSColors.electricBlue, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Search destinations, fuel, mountain passes...',
                    hintStyle: TextStyle(color: RoadOSColors.textMuted, fontSize: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.directions_bike_rounded, color: RoadOSColors.apexEmerald, size: 20),
                onPressed: _previewRoute,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 6,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final cat = [
                PoiCategory.petrol,
                PoiCategory.evCharging,
                PoiCategory.motoService,
                PoiCategory.hospital,
                PoiCategory.workshop,
                PoiCategory.cafe,
              ][i];
              final isSelected = _selectedCategory == cat;

              return FilterChip(
                label: Text(cat.displayName, style: TextStyle(color: isSelected ? Colors.white : RoadOSColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                avatar: Icon(cat.icon, size: 14, color: isSelected ? Colors.white : cat.color),
                backgroundColor: const Color(0xFF080C1A).withValues(alpha: 0.85),
                selectedColor: cat.color.withValues(alpha: 0.8),
                selected: isSelected,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? cat.color : RoadOSColors.borderTranslucent)),
                onSelected: (_) => _onCategorySelected(cat),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCameraModeControls() {
    return Column(
      children: [
        _buildCircleButton(
          icon: Icons.explore_rounded,
          color: RoadOSColors.electricBlue,
          onTap: () {
        LuxAudioHapticsService.lightImpact();
            setState(() {
              final next = _navEngine.cameraMode == CameraMode.navigation3D ? CameraMode.northUp : CameraMode.navigation3D;
              _navEngine.setCameraMode(next);
            });
          },
        ),
        const SizedBox(height: 10),
        _buildCircleButton(
          icon: Icons.my_location_rounded,
          color: RoadOSColors.apexEmerald,
          onTap: () => _navEngine.setCameraMode(CameraMode.followLocation),
        ),
      ],
    );
  }

  Widget _buildCircleButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF070B18).withValues(alpha: 0.9),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF1A2035)),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildSpeedAndTrafficHud() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF1A2035)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.traffic_rounded, color: Color(0xFFFFD600), size: 12),
              SizedBox(width: 4),
              Text(
                'SIMULATED TRAFFIC',
                style: TextStyle(color: Color(0xFFFFD600), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF070B18).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1A2035)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_navEngine.currentSpeedKmh.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              const Text('KM/H', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomCockpitCard(NavigationSessionState state) {
    if (state == NavigationSessionState.routePreview) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF080C1A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF1A2035)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('SELECT ROUTE OPTION', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                Text('${_navEngine.availableAlternatives.length} Routes Found', style: const TextStyle(color: RoadOSColors.electricBlue, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ..._navEngine.availableAlternatives.map((alt) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: alt.routeType == RideRouteType.fastest ? RoadOSColors.electricBlue.withValues(alpha: 0.12) : Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: alt.routeType == RideRouteType.fastest ? RoadOSColors.electricBlue : RoadOSColors.borderTranslucent),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alt.routeType.displayName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('${alt.totalDistanceKm.toStringAsFixed(1)} km | ~${alt.totalDurationMinutes} mins', style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11)),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: RoadOSColors.apexEmerald, foregroundColor: Colors.white, minimumSize: const Size(80, 34)),
                    onPressed: () => _navEngine.startNavigation(selectedAlternative: alt),
                    child: const Text('GO', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            )),
          ],
        ),
      );
    }

    if (state == NavigationSessionState.navigating) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF080C1A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF1A2035)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ETA: ${_formatEta(_navEngine.remainingDurationMinutes)}', style: const TextStyle(color: RoadOSColors.apexEmerald, fontSize: 15, fontWeight: FontWeight.bold)),
                Text('${_navEngine.remainingDistanceKm.toStringAsFixed(1)} km remaining', style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11)),
              ],
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text('END', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, minimumSize: const Size(90, 40)),
              onPressed: () => _navEngine.cancelNavigation(),
            ),
          ],
        ),
      );
    }

    return ElevatedButton.icon(
      icon: const Icon(Icons.navigation_rounded),
      label: const Text('START NAVIGATION PREVIEW', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      style: ElevatedButton.styleFrom(
        backgroundColor: RoadOSColors.electricBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: _previewRoute,
    );
  }

  String _formatEta(double durationMinutes) {
    final arrival = DateTime.now().add(Duration(minutes: durationMinutes.toInt()));
    final hour = arrival.hour.toString().padLeft(2, '0');
    final minute = arrival.minute.toString().padLeft(2, '0');
    return '$hour:$minute (${durationMinutes.toInt()} min)';
  }
}
