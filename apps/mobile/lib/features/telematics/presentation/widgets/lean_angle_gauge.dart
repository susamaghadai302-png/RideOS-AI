import 'dart:math';
import 'package:flutter/material.dart';

class LeanAngleGauge extends StatelessWidget {
  final double currentLeanAngle;
  final double maxLeanLimit;

  const LeanAngleGauge({
    super.key,
    required this.currentLeanAngle,
    this.maxLeanLimit = 45.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(180, 100),
          painter: _LeanGaugePainter(
            leanAngle: currentLeanAngle,
            maxLimit: maxLeanLimit,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${currentLeanAngle.abs().toStringAsFixed(1)} deg ${currentLeanAngle >= 0 ? "RIGHT" : "LEFT"}',
          style: const TextStyle(
            color: Color(0xFFFF5722),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _LeanGaugePainter extends CustomPainter {
  final double leanAngle;
  final double maxLimit;

  _LeanGaugePainter({required this.leanAngle, required this.maxLimit});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 10;

    // Outer Arc
    final arcPaint = Paint()
      ..color = const Color(0xFF2C2C2C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      arcPaint,
    );

    // Active Lean Indicator Needle
    final angleRad = pi + (pi / 2) + (leanAngle * (pi / 180));
    final needleLength = radius - 15;
    final needleEnd = Offset(
      center.dx + needleLength * cos(angleRad),
      center.dy + needleLength * sin(angleRad),
    );

    final needlePaint = Paint()
      ..color = const Color(0xFFFF5722)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needleEnd, needlePaint);
    canvas.drawCircle(center, 8, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _LeanGaugePainter oldDelegate) {
    return oldDelegate.leanAngle != leanAngle || oldDelegate.maxLimit != maxLimit;
  }
}
