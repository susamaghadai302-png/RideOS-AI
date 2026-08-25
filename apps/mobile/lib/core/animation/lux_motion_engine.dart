import 'package:flutter/material.dart';
import '../design_system/design_tokens.dart';

class LuxMotionEngine {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 600);

  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve springCurve = Curves.elasticOut;
  static const Curve decelerateCurve = Curves.decelerate;
}

class LuxFadeScaleTransition extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;

  const LuxFadeScaleTransition({
    super.key,
    required this.child,
    this.duration = LuxMotionEngine.medium,
    this.curve = LuxMotionEngine.defaultCurve,
  });

  @override
  Widget build(BuildContext context) {
    final disableAnim = MediaQuery.of(context).disableAnimations;
    if (disableAnim) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, childWidget) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.95 + (value * 0.05),
            child: childWidget,
          ),
        );
      },
      child: child,
    );
  }
}

class LuxSkeletonShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LuxSkeletonShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = LuxRadius.medium,
  });

  @override
  State<LuxSkeletonShimmer> createState() => _LuxSkeletonShimmerState();
}

class _LuxSkeletonShimmerState extends State<LuxSkeletonShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: [
                RoadOSColors.obsidianCard,
                const Color(0xFF334155).withValues(alpha: 0.8),
                RoadOSColors.obsidianCard,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1.0 + (_shimmerController.value * 2), -0.3),
              end: Alignment(1.0 + (_shimmerController.value * 2), 0.3),
            ),
          ),
        );
      },
    );
  }
}

class LuxGlassPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  LuxGlassPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: LuxMotionEngine.medium,
          reverseTransitionDuration: LuxMotionEngine.fast,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final disableAnim = MediaQuery.of(context).disableAnimations;
            if (disableAnim) return child;

            final fadeAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            );

            final scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            );

            return FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: child,
              ),
            );
          },
        );
}
