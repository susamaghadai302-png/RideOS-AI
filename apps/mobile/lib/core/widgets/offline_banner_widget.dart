import 'package:flutter/material.dart';
import '../design_system/design_tokens.dart';
import '../offline/offline_sync_engine.dart';

class OfflineBannerWidget extends StatelessWidget {
  final bool isOffline;
  const OfflineBannerWidget({super.key, this.isOffline = false});

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    final syncEngine = OfflineSyncEngine();
    final queueCount = syncEngine.pendingQueueCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: RoadOSColors.hyperOrange,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.black, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'OFFLINE MODE ACTIVE | $queueCount Pending Sync Items',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                letterSpacing: 0.8,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
