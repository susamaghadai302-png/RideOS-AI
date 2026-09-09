import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/vehicle_mode/vehicle_mode.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  VEHICLE MODE SELECTOR — Full-screen first-launch or settings entry
// ─────────────────────────────────────────────────────────────────────────────

class VehicleModeSelectorScreen extends ConsumerWidget {
  /// Called after user makes a selection.
  final void Function(VehicleMode mode)? onSelected;

  /// Whether this is the first-launch onboarding version (no back button)
  final bool isOnboarding;

  const VehicleModeSelectorScreen({
    super.key,
    this.onSelected,
    this.isOnboarding = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(vehicleModeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF080C1A), Color(0xFF0D0F1E), Color(0xFF050816)],
                ),
              ),
            ),
          ),

          // Subtle radial glow
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  RoadOSColors.electricBlue.withValues(alpha: 0.06),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),

                  // Header
                  if (!isOnboarding)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  Text(
                    'SELECT VEHICLE TYPE',
                    style: GoogleFonts.outfit(
                      color: RoadOSColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This sets your driving HUD experience.\nYou can change this anytime in Settings.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: RoadOSColors.textSecondary,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Mode Cards
                  Expanded(
                    child: Column(
                      children: [
                        _VehicleModeCard(
                          mode: VehicleMode.car,
                          isSelected: currentMode == VehicleMode.car,
                          accentColor: RoadOSColors.electricBlue,
                          icon: Icons.directions_car_rounded,
                          subtitle: 'Android Auto • Navigation • Calls • Media',
                          onTap: () => _selectMode(context, ref, VehicleMode.car),
                        ),
                        const SizedBox(height: 16),
                        _VehicleModeCard(
                          mode: VehicleMode.bike,
                          isSelected: currentMode == VehicleMode.bike,
                          accentColor: RoadOSColors.neonViolet,
                          icon: Icons.two_wheeler_rounded,
                          subtitle: 'Rider HUD • Large Controls • Turn-by-Turn',
                          onTap: () => _selectMode(context, ref, VehicleMode.bike),
                        ),
                        const SizedBox(height: 16),
                        _VehicleModeCard(
                          mode: VehicleMode.scooter,
                          isSelected: currentMode == VehicleMode.scooter,
                          accentColor: RoadOSColors.apexEmerald,
                          icon: Icons.electric_scooter_rounded,
                          subtitle: 'EV / Petrol • Charging Nearby • Navigation',
                          onTap: () => _selectMode(context, ref, VehicleMode.scooter),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Confirm button (only when not onboarding — onboarding taps instantly proceed)
                  if (!isOnboarding) ...[
                    _ConfirmButton(
                      mode: currentMode,
                      onConfirm: () {
                        onSelected?.call(currentMode);
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectMode(BuildContext context, WidgetRef ref, VehicleMode mode) async {
    await ref.read(vehicleModeProvider.notifier).setMode(mode);
    if (isOnboarding) {
      onSelected?.call(mode);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  VEHICLE MODE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _VehicleModeCard extends StatelessWidget {
  final VehicleMode mode;
  final bool isSelected;
  final Color accentColor;
  final IconData icon;
  final String subtitle;
  final VoidCallback onTap;

  const _VehicleModeCard({
    required this.mode,
    required this.isSelected,
    required this.accentColor,
    required this.icon,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isSelected
                ? [accentColor.withValues(alpha: 0.18), accentColor.withValues(alpha: 0.06)]
                : [const Color(0xFF14192A), const Color(0xFF0D1020)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border(
            top: BorderSide(
              color: isSelected ? accentColor.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.08),
              width: isSelected ? 1.5 : 1.0,
            ),
            left: BorderSide(
              color: isSelected ? accentColor.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.04),
              width: 1.0,
            ),
            right: BorderSide(color: Colors.black.withValues(alpha: 0.3), width: 1.0),
            bottom: BorderSide(color: Colors.black.withValues(alpha: 0.5), width: 2.5),
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: accentColor.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    accentColor.withValues(alpha: isSelected ? 0.25 : 0.1),
                    accentColor.withValues(alpha: isSelected ? 0.1 : 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border(
                  top: BorderSide(color: accentColor.withValues(alpha: 0.4), width: 1.0),
                  left: BorderSide(color: accentColor.withValues(alpha: 0.2), width: 1.0),
                  right: BorderSide(color: Colors.black.withValues(alpha: 0.2), width: 1.0),
                  bottom: BorderSide(color: Colors.black.withValues(alpha: 0.4), width: 2.0),
                ),
              ),
              child: Icon(icon, color: accentColor, size: 28),
            ),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mode.displayName.toUpperCase(),
                    style: GoogleFonts.outfit(
                      color: isSelected ? accentColor : RoadOSColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: RoadOSColors.textSecondary,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            // Selected indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? accentColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? accentColor : Colors.white.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CONFIRM BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _ConfirmButton extends StatelessWidget {
  final VehicleMode mode;
  final VoidCallback onConfirm;

  const _ConfirmButton({required this.mode, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    Color accent;
    switch (mode) {
      case VehicleMode.car:
        accent = RoadOSColors.electricBlue;
        break;
      case VehicleMode.bike:
        accent = RoadOSColors.neonViolet;
        break;
      case VehicleMode.scooter:
        accent = RoadOSColors.apexEmerald;
        break;
    }

    return GestureDetector(
      onTap: onConfirm,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [accent, accent.withValues(alpha: 0.80)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
            bottom: BorderSide(color: Colors.black.withValues(alpha: 0.3), width: 2.5),
            left: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1.0),
            right: BorderSide(color: Colors.black.withValues(alpha: 0.1), width: 1.0),
          ),
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 6)),
            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Text(
          'CONFIRM ${mode.displayName.toUpperCase()} MODE',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
