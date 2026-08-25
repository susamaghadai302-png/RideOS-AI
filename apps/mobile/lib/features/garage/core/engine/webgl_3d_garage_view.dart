import 'package:flutter/material.dart';
import '../../../../core/vehicle_resolution/models/vehicle_profile.dart';
import 'garage_3d_viewport.dart';

import 'webgl_3d_garage_view_stub.dart'
    if (dart.library.html) 'webgl_3d_garage_view_web.dart';

/// True 3D WebGL Motorcycle Viewport embedding the Three.js 3D Showroom Engine
class WebGl3dGarageView extends StatelessWidget {
  final VehicleProfile vehicle;
  final GarageLightingMode lightingMode;
  final bool isAutoRotate;
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

  const WebGl3dGarageView({
    super.key,
    required this.vehicle,
    required this.lightingMode,
    required this.isAutoRotate,
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

  static void setCameraPreset(GarageCameraPreset preset) {
    WebGl3dGarageViewPlatform.invokeSetCameraPreset(preset.name);
  }

  static void loadVehicleProfile(String profileJson) {
    WebGl3dGarageViewPlatform.invokeLoadVehicleProfile(profileJson);
  }

  static void updateTelemetry(String telemetryJson) {
    WebGl3dGarageViewPlatform.invokeUpdateTelemetry(telemetryJson);
  }

  @override
  Widget build(BuildContext context) {
    return WebGl3dGarageViewPlatform(
      vehicle: vehicle,
      lightingMode: lightingMode,
      isAutoRotate: isAutoRotate,
      isEngineRunning: isEngineRunning,
      engineRpm: engineRpm,
      isHeadlightOn: isHeadlightOn,
      isHighBeamOn: isHighBeamOn,
      isBrakeLightOn: isBrakeLightOn,
      isLeftIndicatorOn: isLeftIndicatorOn,
      isRightIndicatorOn: isRightIndicatorOn,
      isHazardOn: isHazardOn,
      isExplodedView: isExplodedView,
      onComponentClicked: onComponentClicked,
    );
  }
}
