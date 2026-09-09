import 'dart:ui';
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../../../cockpit/presentation/screens/cockpit_command_center_screen.dart';
import '../../../garage/presentation/screens/luxury_garage_showroom_screen.dart';
import '../../../navigation/presentation/screens/navigation_hud_screen.dart';
import '../../../sos_safety/presentation/bloc/sos_bloc.dart';
import '../../../sos_safety/presentation/bloc/sos_event.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../../core/design_system/premium_navigation.dart';

class GarageScreen extends StatelessWidget {
  const GarageScreen({super.key});

  static void showAddBikeDialog(BuildContext context) {
  final makeCtrl = TextEditingController();
  final modelCtrl = TextEditingController();
  final yearCtrl = TextEditingController();
  final ccCtrl = TextEditingController();

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogCtx) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: RoadOSCard(
            blurSigma: 24,
            padding: const EdgeInsets.all(26),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LuxGradients.hyperOrange,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: LuxShadows.glassGlow(RoadOSColors.hyperOrange),
                        ),
                        child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'REGISTER MOTORCYCLE',
                              style: LuxTypography.titleLarge(color: RoadOSColors.platinumWhite),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Add vehicle to Rideo Pro Digital Garage',
                              style: LuxTypography.caption(color: RoadOSColors.cyberCyan),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  _buildDialogTextField('Make (e.g. Yamaha, Ducati)', makeCtrl, Icons.branding_watermark_outlined),
                  const SizedBox(height: 16),
                  _buildDialogTextField('Model (e.g. YZF-R1M, Panigale)', modelCtrl, Icons.two_wheeler_outlined),
                  const SizedBox(height: 16),
                  _buildDialogTextField('Year (e.g. 2024)', yearCtrl, Icons.calendar_today_outlined, isNumber: true),
                  const SizedBox(height: 16),
                  _buildDialogTextField('Engine CC (e.g. 998)', ccCtrl, Icons.speed_outlined, isNumber: true),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            LuxAudioHapticsService.lightImpact();
                            Navigator.pop(dialogCtx);
                          },
                          child: Text(
                            'CANCEL',
                            style: LuxTypography.bodyMedium(color: RoadOSColors.textMuted).copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RoadOSButton(
                          label: 'ADD BIKE',
                          icon: Icons.add_rounded,
                          gradient: LuxGradients.hyperOrange,
                          onPressed: () {
                            final make = makeCtrl.text.trim();
                            final model = modelCtrl.text.trim();
                            final year = int.tryParse(yearCtrl.text) ?? 2024;
                            final engineCC = int.tryParse(ccCtrl.text) ?? 600;

                            if (make.isNotEmpty && model.isNotEmpty) {
                              LuxAudioHapticsService.heavyImpact();
                              context.read<AuthBloc>().add(
                                    AddBikeSubmittedEvent(
                                      make: make,
                                      model: model,
                                      year: year,
                                      engineCC: engineCC,
                                    ),
                                  );
                              Navigator.pop(dialogCtx);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

static Widget _buildDialogTextField(String label, TextEditingController ctrl, IconData icon, {bool isNumber = false}) {
  return TextField(
    controller: ctrl,
    keyboardType: isNumber ? TextInputType.number : TextInputType.text,
    style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.w600),
    decoration: buildLuxGlassInputDecoration(
      label: label,
      icon: icon,
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('RIDER DASHBOARD & GARAGE', style: LuxTypography.titleLarge(color: RoadOSColors.platinumWhite)),
            Text('Connected Vehicle Operating System', style: LuxTypography.caption(color: RoadOSColors.textMuted)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: RoadOSColors.hyperOrange),
            onPressed: () {
              LuxAudioHapticsService.mediumImpact();
              context.read<AuthBloc>().add(LogoutEvent());
            },
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(LuxRadius.circular),
          boxShadow: LuxShadows.glassGlow(RoadOSColors.hyperOrange),
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            LuxAudioHapticsService.selectionClick();
            showAddBikeDialog(context);
          },
          backgroundColor: RoadOSColors.hyperOrange,
          elevation: 6,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'ADD BIKE',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white),
          ),
        ),
      ),
      body: LuxAuroraBackground(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthenticatedState) {
              final rider = state.rider;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rider Profile Header Glass Card
                    RoadOSCard(
                      padding: const EdgeInsets.all(18.0),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LuxGradients.hyperOrange,
                              boxShadow: LuxShadows.glassGlow(RoadOSColors.hyperOrange),
                            ),
                            child: const Icon(Icons.person_rounded, size: 36, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rider.fullName,
                                  style: LuxTypography.titleLarge(color: RoadOSColors.platinumWhite),
                                ),
                                const SizedBox(height: 2),
                                Text(rider.email, style: LuxTypography.bodyMedium(color: RoadOSColors.textMuted)),
                                Text(rider.phone, style: LuxTypography.bodyMedium(color: RoadOSColors.cyberCyan)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Quick Telematics Action Grid
                    Row(
                      children: [
                        _buildQuickActionButton(
                          context,
                          'COCKPIT',
                          Icons.flight_takeoff_rounded,
                          RoadOSColors.cyberCyan,
                          () => Navigator.push(context, premiumRoute(const CockpitCommandCenterScreen())),
                        ),
                        const SizedBox(width: 8),
                        _buildQuickActionButton(
                          context,
                          'SHOWROOM',
                          Icons.storefront_rounded,
                          RoadOSColors.hyperOrange,
                          () => Navigator.push(context, premiumRoute(const LuxuryGarageShowroomScreen())),
                        ),
                        const SizedBox(width: 8),
                        _buildQuickActionButton(
                          context,
                          'NAV HUD',
                          Icons.navigation_outlined,
                          RoadOSColors.apexEmerald,
                          () => Navigator.push(context, premiumRoute(const NavigationHudScreen())),
                        ),
                        const SizedBox(width: 8),
                        _buildQuickActionButton(
                          context,
                          'AI ASSIST',
                          Icons.auto_awesome_rounded,
                          const Color(0xFF8B5CF6),
                          () => Navigator.push(context, premiumRoute(const AiAssistantScreen())),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Emergency SOS Trigger Button
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(LuxRadius.md),
                        boxShadow: LuxShadows.glassGlow(RoadOSColors.errorCrimson),
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RoadOSColors.errorCrimson,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LuxRadius.md)),
                          elevation: 4,
                        ),
                        icon: const Icon(Icons.warning_amber_rounded, size: 22),
                        label: const Text(
                          'TRIGGER TEST EMERGENCY SOS',
                          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                        onPressed: () {
                          LuxAudioHapticsService.alertVibrate();
                          context.read<SosBloc>().add(
                                const TriggerSosEvent(
                                  lat: 37.7749,
                                  lng: -122.4194,
                                  triggerType: 'MANUAL',
                                  impactForceG: 5.2,
                                ),
                              );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Garage Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'MOTORCYCLE GARAGE (${rider.garage.length})',
                          style: LuxTypography.caption(color: RoadOSColors.textMuted),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: RoadOSColors.hyperOrange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(LuxRadius.sm),
                            border: Border.all(color: RoadOSColors.hyperOrange.withValues(alpha: 0.4)),
                          ),
                          child: const Text(
                            'ONLINE TELEMETRY',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: RoadOSColors.hyperOrange),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Motorcycle List / Empty State
                    Expanded(
                      child: rider.garage.isEmpty
                          ? Center(
                              child: RoadOSCard(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.two_wheeler_rounded, size: 48, color: RoadOSColors.textMuted),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No motorcycles in garage yet.\nTap ADD BIKE below to get started.',
                                      textAlign: TextAlign.center,
                                      style: LuxTypography.bodyMedium(color: RoadOSColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: rider.garage.length,
                              itemBuilder: (context, index) {
                                final bike = rider.garage[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  child: RoadOSCard(
                                    borderColor: bike.isPrimary ? RoadOSColors.hyperOrange : const Color(0xFF334155),
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: bike.isPrimary
                                                ? RoadOSColors.hyperOrange.withValues(alpha: 0.18)
                                                : RoadOSColors.titaniumSlate,
                                            borderRadius: BorderRadius.circular(LuxRadius.md),
                                          ),
                                          child: Icon(
                                            Icons.two_wheeler_rounded,
                                            color: bike.isPrimary ? RoadOSColors.hyperOrange : RoadOSColors.platinumWhite,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${bike.make} ${bike.model}',
                                                style: LuxTypography.titleMedium(color: RoadOSColors.platinumWhite),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '${bike.year} | ${bike.engineCC} cc | Max Lean ${bike.maxLeanAngleLimit} deg',
                                                style: LuxTypography.bodyMedium(color: RoadOSColors.textMuted),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (bike.isPrimary)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              gradient: LuxGradients.hyperOrange,
                                              borderRadius: BorderRadius.circular(LuxRadius.sm),
                                            ),
                                            child: const Text(
                                              'PRIMARY',
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            }
            return const Center(
              child: CircularProgressIndicator(color: RoadOSColors.hyperOrange),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          LuxAudioHapticsService.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(LuxRadius.md),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1.2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
