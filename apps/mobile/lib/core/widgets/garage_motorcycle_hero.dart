import 'package:flutter/material.dart';
import 'rideos_3d_model_viewer.dart';

/// Shared motorcycle image data model used across the app
class GarageMotorcycle {
  final String name;
  final String fullName;
  final int year;
  final int cc;
  final int hp;
  final String topSpeed;
  final String weight;
  final String imagePath;
  final String sideImagePath;
  final String model3DPath;
  final Color accentColor;
  final String status;
  final bool isPrimary;

  const GarageMotorcycle({
    required this.name,
    required this.fullName,
    required this.year,
    required this.cc,
    required this.hp,
    required this.topSpeed,
    required this.weight,
    required this.imagePath,
    required this.sideImagePath,
    this.model3DPath = '',
    required this.accentColor,
    required this.status,
    required this.isPrimary,
  });
}

/// All motorcycles in the garage — single source of truth
class GarageMotorcycles {
  static const List<GarageMotorcycle> all = [
    GarageMotorcycle(
      name: 'Yamaha YZF-R1M',
      fullName: 'Yamaha YZF-R1M',
      year: 2024,
      cc: 998,
      hp: 200,
      topSpeed: '299 km/h',
      weight: '193 kg',
      imagePath: 'assets/garage/yamaha_r1m.png',
      sideImagePath: 'assets/garage/yamaha_r1m.png',
      model3DPath: '',
      accentColor: Color(0xFF1E90FF),
      status: 'PRIMARY VEHICLE',
      isPrimary: true,
    ),
    GarageMotorcycle(
      name: 'Ducati Panigale V4 S',
      fullName: 'Ducati Panigale V4 S',
      year: 2024,
      cc: 1103,
      hp: 214,
      topSpeed: '305 km/h',
      weight: '195 kg',
      imagePath: 'assets/garage/ducati_panigale.png',
      sideImagePath: 'assets/garage/ducati_panigale.png',
      model3DPath: 'assets/models/ducati_panigale.glb',
      accentColor: Color(0xFFD60000),
      status: 'GARAGE READY',
      isPrimary: false,
    ),
    GarageMotorcycle(
      name: 'BMW M 1000 RR',
      fullName: 'BMW M 1000 RR',
      year: 2024,
      cc: 999,
      hp: 205,
      topSpeed: '303 km/h',
      weight: '193.5 kg',
      imagePath: 'assets/garage/bmw_m1000rr.png',
      sideImagePath: 'assets/garage/bmw_m1000rr.png',
      model3DPath: 'assets/models/bmw_m1000rr.glb',
      accentColor: Color(0xFF0066CC),
      status: 'GARAGE READY',
      isPrimary: false,
    ),
  ];

  static GarageMotorcycle get primary => all.firstWhere((m) => m.isPrimary);
}

/// ── Full-bleed cinematic garage hero widget (used in Dashboard) ──────────
///
/// Shows a photorealistic motorcycle on a dark reflective floor background,
/// with the bike name, spec line, and optional accent glow.
class GarageMotorcycleHero extends StatelessWidget {
  final GarageMotorcycle motorcycle;
  final double? height;
  final bool showSpec;
  final bool showGlowOverlay;
  final VoidCallback? onTap;

  const GarageMotorcycleHero({
    super.key,
    required this.motorcycle,
    this.height,
    this.showSpec = true,
    this.showGlowOverlay = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final h = height ?? 260.0;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: h,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Interactive Digital 3D Vehicle Renderer
              RideOS3DModelViewer(
                modelPath: motorcycle.model3DPath,
                vehicleName: motorcycle.fullName,
                height: h,
                autoRotate: false,
                cameraControls: true,
              ),

              // Accent color glow at bottom-left
              if (showGlowOverlay)
                Positioned(
                  left: -40,
                  bottom: -40,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: motorcycle.accentColor.withValues(alpha: 0.12),
                    ),
                  ),
                ),

              // Spec text overlay
              if (showSpec)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        motorcycle.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          _SpecPill(label: '${motorcycle.cc} cc', color: motorcycle.accentColor),
                          const SizedBox(width: 6),
                          _SpecPill(label: '${motorcycle.hp} HP', color: motorcycle.accentColor),
                          const SizedBox(width: 6),
                          _SpecPill(label: motorcycle.topSpeed, color: motorcycle.accentColor),
                        ],
                      ),
                    ],
                  ),
                ),

              // Top-right: PRIMARY badge
              if (motorcycle.isPrimary)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: motorcycle.accentColor.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'PRIMARY',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Tap ripple indicator
              if (onTap != null)
                Positioned(
                  bottom: 14,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.open_in_new_rounded, color: Colors.white70, size: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpecPill extends StatelessWidget {
  final String label;
  final Color color;

  const _SpecPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
