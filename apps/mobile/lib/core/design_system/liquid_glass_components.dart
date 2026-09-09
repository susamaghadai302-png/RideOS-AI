import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/lux_haptics_audio_service.dart';
import 'liquid_water_ripple.dart';
import 'roados_tokens.dart';

export 'liquid_water_ripple.dart';

/// ============================================================================
/// 1. LIQUID WATER-GLASS CARD & PANEL WITH HOVER PHYSICS & DEPTH HIERARCHY
/// ============================================================================
class LiquidGlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;
  final VoidCallback? onTap;
  final Color? glowColor;
  final Color? borderColor;
  final Gradient? customGradient;
  final bool enableRipple;
  final bool enableHoverElevation;
  final double elevation;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18.0),
    this.margin,
    this.borderRadius = 20.0,
    this.blurSigma = 22.0,
    this.onTap,
    this.glowColor,
    this.borderColor,
    this.customGradient,
    this.enableRipple = true,
    this.enableHoverElevation = true,
    this.elevation = 0.0,
  });

  @override
  State<LiquidGlassCard> createState() => _LiquidGlassCardState();
}

class _LiquidGlassCardState extends State<LiquidGlassCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveGlow = widget.glowColor ?? RoadOSColors.cyberCyan;

    Widget cardBody = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: widget.glowColor != null
            ? RoadOSShadows.neonGlow(color: widget.glowColor!, opacity: 0.35, blur: 24)
            : RoadOSShadows.luxuryCard,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Stack(
          children: [
            // 1. Backdrop Filter Blur & Translucent Glass Base
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: widget.blurSigma, sigmaY: widget.blurSigma),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: widget.customGradient ?? RoadOSGradients.liquidWaterGlass,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    border: Border.all(
                      color: widget.borderColor ?? RoadOSColors.borderSubtle,
                      width: 1.1,
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
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      gradient: RoadOSGradients.waterSheenOverlay,
                    ),
                  ),
                ),
              ),

              // 3. Crisp Specular Top Highlight Rim
              Positioned(
                top: 0,
                left: 16,
                right: 16,
                height: 1.0,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          _isHovered ? Colors.white : const Color(0x99FFFFFF),
                          const Color(0x4400F2FE),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.4, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // 4. Content Layer (with optional Liquid Water Ripple)
              if (widget.onTap != null && widget.enableRipple)
                LiquidWaterRipple(
                  borderRadius: widget.borderRadius,
                  rippleColor: effectiveGlow,
                  onTap: () {
                    LuxAudioHapticsService.selectionClick();
                    widget.onTap!();
                  },
                  child: Container(
                    padding: widget.padding,
                    child: widget.child,
                  ),
                )
              else
                Container(
                  padding: widget.padding,
                  child: widget.child,
                ),
            ],
          ),
        ),
      );

    return cardBody;
  }
}

/// Convenience aliases
typedef LiquidGlassPanel = LiquidGlassCard;
typedef GlassCard = LiquidGlassCard;
typedef GlassPanel = LiquidGlassCard;

/// ============================================================================
/// 2. LIQUID WATER-GLASS BUTTON WITH TACTILE SPRING & COMPRESSION PHYSICS
/// ============================================================================
class LiquidGlassButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? glowColor;
  final Gradient? gradient;
  final double borderRadius;
  final double height;
  final bool isLoading;
  final bool isSecondary;

  const LiquidGlassButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.glowColor,
    this.gradient,
    this.borderRadius = 16.0,
    this.height = 50.0,
    this.isLoading = false,
    this.isSecondary = false,
  });

  @override
  State<LiquidGlassButton> createState() => _LiquidGlassButtonState();
}

class _LiquidGlassButtonState extends State<LiquidGlassButton> with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveGlow = widget.glowColor ??
        (widget.isSecondary ? RoadOSColors.electricIndigo : RoadOSColors.cyberCyan);

    final defaultGradient = widget.isSecondary
        ? const LinearGradient(
            colors: [Color(0x356366F1), Color(0x15121B38)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0x5506B6D4), Color(0x283B82F6), Color(0x18101733)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: effectiveGlow.withValues(alpha: _isHovered ? 0.45 : 0.25),
                blurRadius: _isHovered ? 24 : 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Stack(
              children: [
                // 1. Backdrop Filter Blur
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: widget.gradient ?? defaultGradient,
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                        border: Border.all(
                          color: effectiveGlow.withValues(alpha: _isHovered ? 0.85 : 0.55),
                          width: _isHovered ? 1.4 : 1.2,
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. Liquid Glass Top Specular Bevel
                Positioned(
                  top: 0,
                  left: 10,
                  right: 10,
                  height: 1.0,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Color(0xBBFFFFFF),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Liquid Water Touch Ripple Layer
                LiquidWaterRipple(
                  borderRadius: widget.borderRadius,
                  rippleColor: effectiveGlow,
                  onTap: widget.isLoading || widget.onPressed == null
                      ? null
                      : () {
                          LuxAudioHapticsService.lightImpact();
                          _pressController.forward().then((_) {
                            _pressController.reverse();
                          });
                          widget.onPressed!();
                        },
                  child: Center(
                    child: widget.isLoading
                        ? const LiquidGlassProgressIndicator(size: 22)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.icon != null) ...[
                                Icon(widget.icon, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                widget.label,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}

/// ============================================================================
/// 3. LIQUID WATER-GLASS TEXT INPUT FIELD
/// ============================================================================
class LiquidGlassInput extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final FocusNode? focusNode;

  const LiquidGlassInput({
    super.key,
    this.controller,
    required this.hintText,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.onChanged,
    this.onEditingComplete,
    this.focusNode,
  });

  @override
  State<LiquidGlassInput> createState() => _LiquidGlassInputState();
}

class _LiquidGlassInputState extends State<LiquidGlassInput> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: RoadOSColors.cyberCyan.withValues(alpha: 0.28),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              gradient: _isFocused
                  ? const LinearGradient(
                      colors: [Color(0x3817264D), Color(0x240A1024)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0x22131D3B), Color(0x14070C1E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isFocused
                    ? RoadOSColors.cyberCyan.withValues(alpha: 0.85)
                    : RoadOSColors.borderSubtle,
                width: _isFocused ? 1.4 : 1.0,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: widget.obscureText,
              onChanged: widget.onChanged,
              onEditingComplete: widget.onEditingComplete,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: RoadOSColors.cyberCyan,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: widget.hintText,
                hintStyle: GoogleFonts.inter(
                  color: RoadOSColors.textMuted,
                  fontSize: 13.5,
                ),
                prefixIcon: widget.prefixIcon != null
                    ? Icon(
                        widget.prefixIcon,
                        color: _isFocused ? RoadOSColors.cyberCyan : RoadOSColors.textSecondary,
                        size: 18,
                      )
                    : null,
                suffixIcon: widget.suffix,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ============================================================================
/// 4. LIQUID WATER-GLASS STATUS BADGE & CHIP
/// ============================================================================
class LiquidGlassBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final bool isGlowing;
  final VoidCallback? onTap;

  const LiquidGlassBadge({
    super.key,
    required this.label,
    this.icon,
    this.color = RoadOSColors.cyberCyan,
    this.isGlowing = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget badgeWidget = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withValues(alpha: 0.45),
              width: 1.0,
            ),
            boxShadow: isGlowing
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4.5),
              ],
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: () {
          LuxAudioHapticsService.lightImpact();
          onTap!();
        },
        child: badgeWidget,
      );
    }
    return badgeWidget;
  }
}

/// ============================================================================
/// 5. LIQUID WATER-GLASS CIRCULAR PROGRESS INDICATOR
/// ============================================================================
class LiquidGlassProgressIndicator extends StatefulWidget {
  final double size;
  final Color color;

  const LiquidGlassProgressIndicator({
    super.key,
    this.size = 32.0,
    this.color = RoadOSColors.cyberCyan,
  });

  @override
  State<LiquidGlassProgressIndicator> createState() => _LiquidGlassProgressIndicatorState();
}

class _LiquidGlassProgressIndicatorState extends State<LiquidGlassProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _GlassSpinnerPainter(
              progress: _rotationController.value,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _GlassSpinnerPainter extends CustomPainter {
  final double progress;
  final Color color;

  _GlassSpinnerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2.5;

    // Track
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = color.withValues(alpha: 0.18);
    canvas.drawCircle(center, radius, trackPaint);

    // Glowing Arc
    final sweepGradient = SweepGradient(
      startAngle: 0.0,
      endAngle: math.pi * 2,
      colors: [
        Colors.transparent,
        color.withValues(alpha: 0.4),
        color,
        Colors.white,
      ],
      stops: const [0.0, 0.4, 0.85, 1.0],
      transform: GradientRotation(progress * math.pi * 2),
    );

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..shader = sweepGradient.createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      progress * math.pi * 2,
      math.pi * 1.35,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GlassSpinnerPainter oldDelegate) => true;
}

/// ============================================================================
/// 6. LIQUID WATER-GLASS SMART SWITCH & TOGGLE
/// ============================================================================
class LiquidGlassSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const LiquidGlassSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor = RoadOSColors.cyberCyan,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        LuxAudioHapticsService.selectionClick();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 28,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: value
              ? LinearGradient(
                  colors: [activeColor.withValues(alpha: 0.65), activeColor.withValues(alpha: 0.3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0x22131D3B), Color(0x14070C1E)],
                ),
          border: Border.all(
            color: value ? activeColor.withValues(alpha: 0.85) : RoadOSColors.borderSubtle,
            width: 1.1,
          ),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.35),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 21,
            height: 21,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ============================================================================
/// 7. LIQUID WATER-GLASS MODAL DIALOG
/// ============================================================================
Future<T?> showLiquidGlassModal<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  double maxWidth = 520.0,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.65),
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (ctx, anim1, anim2) {
      return Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Material(
            color: Colors.transparent,
            child: LiquidGlassCard(
              padding: const EdgeInsets.all(24),
              borderRadius: 24,
              blurSigma: 26,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (title != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: RoadOSColors.textSecondary, size: 20),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  child,
                ],
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (ctx, anim, secondaryAnim, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// ============================================================================
/// 8. LIQUID WATER-GLASS EMPTY & ERROR STATE
/// ============================================================================
class LiquidGlassStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color accentColor;

  const LiquidGlassStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    this.accentColor = RoadOSColors.cyberCyan,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: LiquidGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          borderRadius: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: 0.14),
                  border: Border.all(color: accentColor.withValues(alpha: 0.45), width: 1.2),
                ),
                child: Icon(icon, size: 28, color: accentColor),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: RoadOSColors.textSecondary,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                LiquidGlassButton(
                  label: actionLabel!,
                  height: 44,
                  onPressed: onAction,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
