import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../core/vehicle_resolution/models/digital_twin_model.dart';

class ModelValidationResult {
  final bool isValid;
  final List<String> errorMessages;
  final List<String> warnings;
  final DigitalTwinMeshStats stats;
  final double qualityScore; // 0.0 to 1.0

  const ModelValidationResult({
    required this.isValid,
    required this.errorMessages,
    required this.warnings,
    required this.stats,
    required this.qualityScore,
  });
}

class ModelQualityValidator {
  static final ModelQualityValidator _instance = ModelQualityValidator._internal();
  factory ModelQualityValidator() => _instance;
  ModelQualityValidator._internal();

  /// Validates reconstructed 3D digital twin mesh parameters before publishing to Smart Garage.
  ModelValidationResult validateDigitalTwin({
    required String modelPath,
    required DigitalTwinMeshStats stats,
    DigitalTwinQuality targetQuality = DigitalTwinQuality.high,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    // 1. Polygon count validation
    if (stats.polygonCount < 1000) {
      errors.add('Geometry error: Model contains insufficient polygons (${stats.polygonCount} < 1000). Mesh is degenerate.');
    } else if (stats.polygonCount > 600000) {
      warnings.add('High polygon count (${stats.polygonCount}). Optimization Recommended for Mobile Web.');
    }

    // 2. Dimensional sanity validation (Two-wheeler bounds)
    // Realistic motorcycle length: 1.4m - 2.6m, width: 0.6m - 1.1m, height: 0.9m - 1.8m
    if (stats.lengthMeters < 0.8 || stats.lengthMeters > 3.5) {
      errors.add('Dimensional anomaly: Vehicle length (${stats.lengthMeters.toStringAsFixed(2)}m) is out of bounds (0.8m - 3.5m).');
    }
    if (stats.widthMeters < 0.3 || stats.widthMeters > 1.8) {
      errors.add('Dimensional anomaly: Vehicle width (${stats.widthMeters.toStringAsFixed(2)}m) is out of bounds (0.3m - 1.8m).');
    }
    if (stats.heightMeters < 0.5 || stats.heightMeters > 2.2) {
      errors.add('Dimensional anomaly: Vehicle height (${stats.heightMeters.toStringAsFixed(2)}m) is out of bounds (0.5m - 2.2m).');
    }

    // 3. Ground plane alignment check (y >= 0)
    if (!stats.isGroundAligned) {
      warnings.add('Model bottom was adjusted to touch ground plane at y=0.');
    }

    // 4. Manifold & Texture checks
    if (!stats.isManifold) {
      warnings.add('Mesh contains open topological boundaries.');
    }

    final bool isValid = errors.isEmpty;
    double score = 1.0;
    if (errors.isNotEmpty) {
      score = 0.0;
    } else {
      score -= (warnings.length * 0.05);
      if (stats.polygonCount >= targetQuality.targetTriangles * 0.7) {
        score = (score).clamp(0.85, 1.0);
      }
    }

    return ModelValidationResult(
      isValid: isValid,
      errorMessages: errors,
      warnings: warnings,
      stats: stats,
      qualityScore: (score * 100).round() / 100.0,
    );
  }
}
