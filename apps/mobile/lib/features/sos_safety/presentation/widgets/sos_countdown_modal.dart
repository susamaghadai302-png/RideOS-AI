import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/sos_bloc.dart';
import '../bloc/sos_event.dart';
import '../bloc/sos_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  SOS Countdown Modal — Luxury Edition
//  All original logic preserved. UI upgraded to premium OLED black + red glow.
// ─────────────────────────────────────────────────────────────────────────────

class SosCountdownModal extends StatefulWidget {
  const SosCountdownModal({super.key});

  @override
  State<SosCountdownModal> createState() => _SosCountdownModalState();
}

class _SosCountdownModalState extends State<SosCountdownModal>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _rippleCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _rippleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rippleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SosBloc, SosState>(
      listener: (context, state) {
        if (state is SosCancelledState || state is SosIdleState) {
          Navigator.of(context, rootNavigator: true).maybePop();
        }
      },
      builder: (context, state) {
        if (state is SosCountdownState) {
          return _buildCountdownView(context, state);
        }
        if (state is SosDispatchedState) {
          return _buildDispatchedView(context, state);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCountdownView(BuildContext context, SosCountdownState state) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pulsing warning icon
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFF3B5C).withValues(alpha: 0.08 + _pulseCtrl.value * 0.10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF3B5C).withValues(alpha: 0.30 + _pulseCtrl.value * 0.40),
                        blurRadius: 40 + _pulseCtrl.value * 20,
                        spreadRadius: 2 + _pulseCtrl.value * 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.warning_amber_rounded, size: 80, color: Color(0xFFFF3B5C)),
                ),
              ),
              const SizedBox(height: 28),

              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [Color(0xFFFF3B5C), Color(0xFFFF6B35)],
                ).createShader(b),
                child: Text('CRASH DETECTED!',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    )),
              ),
              const SizedBox(height: 10),
              Text('Dispatching emergency contacts in:',
                  style: GoogleFonts.inter(color: Colors.white60, fontSize: 15)),
              const SizedBox(height: 32),

              // Countdown orb with ripple rings
              SizedBox(
                width: 160, height: 160,
                child: AnimatedBuilder(
                  animation: _rippleCtrl,
                  builder: (_, child) {
                    return Stack(alignment: Alignment.center, children: [
                      // Ripple rings
                      for (int i = 0; i < 3; i++)
                        _RippleRing(
                          progress: (_rippleCtrl.value + i * 0.33) % 1.0,
                          color: const Color(0xFFFF3B5C),
                          maxRadius: 80,
                        ),
                      // Core orb
                      child!,
                    ]);
                  },
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                      border: Border.all(color: const Color(0xFFFF3B5C), width: 3),
                      boxShadow: [BoxShadow(color: const Color(0xFFFF3B5C).withValues(alpha: 0.55), blurRadius: 30)],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${state.secondsRemaining}',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Cancel button (3D press)
              _LuxSosBtn(
                label: 'I AM OK — CANCEL SOS',
                accentColor: const Color(0xFFFF3B5C),
                fillWhite: true,
                onTap: () {
                  HapticFeedback.heavyImpact();
                  context.read<SosBloc>().add(const CancelSosEvent());
                },
              ),
              const SizedBox(height: 12),
              // Confirm outline
              _LuxSosBtn(
                label: 'CONFIRM & DISPATCH NOW',
                accentColor: Colors.white,
                fillWhite: false,
                onTap: () {
                  HapticFeedback.heavyImpact();
                  context.read<SosBloc>().add(const ConfirmSosEvent());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDispatchedView(BuildContext context, SosDispatchedState state) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success orb
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00E676).withValues(alpha: 0.10),
                  boxShadow: [BoxShadow(color: const Color(0xFF00E676).withValues(alpha: 0.40), blurRadius: 40)],
                  border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.50), width: 2),
                ),
                child: const Icon(Icons.check_circle_rounded, size: 80, color: Color(0xFF00E676)),
              ),
              const SizedBox(height: 28),

              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [Color(0xFF00E676), Color(0xFF00F2FE)],
                ).createShader(b),
                child: Text('ALERT DISPATCHED',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    )),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  state.isOfflineQueued
                      ? 'Offline: Emergency payload queued locally and will sync as soon as connectivity returns.'
                      : 'Emergency contacts have been notified with your live GPS location.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 14, height: 1.6),
                ),
              ),
              const SizedBox(height: 48),

              _LuxSosBtn(
                label: 'DISMISS',
                accentColor: const Color(0xFF00E676),
                fillWhite: false,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  context.read<SosBloc>().add(const CancelSosEvent());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Ripple Ring ──────────────────────────────────────────────────────────────
class _RippleRing extends StatelessWidget {
  final double progress, maxRadius;
  final Color color;
  const _RippleRing({required this.progress, required this.maxRadius, required this.color});
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: (1.0 - progress).clamp(0.0, 1.0),
      child: Container(
        width: maxRadius * 2 * progress,
        height: maxRadius * 2 * progress,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.5),
        ),
      ),
    );
  }
}

// ── 3D SOS Button ────────────────────────────────────────────────────────────
class _LuxSosBtn extends StatefulWidget {
  final String label;
  final Color accentColor;
  final bool fillWhite;
  final VoidCallback onTap;
  const _LuxSosBtn({required this.label, required this.accentColor, required this.fillWhite, required this.onTap});
  @override State<_LuxSosBtn> createState() => _LuxSosBtnState();
}
class _LuxSosBtnState extends State<_LuxSosBtn> {
  double _scale = 1.0;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { HapticFeedback.mediumImpact(); setState(() => _scale = 0.93); },
      onTapUp: (_) { setState(() => _scale = 1.0); widget.onTap(); },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale, duration: const Duration(milliseconds: 110), curve: Curves.easeOutBack,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 17),
          decoration: BoxDecoration(
            color: widget.fillWhite ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: widget.fillWhite ? null : Border.all(color: widget.accentColor.withValues(alpha: 0.60), width: 1.5),
            boxShadow: widget.fillWhite ? [BoxShadow(color: Colors.white.withValues(alpha: 0.25), blurRadius: 18, offset: const Offset(0, 6))] : [],
          ),
          alignment: Alignment.center,
          child: Text(widget.label,
              style: GoogleFonts.outfit(
                color: widget.fillWhite ? const Color(0xFFFF3B5C) : widget.accentColor,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              )),
        ),
      ),
    );
  }
}
