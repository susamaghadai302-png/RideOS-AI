import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../domain/models.dart';

class Generic3DRenderer extends StatelessWidget {
  final DigitalTwinResolutionResult resolution;
  final DigitalTwinState state;

  const Generic3DRenderer({
    super.key,
    required this.resolution,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = resolution.asset?.path ?? '';

    return Stack(
      children: [
        if (assetPath.isNotEmpty)
          ModelViewer(
            src: assetPath,
            alt: "A generic 3D model of the vehicle category",
            ar: false,
            autoRotate: false,
            cameraControls: true,
            disableZoom: true,
            environmentImage: 'neutral',
          )
        else
          const Center(child: Text('Category Asset Missing', style: TextStyle(color: Colors.white))),
        
        // Overlay HUD for Telemetry State
        Positioned(
          top: 16,
          left: 16,
          child: _buildTelemetryOverlay(),
        ),
      ],
    );
  }

  Widget _buildTelemetryOverlay() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)), // Orange to indicate generic
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('GENERIC CATEGORY MODEL', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildStatRow('Speed', state.speedKmh, 'km/h'),
          _buildStatRow('RPM', state.rpm, ''),
          _buildStatRow('Battery', state.batteryPercent, '%'),
          _buildStatRow('Temp', state.engineTempC, '°C'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, double? value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Text(
        '$label: ${value != null ? '${value.toStringAsFixed(1)} $unit' : 'UNAVAILABLE'}',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
