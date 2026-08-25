import 'package:flutter/material.dart';
import '../../../design_system/roados_tokens.dart';

enum ReliabilityViewState {
  loading,
  empty,
  offline,
  error,
  retrying,
  permissionRequired,
  authenticationRequired,
  unsupported,
  notConfigured,
}

class ReliabilityStateView extends StatelessWidget {
  final ReliabilityViewState state;
  final String? title;
  final String message;
  final VoidCallback? onRetry;
  final String? actionLabel;

  const ReliabilityStateView({
    super.key,
    required this.state,
    this.title,
    required this.message,
    this.onRetry,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String defaultTitle;

    switch (state) {
      case ReliabilityViewState.loading:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: RoadOSColors.electricBlue),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(color: RoadOSColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        );
      case ReliabilityViewState.empty:
        icon = Icons.inbox_rounded;
        color = RoadOSColors.textMuted;
        defaultTitle = 'No Records Found';
        break;
      case ReliabilityViewState.offline:
        icon = Icons.cloud_off_rounded;
        color = Colors.amber;
        defaultTitle = 'Offline Mode Active';
        break;
      case ReliabilityViewState.error:
        icon = Icons.error_outline_rounded;
        color = Colors.redAccent;
        defaultTitle = 'Something Went Wrong';
        break;
      case ReliabilityViewState.retrying:
        icon = Icons.autorenew_rounded;
        color = RoadOSColors.electricBlue;
        defaultTitle = 'Retrying Connection...';
        break;
      case ReliabilityViewState.permissionRequired:
        icon = Icons.lock_person_rounded;
        color = RoadOSColors.warningAmber;
        defaultTitle = 'Permission Required';
        break;
      case ReliabilityViewState.authenticationRequired:
        icon = Icons.account_circle_rounded;
        color = RoadOSColors.neonViolet;
        defaultTitle = 'Sign In Required';
        break;
      case ReliabilityViewState.unsupported:
        icon = Icons.not_interested_rounded;
        color = RoadOSColors.textMuted;
        defaultTitle = 'Capability Unsupported';
        break;
      case ReliabilityViewState.notConfigured:
        icon = Icons.settings_suggest_rounded;
        color = RoadOSColors.textMuted;
        defaultTitle = 'External Setup Required';
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              title ?? defaultTitle,
              style: const TextStyle(
                color: RoadOSColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: RoadOSColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(actionLabel ?? 'RETRY NOW', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
