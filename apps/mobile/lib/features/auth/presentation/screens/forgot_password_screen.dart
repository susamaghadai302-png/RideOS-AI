import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/design_system/lux_components.dart'
    hide RoadOSButton, RoadOSCard;
import '../../../../core/security/input_sanitizer.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Production forgot-password screen.
///
/// Dispatches [ForgotPasswordSubmittedEvent] to [AuthBloc] which calls
/// `POST /auth/forgot-password` on the real backend.
///
/// States handled:
///  • [AuthLoadingState]         → shows inline loading
///  • [ForgotPasswordSentState]  → shows success confirmation
///  • [AuthFailureState]         → shows error with retry action
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AnimationController _entryController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
    ));

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      LuxAudioHapticsService.mediumImpact();
      context.read<AuthBloc>().add(
            ForgotPasswordSubmittedEvent(email: _emailController.text.trim()),
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
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (_, current) =>
            current is ForgotPasswordSentState ||
            current is AuthFailureState ||
            current is AuthLoadingState,
        listener: (context, state) {
          // On failure, show a premium snackbar with retry — do NOT pop
          if (state is AuthFailureState) {
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
                action: SnackBarAction(
                  label: 'RETRY',
                  textColor: RoadOSColors.hyperOrange,
                  onPressed: _submit,
                ),
                duration: const Duration(seconds: 6),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoadingState;
          final isSent = state is ForgotPasswordSentState;
          final sentEmail = isSent
              ? state.email
              : _emailController.text.trim();

          return Stack(
            fit: StackFit.expand,
            children: [
              // ── Cinematic Background ────────────────────────────────────
              _buildBackground(),

              // ── Content ─────────────────────────────────────────────────
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 32,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: isSent
                              ? _buildSuccessCard(sentEmail)
                              : _buildFormCard(isLoading),
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

  // ─────────────────────────────────────────────────────────────────────────
  // Background
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.3),
                  radius: 1.3,
                  colors: [
                    Color(0xFF0A0818),
                    RoadOSColors.deepSpaceBlack,
                  ],
                ),
              ),
            ),
            // Orange/amber orb — matches lock-reset theme
            Positioned(
              right: -60,
              top: 80,
              child: _Orb(
                size: 260,
                color: RoadOSColors.hyperOrange,
                opacity: 0.08 * _pulseAnim.value,
              ),
            ),
            Positioned(
              left: -80,
              bottom: 120,
              child: _Orb(
                size: 200,
                color: RoadOSColors.cyberCyan,
                opacity: 0.06 * _pulseAnim.value,
              ),
            ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Form card (pre-submit)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildFormCard(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hero icon
        AnimatedBuilder(
          animation: _pulseController,
          builder: (_, child) => Transform.scale(
            scale: _pulseAnim.value,
            child: child,
          ),
          child: Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: RoadOSColors.hyperOrange.withValues(alpha: 0.45),
                    blurRadius: 32,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                size: 42,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Heading
        Text(
          'RECOVER ACCESS',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your registered email to receive\na secure password reset link.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),

        // Glass card
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: RoadOSColors.hyperOrange.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: buildLuxGlassInputDecoration(
                        label: 'Registered Email',
                        icon: Icons.email_outlined,
                      ),
                      validator: (v) => InputSanitizer.isValidEmail(v ?? '')
                          ? null
                          : 'Enter a valid email address',
                    ),
                    const SizedBox(height: 24),

                    // Submit button
                    _PremiumButton(
                      label: 'SEND RESET LINK',
                      icon: Icons.send_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                      ),
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Footer note
        Text(
          'Check your spam folder if the email doesn\'t arrive within a few minutes.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 11,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Success card (post-submit)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSuccessCard(String email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Animated checkmark
        Center(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (_, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: RoadOSColors.apexEmerald.withValues(alpha: 0.5),
                    blurRadius: 36,
                  ),
                ],
              ),
              child: const Icon(
                Icons.mark_email_read_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),

        Text(
          'CHECK YOUR INBOX',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Reset instructions were sent to',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          email,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: RoadOSColors.apexEmerald,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 36),

        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: RoadOSColors.apexEmerald.withValues(alpha: 0.3),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: const Column(
                children: [
                  _InfoRow(
                    icon: Icons.timer_outlined,
                    text: 'Link expires in 15 minutes',
                  ),
                  SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.security_rounded,
                    text: 'Link is single-use and encrypted',
                  ),
                  SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.folder_outlined,
                    text: 'Check spam if not in inbox',
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),

        _PremiumButton(
          label: 'RETURN TO LOGIN',
          icon: Icons.arrow_back_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
          ),
          isLoading: false,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _Orb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: opacity * 0.3),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: RoadOSColors.apexEmerald, size: 16),
        const SizedBox(width: 10),
        Text(
          text,
          style: GoogleFonts.outfit(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _PremiumButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final LinearGradient gradient;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _PremiumButton({
    required this.label,
    this.icon,
    required this.gradient,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  State<_PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<_PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _pressController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: widget.isLoading ? null : widget.gradient,
            color: widget.isLoading
                ? Colors.white.withValues(alpha: 0.08)
                : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.isLoading
                ? []
                : [
                    BoxShadow(
                      color: widget.gradient.colors.first.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: widget.isLoading
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
