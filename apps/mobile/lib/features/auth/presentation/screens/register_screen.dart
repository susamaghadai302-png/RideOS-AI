import 'package:flutter/material.dart';
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard, RoadOSThemeEngine;

import '../../../../core/design_system/premium_navigation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/security/input_sanitizer.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _bikeMakeController = TextEditingController(text: 'Yamaha');
  final _bikeModelController = TextEditingController(text: 'YZF-R1M');
  final _bikeYearController = TextEditingController(text: '2024');
  final _engineCCController = TextEditingController(text: '998');
  final _maxLeanController = TextEditingController(text: '50.0');

  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _emergencyContactController.dispose();
    _bikeMakeController.dispose();
    _bikeModelController.dispose();
    _bikeYearController.dispose();
    _engineCCController.dispose();
    _maxLeanController.dispose();
    super.dispose();
  }

  void _onRegisterPressed() {
    if (_isSubmitting) return;

    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      LuxAudioHapticsService.mediumImpact();

      final email = InputSanitizer.sanitizeEmail(_emailController.text);
      final fullName = InputSanitizer.sanitizeName(_fullNameController.text);
      final phone = InputSanitizer.sanitizePhone(_phoneController.text);
      final emergency = InputSanitizer.sanitizePhone(_emergencyContactController.text);

      context.read<AuthBloc>().add(
            RegisterSubmittedEvent(
              email: email,
              password: _passwordController.text,
              fullName: fullName,
              phone: phone,
              emergencyContact: emergency,
              bikeMake: _bikeMakeController.text.trim(),
              bikeModel: _bikeModelController.text.trim(),
              bikeYear: int.tryParse(_bikeYearController.text) ?? 2024,
              engineCC: int.tryParse(_engineCCController.text) ?? 998,
              maxLeanAngleLimit: double.tryParse(_maxLeanController.text) ?? 50.0,
            ),
          );
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: RoadOSColors.platinumWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NEW RIDER PROFILE',
              style: LuxTypography.titleLarge(color: RoadOSColors.platinumWhite),
            ),
            Text(
              'Telematics & SOS Registration',
              style: LuxTypography.caption(color: RoadOSColors.cyberCyan),
            ),
          ],
        ),
      ),
      body: LuxAuroraBackground(
        child: SafeArea(
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthFailureState) {
                setState(() => _isSubmitting = false);
                final isConflict = state.errorMessage.toLowerCase().contains('already exists');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage),
                    backgroundColor: RoadOSColors.errorCrimson,
                    duration: const Duration(seconds: 4),
                    action: isConflict
                        ? SnackBarAction(
                            label: 'LOG IN',
                            textColor: RoadOSColors.cyberCyan,
                            onPressed: () => Navigator.pop(context),
                          )
                        : null,
                  ),
                );
              } else if (state is AuthenticatedState) {
                setState(() => _isSubmitting = false);
                showLuxSnack(context, 'Registration Successful! Welcome to Rideo Pro', variant: LuxSnackVariant.info);
                Navigator.pop(context);
              }
            },
            builder: (context, state) {
              final isLoading = state is AuthLoadingState;
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: LuxResponsiveContainer(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RoadOSCard(
                          blurSigma: 20,
                          padding: const EdgeInsets.all(26.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: LuxGradients.quantumCyan,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.badge_outlined, color: Colors.black, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'JOIN RIDEOS AI TELEMATICS',
                                          style: LuxTypography.caption(color: RoadOSColors.cyberCyan),
                                        ),
                                        Text(
                                          'Create Rider Profile',
                                          style: LuxTypography.titleLarge(color: RoadOSColors.platinumWhite),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              TextFormField(
                                controller: _fullNameController,
                                style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.w600),
                                decoration: buildLuxGlassInputDecoration(
                                  label: 'Full Name',
                                  icon: Icons.person_outline,
                                ),
                                validator: (v) => InputSanitizer.isValidName(v ?? '') ? null : 'Enter full legal name',
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.w600),
                                decoration: buildLuxGlassInputDecoration(
                                  label: 'Email Address',
                                  icon: Icons.email_outlined,
                                ),
                                validator: (v) => InputSanitizer.isValidEmail(v ?? '') ? null : 'Enter a valid email',
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.w600),
                                decoration: buildLuxGlassInputDecoration(
                                  label: 'Mobile Phone Number',
                                  icon: Icons.phone_outlined,
                                ),
                                validator: (v) => InputSanitizer.isValidPhone(v ?? '') ? null : 'Enter valid phone with country code',
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _emergencyContactController,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.w600),
                                decoration: buildLuxGlassInputDecoration(
                                  label: 'Emergency ICE Contact Number',
                                  icon: Icons.emergency_outlined,
                                ),
                                validator: (v) => InputSanitizer.isValidPhone(v ?? '') ? null : 'Enter valid emergency phone',
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.w600),
                                decoration: buildLuxGlassInputDecoration(
                                  label: 'Security Password',
                                  icon: Icons.lock_outline,
                                ),
                                validator: (v) => (v == null || v.length < 8) ? 'Minimum 8 characters' : null,
                              ),
                              const SizedBox(height: 28),

                              RoadOSButton(
                                label: 'CREATE RIDER ACCOUNT',
                                icon: Icons.person_add_alt_1_rounded,
                                gradient: LuxGradients.quantumCyan,
                                isLoading: isLoading,
                                onPressed: _onRegisterPressed,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
