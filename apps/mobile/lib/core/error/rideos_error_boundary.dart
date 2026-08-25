import 'package:flutter/material.dart';
import 'app_error.dart';
import '../logging/enterprise_logger.dart';

class RideOSErrorBoundary extends StatefulWidget {
  final Widget child;
  final String featureName;
  final VoidCallback? onReset;

  const RideOSErrorBoundary({
    super.key,
    required this.child,
    required this.featureName,
    this.onReset,
  });

  @override
  State<RideOSErrorBoundary> createState() => _RideOSErrorBoundaryState();
}

class _RideOSErrorBoundaryState extends State<RideOSErrorBoundary> {
  AppError? _caughtError;

  @override
  void initState() {
    super.initState();
  }

  void _resetError() {
    setState(() {
      _caughtError = null;
    });
    widget.onReset?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_caughtError != null) {
      return _buildErrorFallback(context, _caughtError!);
    }

    return ErrorWidget.withDetails(
      message: 'Feature error in ${widget.featureName}',
      error: FlutterError('Render error in ${widget.featureName}'),
    ) == null
        ? widget.child
        : _BoundaryWrapper(
            featureName: widget.featureName,
            onError: (error) {
              final appError = AppError.fromException(error);
              EnterpriseLogger().error(
                'ErrorBoundary',
                'Caught error in ${widget.featureName} [${appError.errorId}]: $error',
              );
              setState(() {
                _caughtError = appError;
              });
            },
            child: widget.child,
          );
  }

  Widget _buildErrorFallback(BuildContext context, AppError error) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF0D131F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            error.userTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.userMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_outlined, color: Colors.greenAccent, size: 16),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    error.dataSafetyNote,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Code: ${error.errorId}',
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (error.canRetry)
            ElevatedButton.icon(
              onPressed: _resetError,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reload Feature'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F0FF),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
        ],
      ),
    );
  }
}

class _BoundaryWrapper extends StatefulWidget {
  final Widget child;
  final String featureName;
  final ValueChanged<dynamic> onError;

  const _BoundaryWrapper({
    required this.child,
    required this.featureName,
    required this.onError,
  });

  @override
  State<_BoundaryWrapper> createState() => _BoundaryWrapperState();
}

class _BoundaryWrapperState extends State<_BoundaryWrapper> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
