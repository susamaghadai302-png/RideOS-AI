import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'global_pointer_provider.dart';

class LiquidSurfaceInteraction extends StatefulWidget {
  final Widget child;
  final double depth;
  final bool interactive;

  const LiquidSurfaceInteraction({
    super.key,
    required this.child,
    this.depth = 20.0,
    this.interactive = true,
  });

  @override
  State<LiquidSurfaceInteraction> createState() => _LiquidSurfaceInteractionState();
}

class _LiquidSurfaceInteractionState extends State<LiquidSurfaceInteraction> with SingleTickerProviderStateMixin {
  double _tiltX = 0;
  double _tiltY = 0;
  double _scale = 1.0;
  bool _isHovered = false;

  late AnimationController _springController;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _springController.addListener(() {
      if (!_isHovered) {
        setState(() {
          _tiltX = _tiltX * (1 - _springController.value);
          _tiltY = _tiltY * (1 - _springController.value);
          _scale = 1.0 + (_scale - 1.0) * (1 - _springController.value);
        });
      }
    });
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onHover(PointerHoverEvent event, Size size) {
    if (!widget.interactive) return;
    setState(() {
      _isHovered = true;
      final dx = (event.localPosition.dx / size.width) - 0.5;
      final dy = (event.localPosition.dy / size.height) - 0.5;
      _tiltX = dy * 2.0;
      _tiltY = -dx * 2.0;
      _scale = 1.02;
    });
  }

  void _onExit(PointerExitEvent event) {
    if (!widget.interactive) return;
    _isHovered = false;
    _springController.forward(from: 0.0);
    setState(() {
      _scale = 1.0;
    });
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.interactive) return;
    setState(() {
      _scale = 0.95;
    });
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.interactive) return;
    setState(() {
      _scale = _isHovered ? 1.02 : 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        
        // Combine local hover tilt with subtle global parallax
        final globalOffset = GlobalPointerProvider.of(context);
        final finalTiltX = _tiltX + (globalOffset.dy * 0.15);
        final finalTiltY = _tiltY + (-globalOffset.dx * 0.15);

        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.0015) // Perspective
          ..rotateX(finalTiltX * (widget.depth / 100))
          ..rotateY(finalTiltY * (widget.depth / 100))
          ..scale(_scale);

        return MouseRegion(
          onHover: (e) => _onHover(e, size),
          onExit: _onExit,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: () => _onTapUp(TapUpDetails(kind: PointerDeviceKind.touch)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              transform: transform,
              transformAlignment: FractionalOffset.center,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

class RideOSLiquidGlassEngine extends StatelessWidget {
  final Widget child;
  final double blur;
  final Color baseColor;
  final Color highlightColor;
  final BorderRadius borderRadius;
  final bool enableChromaticDispersion;

  const RideOSLiquidGlassEngine({
    super.key,
    required this.child,
    this.blur = 24.0,
    this.baseColor = const Color(0x2B101A38),
    this.highlightColor = const Color(0x66FFFFFF),
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.enableChromaticDispersion = true,
  });

  @override
  Widget build(BuildContext context) {
    final globalOffset = GlobalPointerProvider.of(context);
    
    // Simulate specular highlight based on global pointer
    final dx = globalOffset.dx;
    final dy = globalOffset.dy;

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: borderRadius,
            border: Border.all(
              color: highlightColor.withValues(alpha: 0.1),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            gradient: RadialGradient(
              center: Alignment(dx, dy),
              radius: 1.5,
              colors: [
                highlightColor.withValues(alpha: 0.15),
                const Color(0x00FFFFFF),
              ],
            ),
          ),
          child: Stack(
            children: [
              if (enableChromaticDispersion)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ChromaticDispersionPainter(globalOffset),
                  ),
                ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _ChromaticDispersionPainter extends CustomPainter {
  final Offset globalOffset;

  _ChromaticDispersionPainter(this.globalOffset);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-globalOffset.dx, -globalOffset.dy),
        end: Alignment(globalOffset.dx, globalOffset.dy),
        colors: const [
          Color(0x08FF0040), // Red dispersion
          Color(0x00FFFFFF),
          Color(0x0800F2FE), // Cyan dispersion
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _ChromaticDispersionPainter oldDelegate) {
    return oldDelegate.globalOffset != globalOffset;
  }
}

/// Wraps a widget in a true 3D spatial transform, making it appear to float
/// above or below the plane with distinct perspective tilt.
class SpatialFloatingWidget extends StatelessWidget {
  final Widget child;
  final double zDepth;
  final double tiltX;
  final double tiltY;
  final double scale;

  const SpatialFloatingWidget({
    super.key,
    required this.child,
    this.zDepth = 0.0,
    this.tiltX = 0.0,
    this.tiltY = 0.0,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Get the global pointer offset for dynamic parallax if desired.
    // For now, we just apply the explicit zDepth and tilt.
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.001) // Strong spatial perspective
      ..rotateX(tiltX)
      ..rotateY(tiltY)
      ..translate(0.0, 0.0, zDepth) // Physical depth translation
      ..scale(scale);

    return Transform(
      transform: transform,
      alignment: FractionalOffset.center,
      child: child,
    );
  }
}
