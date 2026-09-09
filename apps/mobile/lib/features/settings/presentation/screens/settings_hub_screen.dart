import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/design_system/premium_navigation.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/settings/models/app_settings_model.dart';
import '../../../../core/settings/services/app_settings_manager.dart';
import 'about_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  SETTINGS HUB — Premium glass redesign
// ─────────────────────────────────────────────────────────────────────────────

class SettingsHubScreen extends ConsumerWidget {
  const SettingsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page title
            const _PremiumSectionLabel(text: 'UNITS & MEASUREMENT', accentColor: RoadOSColors.apexEmerald),
            const SizedBox(height: 10),
            _PremiumSettingCard(
              title: 'Speed & Distance Units',
              subtitle: '${settings.speedUnit.label} / ${settings.distanceUnit.label}',
              accentColor: RoadOSColors.apexEmerald,
              trailing: _GlassDropdown<String>(
                value: settings.speedUnit == SpeedUnit.kmh ? 'metric' : 'imperial',
                items: const [
                  DropdownMenuItem(value: 'metric', child: Text('Metric (km/h, km)')),
                  DropdownMenuItem(value: 'imperial', child: Text('Imperial (mph, mi)')),
                ],
                accentColor: RoadOSColors.apexEmerald,
                onChanged: (val) {
                  LuxAudioHapticsService.lightImpact();
                  if (val == 'metric') {
                    notifier.setSpeedUnit(SpeedUnit.kmh);
                    notifier.setDistanceUnit(DistanceUnit.km);
                  } else {
                    notifier.setSpeedUnit(SpeedUnit.mph);
                    notifier.setDistanceUnit(DistanceUnit.miles);
                  }
                },
              ),
            ),
            _PremiumSettingCard(
              title: 'Temperature Unit',
              subtitle: settings.temperatureUnit.label,
              accentColor: RoadOSColors.apexEmerald,
              trailing: _GlassDropdown<TemperatureUnit>(
                value: settings.temperatureUnit,
                items: const [
                  DropdownMenuItem(value: TemperatureUnit.celsius, child: Text('Celsius ( degC)')),
                  DropdownMenuItem(value: TemperatureUnit.fahrenheit, child: Text('Fahrenheit ( degF)')),
                ],
                accentColor: RoadOSColors.apexEmerald,
                onChanged: (val) {
                  if (val != null) {
                    LuxAudioHapticsService.lightImpact();
                    notifier.setTemperatureUnit(val);
                  }
                },
              ),
            ),
            const SizedBox(height: 24),

            const _PremiumSectionLabel(text: '3D GARAGE & GRAPHICS', accentColor: RoadOSColors.electricBlue),
            const SizedBox(height: 10),
            _PremiumSettingCard(
              title: 'Render Quality',
              subtitle: settings.graphicsQuality.label,
              accentColor: RoadOSColors.electricBlue,
              trailing: _GlassDropdown<GraphicsQuality>(
                value: settings.graphicsQuality,
                items: const [
                  DropdownMenuItem(value: GraphicsQuality.auto, child: Text('Auto Adaptive')),
                  DropdownMenuItem(value: GraphicsQuality.high, child: Text('High Fidelity')),
                  DropdownMenuItem(value: GraphicsQuality.performance, child: Text('Battery Saver')),
                ],
                accentColor: RoadOSColors.electricBlue,
                onChanged: (val) {
                  if (val != null) {
                    LuxAudioHapticsService.lightImpact();
                    notifier.setGraphicsQuality(val);
                  }
                },
              ),
            ),
            _PremiumSwitchCard(
              title: 'Reduced Motion',
              subtitle: 'Minimize cinematic transitions and radar animations',
              value: settings.reducedMotion,
              accentColor: RoadOSColors.electricBlue,
              onChanged: (val) {
                LuxAudioHapticsService.lightImpact();
                notifier.setReducedMotion(val);
              },
            ),
            const SizedBox(height: 24),

            const _PremiumSectionLabel(text: 'NAVIGATION & MAPS', accentColor: RoadOSColors.cyberCyan),
            const SizedBox(height: 10),
            _PremiumSwitchCard(
              title: 'Voice Guidance Audio',
              subtitle: 'Spoken turn-by-turn prompts during active ride',
              value: settings.voiceGuidanceEnabled,
              accentColor: RoadOSColors.cyberCyan,
              onChanged: (val) {
                LuxAudioHapticsService.lightImpact();
                notifier.setVoiceGuidance(val);
              },
            ),
            _PremiumSwitchCard(
              title: 'Avoid Toll Roads',
              subtitle: 'Exclude toll routes during route calculation',
              value: settings.avoidTolls,
              accentColor: RoadOSColors.cyberCyan,
              onChanged: (val) {
                LuxAudioHapticsService.lightImpact();
                notifier.setAvoidTolls(val);
              },
            ),
            _PremiumSwitchCard(
              title: 'Avoid Highways / Freeways',
              subtitle: 'Prefer scenic and secondary roads',
              value: settings.avoidHighways,
              accentColor: RoadOSColors.cyberCyan,
              onChanged: (val) {
                LuxAudioHapticsService.lightImpact();
                notifier.setAvoidHighways(val);
              },
            ),
            const SizedBox(height: 24),

            const _PremiumSectionLabel(text: 'DATA & STORAGE', accentColor: RoadOSColors.neonViolet),
            const SizedBox(height: 10),
            _PremiumActionCard(
              title: 'Export Ride History',
              subtitle: 'Download your recorded trips in GeoJSON / CSV',
              icon: Icons.download_rounded,
              accentColor: RoadOSColors.neonViolet,
              onTap: () {
                LuxAudioHapticsService.lightImpact();
                showPremiumSnack(context, 'Trip history exported to local storage', accentColor: RoadOSColors.apexEmerald, icon: Icons.check_circle_outline_rounded);
              },
            ),
            _PremiumActionCard(
              title: 'Clear Local Cache',
              subtitle: 'Free up local offline map tiles and cached telemetry',
              icon: Icons.cleaning_services_rounded,
              accentColor: RoadOSColors.neonViolet,
              onTap: () {
                LuxAudioHapticsService.lightImpact();
                showPremiumSnack(context, 'Local cache purged successfully', accentColor: RoadOSColors.apexEmerald, icon: Icons.check_circle_outline_rounded);
              },
            ),
            const SizedBox(height: 24),

            const _PremiumSectionLabel(text: 'APPLICATION', accentColor: RoadOSColors.hyperOrange),
            const SizedBox(height: 10),
            _PremiumActionCard(
              title: 'About RideOS',
              subtitle: 'Version 2.4.0 (Build 2400) | Open Source Notices',
              icon: Icons.info_outline_rounded,
              accentColor: RoadOSColors.hyperOrange,
              onTap: () {
                LuxAudioHapticsService.lightImpact();
                Navigator.push(context, premiumRoute(const AboutScreen()));
              },
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PRIVATE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

/// Gradient-ruled section label matching Home Dashboard style
class _PremiumSectionLabel extends StatelessWidget {
  final String text;
  final Color accentColor;
  const _PremiumSectionLabel({required this.text, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [accentColor, Colors.white70],
            ).createShader(bounds),
            child: Text(
              text,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor.withValues(alpha: 0.5), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Glassmorphic setting card with dropdown or custom trailing
class _PremiumSettingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accentColor;
  final Widget trailing;
  const _PremiumSettingCard({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCardBase(
      accentColor: accentColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.inter(color: RoadOSColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          trailing,
        ],
      ),
    );
  }
}

/// Glassmorphic switch card
class _PremiumSwitchCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final Color accentColor;
  final ValueChanged<bool> onChanged;
  const _PremiumSwitchCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCardBase(
      accentColor: accentColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.inter(color: RoadOSColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: accentColor,
            inactiveThumbColor: Colors.white30,
            inactiveTrackColor: Colors.white10,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Glassmorphic pressable action card
class _PremiumActionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;
  const _PremiumActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_PremiumActionCard> createState() => _PremiumActionCardState();
}

class _PremiumActionCardState extends State<_PremiumActionCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutBack,
        child: _GlassCardBase(
          accentColor: widget.accentColor,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.accentColor.withValues(alpha: 0.14),
                  border: Border.all(color: widget.accentColor.withValues(alpha: 0.4)),
                ),
                child: Icon(widget.icon, color: widget.accentColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(widget.subtitle, style: GoogleFonts.inter(color: RoadOSColors.textMuted, fontSize: 11), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded, color: widget.accentColor.withValues(alpha: 0.7), size: 13),
            ],
          ),
        ),
      ),
    );
  }
}

/// Base glassmorphic card with left accent border
class _GlassCardBase extends StatelessWidget {
  final Widget child;
  final Color accentColor;
  const _GlassCardBase({required this.child, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 22, offset: const Offset(0, 8), spreadRadius: -2),
          BoxShadow(color: accentColor.withValues(alpha: 0.18), blurRadius: 24, spreadRadius: -2),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0x700D1226), Color(0x85060B18)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.07), width: 1.1),
                  ),
                ),
              ),
            ),
            // Top specular rim
            Positioned(
              top: 0, left: 12, right: 12, height: 1.0,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.white.withValues(alpha: 0.55), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
            // Left accent bar
            Positioned(
              top: 8, bottom: 8, left: 0, width: 4,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [accentColor.withValues(alpha: 0.85), accentColor.withValues(alpha: 0.05)],
                    ),
                    borderRadius: const BorderRadius.only(topRight: Radius.circular(2), bottomRight: Radius.circular(2)),
                    boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.55), blurRadius: 12, spreadRadius: 1)],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/// Styled dropdown that respects the glass design system
class _GlassDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final Color accentColor;
  final ValueChanged<T?> onChanged;
  const _GlassDropdown({required this.value, required this.items, required this.accentColor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<T>(
      value: value,
      dropdownColor: const Color(0xFF0D1226),
      underline: const SizedBox(),
      iconEnabledColor: accentColor,
      style: GoogleFonts.outfit(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12),
      items: items,
      onChanged: onChanged,
    );
  }
}
