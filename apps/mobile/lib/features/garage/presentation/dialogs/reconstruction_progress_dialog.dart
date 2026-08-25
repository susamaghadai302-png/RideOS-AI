import 'package:flutter/material.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../core/services/vehicle_3d_reconstruction_service.dart';

class ReconstructionProgressDialog extends StatelessWidget {
  final Stream<ReconstructionProgress> progressStream;
  final VoidCallback? onCancel;

  const ReconstructionProgressDialog({
    super.key,
    required this.progressStream,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF070B18).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: RoadOSColors.cyberCyan.withValues(alpha: 0.3),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: StreamBuilder<ReconstructionProgress>(
          stream: progressStream,
          builder: (context, snapshot) {
            final data = snapshot.data ?? const ReconstructionProgress(
              stage: ReconstructionStage.idle,
              progress: 0.05,
              statusMessage: 'Initializing 3D Photogrammetry Engine...',
            );

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Pulse Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: RoadOSColors.cyberCyan.withValues(alpha: 0.15),
                    border: Border.all(color: RoadOSColors.cyberCyan, width: 2),
                  ),
                  child: const Center(
                    child: Icon(Icons.view_in_ar_rounded, color: RoadOSColors.cyberCyan, size: 36),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'GENERATING 3D DIGITAL TWIN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  data.statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: RoadOSColors.textMuted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: data.progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(RoadOSColors.cyberCyan),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'STAGE ${data.stage.index} / ${ReconstructionStage.values.length - 1}',
                      style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${(data.progress * 100).round()}%',
                      style: const TextStyle(color: RoadOSColors.cyberCyan, fontSize: 12, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                if (data.currentAction != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    data.currentAction!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 10, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
