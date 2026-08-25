import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Central haptic feedback service for the RideOS luxury experience.
///
/// Semantic method naming lets call-sites communicate *intent*, not vibration
/// intensity, so the whole app stays consistent even if intensity values are
/// tuned per-platform later.
class LuxAudioHapticsService {
  // ── Physical / mechanical feel ─────────────────────────────────────────────

  /// Navigation taps, toggles, list-item selection.
  static void lightImpact() => HapticFeedback.lightImpact();

  /// Standard button press; card tap; dismissal.
  static void mediumImpact() => HapticFeedback.mediumImpact();

  /// Power action (e.g. engine start, major confirmation).
  static void heavyImpact() => HapticFeedback.heavyImpact();

  /// Picker scroll tick, segmented-control change.
  static void selectionClick() => HapticFeedback.selectionClick();

  // ── Semantic shortcuts ─────────────────────────────────────────────────────

  /// Login / sign-up form submission — single authoritative medium press.
  static void formSubmit() => HapticFeedback.mediumImpact();

  /// Positive outcome confirmation: connection established, save success.
  static Future<void> successPattern() async {
    HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    HapticFeedback.lightImpact();
  }

  /// Destructive / irreversible action warning before the action fires.
  static void dangerAlert() => HapticFeedback.heavyImpact();

  /// Error state — inline field validation failure or API error.
  static void errorImpact() => HapticFeedback.vibrate();

  /// SOS / emergency — long vibrate to ensure physical awareness.
  static void alertVibrate() => HapticFeedback.vibrate();
}

/// Mixin for StatefulWidgets that need consistent press-scale haptics.
/// Mix in, then call [hapticTapDown] / [hapticTapUp] from GestureDetector.
mixin LuxPressMixin<T extends StatefulWidget> on State<T> {
  double pressScale = 1.0;

  void hapticTapDown(TapDownDetails _) {
    HapticFeedback.lightImpact();
    setState(() => pressScale = 0.95);
  }

  void hapticTapUp(TapUpDetails _, VoidCallback callback) {
    setState(() => pressScale = 1.0);
    callback();
  }

  void hapticTapCancel() => setState(() => pressScale = 1.0);
}
