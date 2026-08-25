import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard, RoadOSThemeEngine;
import '../../../../core/graphics/liquid_glass_engine.dart';
import '../../../../core/widgets/cinematic_background.dart';
import '../../../../core/widgets/rideos_3d_model_viewer.dart';
import '../../../../core/vehicle_resolution/models/vehicle_profile.dart';
import '../../../../core/vehicle_resolution/models/active_vehicle_context.dart';
import '../../../../core/vehicle_resolution/providers/my_vehicles_provider.dart';
import '../../../../core/vehicle_resolution/providers/active_vehicle_context_provider.dart';
import '../../../../core/graphics/global_3d_state_bridge.dart';
import '../../../garage/presentation/screens/luxury_garage_showroom_screen.dart';

class MyVehiclesScreen extends ConsumerStatefulWidget {
  const MyVehiclesScreen({super.key});

  @override
  ConsumerState<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends ConsumerState<MyVehiclesScreen> {
  late PageController _pageController;
  double _currentPageValue = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.7);
    _pageController.addListener(() {
      setState(() {
        _currentPageValue = _pageController.page ?? 0.0;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Global3DStateBridge().setCameraPreset('vehicles');
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ownedVehicles = ref.watch(myVehiclesProvider);
    final activeContext = ref.watch(activeVehicleContextProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // LAYER 0: Cinematic Background
          Positioned.fill(
            child: CinematicBackground(
              child: Container(),
            ),
          ),
          
          // LAYER 1: 3D Showroom Title & Nav
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: SafeArea(
              child: _buildTopHeader(context, activeContext),
            ),
          ),

          // LAYER 2: Spatial 3D Carousel
          Positioned.fill(
            top: 120,
            bottom: 60,
            child: PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              itemCount: ownedVehicles.length,
              itemBuilder: (context, index) {
                final vehicle = ownedVehicles[index];
                
                // Calculate 3D transformation properties based on scroll position
                double relativePosition = index - _currentPageValue;
                double scale = 1.0 - (relativePosition.abs() * 0.2).clamp(0.0, 0.4);
                double tiltY = -relativePosition * 0.5; // Rotate away from center
                double opacity = 1.0 - (relativePosition.abs() * 0.5).clamp(0.0, 0.8);

                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // Perspective
                    ..rotateY(tiltY)
                    ..scale(scale),
                  alignment: FractionalOffset.center,
                  child: Opacity(
                    opacity: opacity,
                    child: _build3DVehicleCard(context, vehicle, index == _currentPageValue.round()),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, ActiveVehicleContext activeContext) {
    return SpatialFloatingWidget(
      tiltX: 0.1,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
                border: Border.all(color: RoadOSColors.cyberCyan.withOpacity(0.5)),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            ),
          ),
          Text(
            '3D SHOWROOM',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(width: 44), // Balances the back button
        ],
      ),
    );
  }

  Widget _build3DVehicleCard(BuildContext context, VehicleProfile vehicle, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: isActive ? RoadOSColors.cyberCyan.withOpacity(0.3) : Colors.transparent,
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0x40101A38),
                  const Color(0x2004060C),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isActive ? RoadOSColors.cyberCyan : RoadOSColors.borderTranslucent,
                width: isActive ? 2.0 : 1.0,
              ),
            ),
            child: Stack(
              children: [
                // 1. The 3D Digital Twin Model
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 120),
                    child: IgnorePointer(
                      ignoring: !isActive, // Only active vehicle gets interaction
                      child: RideOS3DModelViewer(
                        vehicleProfile: vehicle,
                        cameraOrbit: isActive ? '45deg 75deg 90%' : '90deg 75deg 90%',
                        autoRotate: true,
                        exposure: 1.2,
                      ),
                    ),
                  ),
                ),
                
                // 2. Floating Spec UI
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.9),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          vehicle.manufacturer.toUpperCase(),
                          style: TextStyle(
                            color: RoadOSColors.cyberCyan,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                        Text(
                          vehicle.model.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildSpecPill(vehicle.engineType ?? 'EV'),
                            const SizedBox(width: 8),
                            _buildSpecPill(vehicle.category),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (isActive)
                          SpatialFloatingWidget(
                            zDepth: 10,
                            child: RoadOSButton(
                              label: 'INITIALIZE TWIN',
                              icon: Icons.power_settings_new_rounded,
                              onPressed: () {
                                ref.read(activeVehicleContextProvider.notifier).switchVehicle(vehicle);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LuxuryGarageShowroomScreen()),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
