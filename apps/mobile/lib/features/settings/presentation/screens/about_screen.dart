import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/widgets/cinematic_background.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: ShaderMask(
          shaderCallback: (b) => const LinearGradient(colors: [Color(0xFF00F2FE), Color(0xFF0066FF)]).createShader(b),
          child: Text('ABOUT RIDEOS',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2.5)),
        ),
        centerTitle: true,
      ),
      body: CinematicBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 120),
        physics: const BouncingScrollPhysics(),
        child: Column(children: [
          const SizedBox(height: 24),

          // Logo orb
          Container(
            width: 96, height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(colors: [Color(0xFF0D1A3A), Color(0xFF060912)]),
              border: Border.all(color: const Color(0xFF00F2FE).withValues(alpha: 0.45), width: 1.5),
              boxShadow: [
                BoxShadow(color: const Color(0xFF00F2FE).withValues(alpha: 0.25), blurRadius: 28),
                const BoxShadow(color: Colors.black, blurRadius: 10),
              ],
            ),
            child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF00F2FE), size: 44),
          ),
          const SizedBox(height: 20),

          ShaderMask(
            shaderCallback: (b) => const LinearGradient(colors: [Color(0xFF00F2FE), Color(0xFF0066FF)]).createShader(b),
            child: Text('RIDEOS PRO',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 4)),
          ),
          const SizedBox(height: 6),
          Text('Version 2.4.0 (Build 2400)',
              style: GoogleFonts.robotoMono(color: const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 32),

          // Mission card
          RoadOSCard(
            borderColor: const Color(0xFF00F2FE).withValues(alpha: 0.3),
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('CONNECTED MOTORCYCLE PLATFORM',
                  style: GoogleFonts.robotoMono(color: const Color(0xFF00F2FE), fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
              const SizedBox(height: 10),
              Text(
                'RideOS is an enterprise-grade connected vehicle ecosystem designed for modern riders. Featuring real-time BLE ECU telemetry, 3D WebGL digital twin rendering, offline-resilient turn-by-turn navigation, and SAE-standard vehicle health monitoring.',
                style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12, height: 1.65),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Legal rows
          _buildLuxLegalRow('Terms of Service',      'https://rideos.ai/terms',   Icons.article_outlined,          const Color(0xFF00F2FE), true),
          _buildLuxLegalRow('Privacy Policy',         'https://rideos.ai/privacy', Icons.privacy_tip_outlined,       const Color(0xFF00E676), true),
          _buildLuxLegalRow('Open Source Licenses',   'MIT & Apache 2.0',          Icons.code_rounded,               const Color(0xFF8A2BE2), true),
          _buildLuxLegalRow('Security Disclosure',    'security@rideos.ai',        Icons.security_rounded,           const Color(0xFFFFB800), true),
          const SizedBox(height: 40),
        ]),
      ),
      ),
    );
  }

  Widget _buildLuxLegalRow(String title, String value, IconData icon, Color accentColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? accentColor.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.80),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accentColor.withValues(alpha: 0.22), width: 1),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: 0.12),
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title,
                  style: GoogleFonts.outfit(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 13, fontWeight: FontWeight.w800,
                  ))),
              Text(value,
                  style: GoogleFonts.inter(color: accentColor, fontSize: 10, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_ios_rounded, color: accentColor.withValues(alpha: 0.6), size: 11),
            ]),
          ),
        ),
      ),
    );
  }
}
