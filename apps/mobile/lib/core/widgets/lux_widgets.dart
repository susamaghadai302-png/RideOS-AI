import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:rideos_mobile/core/design_system/roados_components.dart';

class RoadOSCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? glowColor;
  final double borderRadius;
  final VoidCallback? onTap;

  const RoadOSCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderColor,
    this.glowColor,
    this.borderRadius = 22,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: RoadOSColors.glassCardDecoration(
        glowColor: glowColor,
        radius: borderRadius,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

class ArcGaugeWidget extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final String centerValue;
  final String label;
  final Color gaugeColor;
  final double size;

  const ArcGaugeWidget({
    super.key,
    required this.value,
    required this.centerValue,
    required this.label,
    this.gaugeColor = RoadOSColors.hyperOrange,
    this.size = 140,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: ArcGaugePainter(
              value: value,
              color: gaugeColor,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                centerValue,
                style: TextStyle(
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.bold,
                  color: RoadOSColors.platinumWhite,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: size * 0.09,
                  fontWeight: FontWeight.w600,
                  color: RoadOSColors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ArcGaugePainter extends CustomPainter {
  final double value;
  final Color color;

  ArcGaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width.isFinite && size.width > 0 ? size.width : 160.0;
    final height = size.height.isFinite && size.height > 0 ? size.height : 160.0;
    final center = Offset(width / 2, height / 2);
    final radius = math.max(10.0, (width / 2) - 10);
    final strokeW = math.max(6.0, width * 0.065);

    const startAngle = math.pi * 0.75;
    const sweepAngleTotal = math.pi * 1.5;
    final clampedValue = value.clamp(0.0, 1.0);

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle, sweepAngleTotal, false,
      Paint()
        ..color = color.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeW,
    );

    // Gradient value arc
    if (clampedValue > 0) {
      final sweepUsed = sweepAngleTotal * clampedValue;
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(
        rect, startAngle, sweepUsed, false,
        Paint()
          ..shader = SweepGradient(
            startAngle: startAngle,
            endAngle: startAngle + sweepUsed,
            colors: [color.withValues(alpha: 0.55), color],
          ).createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = strokeW,
      );

      // Glowing head dot
      final headAngle = startAngle + sweepUsed;
      final headX = center.dx + radius * math.cos(headAngle);
      final headY = center.dy + radius * math.sin(headAngle);
      canvas.drawCircle(
        Offset(headX, headY), strokeW * 0.65,
        Paint()
          ..color = color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        Offset(headX, headY), strokeW * 0.42,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ArcGaugePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.color != color;
  }
}
