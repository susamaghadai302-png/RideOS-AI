// This file is a backwards-compatible redirect.
// ThreeDGarageScreen now delegates entirely to LuxuryGarageShowroomScreen
// which renders photorealistic motorcycle images in a cinematic showroom.
import 'package:flutter/material.dart';
import 'luxury_garage_showroom_screen.dart';

/// @deprecated Use [LuxuryGarageShowroomScreen] directly.
/// Kept for backwards-compat with any deep-links or tests.
class ThreeDGarageScreen extends StatelessWidget {
  const ThreeDGarageScreen({super.key});

  @override
  Widget build(BuildContext context) => const LuxuryGarageShowroomScreen();
}
