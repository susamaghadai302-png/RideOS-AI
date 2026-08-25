import '../vehicle_resolution/models/vehicle_profile.dart';
import 'global_3d_state_bridge_stub.dart'
    if (dart.library.html) 'global_3d_state_bridge_web.dart';

/// Global 3D State Bridge for RideOS-AI.
/// Synchronizes Flutter routing, vehicle selection, and real-time telemetry
/// with the persistent Three.js 3D WebGL Showroom engine.
class Global3DStateBridge {
  static final Global3DStateBridge _instance = Global3DStateBridge._internal();
  factory Global3DStateBridge() => _instance;
  Global3DStateBridge._internal();

  final Global3DStateBridgeImpl _impl = Global3DStateBridgeImpl();

  VehicleProfile? get currentVehicle => _impl.currentVehicle;
  String get currentCameraPreset => _impl.currentCameraPreset;
  bool get isEngineReady => _impl.isEngineReady;

  void setEngineReady() => _impl.setEngineReady();

  void loadVehicle(VehicleProfile vehicle) => _impl.loadVehicle(vehicle);

  void setCameraPreset(String preset, {double duration = 1.1}) =>
      _impl.setCameraPreset(preset, duration: duration);

  void updateTelemetry({
    required double speedKmh,
    required double rpm,
    required bool isIgnitionOn,
    bool isHeadlightOn = true,
    bool isBraking = false,
    double? batteryPercent,
    double? engineTempC,
  }) =>
      _impl.updateTelemetry(
        speedKmh: speedKmh,
        rpm: rpm,
        isIgnitionOn: isIgnitionOn,
        isHeadlightOn: isHeadlightOn,
        isBraking: isBraking,
        batteryPercent: batteryPercent,
        engineTempC: engineTempC,
      );

  void setLightingMode(String mode) => _impl.setLightingMode(mode);

  void setPaintColor(String hexColor) => _impl.setPaintColor(hexColor);

  void setExplodedView(bool exploded) => _impl.setExplodedView(exploded);

  void highlightComponent(String componentName) =>
      _impl.highlightComponent(componentName);

  void setPointerEventsEnabled(bool enabled) =>
      _impl.setPointerEventsEnabled(enabled);
}
