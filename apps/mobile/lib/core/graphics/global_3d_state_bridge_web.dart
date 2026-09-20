/*
// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
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
    if (_currentVehicle != null) {
      loadVehicle(_currentVehicle!);
    }
    setCameraPreset(_currentCameraPreset);
  }

  void loadVehicle(VehicleProfile vehicle) {
    _currentVehicle = vehicle;
    try {
      final profileJson = {
        'id': vehicle.id,
        'manufacturer': vehicle.manufacturer,
        'model': vehicle.model,
        'variant': vehicle.variant,
        'model3DUrl': vehicle.model3DUrl,
        'category': vehicle.category,
        'specifications': vehicle.specifications,
      };

      final rideOs3d = js.context['RideOS3D'];
      if (rideOs3d != null) {
        rideOs3d.callMethod('loadVehicleProfile', [jsonEncode(profileJson)]);
      }
    } catch (e) {
      debugPrint('[Global3DStateBridgeWeb] loadVehicle error: $e');
    }
  }

  void setCameraPreset(String preset, {double duration = 1.1}) {
    _currentCameraPreset = preset;
    try {
      final rideOs3d = js.context['RideOS3D'];
      if (rideOs3d != null) {
        rideOs3d.callMethod('setCameraPreset', [preset, duration]);
      }
    } catch (e) {
      debugPrint('[Global3DStateBridgeWeb] setCameraPreset error: $e');
    }
  }

  void updateTelemetry({
    double? speedKmh,
    double? rpm,
    required bool isIgnitionOn,
    bool isHeadlightOn = true,
    bool isBraking = false,
    double? batteryPercent,
    double? engineTempC,
  }) {
    try {
      final telemetryPayload = {
        'speedKmh': speedKmh,
        'rpm': rpm,
        'ignition': isIgnitionOn,
        'headlight': isHeadlightOn,
        'brakeState': isBraking,
        'batteryPercent': batteryPercent,
        'engineTempC': engineTempC,
      };

      final rideOs3d = js.context['RideOS3D'];
      if (rideOs3d != null) {
        rideOs3d.callMethod('updateTelemetry', [jsonEncode(telemetryPayload)]);
      }
    } catch (_) {}
  }

  void setLightingMode(String mode) {
    try {
      final rideOs3d = js.context['RideOS3D'];
      if (rideOs3d != null) {
        rideOs3d.callMethod('setLightingMode', [mode]);
      }
    } catch (_) {}
  }

  void setPaintColor(String hexColor) {
    try {
      final rideOs3d = js.context['RideOS3D'];
      if (rideOs3d != null) {
        rideOs3d.callMethod('setPaintColor', [hexColor]);
      }
    } catch (_) {}
  }

  void setExplodedView(bool exploded) {
    try {
      final rideOs3d = js.context['RideOS3D'];
      if (rideOs3d != null) {
        rideOs3d.callMethod('setExplodedView', [exploded]);
      }
    } catch (_) {}
  }

  void highlightComponent(String componentName) {
    try {
      final rideOs3d = js.context['RideOS3D'];
      if (rideOs3d != null) {
        rideOs3d.callMethod('highlightComponent', [componentName]);
      }
    } catch (_) {}
  }

  void setPointerEventsEnabled(bool enabled) {
    try {
      final rideOs3d = js.context['RideOS3D'];
      if (rideOs3d != null) {
        rideOs3d.callMethod('setPointerEventsEnabled', [enabled]);
      }
    } catch (_) {}
  }
}

*/