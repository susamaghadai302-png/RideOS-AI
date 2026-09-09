import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/design_system/lux_components.dart'
    hide RoadOSButton, RoadOSCard, RoadOSThemeEngine;
import '../../../../core/security/input_sanitizer.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Production RegisterScreen with:
///  • Confirm-password field with match validation
///  • Animated 4-level password strength indicator
///  • Terms & Privacy acknowledgement (required)
///  • Show/hide password toggles
///  • Collapsed optional vehicle details section
///  • Dispatches [RegisterSubmittedEvent] to [AuthBloc]
///  • Navigation handled by [AuthGate] — no manual pushAndRemoveUntil needed
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  // ── Controllers ────────────────────────────────────────────────────────────
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Optional vehicle section
  final _bikeMakeController = TextEditingController(text: 'Yamaha');
  final _bikeModelController = TextEditingController(text: 'YZF-R1M');
  final _bikeYearController = TextEditingController(text: '2024');
  final _engineCCController = TextEditingController(text: '998');

  final _formKey = GlobalKey<FormState>();

  // ── UI state ───────────────────────────────────────────────────────────────
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _termsAccepted = false;
  bool _showVehicleSection = false;
  bool _isSubmitting = false;

  // Password strength (0–4)
  int _passwordStrength = 0;

  // ── Animation ──────────────────────────────────────────────────────────────
  late AnimationController _entryController;
  late AnimationController _strengthController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _strengthController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    ));

    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    final strength = _calculateStrength(_passwordController.text);
    setState(() => _passwordStrength = strength);
    _strengthController.animateTo(
      strength / 4.0,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 350),
    );
  }

  int _calculateStrength(String p) {
    if (p.isEmpty) return 0;
    int score = 0;
    if (p.length >= 8) score++;
    if (p.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[!@#\$&*~^%()_+\-=\[\]{};:\\|,.<>?/]').hasMatch(p)) score++;
    return score.clamp(0, 4);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _bikeMakeController.dispose();
    _bikeModelController.dispose();
    _bikeYearController.dispose();
    _engineCCController.dispose();
    _entryController.dispose();
    _strengthController.dispose();
    super.dispose();
  }

  void _onRegisterPressed() {
    FocusScope.of(context).unfocus();
    if (_isSubmitting) return;

    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please accept the Terms of Service to continue.'),
          backgroundColor: const Color(0xFF1A1020),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      LuxAudioHapticsService.mediumImpact();

      context.read<AuthBloc>().add(
            RegisterSubmittedEvent(
              email: InputSanitizer.sanitizeEmail(_emailController.text),
              password: _passwordController.text,
              fullName: InputSanitizer.sanitizeName(_fullNameController.text),
              phone: InputSanitizer.sanitizePhone(_phoneController.text),
              bikeMake: _showVehicleSection
                  ? _bikeMakeController.text.trim()
                  : null,
              bikeModel: _showVehicleSection
                  ? _bikeModelController.text.trim()
                  : null,
              bikeYear: _showVehicleSection
                  ? (int.tryParse(_bikeYearController.text) ?? 2024)
                  : null,
              engineCC: _showVehicleSection
                  ? (int.tryParse(_engineCCController.text) ?? 998)
                  : null,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoadOSColors.deepSpaceBlack,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: RoadOSColors.platinumWhite,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'CREATE ACCOUNT',
          style: GoogleFonts.outfit(
            color: RoadOSColors.platinumWhite,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (_, current) =>
            current is AuthFailureState || current is AuthenticatedState,
        listener: (context, state) {
          if (state is AuthFailureState) {
            setState(() => _isSubmitting = false);
            final isConflict =
                state.errorMessage.toLowerCase().contains('already exists');
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF1A0A0A),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: RoadOSColors.errorCrimson.withValues(alpha: 0.5),
                  ),
                ),
                content: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: RoadOSColors.errorCrimson, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.errorMessage,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                action: isConflict
                    ? SnackBarAction(
                        label: 'SIGN IN',
                        textColor: RoadOSColors.cyberCyan,
                        onPressed: () => Navigator.pop(context),
                      )
                    : null,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          // AuthGate handles navigation on AuthenticatedState — no manual push needed.
          if (state is AuthenticatedState) {
            setState(() => _isSubmitting = false);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoadingState || _isSubmitting;
          return Stack(
            fit: StackFit.expand,
            children: [
              _buildBackground(),
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 24),
                              _buildPersonalSection(),
                              const SizedBox(height: 16),
                              _buildPasswordSection(),
                              const SizedBox(height: 16),
                              _buildVehicleToggle(),
                              if (_showVehicleSection) ...[
                                const SizedBox(height: 16),
                                _buildVehicleSection(),
                              ],
                              const SizedBox(height: 20),
                              _buildTermsRow(),
                              const SizedBox(height: 24),
                              _buildSubmitButton(isLoading),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF07040F), RoadOSColors.deepSpaceBlack],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gradient brand pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
            ),
          ),
          child: Text(
            'RIDEOS AI',
            style: GoogleFonts.robotoMono(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Create\nYour Account',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Intelligent mobility starts here.',
          style: GoogleFonts.outfit(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalSection() {
    return _GlassSection(
      title: 'PERSONAL DETAILS',
      icon: Icons.person_outline_rounded,
      accentColor: RoadOSColors.cyberCyan,
      children: [
        _field(
          controller: _fullNameController,
          label: 'Full Name',
          icon: Icons.badge_outlined,
          inputType: TextInputType.name,
          action: TextInputAction.next,
          validator: (v) => InputSanitizer.isValidName(v ?? '')
              ? null
              : 'Enter your full legal name',
        ),
        const SizedBox(height: 14),
        _field(
          controller: _emailController,
          label: 'Email Address',
          icon: Icons.email_outlined,
          inputType: TextInputType.emailAddress,
          action: TextInputAction.next,
          validator: (v) => InputSanitizer.isValidEmail(v ?? '')
              ? null
              : 'Enter a valid email address',
        ),
        const SizedBox(height: 14),
        _field(
          controller: _phoneController,
          label: 'Phone Number',
          icon: Icons.phone_outlined,
          inputType: TextInputType.phone,
          action: TextInputAction.next,
          validator: (v) => InputSanitizer.isValidPhone(v ?? '')
              ? null
              : 'Enter a valid phone with country code',
        ),
      ],
    );
  }

  Widget _buildPasswordSection() {
    return _GlassSection(
      title: 'SECURITY',
      icon: Icons.shield_outlined,
      accentColor: RoadOSColors.neonViolet,
      children: [
        // Password
        TextFormField(
          controller: _passwordController,
          obscureText: !_showPassword,
          textInputAction: TextInputAction.next,
          style: GoogleFonts.outfit(
              color: Colors.white, fontWeight: FontWeight.w500),
          decoration: buildLuxGlassInputDecoration(
            label: 'Password',
            icon: Icons.lock_outline_rounded,
          ).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.white38,
                size: 20,
              ),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
          validator: (v) {
            if (v == null || v.length < 8) return 'Minimum 8 characters required';
            return null;
          },
        ),
        const SizedBox(height: 10),

        // Strength indicator
        _PasswordStrengthBar(strength: _passwordStrength),
        const SizedBox(height: 16),

        // Confirm password
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_showConfirmPassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _onRegisterPressed(),
          style: GoogleFonts.outfit(
              color: Colors.white, fontWeight: FontWeight.w500),
          decoration: buildLuxGlassInputDecoration(
            label: 'Confirm Password',
            icon: Icons.lock_reset_outlined,
          ).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _showConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white38,
                size: 20,
              ),
              onPressed: () => setState(
                  () => _showConfirmPassword = !_showConfirmPassword),
            ),
          ),
          validator: (v) {
            if (v != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildVehicleToggle() {
    return GestureDetector(
      onTap: () => setState(() => _showVehicleSection = !_showVehicleSection),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.two_wheeler_rounded,
              color: RoadOSColors.hyperOrange.withValues(alpha: 0.8),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Add Vehicle Details (optional)',
                style: GoogleFonts.outfit(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            AnimatedRotation(
              turns: _showVehicleSection ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: Icon(
                Icons.expand_more_rounded,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleSection() {
    return _GlassSection(
      title: 'VEHICLE INFO',
      icon: Icons.two_wheeler_rounded,
      accentColor: RoadOSColors.hyperOrange,
      children: [
        Row(
          children: [
            Expanded(
              child: _field(
                controller: _bikeMakeController,
                label: 'Make',
                icon: Icons.business_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(
                controller: _bikeModelController,
                label: 'Model',
                icon: Icons.directions_bike_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _field(
                controller: _bikeYearController,
                label: 'Year',
                icon: Icons.calendar_today_outlined,
                inputType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(
                controller: _engineCCController,
                label: 'Engine CC',
                icon: Icons.speed_rounded,
                inputType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showLegalDialog(String title, String content) {
    LuxAudioHapticsService.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D1322),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.3), width: 1.5),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: GoogleFonts.inter(
                color: RoadOSColors.platinumWhite,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: RoadOSColors.cyberCyan,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('I UNDERSTAND', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() => _termsAccepted = !_termsAccepted);
            LuxAudioHapticsService.lightImpact();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: _termsAccepted
                  ? const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
                    )
                  : null,
              color: _termsAccepted
                  ? null
                  : Colors.white.withValues(alpha: 0.08),
              border: Border.all(
                color: _termsAccepted
                    ? Colors.transparent
                    : Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: _termsAccepted
                ? const Icon(Icons.check_rounded,
                    color: Colors.white, size: 14)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12.5,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms of Service',
                  style: GoogleFonts.outfit(
                    color: RoadOSColors.cyberCyan,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: RoadOSColors.cyberCyan,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => _showLegalDialog(
                          'Terms of Service',
                          'By signing up for RideOS-AI, you agree that telemetry advisories, angle estimates, and AI navigation are assistive systems.',
                        ),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: GoogleFonts.outfit(
                    color: RoadOSColors.cyberCyan,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: RoadOSColors.cyberCyan,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => _showLegalDialog(
                          'Privacy Policy',
                          'RideOS-AI processes your motorcycle telemetry and diagnostic codes securely with on-device hardware encryption.',
                        ),
                ),
                const TextSpan(text: '. Your data is encrypted and never sold.'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isLoading) {
    return GestureDetector(
      onTap: isLoading ? null : _onRegisterPressed,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isLoading || !_termsAccepted ? 0.6 : 1.0,
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_add_alt_1_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'CREATE ACCOUNT',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    TextInputAction action = TextInputAction.next,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      textInputAction: action,
      style:
          GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500),
      decoration: buildLuxGlassInputDecoration(label: label, icon: icon),
      validator: validator,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glass section container
// ─────────────────────────────────────────────────────────────────────────────

class _GlassSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<Widget> children;

  const _GlassSection({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.2),
            ),
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      color: accentColor.withValues(alpha: 0.15),
                    ),
                    child: Icon(icon, color: accentColor, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: GoogleFonts.robotoMono(
                      color: accentColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Password strength bar
// ─────────────────────────────────────────────────────────────────────────────

class _PasswordStrengthBar extends StatelessWidget {
  final int strength; // 0–4

  const _PasswordStrengthBar({required this.strength});

  static const _labels = ['', 'Weak', 'Fair', 'Strong', 'Excellent'];
  static const _colors = [
    Color(0xFFEF4444), // Weak — red
    Color(0xFFF59E0B), // Fair — amber
    Color(0xFF10B981), // Strong — emerald
    Color(0xFF06B6D4), // Excellent — cyan
  ];

  Color get _barColor =>
      strength > 0 ? _colors[(strength - 1).clamp(0, 3)] : Colors.transparent;

  @override
  Widget build(BuildContext context) {
    if (strength == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bar segments
        Row(
          children: List.generate(4, (i) {
            final filled = i < strength;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: filled
                      ? _barColor
                      : Colors.white.withValues(alpha: 0.12),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _barColor,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Security score: ${_labels[strength.clamp(0, 4)]}',
              style: GoogleFonts.outfit(
                color: _barColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
