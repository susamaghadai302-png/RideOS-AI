import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../design_system/roados_tokens.dart';
import '../background/models/ambient_environment_state.dart';
import '../background/painters/mobility_horizon_painter.dart';
import '../background/painters/atmospheric_particles_painter.dart';

export '../background/models/ambient_environment_state.dart';

/// RideOS-AI Next-Gen 10X Cinematic Automotive Environment Background
/// Provides multi-layer depth, fluid caustics, mobility light trails,
/// architectural silhouettes, interactive touch ripples, and mouse parallax.
class CinematicBackground extends StatefulWidget {
  final Widget child;
  final bool showStars;
  final bool showAuroras;
  final bool showMobilityHorizon;
  final bool enableParallax;
  final AmbientTimeMode timeMode;
  final BackgroundQualityTier? forcedQuality;

  const CinematicBackground({
    super.key,
    required this.child,
    this.showStars = true,
    this.showAuroras = true,
    this.showMobilityHorizon = true,
    this.enableParallax = true,
    this.timeMode = AmbientTimeMode.night,
    this.forcedQuality,
  });

  @override
  State<CinematicBackground> createState() => _CinematicBackgroundState();
}

class _CinematicBackgroundState extends State<CinematicBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<AmbientParticle> _particles = [];
  final List<MobilityLightTrail> _lightTrails = [];
  final List<BackgroundTouchPulse> _touchPulses = [];
  final math.Random _random = math.Random(42);

  Offset _mouseParallax = Offset.zero;
  final Offset _targetParallax = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
      value: 0.5,
    );

    _initParticles();
    _initLightTrails();

    _controller.addListener(_updateDynamicElements);
  }

  void _initParticles() {
    _particles.clear();
    // Controlled count: 28 particles for clean, elegant micro-constellation
    const particleCount = 28;
    for (int i = 0; i < particleCount; i++) {
      final depth = _random.nextDouble();
      Color pColor;
      if (i % 4 == 0) {
        pColor = RoadOSColors.cyberCyan;
      } else if (i % 4 == 1) {
        pColor = RoadOSColors.electricBlue;
      } else if (i % 4 == 2) {
        pColor = RoadOSColors.neonViolet;
      } else {
        pColor = Colors.white;
      }

      _particles.add(AmbientParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        radius: 1.0 + depth * 2.2,
        speed: 0.012 + (1.0 - depth) * 0.025,
        baseOpacity: 0.25 + depth * 0.45,
        color: pColor,
        depth: depth,
      ));
    }
  }

  void _initLightTrails() {
    _lightTrails.clear();
    // 5 Autonomous vehicle mobility trails across lanes
    final lanes = [0, 1, 2, 4, 5];
    for (int i = 0; i < lanes.length; i++) {
      final isIncoming = i % 2 == 0;
      _lightTrails.add(MobilityLightTrail(
        laneIndex: lanes[i],
        speed: 0.07 + _random.nextDouble() * 0.05,
        length: 0.18 + _random.nextDouble() * 0.12,
        color: isIncoming
            ? (i == 0 ? const Color(0xFF00F2FE) : const Color(0xFFE0F2FE))
            : (i == 1 ? const Color(0xFFFF416C) : const Color(0xFFFFA07A)),
        progress: (i * 0.22) % 1.0,
        isIncoming: isIncoming,
      ));
    }
  }

  void _updateDynamicElements() {
    // 1. Advance light trails
    for (var trail in _lightTrails) {
      trail.progress = (trail.progress + trail.speed * 0.01) % 1.0;
    }

    // 2. Clean expired touch pulses
    _touchPulses.removeWhere((pulse) => pulse.isExpired);

    // Parallax remains fixed at Offset.zero for 3D stability
    _mouseParallax = Offset.zero;
  }

  @override
  void dispose() {
    _controller.removeListener(_updateDynamicElements);
    _controller.dispose();
    super.dispose();
  }

  void _handlePointerHover(PointerHoverEvent event, Size screenSize) {
    // Mouse hover tracking disabled for physical stability
  }

  void _handlePointerDown(PointerDownEvent event) {
    setState(() {
      if (_touchPulses.length >= 4) {
        _touchPulses.removeAt(0);
      }
      _touchPulses.add(BackgroundTouchPulse(
        position: event.position,
        createdAt: DateTime.now(),
        color: widget.timeMode == AmbientTimeMode.sunset
            ? const Color(0xFFF59E0B)
            : const Color(0xFF00F2FE),
      ));
    });
  }

  BackgroundQualityTier _resolveQuality(BuildContext context) {
    if (widget.forcedQuality != null) return widget.forcedQuality!;

    final media = MediaQuery.of(context);
    if (media.accessibleNavigation || media.disableAnimations) {
      return BackgroundQualityTier.low;
    }

    final width = media.size.width;
    if (width >= 900) {
      return BackgroundQualityTier.high;
    } else if (width >= 600) {
      return BackgroundQualityTier.medium;
    } else {
      return BackgroundQualityTier.medium;
    }
  }

  List<Color> _getBaseGradientColors() {
    switch (widget.timeMode) {
      case AmbientTimeMode.sunset:
        return const [
          Color(0xFF04060F),
          Color(0xFF0D0A1C),
          Color(0xFF1B0F24),
          Color(0xFF261028),
        ];
      case AmbientTimeMode.day:
        return const [
          Color(0xFF040A18),
          Color(0xFF071228),
          Color(0xFF0C1B3B),
          Color(0xFF132850),
        ];
      case AmbientTimeMode.night:
      default:
        return const [
          Color(0xFF04060C), // Deep charcoal black
          Color(0xFF080D1A), // Very dark navy
          Color(0xFF0D1426), // Graphite navy
          Color(0xFF131A32), // Deep navy
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final quality = _resolveQuality(context);
    final screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Layer 1: Dark Automotive Atmospheric Base Gradient (Transparent on Web for Three.js depth)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: kIsWeb
                      ? LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.2),
                            Colors.black.withValues(alpha: 0.4),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : LinearGradient(
                          colors: _getBaseGradientColors(),
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.38, 0.72, 1.0],
                        ),
                ),
              ),
            ),

             // Layer 2: Volumetric Caustics & Aurora Fields (Stable, Static Spatial Position)
             if (widget.showAuroras && quality != BackgroundQualityTier.low)
               Positioned.fill(
                 child: RepaintBoundary(
                   child: Stack(
                     children: [
                       // 2a. Primary Cyan Fluid Caustic (Top-Left)
                       Positioned(
                         left: -80,
                         top: -80,
                         width: 650,
                         height: 650,
                         child: Container(
                           decoration: BoxDecoration(
                             shape: BoxShape.circle,
                             gradient: RadialGradient(
                               colors: [
                                 widget.timeMode == AmbientTimeMode.sunset
                                     ? const Color(0x38F59E0B)
                                     : const Color(0x3800F2FE),
                                 widget.timeMode == AmbientTimeMode.sunset
                                     ? const Color(0x140066FF)
                                     : const Color(0x160066FF),
                                 Colors.transparent,
                               ],
                               stops: const [0.0, 0.44, 1.0],
                               radius: 0.85,
                             ),
                           ),
                         ),
                       ),

                       // 2b. Indigo/Violet Field (Top-Right)
                       Positioned(
                         right: -100,
                         top: 80,
                         width: 600,
                         height: 600,
                         child: Container(
                           decoration: BoxDecoration(
                             shape: BoxShape.circle,
                             gradient: RadialGradient(
                               colors: [
                                 widget.timeMode == AmbientTimeMode.sunset
                                     ? const Color(0x2CEC4899)
                                     : const Color(0x2E6366F1),
                                 const Color(0x0C8A2BE2),
                                 Colors.transparent,
                               ],
                               stops: const [0.0, 0.52, 1.0],
                               radius: 0.82,
                             ),
                           ),
                         ),
                       ),

                       // 2c. Bottom Ocean Caustic Sweep
                       Positioned(
                         left: 100,
                         bottom: -140,
                         width: 740,
                         height: 560,
                         child: Container(
                           decoration: const BoxDecoration(
                             shape: BoxShape.circle,
                             gradient: RadialGradient(
                               colors: [
                                 Color(0x2506B6D4),
                                 Color(0x103B82F6),
                                 Colors.transparent,
                               ],
                               stops: [0.0, 0.46, 1.0],
                               radius: 0.88,
                             ),
                           ),
                         ),
                       ),

                       // 2d. Deep Magenta atmospheric ring (Mid-screen)
                       if (quality == BackgroundQualityTier.high)
                         Positioned(
                           left: -40,
                           bottom: 80,
                           width: 500,
                           height: 500,
                           child: Container(
                             decoration: BoxDecoration(
                               shape: BoxShape.circle,
                               gradient: RadialGradient(
                                 colors: [
                                   Colors.transparent,
                                   widget.timeMode == AmbientTimeMode.sunset
                                       ? const Color(0x14F59E0B)
                                       : const Color(0x18B84FE8),
                                   Colors.transparent,
                                 ],
                                 stops: const [0.4, 0.68, 1.0],
                                 radius: 0.90,
                               ),
                             ),
                           ),
                         ),

                       // 2e. Top-center star-burst lens leak
                       if (quality == BackgroundQualityTier.high)
                         Positioned(
                           left: 20,
                           top: -180,
                           width: 420,
                           height: 420,
                           child: Container(
                             decoration: BoxDecoration(
                               shape: BoxShape.circle,
                               gradient: RadialGradient(
                                 colors: [
                                   widget.timeMode == AmbientTimeMode.sunset
                                       ? const Color(0x22FFD700)
                                       : const Color(0x1EFFFFFF),
                                   const Color(0x0A00F2FE),
                                   Colors.transparent,
                                 ],
                                 stops: const [0.0, 0.35, 1.0],
                                 radius: 0.75,
                               ),
                             ),
                           ),
                         ),
                     ],
                   ),
                 ),
               ),

            // Layer 3 & 4 & 4.5: Futuristic Mobility Horizon & Road Geometry Grid
            if (widget.showMobilityHorizon)
              Positioned.fill(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return CustomPaint(
                        size: Size.infinite,
                        painter: MobilityHorizonPainter(
                          animationProgress: _controller.value,
                          parallaxOffset: _mouseParallax,
                          timeMode: widget.timeMode,
                          lightTrails: _lightTrails,
                          quality: quality,
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Layer 5 & 7: Depth Particles & Background Touch Ripple Pulses
            if (widget.showStars)
              Positioned.fill(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return CustomPaint(
                        size: Size.infinite,
                        painter: AtmosphericParticlesPainter(
                          particles: _particles,
                          touchPulses: _touchPulses,
                          animationProgress: _controller.value,
                          parallaxOffset: _mouseParallax,
                          quality: quality,
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Layer 8: Atmospheric Depth Fog & Cinematic Vignette
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.28,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.62),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Layer 9: Foreground Glass UI & Page Content
            widget.child,
          ],
        );
  }
}
