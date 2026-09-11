import 'package:flutter/material.dart';
import '../../../../core/vehicle_resolution/models/vehicle_profile.dart';
import 'garage_3d_viewport.dart';

class WebGl3dGarageViewPlatform extends StatefulWidget {
  final VehicleProfile vehicle;
  final GarageLightingMode lightingMode;
  final bool isEngineRunning;
  final double engineRpm;
  final bool isHeadlightOn;
  final bool isHighBeamOn;
  final bool isBrakeLightOn;
  final bool isLeftIndicatorOn;
  final bool isRightIndicatorOn;
  final bool isHazardOn;
  final bool isExplodedView;
  final Function(String componentKey)? onComponentClicked;

  const WebGl3dGarageViewPlatform({
    super.key,
    required this.vehicle,
    required this.lightingMode,
    required this.isEngineRunning,
    required this.engineRpm,
    required this.isHeadlightOn,
    required this.isHighBeamOn,
    required this.isBrakeLightOn,
    required this.isLeftIndicatorOn,
    required this.isRightIndicatorOn,
    required this.isHazardOn,
    required this.isExplodedView,
    this.onComponentClicked,
  });

  static void invokeSetCameraPreset(String preset) {}
  static void invokeLoadVehicleProfile(String profileJson) {}
  static void invokeUpdateTelemetry(String telemetryJson) {}

  @override
  State<WebGl3dGarageViewPlatform> createState() => _WebGl3dGarageViewPlatformState();
}

class _WebGl3dGarageViewPlatformState extends State<WebGl3dGarageViewPlatform> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Text(
          'WebGL Not Supported on this Platform',
          style: TextStyle(color: Colors.white54),
        ),
      ),
    );
  }
}
