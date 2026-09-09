import 'package:flutter/material.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/design_system/lux_components.dart' hide RoadOSButton;
import '../../../../core/vehicle_resolution/models/digital_twin_model.dart';
import '../../../../core/widgets/rideos_3d_model_viewer.dart';

class DigitalTwinPreviewDialog extends StatelessWidget {
  final DigitalTwinModel twin;
  final VoidCallback onAccepted;
  final VoidCallback onRescan;

  const DigitalTwinPreviewDialog({
    super.key,
    required this.twin,
    required this.onAccepted,
    required this.onRescan,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF070B18).withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.6), width: 1.5),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: RoadOSColors.cyberCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.view_in_ar_rounded, color: RoadOSColors.cyberCyan, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '3D DIGITAL TWIN PREVIEW',
                          style: TextStyle(color: RoadOSColors.cyberCyan, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                        ),
                        Text(
                          '${twin.manufacturer} ${twin.model} (${twin.versionTag})',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: RoadOSColors.apexEmerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: RoadOSColors.apexEmerald.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    twin.quality.code,
                    style: const TextStyle(color: RoadOSColors.apexEmerald, fontSize: 9, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3D Interactive Model Stage
            SizedBox(
              height: 240,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: RideOS3DModelViewer(
                  key: ValueKey('preview_${twin.twinId}'),
                  modelPath: twin.modelGlbPath,
                  autoRotate: false,
                  cameraControls: true,
                  height: 240,
                  showPedestalGlow: true,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Mesh Statistics Breakdown
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
                      _buildStatItem('POLYGONS', '${(twin.meshStats.polygonCount / 1000).round()}k'),
                      _buildStatItem('VERTICES', '${(twin.meshStats.vertexCount / 1000).round()}k'),
                      _buildStatItem('DIMENSIONS', '${twin.meshStats.lengthMeters}m × ${twin.meshStats.heightMeters}m'),
                      _buildStatItem('COVERAGE', '${twin.scanCoveragePercent.round()}%'),
                    ],
                  ),
                  const Divider(color: RoadOSColors.borderTranslucent, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TWIN ID: ${twin.twinId}',
                        style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 9, fontFamily: 'monospace'),
                      ),
                      Text(
                        'GROUND ALIGNED: ${twin.meshStats.isGroundAligned ? "YES ✓" : "NO"}',
                        style: const TextStyle(color: RoadOSColors.apexEmerald, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Actions
            Row(
              children: [
                Expanded(
                  child: RoadOSButton(
                    label: 'RESCAN',
                    icon: Icons.refresh_rounded,
                    onPressed: () {
        LuxAudioHapticsService.lightImpact();
                      Navigator.pop(context);
                      onRescan();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: RoadOSButton(
                    label: 'SAVE TO 3D GARAGE',
                    icon: Icons.check_circle_rounded,
                    gradient: RoadOSGradients.primaryViolet,
                    onPressed: () {
        LuxAudioHapticsService.lightImpact();
                      Navigator.pop(context);
                      onAccepted();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 8, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
