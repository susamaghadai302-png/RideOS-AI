import 'package:flutter/material.dart';
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard, RoadOSThemeEngine;

import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/security/input_sanitizer.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitted = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handlePasswordReset() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      LuxAudioHapticsService.mediumImpact();

      await Future.delayed(const Duration(milliseconds: 1200));

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSubmitted = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: RoadOSColors.platinumWhite, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('RECOVER ACCOUNT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: RoadOSColors.hyperOrange)),
      ),
      body: LuxAuroraBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: LuxResponsiveContainer(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Hero Shield Emblem
                      Hero(
                        tag: 'auth_emblem',
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LuxGradients.hyperOrange,
                            boxShadow: LuxShadows.glassGlow(RoadOSColors.hyperOrange),
                          ),
                          child: const Icon(Icons.lock_reset_rounded, size: 48, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Forgot Password?',
                        style: LuxTypography.displayHeader(color: RoadOSColors.platinumWhite).copyWith(fontSize: 28),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your registered email address below to receive an authenticated reset link.',
                        textAlign: TextAlign.center,
                        style: LuxTypography.bodyMedium(color: RoadOSColors.textMuted),
                      ),
                      const SizedBox(height: 32),

                      RoadOSCard(
                        padding: const EdgeInsets.all(24),
                        child: _isSubmitted
                            ? Column(
                                children: [
                                  const Icon(Icons.mark_email_read_rounded, color: RoadOSColors.apexEmerald, size: 56),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'RESET LINK SENT!',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: RoadOSColors.apexEmerald),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Instructions sent to ${_emailController.text.trim()}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: RoadOSColors.platinumWhite, fontSize: 12),
                                  ),
                                  const SizedBox(height: 20),
                                  RoadOSButton(
                                    label: 'RETURN TO LOGIN',
                                    gradient: LuxGradients.cyberPurple,
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.w600),
                                    decoration: buildLuxGlassInputDecoration(
                                      label: 'Rider Email',
                                      icon: Icons.email_outlined,
                                    ),
                                    validator: (v) => InputSanitizer.isValidEmail(v ?? '') ? null : 'Enter a valid email address',
                                  ),
                                  const SizedBox(height: 24),
                                  RoadOSButton(
                                    label: 'SEND RESET LINK',
                                    icon: Icons.send_rounded,
                                    gradient: LuxGradients.hyperOrange,
                                    isLoading: _isLoading,
                                    onPressed: _handlePasswordReset,
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
