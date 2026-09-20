/*
// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import '../../../../core/vehicle_resolution/models/vehicle_profile.dart';
import 'garage_3d_viewport.dart';

/// WebGL 3D Motorcycle Showroom Platform View for Flutter Web
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

  static void invokeSetCameraPreset(String preset) {
    try {
      final rideOs3d = js.context['RideOS3D'];
      if (rideOs3d != null) {
        rideOs3d.callMethod('setCameraPreset', [preset]);
      }
    } catch (_) {}
  }

  static void invokeLoadVehicleProfile(String profileJson) {
    try {
      final rideOs3d = js.context['RideOS3D'];
      if (rideOs3d != null) {
        rideOs3d.callMethod('loadVehicleProfile', [profileJson]);
      }
    } catch (_) {}
  }

  static void invokeUpdateTelemetry(String telemetryJson) {
    try {
      final rideOs3d = js.context['RideOS3D'];
      if (rideOs3d != null) {
        rideOs3d.callMethod('updateTelemetry', [telemetryJson]);
      }
    } catch (_) {}
  }

  @override
  State<WebGl3dGarageViewPlatform> createState() => _WebGl3dGarageViewPlatformState();
}

class _WebGl3dGarageViewPlatformState extends State<WebGl3dGarageViewPlatform> {
  static const String _viewType = 'rideos-3d-showroom-view';
  static bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    _registerViewFactory();

    // Hook JS component click callback to Flutter
    js.context['invokeFlutterMethod'] = (String method, dynamic arg) {
      if (method == 'onEngineReady') {
        _onEngineReady();
      } else if (method == 'onComponentClicked') {
        widget.onComponentClicked?.call(arg as String);
      }
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init3DShowroom();
    });
  }

  void _registerViewFactory() {
    if (!_isRegistered) {
      ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
        final div = html.DivElement()
          ..id = 'rideos-3d-canvas-container-$viewId'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.position = 'absolute'
          ..style.top = '0'
          ..style.left = '0'
          ..style.right = '0'
          ..style.bottom = '0'
          ..style.overflow = 'hidden'
          ..style.backgroundColor = 'transparent';

        return div;
      });
      _isRegistered = true;
    }
  }

  void _init3DShowroom() {
    try {
      final rideOs3d = js.context['RideOS3D'];
      if (rideOs3d != null) {
        rideOs3d.callMethod('initialize', []);
      }
    } catch (_) {}
  }

  void _onEngineReady() {
    final profileJson = {
      'manufacturer': widget.vehicle.manufacturer,
      'model': widget.vehicle.model,
      'model3DUrl': widget.vehicle.model3DUrl,
      'specifications': {
        'hotspots': widget.vehicle.specifications.keys.map((k) {
          return {'name': k, 'position': {'x': 0, 'y': 0.5, 'z': 0}}; 
        }).toList()
      }
    };
    WebGl3dGarageViewPlatform.invokeLoadVehicleProfile(jsonEncode(profileJson));
  }

  @override
  void didUpdateWidget(WebGl3dGarageViewPlatform oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if telemetry state changed
    if (oldWidget.isEngineRunning != widget.isEngineRunning ||
        oldWidget.engineRpm != widget.engineRpm ||
        oldWidget.isHeadlightOn != widget.isHeadlightOn ||
        oldWidget.isBrakeLightOn != widget.isBrakeLightOn) {
      
      final telemetryPayload = {
        'ignition': widget.isEngineRunning,
        'rpm': widget.engineRpm,
        'headlight': widget.isHeadlightOn,
        'brakePressure': widget.isBrakeLightOn ? 1.0 : 0.0,
        // Calculate rough speed from RPM for animation
        'speedKmh': widget.isEngineRunning ? (widget.engineRpm / 1000) * 15 : 0
      };
      
      WebGl3dGarageViewPlatform.invokeUpdateTelemetry(jsonEncode(telemetryPayload));
    }

    if (oldWidget.vehicle.id != widget.vehicle.id) {
      _onEngineReady(); // Reload profile if switched
    }
  }

  @override
  Widget build(BuildContext context) {
    return const HtmlElementView(viewType: _viewType);
  }
}

*/