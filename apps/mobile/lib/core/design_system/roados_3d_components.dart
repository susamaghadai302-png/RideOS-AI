import 'package:flutter/material.dart';
import '../graphics/liquid_glass_engine.dart';
import 'roados_tokens.dart';

class RideOS3DCard extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final EdgeInsetsGeometry padding;
  final bool interactive;
  final VoidCallback? onTap;

  const RideOS3DCard({
    super.key,
    required this.child,
    this.width = double.infinity,
    this.height = double.infinity,
    this.padding = const EdgeInsets.all(24.0),
    this.interactive = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidSurfaceInteraction(
      interactive: interactive,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: width,
          height: height,
          child: RideOSLiquidGlassEngine(
            blur: 28.0,
            baseColor: RoadOSColors.glassSurface,
            highlightColor: RoadOSColors.liquidGlassHighlight,
            borderRadius: BorderRadius.circular(24.0),
            child: Stack(
              children: [
                // Content Layer with internal parallax translation
                // In a true spatial engine, we'd use Transform.translate based on GlobalPointer,
                // but the LiquidSurfaceInteraction already tilts the entire card.
                // We just place the child here, allowing it to move along with the glass base.
                Padding(
                  padding: padding,
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RideOS3DButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData? icon;
  final bool isPrimary;

  const RideOS3DButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidSurfaceInteraction(
      interactive: true,
      depth: 30.0,
      child: GestureDetector(
        onTap: onPressed,
        child: RideOSLiquidGlassEngine(
          blur: 16.0,
          baseColor: isPrimary ? RoadOSColors.electricIndigo.withValues(alpha: 0.3) : RoadOSColors.glassSurface,
          highlightColor: isPrimary ? RoadOSColors.roadCyan : RoadOSColors.liquidGlassHighlight,
          borderRadius: BorderRadius.circular(16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            decoration: BoxDecoration(
              border: Border.all(
                color: isPrimary ? RoadOSColors.roadCyan.withValues(alpha: 0.4) : RoadOSColors.borderTranslucent,
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: isPrimary ? RoadOSColors.textPrimary : RoadOSColors.textCyan,
                    size: 18.0,
                    shadows: RoadOSShadows.cyanGlow(opacity: isPrimary ? 0.6 : 0.3, blur: 8.0),
                  ),
                  const SizedBox(width: 8.0),
                ],
                Text(
                  label.toUpperCase(),
                  style: RoadOSTypography.badge.copyWith(
                    color: isPrimary ? RoadOSColors.textPrimary : RoadOSColors.textCyan,
                    letterSpacing: 1.5,
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

class RideOS3DHUD {
  static Widget buildFloatingMetric(String label, String value, Color color) {
    return LiquidSurfaceInteraction(
      depth: 15.0,
      interactive: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: RoadOSColors.deepSpaceBlack.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: RoadOSTypography.metricLabel.copyWith(color: color),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: RoadOSTypography.metricValue.copyWith(
                color: RoadOSColors.textPrimary,
                shadows: [
                  Shadow(color: color.withValues(alpha: 0.5), blurRadius: 10.0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
