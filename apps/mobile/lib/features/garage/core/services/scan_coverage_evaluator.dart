import 'package:flutter/foundation.dart';
import 'dart:math' as math;

enum ScanSector {
  front('Front', 0, 'Front Headlight & Fairing', true),
  frontRight('Front-Right', 45, 'Front-Right Quarter & Wheel', true),
  right('Right', 90, 'Right Flank, Tank & Engine', true),
  rearRight('Rear-Right', 135, 'Rear-Right Quarter & Exhaust', true),
  rear('Rear', 180, 'Tail Light & Rear Wheel', true),
  rearLeft('Rear-Left', 225, 'Rear-Left Quarter & Swingarm', true),
  left('Left', 270, 'Left Flank, Chain & Engine', true),
  frontLeft('Front-Left', 315, 'Front-Left Quarter & Fork', true),
  dashboard('Cockpit', -1, 'Handlebars, TFT & Controls', false),
  wheels('Wheels', -2, 'Rims, Calipers & Rotors', false),
  exhaust('Exhaust', -3, 'Silencer & Header Pipes', false),
  enginePowertrain('Engine', -4, 'Motor / Engine Block Details', false);

  final String title;
  final int targetAngleDeg;
  final String description;
  final bool isRadialAngle;
  const ScanSector(this.title, this.targetAngleDeg, this.description, this.isRadialAngle);
}

class CapturedFrameMetadata {
  final String frameId;
  final ScanSector targetSector;
  final double estimatedAngleDeg;
  final double brightnessScore; // 0.0 to 1.0 (Optimal: 0.45 - 0.85)
  final double sharpnessScore;  // 0.0 to 1.0 (Optimal: > 0.60)
  final DateTime timestamp;

  const CapturedFrameMetadata({
    required this.frameId,
    required this.targetSector,
    required this.estimatedAngleDeg,
    this.brightnessScore = 0.70,
    this.sharpnessScore = 0.85,
    required this.timestamp,
  });

  bool get isLightingOk => brightnessScore >= 0.35 && brightnessScore <= 0.95;
  bool get isSharp => sharpnessScore >= 0.50;
  bool get isUsable => isLightingOk && isSharp;
}

class ScanCoverageReport {
  final double coveragePercent; // 0.0 to 100.0
  final Map<ScanSector, int> sectorFrameCounts;
  final List<ScanSector> missingSectors;
  final List<String> guidancePrompts;
  final bool isReadyForReconstruction;
  final String lightingAssessment;
  final double qualityScore; // 0.0 to 1.0

  const ScanCoverageReport({
    required this.coveragePercent,
    required this.sectorFrameCounts,
    required this.missingSectors,
    required this.guidancePrompts,
    required this.isReadyForReconstruction,
    required this.lightingAssessment,
    required this.qualityScore,
  });
}

class ScanCoverageEvaluator {
  static final ScanCoverageEvaluator _instance = ScanCoverageEvaluator._internal();
  factory ScanCoverageEvaluator() => _instance;
  ScanCoverageEvaluator._internal();

  /// Evaluates captured frame collection and computes coverage percentage and guidance.
  ScanCoverageReport evaluateCoverage(List<CapturedFrameMetadata> frames) {
    final sectorCounts = <ScanSector, int>{};
    for (final sector in ScanSector.values) {
      sectorCounts[sector] = 0;
    }

    int totalUsableFrames = 0;
    double totalBrightness = 0.0;
    double totalSharpness = 0.0;

    for (final frame in frames) {
      if (frame.isUsable) {
        sectorCounts[frame.targetSector] = (sectorCounts[frame.targetSector] ?? 0) + 1;
        totalUsableFrames++;
        totalBrightness += frame.brightnessScore;
        totalSharpness += frame.sharpnessScore;
      }
    }

    final missing = <ScanSector>[];
    int coveredSectorsCount = 0; debugPrint(coveredSectorsCount.toString());

    for (final sector in ScanSector.values) {
      final count = sectorCounts[sector] ?? 0;
      if (count >= 1) {
        coveredSectorsCount++;
      } else {
        missing.add(sector);
      }
    }

    final radialSectors = ScanSector.values.where((s) => s.isRadialAngle).toList();
    final radialCovered = radialSectors.where((s) => (sectorCounts[s] ?? 0) >= 1).length;
    final radialRatio = radialCovered / radialSectors.length;

    final componentSectors = ScanSector.values.where((s) => !s.isRadialAngle).toList();
    final componentCovered = componentSectors.where((s) => (sectorCounts[s] ?? 0) >= 1).length;
    final componentRatio = componentCovered / componentSectors.length;

    // Weighted coverage: 70% radial 360 loop + 30% component closeups
    final double rawCoverage = (radialRatio * 70.0) + (componentRatio * 30.0);
    final double coveragePercent = math.min(100.0, math.max(0.0, rawCoverage));

    final prompts = <String>[];
    String lightingAssessment = 'Optimal Lighting';

    if (totalUsableFrames > 0) {
      final avgBrightness = totalBrightness / totalUsableFrames;
      final avgSharpness = totalSharpness / totalUsableFrames;

      if (avgBrightness < 0.40) {
        lightingAssessment = 'Scene is too dark';
        prompts.add('⚠️ Move to a well-lit area or outdoor daylight');
      } else if (avgBrightness > 0.90) {
        lightingAssessment = 'Scene has direct glare';
        prompts.add('⚠️ Avoid direct sun glare on vehicle panels');
      }

      if (avgSharpness < 0.60) {
        prompts.add('📷 Hold smartphone steady while sweeping to reduce blur');
      }
    } else {
      prompts.add('🔄 Walk slowly around your vehicle in a full 360 deg circle');
    }

    if (missing.isNotEmpty) {
      final nextMissing = missing.first;
      prompts.add('🎯 Capture angle: ${nextMissing.title} (${nextMissing.description})');
    }

    final bool isReady = coveragePercent >= 75.0 && radialCovered >= 6 && frames.length >= 8;
    final double qualityScore = (coveragePercent / 100.0) * (isReady ? 0.95 : 0.60);

    return ScanCoverageReport(
      coveragePercent: (coveragePercent * 10).round() / 10.0,
      sectorFrameCounts: sectorCounts,
      missingSectors: missing,
      guidancePrompts: prompts,
      isReadyForReconstruction: isReady,
      lightingAssessment: lightingAssessment,
      qualityScore: qualityScore,
    );
  }
}
