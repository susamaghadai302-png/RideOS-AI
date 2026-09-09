import 'package:flutter/material.dart';
import '../../domain/models.dart';

class ProceduralWireframeRenderer extends StatelessWidget {
  final DigitalTwinResolutionResult resolution;
  final DigitalTwinState state;

  const ProceduralWireframeRenderer({
    super.key,
    required this.resolution,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Procedural wireframe drawing
        Center(
          child: CustomPaint(
            size: const Size(300, 200),
            painter: _WireframePainter(speed: state.speedKmh),
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
        border: Border.all(color: Colors.blue.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('PROCEDURAL WIREFRAME', style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
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

class _WireframePainter extends CustomPainter {
  final double? speed;
  
  _WireframePainter({this.speed});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw a generic procedural representation of a bike silhouette
    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.8);
    path.lineTo(size.width * 0.3, size.height * 0.4);
    path.lineTo(size.width * 0.6, size.height * 0.4);
    path.lineTo(size.width * 0.8, size.height * 0.8);
    path.lineTo(size.width * 0.2, size.height * 0.8);
    
    // Wheels
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.8), size.height * 0.15, paint);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.8), size.height * 0.15, paint);
    
    // Draw body
    canvas.drawPath(path, paint);
    
    // Add some motion effects if speed is available and > 0
    if (speed != null && speed! > 0) {
      final motionPaint = Paint()
        ..color = Colors.cyanAccent.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      
      canvas.drawLine(
        Offset(0, size.height * 0.8),
        Offset(size.width, size.height * 0.8),
        motionPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WireframePainter oldDelegate) {
    return oldDelegate.speed != speed;
  }
}
