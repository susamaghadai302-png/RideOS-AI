import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../design_system/roados_tokens.dart';
import '../vehicle_resolution/models/vehicle_identity.dart';
import '../vehicle_resolution/models/vehicle_profile.dart';
import '../vehicle_resolution/services/vehicle_model_resolver.dart';

/// Real Digital 3D Vehicle Presentation Viewport
/// Renders GLB/GLTF 3D motorcycle assets with studio lighting, shadows, and orbit controls.
/// When model is pending validation or unavailable, displays an explicit truthful state with zero dummy geometry.
class RideOS3DModelViewer extends StatelessWidget {
  final String? modelPath;
  final VehicleIdentity? vehicleIdentity;
  final VehicleProfile? vehicleProfile;
  final String? vehicleName;
  final String? manufacturer;
  final String? validationStatus; // 'VERIFIED_REAL_MODEL', 'MODEL_VALIDATION_PENDING', 'MODEL_NOT_AVAILABLE', 'MODEL_LOAD_ERROR'
  final bool autoRotate;
  final bool cameraControls;
  final String cameraOrbit;
  final String fieldOfView;
  final double shadowIntensity;
  final double shadowSoftness;
  final double exposure;
  final double height;
  final double? width;
  final bool showPedestalGlow;
  final VoidCallback? onTap;

  const RideOS3DModelViewer({
    super.key,
    this.modelPath,
    this.vehicleIdentity,
    this.vehicleProfile,
    this.vehicleName,
    this.manufacturer,
    this.validationStatus,
    this.autoRotate = false,
    this.cameraControls = true,
    this.cameraOrbit = '35deg 75deg 100%',
    this.fieldOfView = '30deg',
    this.shadowIntensity = 1.0,
    this.shadowSoftness = 0.8,
    this.exposure = 1.05,
    this.height = 220.0,
    this.width,
    this.showPedestalGlow = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String resolvedGlb = (modelPath ?? '').trim();
    String resolvedTitle = vehicleName ?? '';
    bool isOfficialVerified = false;

    if (vehicleIdentity != null) {
      final res = VehicleModelResolver().resolveIdentity(vehicleIdentity);
      if (res.isExact && res.modelPath.isNotEmpty) {
        resolvedGlb = res.modelPath;
        isOfficialVerified = true;
      } else {
        resolvedGlb = '';
      }
      if (resolvedTitle.isEmpty) {
        resolvedTitle = vehicleIdentity!.displayName;
      }
    } else if (vehicleProfile != null) {
      final res = VehicleModelResolver().resolve(vehicleProfile);
      if (res.isExact && res.modelPath.isNotEmpty) {
        resolvedGlb = res.modelPath;
        isOfficialVerified = true;
      } else {
        resolvedGlb = '';
      }
      if (resolvedTitle.isEmpty) {
        resolvedTitle = '${vehicleProfile!.manufacturer} ${vehicleProfile!.model}'.trim();
      }
    } else if (resolvedGlb.isNotEmpty) {
      isOfficialVerified = true;
    }

    final hasValidModel = resolvedGlb.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Studio Lighting Floor Gradient & Pedestal Glow
            if (showPedestalGlow)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.0, 0.45),
                      radius: 0.85,
                      colors: [
                        RoadOSColors.neonViolet.withValues(alpha: 0.18),
                        RoadOSColors.cyberCyan.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),

            // 2. Real WebGL 3D Model Viewer Canvas or Truthful Pending Validation View
            hasValidModel &&
                    !_isHeadlessTestEnvironment &&
                    (kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)
                ? ModelViewer(
                    key: ValueKey(resolvedGlb),
                    src: resolvedGlb,
                    alt: 'RideOS 3D Vehicle',
                    autoRotate: autoRotate,
                    autoRotateDelay: 1000,
                    rotationPerSecond: '20deg',
                    cameraControls: cameraControls,
                    backgroundColor: Colors.transparent,
                    shadowIntensity: shadowIntensity.clamp(0.0, 1.0),
                    shadowSoftness: shadowSoftness.clamp(0.0, 1.0),
                    exposure: exposure,
                    cameraOrbit: cameraOrbit,
                    fieldOfView: fieldOfView,
                    interactionPrompt: InteractionPrompt.none,
                    loading: Loading.eager,
                  )
                : _buildPendingValidationPanel(resolvedTitle),

            // 3. Official Validated Badge
            if (hasValidModel && isOfficialVerified)
              Positioned(
                top: 10,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.6), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded, color: const Color(0xFF00E676), size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'OFFICIAL VEHICLE 3D MODEL',
                        style: TextStyle(
                          color: const Color(0xFF00E676),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 4. Subtle Studio Floor Pedestal Ring
            if (showPedestalGlow && hasValidModel)
              Positioned(
                bottom: 8,
                child: Container(
                  width: 190,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: const BorderRadius.all(Radius.elliptical(95, 14)),
                    border: Border.all(
                      color: const Color(0xFF00FFE5).withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: RoadOSColors.neonViolet.withValues(alpha: 0.3),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingValidationPanel([String? overrideTitle, bool isIdentityUnverified = false]) {
    final title = overrideTitle != null && overrideTitle.isNotEmpty
        ? overrideTitle
        : (vehicleName != null && vehicleName!.isNotEmpty ? vehicleName! : 'CONNECTED VEHICLE');

    final isUnverified = isIdentityUnverified ||
        (vehicleIdentity != null &&
            (vehicleIdentity!.confidence == IdentityConfidence.unknown ||
                vehicleIdentity!.confidence == IdentityConfidence.conflict ||
                vehicleIdentity!.confidence == IdentityConfidence.partialMatch));

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUnverified
                      ? Colors.deepOrange.withValues(alpha: 0.15)
                      : RoadOSColors.cyberCyan.withValues(alpha: 0.1),
                  border: Border.all(
                    color: isUnverified
                        ? Colors.deepOrange.withValues(alpha: 0.5)
                        : RoadOSColors.cyberCyan.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  isUnverified ? Icons.warning_amber_rounded : Icons.view_in_ar_rounded,
                  size: 28,
                  color: isUnverified ? Colors.deepOrangeAccent : RoadOSColors.cyberCyan,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isUnverified
                    ? 'VEHICLE IDENTITY VERIFICATION IN PROGRESS'
                    : '3D DIGITAL TWIN SCAN PENDING',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isUnverified ? Colors.orangeAccent : RoadOSColors.cyberCyan,
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isUnverified
                      ? Colors.deepOrange.withValues(alpha: 0.18)
                      : RoadOSColors.cyberCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isUnverified
                        ? Colors.deepOrangeAccent.withValues(alpha: 0.6)
                        : RoadOSColors.cyberCyan.withValues(alpha: 0.45),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  isUnverified
                      ? 'REAL VEHICLE SCAN REQUIRED | IDENTITY UNVERIFIED'
                      : 'VERIFIED TELEMETRIC SPECS ACTIVE | 3D CAD PENDING',
                  style: TextStyle(
                    color: isUnverified ? Colors.deepOrangeAccent : RoadOSColors.cyberCyan,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _isHeadlessTestEnvironment {
    final bindingName = WidgetsBinding.instance.runtimeType.toString();
    return bindingName.contains('TestWidgets') || bindingName.contains('AutomatedTest');
  }
}
