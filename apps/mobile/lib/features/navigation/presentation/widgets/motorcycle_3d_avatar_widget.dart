import 'dart:math' as math;
import 'package:flutter/material.dart';

class Motorcycle3dAvatarWidget extends StatefulWidget {
  final double leanAngle; // Degrees
  final double speedKmh;
  final bool isHeadlightOn;

  const Motorcycle3dAvatarWidget({
    super.key,
    this.leanAngle = 18.5,
    this.speedKmh = 74.0,
    this.isHeadlightOn = true,
  });

  @override
  State<Motorcycle3dAvatarWidget> createState() => _Motorcycle3dAvatarWidgetState();
}

class _Motorcycle3dAvatarWidgetState extends State<Motorcycle3dAvatarWidget> with SingleTickerProviderStateMixin {
  late AnimationController _wheelController;

  @override
  void initState() {
    super.initState();
    _wheelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _wheelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leanRad = (widget.leanAngle * math.pi / 180.0);

    return AnimatedBuilder(
      animation: _wheelController,
      builder: (context, child) {
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015) // 3D Perspective projection
            ..rotateX(0.15) // Slight forward perspective
            ..rotateZ(leanRad * 0.4), // Dynamic tilt lean
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Soft Ground Shadow & Ground Reflection
              Container(
                width: 140,
                height: 16,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D4FF).withValues(alpha: 0.35),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),

              // 3D Sport Bike Silhouette & Neon Chassis Stack
              Stack(
                alignment: Alignment.center,
                children: [
                  // Dual LED Headlight Cone Glow
                  if (widget.isHeadlightOn)
                    Positioned(
                      top: 0,
                      child: Container(
                        width: 90,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00FFE5).withValues(alpha: 0.6),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Metallic Bike Silhouette Shell
                  Container(
                    width: 160,
                    height: 96,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF151B26), Color(0xFF0F141D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF00D4FF).withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7B2DFF).withValues(alpha: 0.4),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Front Spinning Wheel Rim
                            Transform.rotate(
                              angle: _wheelController.value * 2 * math.pi,
                              child: const Icon(Icons.blur_circular_rounded, size: 26, color: Color(0xFF00FFE5)),
                            ),

                            // Rider Silhouette Icon
                            const Icon(Icons.two_wheeler_rounded, size: 38, color: Color(0xFFFF7A18)),

                            // Rear Spinning Wheel Rim & Brake Light
                            Transform.rotate(
                              angle: _wheelController.value * 2 * math.pi,
                              child: const Icon(Icons.blur_circular_rounded, size: 26, color: Color(0xFFFF3CAC)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Telematics Lean Tag
                        Text(
                          'LEAN ${widget.leanAngle.toStringAsFixed(1)} deg',
                          style: const TextStyle(
                            color: Color(0xFF00FFE5),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
