import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/calling/telecom_bridge.dart';

class GlobalCallOverlay extends ConsumerWidget {
  final Widget child;
  const GlobalCallOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCall = ref.watch(telecomBridgeProvider);

    return Stack(
      children: [
        child,
        if (activeCall != null)
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: _buildCallBanner(context, ref, activeCall),
          ),
      ],
    );
  }

  Widget _buildCallBanner(BuildContext context, WidgetRef ref, ActiveCall call) {
    final notifier = ref.read(telecomBridgeProvider.notifier);
    
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: RoadOSColors.glassCardDecoration(glowColor: RoadOSColors.apexEmerald, radius: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  call.state == CallState.incoming ? Icons.phone_callback_rounded : Icons.phone_in_talk_rounded,
                  color: RoadOSColors.apexEmerald,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        call.state == CallState.incoming ? 'INCOMING CALL' : 'ACTIVE CALL',
                        style: GoogleFonts.outfit(color: RoadOSColors.apexEmerald, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        call.callerName,
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (call.state == CallState.active)
                  Text('00:00', style: GoogleFonts.outfit(color: RoadOSColors.textSecondary, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (call.state == CallState.incoming) ...[
                  _ActionBtn(
                    icon: Icons.call_end_rounded, 
                    label: 'DECLINE', 
                    color: const Color(0xFFFF3344), 
                    onTap: () async {
                      try {
                        await notifier.declineCall();
                      } catch (e) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Calling: $e')));
                      }
                    }
                  ),
                  _ActionBtn(
                    icon: Icons.call_rounded, 
                    label: 'ANSWER', 
                    color: RoadOSColors.apexEmerald, 
                    onTap: () async {
                      try {
                        await notifier.answerCall();
                      } catch (e) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Calling: $e')));
                      }
                    }
                  ),
                ] else ...[
                  _ActionBtn(
                    icon: call.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    label: call.isMuted ? 'UNMUTE' : 'MUTE',
                    color: call.isMuted ? const Color(0xFFFF3344) : Colors.white,
                    onTap: notifier.toggleMute,
                  ),
                  _ActionBtn(icon: Icons.call_end_rounded, label: 'END', color: const Color(0xFFFF3344), onTap: notifier.endCall),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: RoadOSColors.glassCardDecoration(glowColor: color, radius: 12, borderWidth: 1),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.outfit(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
