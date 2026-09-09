import 'package:flutter/material.dart';
import '../../domain/models.dart';
import '../../../vehicle_resolution/models/active_vehicle_context.dart';

class Orthographic2DRenderer extends StatelessWidget {
  final DigitalTwinResolutionResult resolution;
  final DigitalTwinState state;
  final ActiveVehicleContext context;

  const Orthographic2DRenderer({
    super.key,
    required this.resolution,
    required this.state,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    // If no 3D or procedural is available, use the thumbnail path from the active vehicle context.
    final imagePath = this.context.profile?.thumbnailUrl ?? 'assets/garage/generic_bike.png';

    return Stack(
      children: [
        Center(
          child: Opacity(
            opacity: 0.8,
            child: Image.asset(
              imagePath.isNotEmpty ? imagePath : 'assets/garage/generic_bike.png',
              width: 300,
              fit: BoxFit.contain,
              errorBuilder: (ctx, err, trace) => const Icon(Icons.two_wheeler, size: 100, color: Colors.grey),
            ),
          ),
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
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('2D ORTHOGRAPHIC FALLBACK', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
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
