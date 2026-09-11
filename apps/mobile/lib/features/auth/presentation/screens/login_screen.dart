import 'dart:io' show Platform;
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/design_system/premium_login_animations.dart';
import '../../../../core/design_system/premium_navigation.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/utils/constants.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import '../dialogs/backend_diagnostics_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // ─── Form Controllers ────────────────────────────────────────────────────
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _socialLoading = false;
  String? _socialLoadingType;

  // ─── Animation Controllers ───────────────────────────────────────────────
  late AnimationController _entryController;   // Staggered cinematic entry
  late AnimationController _orbController;     // Floating orbs parallax
  late AnimationController _breatheController; // Card border breathing glow

  @override
  void initState() {
    super.initState();

    // Entry: 1.2 s one-shot reveal
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    // Orbs: infinite slow drift
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    // Breathing glow: 3 s pulse
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _entryController.dispose();
    _orbController.dispose();
    _breatheController.dispose();
    super.dispose();
  }

  // ─── Auth Actions ─────────────────────────────────────────────────────────
  void _onLoginPressed() {
    if (_formKey.currentState!.validate()) {
      LuxAudioHapticsService.formSubmit();
      context.read<AuthBloc>().add(
            LoginSubmittedEvent(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    } else {
      LuxAudioHapticsService.errorImpact();
    }
  }

  Future<void> _onGoogleSignIn() async {
    if (_socialLoading) return;

    setState(() { _socialLoading = true; _socialLoadingType = 'google'; });
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      await googleSignIn.signOut();
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) {
        return;
      }
      final GoogleSignInAuthentication auth = await account.authentication;
      if (!mounted) return;
      context.read<AuthBloc>().add(GoogleSignInWithCredentialEvent(
            email: account.email,
            fullName: account.displayName ?? '',
            idToken: auth.idToken,
            accessToken: auth.accessToken,
          ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Google Sign-In is unavailable or not configured on this build. Please sign in with email & password.'),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() { _socialLoading = false; _socialLoadingType = null; });
    }
  }

  Future<void> _onAppleSignIn() async {
    if (_socialLoading) return;

    if (kIsWeb || Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Apple Sign-In is only available on iOS devices. Please sign in with email & password.'),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() { _socialLoading = true; _socialLoadingType = 'apple'; });
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      if (!mounted) return;
      final String fullName = [
        credential.givenName,
        credential.familyName,
      ].where((s) => s != null && s.isNotEmpty).join(' ');
      context.read<AuthBloc>().add(AppleSignInWithCredentialEvent(
            email: credential.email,
            fullName: fullName.isNotEmpty ? fullName : null,
            identityToken: credential.identityToken,
            authorizationCode: credential.authorizationCode,
          ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Apple Sign-In was cancelled or is unavailable. Please sign in with email & password.'),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() { _socialLoading = false; _socialLoadingType = null; });
    }
  }

  Future<void> _onBiometricAuth() async {
    if (_socialLoading) return;

    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Biometric authentication is not supported on web.'),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() { _socialLoading = true; _socialLoadingType = 'biometric'; });
    try {
      final LocalAuthentication localAuth = LocalAuthentication();
      final bool canCheckBiometrics = await localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await localAuth.isDeviceSupported();

      if (!canCheckBiometrics && !isDeviceSupported) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Biometric authentication is not supported on this device.'),
              backgroundColor: const Color(0xFF1E293B),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        return;
      }
      final List<BiometricType> availableBiometrics = await localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No biometrics enrolled. Please set up fingerprint or face unlock in system settings.'),
              backgroundColor: const Color(0xFF1E293B),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        return;
      }
      final bool authenticated = await localAuth.authenticate(
        localizedReason: 'Authenticate to unlock RideOS AI',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false),
      );
      if (!mounted) return;
      if (authenticated) {
        context.read<AuthBloc>().add(BiometricAuthRequestedEvent());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Biometric authentication cancelled or failed.'),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() { _socialLoading = false; _socialLoadingType = null; });
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthenticatedState) {
            LuxAudioHapticsService.successPattern();
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
          if (state is AuthFailureState) {
            LuxAudioHapticsService.errorImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage),
                backgroundColor: RoadOSColors.errorCrimson,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
        child: Stack(
          children: [
            // 1. Deep atmospheric base
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF04060C), Color(0xFF070B18), Color(0xFF0A0E20)],
                ),
              ),
            ),

            // 2. Animated aurora
            const LuxAuroraBackground(child: SizedBox.expand()),

            // 3. Floating orbs — premium depth
            PremiumFloatingOrb(
              animation: _orbController,
              color: RoadOSColors.hyperOrange,
              size: size.width * 0.65,
              startX: size.width * -0.12,
              startY: size.height * 0.05,
              phaseOffset: 0.0,
            ),
            PremiumFloatingOrb(
              animation: _orbController,
              color: RoadOSColors.cyberCyan,
              size: size.width * 0.55,
              startX: size.width * 0.55,
              startY: size.height * 0.60,
              phaseOffset: 2.1,
            ),
            PremiumFloatingOrb(
              animation: _orbController,
              color: const Color(0xFFFF00FF),
              size: size.width * 0.38,
              startX: size.width * 0.20,
              startY: size.height * 0.75,
              phaseOffset: 1.05,
            ),

            // 4. Frosted radial vignette
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.0, -0.3),
                      radius: 1.4,
                      colors: [Colors.transparent, Color(0xCC04060C)],
                    ),
                  ),
                ),
              ),
            ),

            // 5. Scrollable content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 32.0),
                  child: LuxResponsiveContainer(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Brand hero
                          PremiumSlideReveal(
                            parentAnimation: _entryController,
                            delay: 0.0,
                            duration: 0.45,
                            slideDistancePx: 48.0,
                            child: _buildBrandHero(),
                          ),

                          const SizedBox(height: 36),

                          // Auth card
                          PremiumSlideReveal(
                            parentAnimation: _entryController,
                            delay: 0.18,
                            duration: 0.52,
                            slideDistancePx: 42.0,
                            child: PremiumBreathingRing(
                              animation: _breatheController,
                              color: RoadOSColors.hyperOrange,
                              borderRadius: 24.0,
                              strokeWidth: 1.2,
                              child: PremiumNeumorphicGlassCard(
                                accentGlow: RoadOSColors.hyperOrange,
                                child: _buildFormContent(),
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Register link
                          PremiumSlideReveal(
                            parentAnimation: _entryController,
                            delay: 0.60,
                            duration: 0.40,
                            child: _buildRegisterLink(),
                          ),

                          const SizedBox(height: 16),

                          // Server badge
                          PremiumSlideReveal(
                            parentAnimation: _entryController,
                            delay: 0.72,
                            duration: 0.28,
                            child: _buildServerBadge(),
                          ),

                          const SizedBox(height: 14),

                          // Legal footer
                          _buildLegalFooter(),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Brand Hero ───────────────────────────────────────────────────────────
  Widget _buildBrandHero() {
    return Column(
      children: [
        PremiumBreathingRing(
          animation: _breatheController,
          color: RoadOSColors.cyberCyan,
          borderRadius: 36.0,
          strokeWidth: 1.5,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFF1A0A3E), Color(0xFF060B18)],
              ),
              boxShadow: [
                BoxShadow(
                  color: RoadOSColors.hyperOrange.withValues(alpha: 0.35),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: RoadOSColors.cyberCyan.withValues(alpha: 0.20),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Text(
                'R',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'RIDEOS AI',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: 4.0,
          ),
        ),
        const SizedBox(height: 6),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFF5500), Color(0xFFFF007A), Color(0xFF00F2FE)],
          ).createShader(bounds),
          child: Text(
            'INTELLIGENT VEHICLE OPERATING SYSTEM',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.8,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  // ─── Form Content ─────────────────────────────────────────────────────────
  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: RoadOSColors.cyberCyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.35), width: 1),
              ),
              child: const Icon(Icons.shield_outlined, color: RoadOSColors.cyberCyan, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RIDER AUTHENTICATION',
                  style: GoogleFonts.outfit(
                    color: RoadOSColors.cyberCyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'Secure encrypted access',
                  style: GoogleFonts.inter(color: RoadOSColors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Email
        PremiumSlideReveal(
          parentAnimation: _entryController,
          delay: 0.30,
          duration: 0.40,
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            style: GoogleFonts.inter(
              color: RoadOSColors.platinumWhite,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            decoration: buildLuxGlassInputDecoration(label: 'Rider Email', icon: Icons.email_outlined),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
              if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email address';
              return null;
            },
          ),
        ),
        const SizedBox(height: 16),

        // Password
        PremiumSlideReveal(
          parentAnimation: _entryController,
          delay: 0.38,
          duration: 0.40,
          child: TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _onLoginPressed(),
            style: GoogleFonts.inter(
              color: RoadOSColors.platinumWhite,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            decoration: buildLuxGlassInputDecoration(
              label: 'Security Password',
              icon: Icons.lock_outline,
            ).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: RoadOSColors.textMuted,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
        ),
        const SizedBox(height: 26),

        // CTA button
        PremiumSlideReveal(
          parentAnimation: _entryController,
          delay: 0.46,
          duration: 0.42,
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final isLoading = state is AuthLoadingState;
              return RoadOSButton(
                label: 'START ENGINE',
                icon: Icons.power_settings_new_rounded,
                gradient: LuxGradients.hyperOrange,
                isLoading: isLoading,
                onPressed: (isLoading || _socialLoading) ? () {} : _onLoginPressed,
              );
            },
          ),
        ),
        const SizedBox(height: 14),

        // Forgot password
        Center(
          child: TextButton(
            onPressed: () {
              Navigator.push(context, premiumRoute(const ForgotPasswordScreen()));
            },
            child: Text(
              'Forgot Password?',
              style: GoogleFonts.inter(
                color: RoadOSColors.cyberCyan,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: RoadOSColors.cyberCyan,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // OR divider
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, const Color(0xFF334155).withValues(alpha: 0.8)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'OR CONNECT WITH',
                style: GoogleFonts.outfit(
                  color: RoadOSColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF334155).withValues(alpha: 0.8), Colors.transparent],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Social auth buttons
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final blocLoading = state is AuthLoadingState;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSocialAuthButton(
                  'GOOGLE',
                  Icons.g_mobiledata_rounded,
                  RoadOSColors.cyberCyan,
                  isLoading: _socialLoadingType == 'google',
                  onTap: (blocLoading || _socialLoading) ? null : _onGoogleSignIn,
                ),
                _buildSocialAuthButton(
                  'APPLE',
                  Icons.apple_rounded,
                  RoadOSColors.platinumWhite,
                  isLoading: _socialLoadingType == 'apple',
                  onTap: (blocLoading || _socialLoading) ? null : _onAppleSignIn,
                ),
                _buildSocialAuthButton(
                  'BIOMETRIC',
                  Icons.fingerprint_rounded,
                  RoadOSColors.apexEmerald,
                  isLoading: _socialLoadingType == 'biometric',
                  onTap: (blocLoading || _socialLoading) ? null : _onBiometricAuth,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ─── Register Link ────────────────────────────────────────────────────────
  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have a Rider Account? ",
          style: GoogleFonts.inter(color: RoadOSColors.textMuted, fontSize: 13),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(context, premiumRoute(const RegisterScreen()));
          },
          child: Text(
            'Register Account',
            style: GoogleFonts.inter(
              color: RoadOSColors.cyberCyan,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              decorationColor: RoadOSColors.cyberCyan,
            ),
          ),
        ),
      ],
    );
  }
  // ─── Server Badge ─────────────────────────────────────────────────────────
  Widget _buildServerBadge() {
    return GestureDetector(
      onTap: _showServerSettingsDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF070B18).withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(color: RoadOSColors.cyberCyan.withValues(alpha: 0.08), blurRadius: 14),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.dns_rounded, color: RoadOSColors.cyberCyan, size: 12),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Server: ${ApiConstants.baseUrl}',
                style: GoogleFonts.robotoMono(
                  fontSize: 10,
                  color: RoadOSColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.edit_outlined, color: RoadOSColors.cyberCyan, size: 11),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => _showLegalInfoDialog('Privacy Policy', 'RideOS-AI processes ECU diagnostics, motorcycle telemetry, and location data securely on-device with zero unauthorized third-party sharing.'),
          child: Text(
            'Privacy Policy',
            style: GoogleFonts.inter(
              color: RoadOSColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('·', style: TextStyle(color: Color(0xFF374151))),
        ),
        GestureDetector(
          onTap: () => _showLegalInfoDialog('Terms of Service', 'By signing into RideOS-AI, you acknowledge that all AI telemetry, lean angle guidance, and safety insights are advisory assistive tools.'),
          child: Text(
            'Terms of Service',
            style: GoogleFonts.inter(
              color: RoadOSColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _showLegalInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0C1222),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: RoadOSColors.cyberCyan.withValues(alpha: 0.3)),
        ),
        title: Text(title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(content, style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(color: RoadOSColors.cyberCyan, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  void _showServerSettingsDialog() async {
    await showDialog(
      context: context,
      builder: (_) => const BackendDiagnosticsDialog(),
    );
    if (mounted) setState(() {});
  }

  Widget _buildSocialAuthButton(
    String label,
    IconData icon,
    Color color, {
    bool isLoading = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.45 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.38)),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 10),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: color),
                )
              else
                Icon(icon, color: color, size: 18),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
