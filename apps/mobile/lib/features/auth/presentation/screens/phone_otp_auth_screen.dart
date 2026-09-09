import 'dart:async';
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class PhoneOtpAuthScreen extends StatefulWidget {
  const PhoneOtpAuthScreen({super.key});

  @override
  State<PhoneOtpAuthScreen> createState() => _PhoneOtpAuthScreenState();
}

class _PhoneOtpAuthScreenState extends State<PhoneOtpAuthScreen> {
  final _phoneController = TextEditingController(text: '+1 (555) 019-2834');
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isOtpSent = false;
  int _resendCountdown = 30;
  Timer? _resendTimer;
  final String _autoDetectedOtp = '982041';

  @override
  void dispose() {
    _phoneController.dispose();
    _resendTimer?.cancel();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _resendCountdown = 30;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  void _sendOtp() {
    if (_phoneController.text.length < 8) {
      showLuxSnack(context, 'Please enter a valid phone number with country code', variant: LuxSnackVariant.info);
      return;
    }

    LuxAudioHapticsService.mediumImpact();
    setState(() => _isOtpSent = true);
    _startResendTimer();

    // Auto-detect OTP simulation
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      for (int i = 0; i < 6; i++) {
        _otpControllers[i].text = _autoDetectedOtp[i];
      }
      LuxAudioHapticsService.selectionClick();
      showLuxSnack(context, 'SMS OTP Auto-Detected: 982041', variant: LuxSnackVariant.info);
    });
  }

  void _verifyOtp() {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length < 6) {
      showLuxSnack(context, 'Please enter complete 6-digit OTP code', variant: LuxSnackVariant.info);
      return;
    }

    LuxAudioHapticsService.heavyImpact();
    context.read<AuthBloc>().add(AppStartedEvent());
    Navigator.pop(context);
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
        title: const Text(
          'PHONE OTP AUTHENTICATION',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: RoadOSColors.hyperOrange),
        ),
      ),
      body: LuxAuroraBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: LuxResponsiveContainer(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  // Hero Phone Icon
                  Hero(
                    tag: 'phone_otp_emblem',
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LuxGradients.hyperOrange,
                        boxShadow: LuxShadows.glassGlow(RoadOSColors.hyperOrange),
                      ),
                      child: const Icon(Icons.phone_android_rounded, size: 52, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    _isOtpSent ? 'Enter Security Code' : 'Mobile Phone Verification',
                    style: LuxTypography.displayHeader(color: RoadOSColors.platinumWhite).copyWith(fontSize: 26),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isOtpSent
                        ? '6-digit OTP code sent to ${_phoneController.text}'
                        : 'We will send a one-time SMS passkey to verify your rider profile.',
                    textAlign: TextAlign.center,
                    style: LuxTypography.bodyMedium(color: RoadOSColors.textMuted),
                  ),
                  const SizedBox(height: 32),

                  RoadOSCard(
                    padding: const EdgeInsets.all(24),
                    child: !_isOtpSent
                        ? Column(
                            children: [
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold),
                                decoration: buildLuxGlassInputDecoration(
                                  label: 'Mobile Phone Number',
                                  icon: Icons.phone_outlined,
                                ),
                              ),
                              const SizedBox(height: 24),
                              RoadOSButton(
                                label: 'SEND SMS PASSKEY',
                                icon: Icons.send_rounded,
                                gradient: LuxGradients.hyperOrange,
                                onPressed: _sendOtp,
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              // 6-Digit OTP Box Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: List.generate(6, (index) {
                                  return SizedBox(
                                    width: 42,
                                    height: 54,
                                    child: TextField(
                                      controller: _otpControllers[index],
                                      focusNode: _otpFocusNodes[index],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      maxLength: 1,
                                      style: const TextStyle(
                                        color: RoadOSColors.hyperOrange,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                      ),
                                      decoration: InputDecoration(
                                        counterText: '',
                                        filled: true,
                                        fillColor: Colors.black45,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFF334155)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: RoadOSColors.hyperOrange, width: 2),
                                        ),
                                      ),
                                      onChanged: (val) {
                                        if (val.isNotEmpty && index < 5) {
                                          _otpFocusNodes[index + 1].requestFocus();
                                        } else if (val.isEmpty && index > 0) {
                                          _otpFocusNodes[index - 1].requestFocus();
                                        }
                                      },
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 24),

                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  return RoadOSButton(
                                    label: 'VERIFY & SIGN IN',
                                    icon: Icons.check_circle_outline_rounded,
                                    gradient: LuxGradients.hyperOrange,
                                    isLoading: state is AuthLoadingState,
                                    onPressed: _verifyOtp,
                                  );
                                },
                              ),
                              const SizedBox(height: 16),

                              // Resend Timer Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Resend code in: ', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 12)),
                                  Text(
                                    _resendCountdown > 0 ? '${_resendCountdown}s' : 'Available Now',
                                    style: TextStyle(
                                      color: _resendCountdown > 0 ? RoadOSColors.cyberCyan : RoadOSColors.apexEmerald,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (_resendCountdown == 0) ...[
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: _sendOtp,
                                      child: const Text('RESEND SMS', style: TextStyle(color: RoadOSColors.hyperOrange, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                  ],
                                ],
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
    );
  }
}
