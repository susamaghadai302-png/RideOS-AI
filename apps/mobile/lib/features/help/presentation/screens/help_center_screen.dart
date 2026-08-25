import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/design_system/design_tokens.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/design_system/theme_engine.dart';

class HelpTopic {
  final String title, category, content;
  const HelpTopic({required this.title, required this.category, required this.content});
}

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const List<HelpTopic> _topics = [
    HelpTopic(title: 'Connecting Bluetooth to your Motorcycle', category: 'CONNECTIVITY',
      content: '1. Turn on your motorcycle ignition switch.\n2. Ensure Bluetooth and Location permissions are enabled on your device.\n3. Open "Connect Vehicle" tab.\n4. Select your vehicle protocol (Yamaha Y-Connect, Ducati Link, BMW Motorrad, or Standard OBD-II).\n5. Tap the discovered device to establish encrypted connection.'),
    HelpTopic(title: 'Understanding ECU Fault Codes (DTCs)', category: 'DIAGNOSTICS',
      content: 'RideOS reads standardised SAE Diagnostic Trouble Codes (DTCs) from your vehicle ECU.\n- Powertrain codes begin with "P" (e.g. P0300 cylinder misfire).\n- Chassis codes begin with "C" (e.g. C0035 ABS wheel speed sensor).\n- Network codes begin with "U" (e.g. U0100 communication loss).\nFaults can only be cleared if supported by your protocol adapter.'),
    HelpTopic(title: 'How Odometer Tracking Works', category: 'MAINTENANCE',
      content: 'When connected to a compatible ECU, RideOS automatically streams your vehicle live odometer. If your vehicle does not expose electronic odometer data over Bluetooth, you can enter your current odometer reading manually in the Maintenance screen.'),
    HelpTopic(title: '3D Garage Camera & Inspection Controls', category: '3D GARAGE',
      content: '- Drag with one finger to rotate around the 3D vehicle.\n- Pinch with two fingers to zoom in on components.\n- Drag with two fingers to pan the camera.\n- Active diagnostic issues will highlight the corresponding vehicle component in red or amber.'),
    HelpTopic(title: 'Offline Navigation & Trip Synchronization', category: 'NAVIGATION',
      content: 'During rides, RideOS buffers GPS points locally on your phone. Even if cellular connectivity or Bluetooth drops mid-ride, trip recording continues seamlessly and synchronises to your account once connectivity is restored.'),
  ];

  static const Map<String, Color> _categoryColors = {
    'CONNECTIVITY': Color(0xFF00F2FE),
    'DIAGNOSTICS':  Color(0xFFFF3B5C),
    'MAINTENANCE':  Color(0xFFFFB800),
    '3D GARAGE':    Color(0xFF8A2BE2),
    'NAVIGATION':   Color(0xFF00E676),
  };

  @override
  Widget build(BuildContext context) {
    final isDark = LuxThemeEngine().isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: ShaderMask(
          shaderCallback: (b) => const LinearGradient(colors: [Color(0xFF00F2FE), Color(0xFF0066FF)]).createShader(b),
          child: Text('HELP & SUPPORT',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2)),
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        physics: const BouncingScrollPhysics(),
        itemCount: _topics.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final topic = _topics[index];
          final color = _categoryColors[topic.category] ?? const Color(0xFF00F2FE);
          return _LuxHelpTile(topic: topic, accentColor: color, isDark: isDark);
        },
      ),
    );
  }
}

class _LuxHelpTile extends StatelessWidget {
  final HelpTopic topic;
  final Color accentColor;
  final bool isDark;
  const _LuxHelpTile({required this.topic, required this.accentColor, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.40), blurRadius: 20, offset: const Offset(0, 6)),
          BoxShadow(color: accentColor.withValues(alpha: 0.06), blurRadius: 16),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: isDark ? [const Color(0x700D1226), const Color(0x85060B18)] : [Colors.white.withValues(alpha: 0.88), Colors.white.withValues(alpha: 0.72)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accentColor.withValues(alpha: 0.18), width: 1.1),
                ),
              ),
            ),
          ),
          // Left accent bar
          Positioned(top: 10, bottom: 10, left: 0, width: 3,
            child: Container(decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [accentColor.withValues(alpha: 0.9), accentColor.withValues(alpha: 0.05)],
              ),
              borderRadius: const BorderRadius.only(topRight: Radius.circular(2), bottomRight: Radius.circular(2)),
              boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.4), blurRadius: 8)],
            ))),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.fromLTRB(20, 4, 16, 4),
              childrenPadding: const EdgeInsets.fromLTRB(20, 0, 16, 16),
              iconColor: accentColor,
              collapsedIconColor: accentColor.withValues(alpha: 0.5),
              title: Text(topic.title,
                  style: GoogleFonts.outfit(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 13, fontWeight: FontWeight.w800,
                  )),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(topic.category,
                    style: GoogleFonts.robotoMono(color: accentColor, fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
              ),
              children: [
                Text(topic.content,
                    style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12, height: 1.6)),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
