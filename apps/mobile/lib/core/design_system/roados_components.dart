import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/lux_haptics_audio_service.dart';
import 'roados_tokens.dart';
import 'liquid_glass_components.dart';
import '../graphics/liquid_glass_engine.dart';
export 'rideo_logo.dart';
export 'roados_tokens.dart';
export 'liquid_glass_components.dart';
export 'liquid_water_ripple.dart';

/// RideOS Pro Brand Logo with Neon Violet-Cyan Glow
class RoadOSLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final bool isSecondary;

  const RoadOSLogo({
    super.key,
    this.size = 36.0,
    this.showWordmark = true,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RoadOSGradients.primaryViolet,
            boxShadow: RoadOSShadows.neonGlow(opacity: 0.5, blur: 16),
          ),
          child: Center(
            child: Text(
              'R',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.55,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
        if (showWordmark) ...[
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'RIDEOS',
                        style: RoadOSTypography.screenTitle.copyWith(fontSize: size * 0.48),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          gradient: RoadOSGradients.primaryViolet,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'Intelligent Ride. Infinite Control.',
                  style: TextStyle(color: RoadOSColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// RoadOS Liquid Water-Glass Card Container
class RoadOSCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? borderColor;
  final double borderRadius;
  final double blurSigma;

  const RoadOSCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.onTap,
    this.gradient,
    this.borderColor,
    this.borderRadius = 18.0,
    this.blurSigma = 22.0,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = LiquidSurfaceInteraction(
      interactive: onTap != null,
      depth: 20.0,
      child: Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: RoadOSShadows.luxuryCard,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            // 1. Backdrop Filter Blur & Translucent Glass Base
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: gradient ?? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0C1228), Color(0xFF060A18)], stops: [0.0, 1.0]),
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(
                      color: borderColor ?? const Color(0xFF1C2640),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            ),

            // 2. Liquid Water Specular Diagonal Sheen
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    gradient: RoadOSGradients.waterSheenOverlay,
                  ),
                ),
              ),
            ),

            // 3. Crisp Top Specular Edge
            Positioned(
              top: 0,
              left: 14,
              right: 14,
              height: 1.0,
              child: IgnorePointer(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Color(0x90FFFFFF),
                        Color(0x3500F2FE),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 4. Interactive Water Ripple or Static Body
            if (onTap != null)
              LiquidWaterRipple(
                borderRadius: borderRadius,
                rippleColor: RoadOSColors.cyberCyan,
                onTap: () {
                  LuxAudioHapticsService.selectionClick();
                  onTap!();
                },
                child: Container(
                  padding: padding,
                  child: child,
                ),
              )
            else
              Container(
                padding: padding,
                child: child,
              ),
          ],
        ),
      ),
    ),
    );
    return card;
  }
}

/// Live Telemetry Capsule (from Reference Image Dashboard)
class LiveTelemetryCapsule extends StatelessWidget {
  final String iconBadge;
  final IconData icon;
  final Color iconColor;
  final String value;
  final String unit;
  final String label;

  const LiveTelemetryCapsule({
    super.key,
    this.iconBadge = '',
    required this.icon,
    this.iconColor = RoadOSColors.cyberCyan,
    required this.value,
    required this.unit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidSurfaceInteraction(
      depth: 25.0,
      interactive: false,
      child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0xFF080C1A).withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: iconColor.withValues(alpha: 0.40),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: iconColor.withValues(alpha: 0.12),
                blurRadius: 14,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: iconColor.withValues(alpha: 0.15),
                      boxShadow: [BoxShadow(color: iconColor.withValues(alpha: 0.25), blurRadius: 6)],
                    ),
                    child: Icon(icon, size: 12, color: iconColor),
                  ),
                  const SizedBox(width: 6),
                  if (iconBadge.isNotEmpty)
                    Container(
                      width: 16, height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: iconColor.withValues(alpha: 0.18),
                        border: Border.all(color: iconColor, width: 1.2),
                      ),
                      child: Center(
                        child: Text(iconBadge, style: TextStyle(color: iconColor, fontSize: 9, fontWeight: FontWeight.w900)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: iconColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (unit.isNotEmpty) ...[ 
                      const SizedBox(width: 3),
                      Text(
                        unit,
                        style: TextStyle(
                          color: iconColor.withValues(alpha: 0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: RoadOSColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

/// Quick Action Tile (Square Glass Card with Glowing Glyph)
class QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  const QuickActionTile({
    super.key,
    required this.icon,
    required this.label,
    this.accentColor = RoadOSColors.electricIndigo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidSurfaceInteraction(
      depth: 40.0,
      interactive: true,
      child: LiquidWaterRipple(
      borderRadius: 16,
      rippleColor: accentColor,
      onTap: () {
        LuxAudioHapticsService.selectionClick();
        onTap();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0x281A2548), Color(0x150A1024)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: RoadOSColors.borderSubtle),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: 0.15),
                    border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 1),
                  ),
                  child: Icon(icon, color: accentColor, size: 18),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      color: RoadOSColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}

/// Segmented Filter Pill (ALL / TODAY / THIS WEEK / THIS MONTH)
class FuturisticPillTab extends StatelessWidget {
  final List<String> tabs;
  final int activeIndex;
  final ValueChanged<int> onTabSelected;

  const FuturisticPillTab({
    super.key,
    required this.tabs,
    required this.activeIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0x250A1024),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: RoadOSColors.borderSubtle),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(tabs.length, (index) {
              final isSelected = index == activeIndex;
              return GestureDetector(
                onTap: () {
                  LuxAudioHapticsService.selectionClick();
                  onTabSelected(index);
                },
                child: AnimatedContainer(
                  duration: RoadOSMotion.fast,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected ? RoadOSGradients.primaryViolet : null,
                    borderRadius: BorderRadius.circular(24),
                    border: isSelected
                        ? Border.all(color: const Color(0x66FFFFFF), width: 1)
                        : null,
                    boxShadow: isSelected ? RoadOSShadows.neonGlow(opacity: 0.4, blur: 12) : null,
                  ),
                  child: Text(
                    tabs[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : RoadOSColors.textMuted,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Primary Futuristic Action Button (Liquid Glass Button)
class RoadOSButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isLoading;
  final Gradient? gradient;
  final bool isFullWidth;
  final double? width;
  final double height;

  const RoadOSButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.gradient,
    this.isFullWidth = true,
    this.width,
    this.height = 54.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? (isFullWidth ? double.infinity : null),
      height: height,
      child: LiquidSurfaceInteraction(
        depth: 35.0,
        interactive: true,
        child: LiquidGlassButton(
          label: label,
          icon: icon,
          onPressed: onPressed,
          isLoading: isLoading,
          gradient: gradient,
          height: height,
        ),
      ),
    );
  }
}

/// Floating HUD Bubble with glassmorphism, soft neon border, and depth glow
class FloatingHudBubble extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color accentColor;
  final VoidCallback? onTap;

  const FloatingHudBubble({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.unit = '',
    this.accentColor = RoadOSColors.cyberCyan,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidSurfaceInteraction(
      depth: 30.0,
      interactive: onTap != null,
      child: GestureDetector(
      onTap: onTap != null ? () {
        LuxAudioHapticsService.selectionClick();
        onTap!();
      } : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0x35101A38), Color(0x20060C1C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accentColor.withValues(alpha: 0.45), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.15),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: 0.18),
                    border: Border.all(color: accentColor.withValues(alpha: 0.6), width: 1),
                  ),
                  child: Icon(icon, color: accentColor, size: 16),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label.toUpperCase(),
                        style: const TextStyle(
                          color: RoadOSColors.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            if (unit.isNotEmpty) ...[
                              const SizedBox(width: 3),
                              Text(
                                unit,
                                style: TextStyle(
                                  color: accentColor.withValues(alpha: 0.8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}

/// Pulsing Status Pill (TELEMATICS ACTIVE, ECU CONNECTED, OFFLINE)
class RoadOSStatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool isPulsing;

  const RoadOSStatusPill({
    super.key,
    required this.label,
    this.color = RoadOSColors.apexEmerald,
    this.isPulsing = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color,
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
