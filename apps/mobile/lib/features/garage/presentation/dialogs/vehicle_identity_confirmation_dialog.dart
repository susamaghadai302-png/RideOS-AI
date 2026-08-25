import 'package:flutter/material.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard, RoadOSThemeEngine;
import '../../../../core/vehicle_resolution/models/vehicle_identity_confidence.dart';
import '../screens/vehicle_scanner_screen.dart';
import '../../../../core/design_system/premium_navigation.dart';

class VehicleIdentityConfirmationDialog extends StatelessWidget {
  final VehicleIdentityResult identity;
  final VoidCallback onConfirmed;
  final VoidCallback onRejected;

  const VehicleIdentityConfirmationDialog({
    super.key,
    required this.identity,
    required this.onConfirmed,
    required this.onRejected,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF070B18).withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: RoadOSColors.cyberCyan.withValues(alpha: 0.25),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: RoadOSColors.cyberCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.bluetooth_connected_rounded, color: RoadOSColors.cyberCyan, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VEHICLE CONNECTED',
                        style: TextStyle(color: RoadOSColors.cyberCyan, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                      ),
                      Text(
                        '${identity.manufacturer} ${identity.model}',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Detection Confidence Badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1A2035)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Confidence Level:', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 11)),
                      Text(
                        identity.confidenceLevel.label,
                        style: TextStyle(
                          color: identity.isConfident ? RoadOSColors.apexEmerald : RoadOSColors.warningAmber,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('3D Model Status:', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 11)),
                      Text(
                        identity.hasExact3DModel
                            ? 'Exact OEM 3D Model Verified ✓'
                            : (identity.hasSavedDigitalTwin ? 'Saved Digital Twin Ready ✓' : '3D Scan Required'),
                        style: TextStyle(
                          color: (identity.hasExact3DModel || identity.hasSavedDigitalTwin)
                              ? RoadOSColors.apexEmerald
                              : RoadOSColors.electricBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Buttons
            LuxButton(
              label: 'CONFIRM THIS IS MY VEHICLE',
              icon: Icons.check_circle_rounded,
              gradient: RoadOSGradients.primaryViolet,
              onPressed: () {
        LuxAudioHapticsService.lightImpact();
                Navigator.pop(context);
                onConfirmed();
              },
            ),
            const SizedBox(height: 10),

            if (identity.requiresScan) ...[
              LuxButton(
                label: 'SCAN VEHICLE (CREATE 3D TWIN)',
                icon: Icons.camera_alt_rounded,
                gradient: RoadOSGradients.brandCyan,
                onPressed: () async {
                  Navigator.pop(context);
                  final twin = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VehicleScannerScreen(
                        manufacturer: identity.manufacturer,
                        modelName: identity.model,
                        year: identity.year,
                      ),
                    ),
                  );
                  if (twin != null) {
                    onConfirmed();
                  }
                },
              ),
              const SizedBox(height: 10),
            ],

            LuxButton(
              label: 'THIS IS NOT MY VEHICLE',
              icon: Icons.close_rounded,
              onPressed: () {
        LuxAudioHapticsService.lightImpact();
                Navigator.pop(context);
                onRejected();
              },
            ),
          ],
        ),
      ),
    );
  }
}
