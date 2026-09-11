import 'package:flutter/material.dart';
import '../../../../core/vehicle_resolution/models/vehicle_profile.dart';
import 'webgl_3d_garage_view.dart';

/// Camera Preset Enum
enum GarageCameraPreset {
  frontThreeQuarter('Front 3/4', 45.0, 14.0, 1.0),
  rearThreeQuarter('Rear 3/4', 225.0, 16.0, 1.0),
  sideProfile('Side Profile', 90.0, 5.0, 1.08),
  frontView('Front', 0.0, 10.0, 1.1),
  rearView('Rear', 180.0, 12.0, 1.1),
  topDown('Top Down', 45.0, 75.0, 1.25),
  cockpitDetail('Cockpit', 15.0, 26.0, 1.9),
  cinematic('Cinematic Orbit', 120.0, 18.0, 1.15),
  riderPov('Rider POV', 0.0, 0.0, 2.4);

  final String label;
  final double yawDeg;
  final double pitchDeg;
  final double zoom;

  const GarageCameraPreset(this.label, this.yawDeg, this.pitchDeg, this.zoom);
}

/// Lighting Environment Modes
enum GarageLightingMode {
  showroomUltra('Showroom Ultra', Color(0xFF0F172A), Color(0xFF00E5FF), 1.0, 0.8),
  darkCyber('Dark Cyber Mode', Color(0xFF040711), Color(0xFFFF6D00), 1.2, 0.9),
  daylightClear('Daylight Studio', Color(0xFF1E293B), Color(0xFFFFFFFF), 0.7, 0.6),
  cinematicSunset('Cinematic Sunset', Color(0xFF1F0B18), Color(0xFFFF9100), 1.1, 0.85),
  nightAurora('Night Aurora', Color(0xFF050B14), Color(0xFF00F5D4), 1.3, 0.95),
  workshopPro('Workshop Pro', Color(0xFF111827), Color(0xFF38BDF8), 0.9, 0.7);

  final String label;
  final Color ambientBg;
  final Color keyLightColor;
  final double reflectionIntensity;
  final double shadowSoftness;

  const GarageLightingMode(
    this.label,
    this.ambientBg,
    this.keyLightColor,
    this.reflectionIntensity,
    this.shadowSoftness,
  );
}

/// Master 3D Viewport for RideOS Garage
class Garage3dViewport extends StatefulWidget {
  final VehicleProfile vehicle;
  final bool isEngineRunning;
  final double engineRpm;
  final GarageLightingMode lightingMode;
  final double keyLightIntensity;
  final double fillLightIntensity;
  final double rimLightIntensity;
  final double reflectionOpacity;
  final bool isHeadlightOn;
  final bool isHighBeamOn;
  final bool isBrakeLightOn;
  final bool isLeftIndicatorOn;
  final bool isRightIndicatorOn;
  final bool isHazardOn;
  final bool showHotspots;
  final bool isExplodedView;
  final Function(String componentKey)? onHotspotTapped;
  final Function(GarageCameraPreset preset)? onCameraPresetChanged;

  const Garage3dViewport({
    super.key,
    required this.vehicle,
    required this.isEngineRunning,
    this.engineRpm = 0.0,
    this.lightingMode = GarageLightingMode.showroomUltra,
    this.keyLightIntensity = 1.0,
    this.fillLightIntensity = 0.7,
    this.rimLightIntensity = 0.85,
    this.reflectionOpacity = 0.75,
    this.isHeadlightOn = true,
    this.isHighBeamOn = false,
    this.isBrakeLightOn = false,
    this.isLeftIndicatorOn = false,
    this.isRightIndicatorOn = false,
    this.isHazardOn = false,
    this.showHotspots = true,
    this.isExplodedView = false,
    this.onHotspotTapped,
    this.onCameraPresetChanged,
  });

  @override
  State<Garage3dViewport> createState() => Garage3dViewportState();
}

class Garage3dViewportState extends State<Garage3dViewport> {
  GarageCameraPreset _currentPreset = GarageCameraPreset.frontThreeQuarter;
  GarageCameraPreset get currentPreset => _currentPreset;

  void setCameraPreset(GarageCameraPreset preset) {
    _currentPreset = preset;
    WebGl3dGarageView.setCameraPreset(preset);
    widget.onCameraPresetChanged?.call(preset);
    setState(() {});
  }

  void resetCamera() {
    setCameraPreset(GarageCameraPreset.frontThreeQuarter);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // True Interactive WebGL 3D Motorcycle Showroom Engine
            Positioned.fill(
              child: WebGl3dGarageView(
                vehicle: widget.vehicle,
                lightingMode: widget.lightingMode,
                isEngineRunning: widget.isEngineRunning,
                engineRpm: widget.engineRpm,
                isHeadlightOn: widget.isHeadlightOn,
                isHighBeamOn: widget.isHighBeamOn,
                isBrakeLightOn: widget.isBrakeLightOn,
                isLeftIndicatorOn: widget.isLeftIndicatorOn,
                isRightIndicatorOn: widget.isRightIndicatorOn,
                isHazardOn: widget.isHazardOn,
                isExplodedView: widget.isExplodedView,
                onComponentClicked: widget.onHotspotTapped,
              ),
            ),
          ],
        );
      },
    );
  }
}
