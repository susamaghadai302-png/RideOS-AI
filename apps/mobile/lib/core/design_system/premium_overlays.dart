import 'dart:ui';
import 'package:rideos_mobile/core/design_system/roados_tokens.dart';

import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_engine.dart';
import '../services/lux_haptics_audio_service.dart';

// ═════════════════════════════════════════════════════════════════════════════
//  PREMIUM OVERLAYS — RideOS AI Luxury UI System
//
//  Exports:
//    | LuxSnackVariant      — success / error / info / warning
//    | showLuxSnack         — drop-in for ScaffoldMessenger.showSnackBar
//    | LuxDialog            — glassmorphic dialog widget
//    | showLuxDialog<T>     — drop-in for showDialog
//    | LuxBottomSheet       — glassmorphic draggable bottom sheet widget
//    | showLuxSheet<T>      — drop-in for showModalBottomSheet
//    | showPremiumDialog/Sheet/Snack — backward-compat aliases
//
//  Design contract:
//    ✓ LuxThemeEngine — adapts OLED dark ↔ pearl light automatically
//    ✓ RepaintBoundary — every BackdropFilter is on its own GPU layer
//    ✓ Semantic haptics — variant-aware feedback on every interaction
//    ✓ No Material AlertDialog or default SnackBar styling leaks
// ═════════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
//  1. SNACK VARIANT ENUM
// ─────────────────────────────────────────────────────────────────────────────

enum LuxSnackVariant { success, error, info, warning }

extension LuxSnackVariantX on LuxSnackVariant {
  Color get color => switch (this) {
        LuxSnackVariant.success => const Color(0xFF00E676),
        LuxSnackVariant.error   => const Color(0xFFFF3B5C),
        LuxSnackVariant.info    => const Color(0xFF00F2FE),
        LuxSnackVariant.warning => const Color(0xFFFFB800),
      };

  IconData get icon => switch (this) {
        LuxSnackVariant.success => Icons.check_circle_rounded,
        LuxSnackVariant.error   => Icons.error_rounded,
        LuxSnackVariant.info    => Icons.info_rounded,
        LuxSnackVariant.warning => Icons.warning_amber_rounded,
      };

  void haptic() {
    switch (this) {
      case LuxSnackVariant.success:
        LuxAudioHapticsService.selectionClick();
      case LuxSnackVariant.error:
        LuxAudioHapticsService.errorImpact();
      case LuxSnackVariant.warning:
        LuxAudioHapticsService.mediumImpact();
      case LuxSnackVariant.info:
        LuxAudioHapticsService.lightImpact();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  2. LUXURY SNACKBAR — floating pill toast
// ─────────────────────────────────────────────────────────────────────────────

/// Drop-in for [ScaffoldMessenger.showSnackBar].
///
/// Usage:
/// ```dart
/// showLuxSnack(context, 'BLE connected!', variant: LuxSnackVariant.success);
/// showLuxSnack(context, 'Engine fault detected', variant: LuxSnackVariant.error,
///   action: () => _viewFaults(), actionLabel: 'VIEW');
/// ```
void showLuxSnack(
  BuildContext context,
  String message, {
  LuxSnackVariant variant = LuxSnackVariant.info,
  Duration duration = const Duration(seconds: 3),
  VoidCallback? action,
  String? actionLabel,
  IconData? overrideIcon,
}) {
  variant.haptic();
  final color  = variant.color;
  final icon   = overrideIcon ?? variant.icon;
  final isDark = LuxThemeEngine().isDarkMode;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: duration,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        content: RepaintBoundary(
          child: _LuxSnackContent(
            message: message,
            color: color,
            icon: icon,
            isDark: isDark,
            action: action,
            actionLabel: actionLabel,
          ),
        ),
      ),
    );
}

class _LuxSnackContent extends StatelessWidget {
  final String message;
  final Color color;
  final IconData icon;
  final bool isDark;
  final VoidCallback? action;
  final String? actionLabel;

  const _LuxSnackContent({
    required this.message,
    required this.color,
    required this.icon,
    required this.isDark,
    this.action,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    colors: [Color(0xDD0A0D1A), Color(0xEE060912)],
                  )
                : LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.92),
                      Colors.white.withValues(alpha: 0.82),
                    ],
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.45), width: 1.2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.20), blurRadius: 20, spreadRadius: -2),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.08),
                blurRadius: 16,
              ),
            ],
          ),
          child: Row(
            children: [
              // Glowing icon orb
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12),
                  border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
                ),
                child: Center(child: Icon(icon, color: color, size: 18)),
              ),
              const SizedBox(width: 12),
              // Message
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
              // Optional action button
              if (action != null && actionLabel != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    LuxAudioHapticsService.lightImpact();
                    action!();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withValues(alpha: 0.40), width: 1),
                    ),
                    child: Text(
                      actionLabel!,
                      style: GoogleFonts.outfit(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  3. LUX DIALOG WIDGET
// ─────────────────────────────────────────────────────────────────────────────

/// Glassmorphic luxury dialog. Pair with [showLuxDialog].
///
/// Usage:
/// ```dart
/// final confirmed = await showLuxDialog<bool>(
///   context: context,
///   child: LuxDialog(
///     title: 'Disconnect Vehicle?',
///     message: 'This will end the active BLE session.',
///     variant: LuxSnackVariant.warning,
///     confirmLabel: 'DISCONNECT',
///     onConfirm: () => Navigator.pop(context, true),
///   ),
/// );
/// ```
class LuxDialog extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? body;
  final LuxSnackVariant variant;
  final IconData? icon;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  /// Set [showCancel] to false for purely informational dialogs.
  final bool showCancel;

  const LuxDialog({
    super.key,
    required this.title,
    this.message,
    this.body,
    this.variant = LuxSnackVariant.info,
    this.icon,
    this.confirmLabel = 'OK',
    this.cancelLabel = 'CANCEL',
    this.onConfirm,
    this.onCancel,
    this.showCancel = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark       = LuxThemeEngine().isDarkMode;
    final accentColor  = variant.color;
    final effectiveIcon = icon ?? variant.icon;

    return RepaintBoundary(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xE80D1226), Color(0xF5060912)],
                          )
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.95),
                              Colors.white.withValues(alpha: 0.88),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.70 : 0.12),
                        blurRadius: 48,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: accentColor.withValues(alpha: isDark ? 0.10 : 0.06),
                        blurRadius: 32,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Accent top rim (color bar)
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, accentColor, Colors.transparent],
                          ),
                          borderRadius:
                              const BorderRadius.vertical(top: Radius.circular(28)),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icon orb
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accentColor.withValues(alpha: 0.10),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.40),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.25),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(effectiveIcon, color: accentColor, size: 30),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Title
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),

                            if (message != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                message!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                  fontSize: 13.5,
                                  height: 1.55,
                                ),
                              ),
                            ],

                            if (body != null) ...[
                              const SizedBox(height: 12),
                              body!,
                            ],

                            const SizedBox(height: 28),
                          ],
                        ),
                      ),

                      // Divider
                      Container(
                        height: 1,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04),
                      ),

                      // Action row
                      IntrinsicHeight(
                        child: Row(
                          children: [
                            if (showCancel) ...[
                              Expanded(
                                child: _LuxDialogButton(
                                  label: cancelLabel,
                                  color: isDark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                  onTap: () {
                                    LuxAudioHapticsService.lightImpact();
                                    if (onCancel != null) {
                                      onCancel!();
                                    } else {
                                      Navigator.of(context).pop(false);
                                    }
                                  },
                                ),
                              ),
                              VerticalDivider(
                                width: 1,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.04),
                              ),
                            ],
                            Expanded(
                              child: _LuxDialogButton(
                                label: confirmLabel,
                                color: accentColor,
                                onTap: () {
                                  LuxAudioHapticsService.mediumImpact();
                                  if (onConfirm != null) {
                                    onConfirm!();
                                  } else {
                                    Navigator.of(context).pop(true);
                                  }
                                },
                              ),
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

class _LuxDialogButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _LuxDialogButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_LuxDialogButton> createState() => _LuxDialogButtonState();
}

class _LuxDialogButtonState extends State<_LuxDialogButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _scale = 0.94),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: widget.color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  4. showLuxDialog<T>
// ─────────────────────────────────────────────────────────────────────────────

/// Drop-in for [showDialog]. Entrance: scale 0.85→1.0 with easeOutBack bounce.
Future<T?> showLuxDialog<T>({
  required BuildContext context,
  required Widget child,
  bool barrierDismissible = true,
}) {
  LuxAudioHapticsService.lightImpact();
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 360),
    transitionBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
    pageBuilder: (context, animation, secondary) => child,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  5. LUXURY BOTTOM SHEET WIDGET
// ─────────────────────────────────────────────────────────────────────────────

/// Glassmorphic draggable bottom sheet. Pair with [showLuxSheet].
///
/// Usage:
/// ```dart
/// await showLuxSheet(
///   context: context,
///   title: 'Quick Tools',
///   accentColor: RoadOSColors.cyberCyan,
///   builder: (ctx) => _QuickToolsContent(),
/// );
/// ```
class LuxBottomSheet extends StatelessWidget {
  final String? title;
  final Widget child;
  final Color? accentColor;

  const LuxBottomSheet({
    super.key,
    this.title,
    required this.child,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = LuxThemeEngine().isDarkMode;
    final accent = accentColor ?? RoadOSColors.hyperOrange;

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
          child: Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xCC0D1226), Color(0xF5060912)],
                    )
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.94),
                        Colors.white.withValues(alpha: 0.88),
                      ],
                    ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  width: 1.0,
                ),
                left: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  width: 1.0,
                ),
                right: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  width: 1.0,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing accent drag handle
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent.withValues(alpha: 0.35),
                          accent.withValues(alpha: 0.90),
                          accent.withValues(alpha: 0.35),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(color: accent.withValues(alpha: 0.45), blurRadius: 10),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Optional title with accent left bar
                if (title != null) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: 18,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.65),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          title!,
                          style: GoogleFonts.outfit(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Sheet content
                child,

                // Safe-area bottom inset
                SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  6. showLuxSheet<T>
// ─────────────────────────────────────────────────────────────────────────────

/// Drop-in for [showModalBottomSheet]. Wraps [builder] in [LuxBottomSheet].
Future<T?> showLuxSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  Color? accentColor,
  bool isScrollControlled = true,
  bool enableDrag = true,
}) {
  LuxAudioHapticsService.lightImpact();
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.62),
    useSafeArea: true,
    builder: (ctx) => LuxBottomSheet(
      title: title,
      accentColor: accentColor,
      child: builder(ctx),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  7. BACKWARD-COMPATIBLE ALIASES
//     (premium_navigation.dart re-exports these)
// ─────────────────────────────────────────────────────────────────────────────

/// Backward-compat alias for [showLuxDialog].
Future<T?> showPremiumDialog<T>({
  required BuildContext context,
  required Widget child,
  bool barrierDismissible = true,
}) =>
    showLuxDialog<T>(
      context: context,
      child: child,
      barrierDismissible: barrierDismissible,
    );

/// Backward-compat alias for [showLuxSheet].
Future<T?> showPremiumSheet<T>({
  required BuildContext context,
  required Widget child,
  bool isScrollControlled = true,
}) =>
    showLuxSheet<T>(
      context: context,
      builder: (_) => child,
      isScrollControlled: isScrollControlled,
    );

/// Backward-compat alias for [showLuxSnack].
void showPremiumSnack(
  BuildContext context,
  String message, {
  Color? accentColor,
  IconData? icon,
}) {
  LuxSnackVariant variant = LuxSnackVariant.info;
  if (accentColor != null) {
    if (accentColor == const Color(0xFF00E676) ||
        accentColor == RoadOSColors.apexEmerald) {
      variant = LuxSnackVariant.success;
    } else if (accentColor == const Color(0xFFFF3B5C) ||
        accentColor == RoadOSColors.errorCrimson) {
      variant = LuxSnackVariant.error;
    } else if (accentColor == const Color(0xFFFFB800)) {
      variant = LuxSnackVariant.warning;
    }
  }
  showLuxSnack(context, message, variant: variant, overrideIcon: icon);
}
