import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:rideos_mobile/core/ecosystem/rideos_master_architecture.dart';
import '../design_system/design_tokens.dart';
import 'package:rideos_mobile/core/design_system/roados_components.dart';
import 'package:rideos_mobile/features/garage/domain/models/advanced_garage_models.dart';

enum ShowroomEnvironmentMode { studio, day, night }

enum PbrMaterialType { mattePaint, glossPaint, carbonFiber, chrome, rubber, glass }

class PbrMaterialConfig {
  final PbrMaterialType type;
  final Color baseColor;
  final double roughness;
  final double metallic;

  const PbrMaterialConfig({
    required this.type,
    required this.baseColor,
    this.roughness = 0.2,
    this.metallic = 0.9,
  });
}

class Vehicle3dEngineController extends ChangeNotifier {
  double cameraYaw = 0.0;
  double cameraPitch = 0.15;
  double cameraZoom = 1.0;
  bool isAutoRotating = false;
  ShowroomEnvironmentMode environmentMode = ShowroomEnvironmentMode.studio;

  Color paintColor = RoadOSColors.hyperOrange;
  PbrMaterialType paintMaterial = PbrMaterialType.glossPaint;

  void rotate(double deltaX, double deltaY) {
    cameraYaw += deltaX * 0.01;
    cameraPitch = (cameraPitch + deltaY * 0.01).clamp(-0.4, 0.6);
    notifyListeners();
  }

  void zoom(double factor) {
    cameraZoom = (cameraZoom * factor).clamp(0.5, 2.5);
    notifyListeners();
  }

  void resetCamera() {
    cameraYaw = 0.0;
    cameraPitch = 0.15;
    cameraZoom = 1.0;
    notifyListeners();
  }

  void applyCameraPreset(CameraPreset preset) {
    cameraYaw = preset.defaultAngleDegrees * (math.pi / 180.0);
    cameraPitch = 0.15;
    cameraZoom = 1.0;
    notifyListeners();
  }

  void applyLightingPreset(LightingPreset preset) {
    switch (preset) {
      case LightingPreset.showroomStudio:
        environmentMode = ShowroomEnvironmentMode.studio;
        break;
      case LightingPreset.cyberpunkNeon:
      case LightingPreset.trackdayPaddock:
      case LightingPreset.daylightNatural:
        environmentMode = ShowroomEnvironmentMode.day;
        break;
    }
    notifyListeners();
  }

  void updatePaintColor(Color newColor) {
    paintColor = newColor;
    notifyListeners();
  }
}

class Vehicle3dCanvasViewer extends StatelessWidget {
  final Vehicle3dEngineController controller;
  final VehicleDomainType domain;
  final double height;

  const Vehicle3dCanvasViewer({
    super.key,
    required this.controller,
    this.domain = VehicleDomainType.unknown,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final transformMatrix = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(controller.cameraYaw)
          ..rotateX(controller.cameraPitch);

        transformMatrix.multiply(
          Matrix4.diagonal3Values(
            controller.cameraZoom,
            controller.cameraZoom,
            controller.cameraZoom,
          ),
        );

        return GestureDetector(
          onPanUpdate: (details) => controller.rotate(details.delta.dx, details.delta.dy),
          onDoubleTap: () => controller.resetCamera(),
          child: Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(LuxRadius.lg),
              gradient: controller.environmentMode == ShowroomEnvironmentMode.studio
                  ? LuxGradients.liquidGlassDark
                  : (controller.environmentMode == ShowroomEnvironmentMode.night
                      ? const LinearGradient(colors: [Colors.black, Color(0xFF0F141D)])
                      : LuxGradients.quantumCyan),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Custom PBR Reflective Stage Painter
                CustomPaint(
                  size: Size(double.infinity, height),
                  painter: PbrStage3dPainter(
                    yaw: controller.cameraYaw,
                    pitch: controller.cameraPitch,
                    paintColor: controller.paintColor,
                  ),
                ),

                // 3D Motorcycle Avatar Graphic
                Transform(
                  alignment: Alignment.center,
                  transform: transformMatrix,
                  child: Icon(
                    _getDomainIcon(domain),
                    size: 160,
                    color: controller.paintColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getDomainIcon(VehicleDomainType domain) {
    switch (domain) {
      case VehicleDomainType.motorcycle:
        return Icons.two_wheeler_rounded;
      case VehicleDomainType.car:
        return Icons.directions_car_rounded;
      case VehicleDomainType.scooter:
        return Icons.electric_scooter_rounded;
      case VehicleDomainType.electricVehicle:
        return Icons.electric_car_rounded;
      case VehicleDomainType.commercialFleet:
        return Icons.local_shipping_rounded;
      case VehicleDomainType.atvUtv:
        return Icons.agriculture_rounded;
      case VehicleDomainType.unknown:
        return Icons.directions_car_rounded;
    }
  }
}

class PbrStage3dPainter extends CustomPainter {
  final double yaw;
  final double pitch;
  final Color paintColor;

  PbrStage3dPainter({
    required this.yaw,
    required this.pitch,
    required this.paintColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width.isFinite && size.width > 0 ? size.width : 400.0;
    final height = size.height.isFinite && size.height > 0 ? size.height : 400.0;
    final center = Offset(width / 2, height / 2);

    // Dynamic 3-Point Studio Rim Light
    final rimLightPaint = Paint()
      ..shader = RadialGradient(
        colors: [paintColor.withValues(alpha: 0.3), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: width * 0.4));

    canvas.drawCircle(center, width * 0.4, rimLightPaint);

    // Floor Reflection Grid
    final gridPaint = Paint()
      ..color = paintColor.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;

    for (double i = -100; i <= 100; i += 20) {
      canvas.drawLine(
        Offset(center.dx + i + math.sin(yaw) * 10, center.dy + 40),
        Offset(center.dx + (i * 2) + math.sin(yaw) * 20, height),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PbrStage3dPainter oldDelegate) =>
      oldDelegate.yaw != yaw || oldDelegate.pitch != pitch || oldDelegate.paintColor != paintColor;
}
