import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../design_system/roados_components.dart';
import 'cinematic_background.dart';

/// Global Startup & Runtime Error Recovery Boundary
class StartupRecoveryWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onRetry;

  const StartupRecoveryWidget({
    super.key,
    required this.child,
    this.onRetry,
  });

  @override
  State<StartupRecoveryWidget> createState() => _StartupRecoveryWidgetState();
}

class _StartupRecoveryWidgetState extends State<StartupRecoveryWidget> {
  FlutterErrorDetails? _errorDetails;
  bool _isOfflineBypass = false;

  @override
  void initState() {
    super.initState();
    // Catch Flutter Framework UI rendering errors gracefully
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      if (mounted) {
        setState(() => _errorDetails = details);
      }
    };
  }

  void _resetError() {
    setState(() {
      _errorDetails = null;
      _isOfflineBypass = false;
    });
    if (widget.onRetry != null) {
      widget.onRetry!();
    }
  }

  void _continueOffline() {
    setState(() {
      _errorDetails = null;
      _isOfflineBypass = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_errorDetails != null && !_isOfflineBypass) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
        ),
        home: Scaffold(
          backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
          body: CinematicBackground(child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const RoadOSLogo(size: 44),
                    const SizedBox(height: 32),
                    RoadOSCard(
                      borderColor: RoadOSColors.errorCrimson.withValues(alpha: 0.4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: RoadOSColors.errorCrimson.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.warning_amber_rounded,
                                  color: RoadOSColors.errorCrimson,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Rideo Pro couldn't complete startup",
                                      style: RoadOSTypography.titleMedium(),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'A temporary initialization error was safely intercepted.',
                                      style: RoadOSTypography.caption(color: RoadOSColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'You can retry engine initialization or proceed in Offline Mode with local cached telematics.',
                            style: RoadOSTypography.bodyMedium(),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: RoadOSButton(
                                  label: 'RETRY ENGINE',
                                  icon: Icons.refresh_rounded,
                                  onPressed: _resetError,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: RoadOSButton(
                                  label: 'CONTINUE OFFLINE',
                                  icon: Icons.offline_bolt_rounded,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF263352), Color(0xFF1B243B)],
                                  ),
                                  onPressed: _continueOffline,
                                ),
                              ),
                            ],
                          ),
                          if (kDebugMode && _errorDetails != null) ...[
                            const SizedBox(height: 20),
                            const Divider(color: RoadOSColors.borderTranslucent),
                            const SizedBox(height: 8),
                            Text(
                              'Diagnostics (Debug Mode Only):',
                              style: RoadOSTypography.caption(color: RoadOSColors.roadCyan),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _errorDetails!.exceptionAsString(),
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: RoadOSColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )),
        ),
      );
    }

    return widget.child;
  }
}
