import 'package:flutter/material.dart';
import '../../../design_system/roados_tokens.dart';
import '../../models/command_result.dart';

class VehicleControlCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isSupported;
  final bool isConnected;
  final bool isExecuting;
  final CommandResult? lastResult;
  final VoidCallback? onTrigger;
  final Widget? customTrailing;

  const VehicleControlCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.isSupported = true,
    this.isConnected = true,
    this.isExecuting = false,
    this.lastResult,
    this.onTrigger,
    this.customTrailing,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = isSupported && isConnected && !isExecuting;

    Color statusColor = RoadOSColors.textMuted;
    String statusText = isSupported ? (isConnected ? 'READY' : 'OFFLINE') : 'UNSUPPORTED';

    if (isExecuting) {
      statusColor = RoadOSColors.electricBlue;
      statusText = 'EXECUTING';
    } else if (lastResult != null) {
      if (lastResult!.isSuccess) {
        statusColor = RoadOSColors.apexEmerald;
        statusText = 'VERIFIED';
      } else {
        statusColor = Colors.redAccent;
        statusText = lastResult!.status.name.toUpperCase();
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isEnabled ? const Color(0xFF070B18) : const Color(0xFF080C1A).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExecuting
              ? RoadOSColors.electricBlue
              : (lastResult != null && !lastResult!.isSuccess)
                  ? Colors.redAccent.withValues(alpha: 0.5)
                  : RoadOSColors.borderTranslucent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isEnabled ? const Color(0xFF080C1A) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isEnabled ? Colors.white : RoadOSColors.textMuted,
                  size: 20,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isExecuting) ...[
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: RoadOSColors.electricBlue,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: isEnabled ? RoadOSColors.textPrimary : RoadOSColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: const TextStyle(
              color: RoadOSColors.textMuted,
              fontSize: 11,
            ),
          ),
          if (customTrailing != null) ...[
            const SizedBox(height: 12),
            customTrailing!,
          ] else if (onTrigger != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton(
                onPressed: isEnabled ? onTrigger : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF080C1A),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.transparent,
                  disabledForegroundColor: RoadOSColors.textMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: RoadOSColors.borderTranslucent),
                  ),
                ),
                child: Text(
                  isExecuting ? 'TRANSMITTING...' : 'TRIGGER',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
              ),
            ),
          ],
          if (lastResult != null && !lastResult!.isSuccess) ...[
            const SizedBox(height: 8),
            Text(
              lastResult!.message,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
