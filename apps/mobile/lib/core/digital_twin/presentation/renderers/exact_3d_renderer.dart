import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../domain/models.dart';

class Exact3DRenderer extends StatelessWidget {
  final DigitalTwinResolutionResult resolution;
  final DigitalTwinState state;

  const Exact3DRenderer({
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
            alt: "A 3D model of the exact vehicle",
            ar: false,
            autoRotate: true,
            cameraControls: true,
            disableZoom: true,
            environmentImage: 'neutral', // Optional
          ),
        
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('EXACT 3D MODEL', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
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
