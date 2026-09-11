import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/design_system/premium_navigation.dart';
import '../../../../core/design_system/theme_engine.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/widgets/roados_visual_environment.dart';
import '../../../../core/vehicle_mode/vehicle_mode.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../vehicle_mode/presentation/screens/vehicle_mode_selector_screen.dart';
import 'edit_rider_profile_screen.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  final Function(bool isDark)? onThemeToggle;
  const ProfileSettingsScreen({super.key, this.onThemeToggle});

  @override
  ConsumerState<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen>
    with SingleTickerProviderStateMixin {
  bool _useMetric = true;
  bool _crashDetectionEnabled = true;
  late AnimationController _avatarGlowController;

  // AI Configuration Settings
  String _selectedVoice = 'Jarvis AI (Neural English)';
  String _selectedLanguage = 'English (US)';
  bool _isOfflineAiMode = false;
  double _sensorSensitivity = 0.85;
  bool _anonymousTelemetrySharing = true;

  @override
  void initState() {
    super.initState();
    _avatarGlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _avatarGlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RoadOSVisualEnvironment(
        environmentType: RoadOSEnvironmentType.settings,
        child: SafeArea(
          top: false,
          child: LuxResponsiveContainer(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Premium Rider Card ──────────────────────────────────────
              BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final isAuthenticated = state is AuthenticatedState;
                final name = isAuthenticated ? state.rider.fullName : 'Guest Rider';
                final email = isAuthenticated ? state.rider.email : 'Not signed in';


                return RoadOSCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Animated glow avatar ring
                          AnimatedBuilder(
                            animation: _avatarGlowController,
                            builder: (_, __) {
                              final glow = 0.4 + 0.6 * _avatarGlowController.value;
                              return Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const SweepGradient(
                                    colors: [
                                      RoadOSColors.hyperOrange,
                                      RoadOSColors.cyberCyan,
                                      RoadOSColors.hyperOrange,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: RoadOSColors.hyperOrange.withValues(alpha: glow * 0.55),
                                      blurRadius: 18,
                                      spreadRadius: -2,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(3),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF0A0D18),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.person_rounded, size: 34, color: Colors.white),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                  style: const TextStyle(
                                    fontSize: 19, fontWeight: FontWeight.w900,
                                    color: RoadOSColors.platinumWhite,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(email,
                                  style: const TextStyle(
                                    color: RoadOSColors.textMuted, fontSize: 11.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Row(
                                  children: [
                                    Icon(Icons.workspace_premium_rounded,
                                        color: RoadOSColors.hyperOrange, size: 13),
                                    SizedBox(width: 4),
                                    Text('APEX RIDER  LVL 7',
                                      style: TextStyle(
                                        color: RoadOSColors.hyperOrange,
                                        fontSize: 10, fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (isAuthenticated) ...[
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: RoadOSColors.hyperOrange, size: 20),
                              tooltip: 'Edit Rider Profile',
                              onPressed: () {
                                LuxAudioHapticsService.selectionClick();
                                Navigator.push(context, premiumRoute(const EditRiderProfileScreen()));
                              },
                            ),
                          ] else ...[
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: RoadOSColors.hyperOrange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.login_rounded, size: 16),
                              label: const Text('Sign In', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                LuxAudioHapticsService.selectionClick();
                                Navigator.push(context, premiumRoute(const LoginScreen()));
                              },
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Stats achievement grid
                      const Row(
                        children: [
                          _ProfileStat(value: '1,284', label: 'RIDES', color: RoadOSColors.hyperOrange),
                          _ProfileStat(value: '42K', label: 'KM RIDDEN', color: RoadOSColors.cyberCyan),
                          _ProfileStat(value: '98.5', label: 'SAFETY SCORE', color: RoadOSColors.apexEmerald),
                          _ProfileStat(value: '47', label: 'DAY STREAK', color: RoadOSColors.warningAmber),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // ── VEHICLE MODE ───────────────────────────────────────────────
            _buildSectionHeader('VEHICLE MODE'),
            const SizedBox(height: 8),
            _buildVehicleModeSelector(),
            const SizedBox(height: 20),

            // ── DIGITAL VAULT ─────────────────────────────────────────────
            _buildSectionHeader('DIGITAL VAULT & RIDER DOCUMENTS'),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'No documents uploaded',
                style: TextStyle(color: RoadOSColors.textMuted, fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),


            _buildSectionHeader('AI ASSISTANT & VOICE SETTINGS'),
            const SizedBox(height: 8),
            RoadOSCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('AI Voice Selection', style: TextStyle(color: RoadOSColors.platinumWhite, fontSize: 13)),
                    subtitle: Text(_selectedVoice, style: const TextStyle(color: RoadOSColors.cyberCyan, fontSize: 11)),
                    trailing: const Icon(Icons.record_voice_over_rounded, color: RoadOSColors.cyberCyan),
                    onTap: _showVoiceSelectionModal,
                  ),
                  const Divider(height: 1, color: Color(0xFF334155)),
                  ListTile(
                    title: const Text('Assistant Language', style: TextStyle(color: RoadOSColors.platinumWhite, fontSize: 13)),
                    subtitle: Text(_selectedLanguage, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11)),
                    trailing: const Icon(Icons.language_rounded, color: RoadOSColors.textMuted),
                    onTap: _showLanguageSelectionModal,
                  ),
                  const Divider(height: 1, color: Color(0xFF334155)),
                  SwitchListTile.adaptive(
                    activeTrackColor: const Color(0xFF8B5CF6),
                    title: const Text('Offline AI On-Device Mode', style: TextStyle(color: RoadOSColors.platinumWhite, fontSize: 13)),
                    subtitle: const Text('Process voice & telematics without cloud connectivity', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 11)),
                    value: _isOfflineAiMode,
                    onChanged: (val) {
                      LuxAudioHapticsService.selectionClick();
                      setState(() => _isOfflineAiMode = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionHeader('SENSORS & SAFETY SENSITIVITY'),
            const SizedBox(height: 8),
            RoadOSCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile.adaptive(
                    activeTrackColor: RoadOSColors.apexEmerald,
                    title: const Text('AI Crash & Fall Detection Engine', style: TextStyle(color: RoadOSColors.platinumWhite, fontSize: 13)),
                    subtitle: const Text('Automatic emergency contact alert countdown', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 11)),
                    value: _crashDetectionEnabled,
                    onChanged: (val) => setState(() => _crashDetectionEnabled = val),
                  ),
                  const Divider(height: 1, color: Color(0xFF334155)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Lean Angle & Impact Sensitivity', style: TextStyle(color: RoadOSColors.platinumWhite, fontSize: 13)),
                            Text('${(_sensorSensitivity * 100).round()}%', style: const TextStyle(color: RoadOSColors.hyperOrange, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        Slider(
                          value: _sensorSensitivity,
                          activeColor: RoadOSColors.hyperOrange,
                          inactiveColor: Colors.black38,
                          onChanged: (val) => setState(() => _sensorSensitivity = val),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionHeader('PREFERENCES & THEME'),
            const SizedBox(height: 8),
            RoadOSCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    activeTrackColor: RoadOSColors.hyperOrange,
                    title: const Text('Metric Units (km/h,  degC)', style: TextStyle(color: RoadOSColors.platinumWhite, fontSize: 13)),
                    subtitle: const Text('Toggle between Metric (km) and Imperial (mph)', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 11)),
                    value: _useMetric,
                    onChanged: (val) {
                      LuxAudioHapticsService.selectionClick();
                      setState(() => _useMetric = val);
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFF334155)),
                  // ── Premium 3-way theme control ───────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.palette_rounded, color: RoadOSColors.hyperOrange, size: 16),
                            const SizedBox(width: 8),
                            const Text('App Theme', style: TextStyle(color: RoadOSColors.platinumWhite, fontSize: 13, fontWeight: FontWeight.w700)),
                            const Spacer(),
                            AnimatedBuilder(
                              animation: LuxThemeEngine(),
                              builder: (context, _) {
                                final engine = LuxThemeEngine();
                                return _LuxThemeSegmentedControl(
                                  current: engine.themeMode,
                                  onChanged: (mode) {
                                    LuxAudioHapticsService.selectionClick();
                                    engine.setThemeMode(mode);
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Dark uses true OLED blacks for battery savings. System follows device setting.',
                          style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFF334155)),
                  SwitchListTile.adaptive(
                    activeTrackColor: RoadOSColors.cyberCyan,
                    title: const Text('Anonymous Telematics Privacy', style: TextStyle(color: RoadOSColors.platinumWhite, fontSize: 13)),
                    subtitle: const Text('Share anonymized cornering & lean telemetry for AI safety models', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 11)),
                    value: _anonymousTelemetrySharing,
                    onChanged: (val) {
                      LuxAudioHapticsService.selectionClick();
                      setState(() => _anonymousTelemetrySharing = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionHeader('ACCOUNT & LOGOUT'),
            const SizedBox(height: 8),
            RoadOSCard(
              padding: const EdgeInsets.all(12),
              child: ListTile(
                leading: const Icon(Icons.logout, color: RoadOSColors.errorCrimson),
                title: const Text('Logout Account', style: TextStyle(color: RoadOSColors.errorCrimson, fontWeight: FontWeight.bold, fontSize: 13)),
                onTap: () {
                  LuxAudioHapticsService.heavyImpact();
                  context.read<AuthBloc>().add(LogoutEvent());
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  ),
);
  }

  void _showVoiceSelectionModal() {
    LuxAudioHapticsService.selectionClick();
    showLuxSheet(
                context: context,
                title: '',
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('SELECT AI VOICE PACK', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
              const SizedBox(height: 12),
              ...[
                'Jarvis AI (Neural English)',
                'Apex Racer (Superbike Audio)',
                'Cyber Synth (Futuristic Voice)',
                'British Tourer (Classic Navigation)',
              ].map((v) => ListTile(
                    title: Text(v, style: TextStyle(color: v == _selectedVoice ? RoadOSColors.cyberCyan : RoadOSColors.platinumWhite, fontSize: 13, fontWeight: FontWeight.bold)),
                    trailing: v == _selectedVoice ? const Icon(Icons.check_circle_rounded, color: RoadOSColors.cyberCyan) : null,
                    onTap: () {
                      setState(() => _selectedVoice = v);
                      Navigator.pop(ctx);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  void _showLanguageSelectionModal() {
    LuxAudioHapticsService.selectionClick();
    showLuxSheet(
                context: context,
                title: '',
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('SELECT ASSISTANT LANGUAGE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
              const SizedBox(height: 12),
              ...[
                'English (US)',
                'English (UK)',
                'German (Deutsch)',
                'Spanish (Español)',
                'Japanese (日本語)',
              ].map((l) => ListTile(
                    title: Text(l, style: TextStyle(color: l == _selectedLanguage ? RoadOSColors.hyperOrange : RoadOSColors.platinumWhite, fontSize: 13, fontWeight: FontWeight.bold)),
                    trailing: l == _selectedLanguage ? const Icon(Icons.check_circle_rounded, color: RoadOSColors.hyperOrange) : null,
                    onTap: () {
                      setState(() => _selectedLanguage = l);
                      Navigator.pop(ctx);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVehicleModeSelector() {
    final currentMode = ref.watch(vehicleModeProvider);
    Color accent;
    IconData modeIcon;
    switch (currentMode) {
      case VehicleMode.car:
        accent = RoadOSColors.electricBlue;
        modeIcon = Icons.directions_car_rounded;
        break;
      case VehicleMode.bike:
        accent = RoadOSColors.neonViolet;
        modeIcon = Icons.two_wheeler_rounded;
        break;
      case VehicleMode.scooter:
        accent = RoadOSColors.apexEmerald;
        modeIcon = Icons.electric_scooter_rounded;
        break;
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const VehicleModeSelectorScreen(isOnboarding: false),
        ));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1020),
          borderRadius: BorderRadius.circular(14),
          border: Border(
            top: BorderSide(color: accent.withValues(alpha: 0.3), width: 1.0),
            left: BorderSide(color: accent.withValues(alpha: 0.15), width: 1.0),
            right: BorderSide(color: Colors.black.withValues(alpha: 0.2), width: 1.0),
            bottom: BorderSide(color: Colors.black.withValues(alpha: 0.4), width: 2.0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Icon(modeIcon, color: accent, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${currentMode.icon} ${currentMode.displayName} Mode',
                    style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const Text(
                    'Tap to change vehicle type',
                    style: TextStyle(color: RoadOSColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: RoadOSColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: RoadOSColors.textMuted,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PREMIUM 3-WAY THEME SEGMENTED CONTROL
// ─────────────────────────────────────────────────────────────────────────────

class _LuxThemeSegmentedControl extends StatelessWidget {
  final ThemeMode current;
  final ValueChanged<ThemeMode> onChanged;

  const _LuxThemeSegmentedControl({
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      (ThemeMode.dark, Icons.nights_stay_rounded, 'Dark'),
      (ThemeMode.system, Icons.brightness_auto_rounded, 'Auto'),
      (ThemeMode.light, Icons.wb_sunny_rounded, 'Light'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0D1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2B3654), width: 1),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((option) {
          final (mode, icon, label) = option;
          final isSelected = current == mode;
          return GestureDetector(
            onTap: () => onChanged(mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? RoadOSColors.hyperOrange : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                boxShadow: isSelected
                    ? [BoxShadow(color: RoadOSColors.hyperOrange.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: -2)]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 13, color: isSelected ? Colors.white : RoadOSColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : RoadOSColors.textMuted,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _ProfileStat — single achievement stat cell in the rider stats grid
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _ProfileStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: RoadOSColors.textMuted,
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
