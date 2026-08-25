import 'package:flutter/material.dart';
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard, RoadOSThemeEngine;


// ─────────────────────────────────────────────────────────────────────────────
//  PREMIUM OVERLAYS — re-exported from premium_overlays.dart (single source of truth).
//  All existing call-sites continue to compile unchanged.
//  For new code, prefer the showLuxDialog / showLuxSheet / showLuxSnack APIs.
// ─────────────────────────────────────────────────────────────────────────────

export 'premium_overlays.dart'
    show
        LuxSnackVariant,
        LuxSnackVariantX,
        showLuxSnack,
        LuxDialog,
        showLuxDialog,
        LuxBottomSheet,
        showLuxSheet,
        showPremiumDialog,
        showPremiumSheet,
        showPremiumSnack;

// ─────────────────────────────────────────────────────────────────────────────
//  PREMIUM NAVIGATION — Universal 420ms slide + fade route transition
//  Use premiumRoute() instead of MaterialPageRoute for ALL app-wide navigation.
// ─────────────────────────────────────────────────────────────────────────────

/// Drop-in replacement for MaterialPageRoute.
/// Returns a slide-from-right + fade route with 420ms Cubic easing.
Route<T> premiumRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondary) => page,
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    transitionsBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      final reverseCurved = CurvedAnimation(parent: secondary, curve: Curves.easeInCubic);
      return FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.055, 0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0.0).animate(reverseCurved),
            child: child,
          ),
        ),
      );
    },
  );
}
