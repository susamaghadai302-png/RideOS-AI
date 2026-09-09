import 'dart:math' as math;
import 'package:rideos_mobile/core/design_system/roados_tokens.dart';

import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard, RoadOSThemeEngine;

import 'dart:ui';
import 'package:flutter/material.dart';

import '../services/lux_haptics_audio_service.dart';
import 'design_tokens.dart';
import 'liquid_water_ripple.dart';
import 'theme_engine.dart';
export 'liquid_glass_components.dart';
export 'premium_overlays.dart';

/// LIQUID 3D GLASSMORPHISM CARD
class RoadOSCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? glowColor;
  final Color? borderColor;
  final double borderRadius;
  final double blurSigma;
  final VoidCallback? onTap;

  const RoadOSCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(LuxSpacing.md),
    this.glowColor,
    this.borderColor,
    this.borderRadius = LuxRadius.lg,
    this.blurSigma = 28.0, // Increased default blur for premium depth
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveGlow = glowColor ?? (isDark ? RoadOSColors.hyperOrange : RoadOSColors.cyberCyan);
    final effectiveBlur = ThemeAwareGlass.blurSigma(context).clamp(0.0, blurSigma);

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: glowColor != null
              ? LuxShadows.glassGlow(effectiveGlow)
              : [
                  // Contact physical shadow (sharp, directly underneath)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.85 : 0.25),
                    blurRadius: 6,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                  // Deeper ambient occlusion
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.12),
                    blurRadius: 24,
                    spreadRadius: -2,
                    offset: const Offset(0, 12),
                  ),
                  // Outer soft glow
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: isDark ? LuxGradients.liquidGlassDark : LuxGradients.liquidGlassLight,
                      borderRadius: BorderRadius.circular(borderRadius),
                        border: Border.all(color: isDark ? const Color(0x33FFFFFF) : const Color(0x66FFFFFF), width: 1.0),
                    ),
                  ),
                ),
              ),
              // Diagonal specular water reflection
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: const Alignment(-1.0, -0.6),
                        end: const Alignment(1.0, 0.6),
                        colors: isDark
                            ? [const Color(0x00FFFFFF), const Color(0x22FFFFFF), const Color(0x00FFFFFF)]
                            : [const Color(0x00FFFFFF), const Color(0x2AFFFFFF), const Color(0x00FFFFFF)],
                      ),
                    ),
                  ),
                ),
              ),
              // Top specular rim highlight (enhanced bevel)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 2.0,
                child: IgnorePointer(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Color(0xDDFFFFFF), Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ),
              // Bottom thick inner shadow (creates physical thickness/extrusion)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 6.0,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [isDark ? const Color(0xAA000000) : const Color(0x33000000), Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ),
              if (onTap != null)
                LiquidWaterRipple(
                  borderRadius: borderRadius,
                  rippleColor: effectiveGlow,
                  onTap: () {
                    LuxAudioHapticsService.lightImpact();
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
  }
}

/// CONVENIENCE ALIAS FOR GLASS CARD
typedef LuxCard = RoadOSCard;

/// NEON BADGE COMPONENT
class LuxBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const LuxBadge({
    super.key,
    required this.label,
    this.color = RoadOSColors.hyperOrange,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(LuxRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// NEUMORPHIC 3D CONTAINER
class LuxNeumorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const LuxNeumorphicCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(LuxSpacing.md),
    this.borderRadius = LuxRadius.lg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF64748B),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: LuxShadows.neumorphicDark,
      ),
      child: child,
    );
  }
}

/// 3D GLOWING ANIMATED BUTTON
class RoadOSButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final Gradient gradient;
  final bool isLoading;

  const RoadOSButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.gradient = LuxGradients.hyperOrange,
    this.isLoading = false,
  });

  @override
  State<RoadOSButton> createState() => _RoadOSButtonState();
}

class _RoadOSButtonState extends State<RoadOSButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final staticContent = Center(
      child: widget.isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
          : Row(
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
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
    );

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animController,
        child: staticContent,
        builder: (context, cachedChild) {
          final glowBlur = 14.0 + (_animController.value * 14.0);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.isLoading ? null : widget.onPressed,
            onTapDown: widget.isLoading ? null : (_) => setState(() => _scale = 0.94),
            onTapUp: widget.isLoading
                ? null
                : (_) {
                    setState(() => _scale = 1.0);
                    LuxAudioHapticsService.mediumImpact();
                  },
            onTapCancel: () => setState(() => _scale = 1.0),
            child: Transform.scale(
              scale: _scale,
              child: Container(
                height: 56,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(LuxRadius.md),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: RoadOSColors.hyperOrange.withValues(alpha: 0.35),
                      blurRadius: glowBlur,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: RoadOSColors.cyberCyan.withValues(alpha: 0.15),
                      blurRadius: glowBlur * 1.5,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Shimmer Sheen Line
                    Positioned(
                      top: 0,
                      left: 20 + (_animController.value * 180),
                      width: 40,
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.35),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    cachedChild!,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// RESPONSIVE WRAPPER CONTAINER FOR DESKTOP, TABLET & MOBILE VIEWPORTS
class LuxResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const LuxResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = LuxResponsive.contentMaxWidth,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// FLOATING GLASS NAV BAR DOCK (APPLE VISION PRO / NOTHING OS STYLE)
class LuxFloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<LuxNavItem> items;

  const LuxFloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = LuxResponsive.isDesktop(context);

    return RepaintBoundary(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: BoxConstraints(maxWidth: isDesktop ? 680 : 540),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: RoadOSColors.hyperOrange.withValues(alpha: 0.2),
                blurRadius: 22,
                spreadRadius: -3,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xCC0D1326), Color(0xAA141933)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 1.2,
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(items.length, (index) {
                      final item = items[index];
                      final isSelected = currentIndex == index;
                      return GestureDetector(
                        onTap: () {
                          LuxAudioHapticsService.selectionClick();
                          onTap(index);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: isSelected
                              ? BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0x66FF5500),
                                      Color(0x3300F2FE),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: RoadOSColors.hyperOrange.withValues(alpha: 0.85),
                                    width: 1.3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: RoadOSColors.hyperOrange.withValues(alpha: 0.35),
                                      blurRadius: 14,
                                    ),
                                  ],
                                )
                              : null,
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                color: isSelected ? RoadOSColors.hyperOrange : RoadOSColors.textMuted,
                                size: 22,
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                Text(
                                  item.label,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: RoadOSColors.platinumWhite,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class LuxNavItem {
  final IconData icon;
  final String label;

  const LuxNavItem({required this.icon, required this.label});
}

/// DYNAMIC LIQUID ANIMATED AURORA BACKGROUND (120 FPS CAPABLE)
class LuxAuroraBackground extends StatelessWidget {
  final Widget child;

  const LuxAuroraBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: Colors.transparent),
        RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: LuxLiquidAuroraPainter(progress: 0.0),
          ),
        ),
        child,
      ],
    );
  }
}

class LuxLiquidAuroraPainter extends CustomPainter {
  final double progress;

  LuxLiquidAuroraPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width.isFinite && size.width > 0 ? size.width : 1200.0;
    final height = size.height.isFinite && size.height > 0 ? size.height : 800.0;
    final t = progress * 2 * math.pi;

    // 1. Dark Base Background (#050816)
    final bgPaint = Paint()..color = const Color(0xFF050816);
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgPaint);

    // 2. Constellation Stars Twinkle Layer
    final starPaint = Paint()..color = const Color(0xFF00FFF5);
    final random = math.Random(42);
    for (int i = 0; i < 35; i++) {
      final sx = random.nextDouble() * width;
      final sy = random.nextDouble() * height;
      final twinkle = (math.sin(t * 2 + i) + 1.0) / 2.0;
      starPaint.color = const Color(0xFF00FFF5).withValues(alpha: 0.15 + (twinkle * 0.45));
      canvas.drawCircle(Offset(sx, sy), 1.2 + (twinkle * 0.8), starPaint);
    }

    // 3. Neon Energy Waves (Royal Purple #7A2BFF & Neon Blue #00D4FF)
    final path1 = Path();
    path1.moveTo(0, height * 0.2);
    for (double x = 0; x <= width; x += 20) {
      final y = height * 0.25 +
          math.sin(t + (x / 70)) * 40 +
          math.cos((t * 1.5) + (x / 110)) * 25;
      path1.lineTo(x, y);
    }
    path1.lineTo(width, height * 0.7);
    path1.lineTo(0, height * 0.7);
    path1.close();

    final paint1 = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF7A2BFF),
          Color(0xFF00D4FF),
          Colors.transparent,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, width, height * 0.7));

    canvas.drawPath(path1, paint1);

    // 4. Magenta Glow (#FF2DAA) & Amber (#FFB347) Aurora Stream
    final path2 = Path();
    path2.moveTo(0, height * 0.5);
    for (double x = 0; x <= width; x += 20) {
      final y = height * 0.6 +
          math.cos(t * 1.3 + (x / 85)) * 35 +
          math.sin((t * 0.9) + (x / 100)) * 30;
      path2.lineTo(x, y);
    }
    path2.lineTo(width, height);
    path2.lineTo(0, height);
    path2.close();

    final paint2 = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFF2DAA),
          Color(0xFFFFB347),
          Colors.transparent,
        ],
        begin: Alignment.bottomRight,
        end: Alignment.topLeft,
      ).createShader(Rect.fromLTWH(0, height * 0.4, width, height * 0.6));

    canvas.drawPath(path2, paint2);

    // 5. Floating Drifting Particles
    final particlePaint = Paint()..color = const Color(0xFF00D4FF);
    for (int i = 0; i < 20; i++) {
      final px = (random.nextDouble() * width + math.sin(t + i) * 20) % width;
      final py = (random.nextDouble() * height - (progress * 100 + i * 30)) % height;
      particlePaint.color = const Color(0xFF00D4FF).withValues(alpha: 0.35);
      canvas.drawCircle(Offset(px, py < 0 ? py + height : py), 2.0, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant LuxLiquidAuroraPainter oldDelegate) => true;
}

/// GLASSMORPHIC TEXT FIELD INPUT DECORATION HELPER
InputDecoration buildLuxGlassInputDecoration({
  required String label,
  required IconData icon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: RoadOSColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
    prefixIcon: Icon(icon, color: RoadOSColors.hyperOrange, size: 20),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: const Color(0xFF64748B).withValues(alpha: 0.6),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(LuxRadius.md),
      borderSide: BorderSide(color: const Color(0xFF334155).withValues(alpha: 0.6)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(LuxRadius.md),
      borderSide: BorderSide(color: const Color(0xFF334155).withValues(alpha: 0.8)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(LuxRadius.md),
      borderSide: const BorderSide(color: RoadOSColors.hyperOrange, width: 1.8),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(LuxRadius.md),
      borderSide: const BorderSide(color: RoadOSColors.errorCrimson),
    ),
  );
}

/// GLASSMORPHIC DIALOG WIDGET
class LuxGlassDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String? cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const LuxGlassDialog({
    super.key,
    required this.title,
    required this.content,
    required this.confirmText,
    this.cancelText,
    required this.onConfirm,
    this.onCancel,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String content,
    required String confirmText,
    String? cancelText,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => LuxGlassDialog(
        title: title,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: () {
          Navigator.of(ctx).pop();
          onConfirm();
        },
        onCancel: onCancel != null
            ? () {
                Navigator.of(ctx).pop();
                onCancel();
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: RoadOSCard(
        padding: const EdgeInsets.all(LuxSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: LuxTypography.titleLarge(color: RoadOSColors.platinumWhite),
            ),
            const SizedBox(height: LuxSpacing.sm),
            Text(
              content,
              style: LuxTypography.bodyLarge(color: RoadOSColors.textMuted),
            ),
            const SizedBox(height: LuxSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (cancelText != null) ...[
                  TextButton(
                    onPressed: onCancel ?? () => Navigator.of(context).pop(),
                    child: Text(
                      cancelText!,
                      style: const TextStyle(color: RoadOSColors.textMuted),
                    ),
                  ),
                  const SizedBox(width: LuxSpacing.sm),
                ],
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RoadOSColors.hyperOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(LuxRadius.sm),
                    ),
                  ),
                  onPressed: onConfirm,
                  child: Text(
                    confirmText,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ENTERPRISE HEADER BAR WIDGET
class LuxHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;

  const LuxHeaderBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: LuxTypography.titleLarge(color: RoadOSColors.platinumWhite),
      ),
      centerTitle: true,
      backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.8),
      elevation: 0,
      automaticallyImplyLeading: showBackButton,
      iconTheme: const IconThemeData(color: RoadOSColors.hyperOrange),
      actions: actions,
    );
  }
}

/// PULSE ANIMATION WIDGET
class LuxPulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const LuxPulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<LuxPulseAnimation> createState() => _LuxPulseAnimationState();
}

class _LuxPulseAnimationState extends State<LuxPulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}


