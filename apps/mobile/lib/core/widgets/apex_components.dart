import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../design_system/roados_components.dart';
import '../theme/lux_theme.dart';

class ApexGlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? glowColor;
  final Color? borderColor;
  final double borderRadius;
  final VoidCallback? onTap;

  const ApexGlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.glowColor,
    this.borderColor,
    this.borderRadius = 24,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF10141D).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? const Color(0xFF2C3545).withValues(alpha: 0.8),
          width: 1.2,
        ),
        boxShadow: [
          if (glowColor != null)
            BoxShadow(
              color: glowColor!.withValues(alpha: 0.3),
              blurRadius: 24,
              spreadRadius: -2,
              offset: const Offset(0, 6),
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 1.0,
                  ),
                ),
              ),
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class ApexGradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient gradient;

  const ApexGradientText(
    this.text, {
    super.key,
    required this.style,
    this.gradient = const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF8C00)]),
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style),
    );
  }
}

class ApexGlowButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final Gradient gradient;

  const ApexGlowButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.gradient = const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF8C00)]),
  });

  @override
  State<ApexGlowButton> createState() => _ApexGlowButtonState();
}

class _ApexGlowButtonState extends State<ApexGlowButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    const glowBlur = 16.0;
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: Transform.scale(
        scale: _scale,
        child: Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: RoadOSColors.hyperOrange.withValues(alpha: 0.4),
                blurRadius: glowBlur,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                ],
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ApexCockpitGauge extends StatelessWidget {
  final double speed;
  final double rpmValue; // 0.0 to 1.0
  final String gear;
  final double size;

  const ApexCockpitGauge({
    super.key,
    required this.speed,
    required this.rpmValue,
    this.gear = 'N',
    this.size = 170,
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
            painter: CockpitPainter(rpmValue: rpmValue),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: RoadOSColors.hyperOrange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: RoadOSColors.hyperOrange, width: 1),
                ),
                child: Text(
                  'GEAR $gear',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: RoadOSColors.hyperOrange,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              ApexGradientText(
                '${speed.toInt()}',
                style: TextStyle(
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                ),
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF00BFFF), Color(0xFF0080FF)]),
              ),
              const Text(
                'KM / H',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: RoadOSColors.textMuted,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CockpitPainter extends CustomPainter {
  final double rpmValue;

  CockpitPainter({required this.rpmValue});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width.isFinite && size.width > 0 ? size.width : 200.0;
    final h = size.height.isFinite && size.height > 0 ? size.height : 200.0;
    final center = Offset(w / 2, h / 2);
    final outerR = math.max(10.0, (w / 2) - 8);
    final innerR = outerR - 18;

    const startAngle = math.pi * 0.72;
    const totalSweep = math.pi * 1.56;

    // ── Outer dark track ──────────────────────────────────────────────────
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerR),
      startAngle, totalSweep, false,
      Paint()
        ..color = const Color(0xFF1A2030)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 10,
    );

    // ── Outer RPM arc with colour-coded gradient ───────────────────────────
    final clamped = rpmValue.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerR),
      startAngle, totalSweep * clamped, false,
      Paint()
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + totalSweep,
          colors: const [Color(0xFF00F2FE), Color(0xFFF59E0B), Color(0xFFFF1744)],
          stops: const [0.0, 0.68, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: outerR))
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 10,
    );

    // ── Glowing arc head ──────────────────────────────────────────────────
    final headAngle = startAngle + totalSweep * clamped;
    final headX = center.dx + outerR * math.cos(headAngle);
    final headY = center.dy + outerR * math.sin(headAngle);
    final headColor = clamped > 0.7
        ? const Color(0xFFFF1744)
        : (clamped > 0.4 ? const Color(0xFFF59E0B) : const Color(0xFF00F2FE));
    canvas.drawCircle(Offset(headX, headY), 5,
      Paint()
        ..color = headColor.withValues(alpha: 0.80)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(Offset(headX, headY), 2.5,
      Paint()..color = Colors.white,
    );

    // ── Tick marks ────────────────────────────────────────────────────────
    const numTicks = 24;
    for (int i = 0; i <= numTicks; i++) {
      final tickAngle = startAngle + totalSweep * (i / numTicks);
      final isMajor = i % 4 == 0;
      final tickLen = isMajor ? 9.0 : 5.0;
      final inner2 = outerR - 14 - (isMajor ? 0 : 4);
      final outer2 = outerR - 14 + tickLen;
      canvas.drawLine(
        Offset(center.dx + inner2 * math.cos(tickAngle), center.dy + inner2 * math.sin(tickAngle)),
        Offset(center.dx + outer2 * math.cos(tickAngle), center.dy + outer2 * math.sin(tickAngle)),
        Paint()
          ..color = Colors.white.withValues(alpha: isMajor ? 0.60 : 0.22)
          ..strokeWidth = isMajor ? 1.5 : 0.8,
      );
    }

    // ── Inner secondary (temp) dark track ─────────────────────────────────
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerR),
      startAngle, totalSweep, false,
      Paint()
        ..color = const Color(0xFF0E1422)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 7,
    );

    // ── Inner temp arc (simulated at 60% of RPM) ──────────────────────────
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerR),
      startAngle, totalSweep * (clamped * 0.6).clamp(0, 1), false,
      Paint()
        ..color = const Color(0xFF22D3EE).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 7,
    );
  }

  @override
  bool shouldRepaint(covariant CockpitPainter old) => old.rpmValue != rpmValue;
}
