import '../vehicle_resolution/models/vehicle_profile.dart';

class Global3DStateBridgeImpl {
  VehicleProfile? _currentVehicle;
  String _currentCameraPreset = 'home';
  bool _isEngineReady = false;

  VehicleProfile? get currentVehicle => _currentVehicle;
  String get currentCameraPreset => _currentCameraPreset;
  bool get isEngineReady => _isEngineReady;

  void setEngineReady() {
    _isEngineReady = true;
  }

  void loadVehicle(VehicleProfile vehicle) {
    _currentVehicle = vehicle;
  }

  void setCameraPreset(String preset, {double duration = 1.1}) {
    _currentCameraPreset = preset;
  }

  void updateTelemetry({
    required double speedKmh,
    required double rpm,
    required bool isIgnitionOn,
    bool isHeadlightOn = true,
    bool isBraking = false,
    double? batteryPercent,
    double? engineTempC,
  }) {}

  void setLightingMode(String mode) {}

  void setPaintColor(String hexColor) {}

  void setExplodedView(bool exploded) {}

  void highlightComponent(String componentName) {}

  void setPointerEventsEnabled(bool enabled) {}
}
