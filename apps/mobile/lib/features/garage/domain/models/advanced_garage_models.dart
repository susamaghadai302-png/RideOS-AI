import 'package:flutter/foundation.dart';

enum CameraPreset {
  isometric,
  front,
  sideProfile,
  rear,
  topInspection;

  String get label {
    switch (this) {
      case CameraPreset.isometric:
        return 'Isometric 3D';
      case CameraPreset.front:
        return 'Front Apex';
      case CameraPreset.sideProfile:
        return 'Side Profile';
      case CameraPreset.rear:
        return 'Rear Exhaust';
      case CameraPreset.topInspection:
        return 'Top Inspection';
    }
  }

  double get defaultAngleDegrees {
    switch (this) {
      case CameraPreset.isometric:
        return 45.0;
      case CameraPreset.front:
        return 0.0;
      case CameraPreset.sideProfile:
        return 90.0;
      case CameraPreset.rear:
        return 180.0;
      case CameraPreset.topInspection:
        return 270.0;
    }
  }
}

enum LightingPreset {
  showroomStudio,
  cyberpunkNeon,
  trackdayPaddock,
  daylightNatural;

  String get label {
    switch (this) {
      case LightingPreset.showroomStudio:
        return 'Studio Spotlight';
      case LightingPreset.cyberpunkNeon:
        return 'Cyberpunk Glow';
      case LightingPreset.trackdayPaddock:
        return 'Track Paddock';
      case LightingPreset.daylightNatural:
        return 'Daylight Natural';
    }
  }
}

@immutable
class Motorcycle3dComponent {
  final String id;
  final String name;
  final String category;
  final int healthScore; // 0-100
  final String maintenanceMilestone;
  final String description;
  final Map<String, String> specs;

  const Motorcycle3dComponent({
    required this.id,
    required this.name,
    required this.category,
    required this.healthScore,
    required this.maintenanceMilestone,
    required this.description,
    this.specs = const {},
  });
}

class GarageAssetValidationResult {
  final bool isValid;
  final List<String> missingAssets;
  final List<String> warnings;

  const GarageAssetValidationResult({
    required this.isValid,
    this.missingAssets = const [],
    this.warnings = const [],
  });
}

@immutable
class MotorcycleGarageProfile {
  final String id;
  final String manufacturer;
  final String modelName;
  final String variant;
  final int year;
  final int displacementCc;
  final double horsepower;
  final double torqueNm;
  final double curbWeightKg;
  final String assetGlbPath;
  final bool isAssetAvailable;
  final List<String> colorOptions;
  final List<Motorcycle3dComponent> components;

  const MotorcycleGarageProfile({
    required this.id,
    required this.manufacturer,
    required this.modelName,
    required this.variant,
    required this.year,
    required this.displacementCc,
    required this.horsepower,
    required this.torqueNm,
    required this.curbWeightKg,
    required this.assetGlbPath,
    this.isAssetAvailable = true,
    required this.colorOptions,
    required this.components,
  });
}

