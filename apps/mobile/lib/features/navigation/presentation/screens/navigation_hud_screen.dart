import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/widgets/floating_glass_dock_widget.dart';
import '../bloc/navigation_bloc.dart';
import '../bloc/navigation_state.dart';
import 'package:rideos_mobile/core/design_system/roados_components.dart';

class NavigationHudScreen extends StatefulWidget {
  const NavigationHudScreen({super.key});

  @override
  State<NavigationHudScreen> createState() => _NavigationHudScreenState();
}

class _NavigationHudScreenState extends State<NavigationHudScreen> {
  int _activeDockIndex = 1; // 1 = Navigation
  final gm.LatLng _gmCenterCoords = const gm.LatLng(28.6139, 77.2090);

  IconData _getTurnIcon(String type) {
    switch (type.toUpperCase()) {
      case 'TURN_LEFT':
        return Icons.turn_left_rounded;
      case 'TURN_RIGHT':
        return Icons.turn_right_rounded;
      case 'MERGE':
        return Icons.merge_rounded;
      case 'EXIT':
        return Icons.output_rounded;
      case 'ARRIVE':
        return Icons.flag_rounded;
      default:
        return Icons.straight_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: Stack(
        children: [
          // 1. Real Interactive CartoDB Dark HUD Map Background (using Google Maps)
          gm.GoogleMap(
            initialCameraPosition: gm.CameraPosition(
              target: _gmCenterCoords,
              zoom: 15.0,
            ),
            mapType: gm.MapType.normal,
            style: '''[
              {
                "elementType": "geometry",
                "stylers": [{"color": "#050816"}]
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
                "featureType": "road",
                "elementType": "geometry",
                "stylers": [{"color": "#162331"}]
              },
              {
                "featureType": "road",
                "elementType": "geometry.stroke",
                "stylers": [{"color": "#213645"}]
              }
            ]''',
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            compassEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {},
            polylines: {
              gm.Polyline(
                polylineId: const gm.PolylineId('route_glow'),
                points: const [
                  gm.LatLng(28.6139, 77.2090),
                  gm.LatLng(28.6180, 77.2120),
                  gm.LatLng(28.6250, 77.2180),
                  gm.LatLng(28.6340, 77.2200),
                ],
                color: const Color(0xFF00D4FF).withValues(alpha: 0.4),
                width: 14,
              ),
              gm.Polyline(
                polylineId: const gm.PolylineId('route_core'),
                points: const [
                  gm.LatLng(28.6139, 77.2090),
                  gm.LatLng(28.6180, 77.2120),
                  gm.LatLng(28.6250, 77.2180),
                  gm.LatLng(28.6340, 77.2200),
                ],
                color: const Color(0xFF00D4FF),
                width: 6,
              ),
            },
          ),

          // 2. Main Telematics Navigation HUD Stack
          SafeArea(
            child: BlocConsumer<NavigationBloc, NavigationState>(
              listener: (context, state) {
                if (state is NavigationErrorState) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message), backgroundColor: RoadOSColors.errorCrimson),
                  );
                }
              },
              builder: (context, state) {
                if (state is RouteCalculatingState) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF00D4FF)),
                        SizedBox(height: 16),
                        Text(
                          'CALCULATING REAL HIGHWAY ROUTE...',
                          style: TextStyle(color: Color(0xFF00FFE5), fontWeight: FontWeight.w900, letterSpacing: 1.5),
                        ),
                      ],
                    ),
                  );
                }

                final step = (state is ActiveTurnByTurnState) ? state.currentStep : null;
                final currentSpeed = (state is ActiveTurnByTurnState) ? (state.currentFix?.speedKmh ?? 74.0) : 74.0;

                return Stack(
                  children: [
                    // Top Navigation Info Card
                    Positioned(
                      top: 12,
                      left: 16,
                      right: 16,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF050816).withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFF00D4FF).withValues(alpha: 0.4), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7B2DFF).withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00FFE5),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00FFE5).withValues(alpha: 0.5),
                                        blurRadius: 16,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _getTurnIcon(step?.type ?? 'TURN_RIGHT'),
                                    size: 36,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        step != null ? 'IN ${(step.distanceMeters > 1000 ? "${(step.distanceMeters / 1000).toStringAsFixed(1)} KM" : "${step.distanceMeters.round()} METERS")}' : 'IN 450 METERS',
                                        style: const TextStyle(
                                          color: Color(0xFF00FFE5),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        step?.instruction ?? 'Turn Right onto Highway 101',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Center Bottom Speedometer & Telemetry Cluster
                    Positioned(
                      bottom: 96,
                      left: 20,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: const Color(0xFF00FFE5).withValues(alpha: 0.55),
                                width: 1.3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00FFE5).withValues(alpha: 0.18),
                                  blurRadius: 18,
                                  spreadRadius: -2,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      currentSpeed.round().toString(),
                                      style: const TextStyle(
                                        fontSize: 38,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    const Text(
                                      'KM/H',
                                      style: TextStyle(
                                        color: Color(0xFF00FFE5),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00E676).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFF00E676).withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: const Text(
                                    '⇥ LEAN  34 deg  APEX ACTIVE',
                                    style: TextStyle(
                                      color: Color(0xFF00E676),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Right Floating Glass HUD Widget Stack
                    Positioned(
                      right: 16,
                      top: 110,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF7B2DFF).withValues(alpha: 0.65),
                                width: 1.3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7B2DFF).withValues(alpha: 0.22),
                                  blurRadius: 18,
                                  spreadRadius: -2,
                                ),
                              ],
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _HudStatusRow(icon: Icons.bluetooth_connected_rounded, label: 'HELMET MESH', color: Color(0xFF00FFE5)),
                                SizedBox(height: 6),
                                _HudStatusRow(icon: Icons.speed_rounded, label: 'OBD-II LIVE', color: Color(0xFF00E676)),
                                SizedBox(height: 6),
                                _HudStatusRow(icon: Icons.tire_repair_rounded, label: 'TPMS 36 PSI', color: Color(0xFFFFD700)),
                                SizedBox(height: 6),
                                _HudStatusRow(icon: Icons.thermostat_rounded, label: 'TEMP 88 degC', color: Color(0xFFFF4500)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // 3. Floating Glass Dock Navigation Bar at Bottom
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: FloatingGlassDockWidget(
              activeIndex: _activeDockIndex,
              onTabSelected: (idx) {
                setState(() => _activeDockIndex = idx);
                if (idx == 0) {
                  Navigator.pop(context);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HudStatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HudStatusRow({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 13, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}
