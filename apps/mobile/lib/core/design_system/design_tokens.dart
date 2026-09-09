import 'package:flutter/material.dart';


import 'package:google_fonts/google_fonts.dart';

/// RIDEOS AI INFINITY EDITION - ENTERPRISE 3D AUTOMOTIVE DESIGN SYSTEM
class LuxColors {
  // Deep Space Automotive Canvas & Cockpit Tones
  static const Color carbonBlack = Color(0xFF04060C);
  static const Color deepSpaceBlue = Color(0xFF070B18);
  static const Color midnightObsidian = Color(0xFF0D1226);
  static const Color titaniumSlate = Color(0xFF14192E);
  static const Color obsidianCard = Color(0xFF161C36);
  static const Color metallicBorder = Color(0xFF2B3654);
  static const Color neonBorderGlow = Color(0xFF384973);

  // Light Palette / Day Mode Fallbacks
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color pearlCanvas = Color(0xFFF1F5F9);
  static const Color glassWhiteCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color darkText = Color(0xFF0F172A);
  static const Color mutedTextLight = Color(0xFF64748B);

  // High-Tech Cyber Automotive Accents
  static const Color hyperOrange = Color(0xFFFF5500);    // Cockpit & Primary Brand
  static const Color sunsetFlame = Color(0xFFFF7A00);    // Warm Atmospheric Glow
  static const Color quantumCyan = Color(0xFF00F2FE);    // 3D Navigation & Vector HUD
  static const Color electricBlue = Color(0xFF0066FF);   // High-Speed Telematics
  static const Color cyberMagenta = Color(0xFFFF007A);   // Jarvis Neural Core & Voice AI
  static const Color neonPink = Color(0xFFF43F5E);       // Reactive Warning Accents
  static const Color apexEmerald = Color(0xFF00E676);    // Vehicle Health Nominal
  static const Color warningAmber = Color(0xFFFFB300);   // Road Hazard & Caution
  static const Color alertCrimson = Color(0xFFFF1744);   // SOS Emergency
  static const Color cyberPurple = Color(0xFF8A2BE2);    // Quantum Copilot
  static const Color solarGold = Color(0xFFFFD700);      // Livery & Showroom Gold

  // Typography Tones
  static const Color platinumWhite = Color(0xFFF8FAFC);
  static const Color mutedSilver = Color(0xFF94A3B8);
  static const Color softIndigo = Color(0xFFCBD5E1);
}

class LuxGradients {
  static const LinearGradient hyperOrange = LinearGradient(
    colors: [Color(0xFFFF5500), Color(0xFFFF8C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient quantumCyan = LinearGradient(
    colors: [Color(0xFF00F2FE), Color(0xFF0066FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient electricBlue = LinearGradient(
    colors: [Color(0xFF0066FF), Color(0xFF00D4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyberPurple = LinearGradient(
    colors: [Color(0xFF8A2BE2), Color(0xFFFF007A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyberMagenta = LinearGradient(
    colors: [Color(0xFFFF007A), Color(0xFFFF5500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cockpitAtmosphere = LinearGradient(
    colors: [Color(0xFF04060C), Color(0xFF0D1226), Color(0xFF14192E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient auroraSpectrum = LinearGradient(
    colors: [Color(0xFFFF5500), Color(0xFFFF007A), Color(0xFF8A2BE2), Color(0xFF00F2FE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient liquidGlassDark = LinearGradient(
    colors: [Color(0x551E2744), Color(0x220D1226)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassBorder = LinearGradient(
    colors: [Color(0x99FFFFFF), Color(0x22FFFFFF), Color(0x6600F2FE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient neonBorderMagenta = LinearGradient(
    colors: [Color(0xFFFF007A), Color(0xFF8A2BE2), Color(0x3300F2FE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient liquidGlassLight = LinearGradient(
    colors: [Color(0xCCFFFFFF), Color(0x88F1F5F9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldPulse = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF00D4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const RadialGradient auroraGlow = RadialGradient(
    colors: [Color(0x5500F2FE), Color(0x33FF007A), Color(0x228A2BE2), Colors.transparent],
    radius: 0.9,
  );
}

class LuxTypography {
  static TextStyle displayXL({required Color color}) => GoogleFonts.orbitron(
        fontSize: 48,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.0,
        color: color,
      );

  static TextStyle displayL({required Color color}) => GoogleFonts.orbitron(
        fontSize: 36,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle speedDisplay({required Color color}) => GoogleFonts.orbitron(
        fontSize: 76,
        fontWeight: FontWeight.w900,
        letterSpacing: -2.0,
        height: 0.9,
        color: color,
      );

  static TextStyle numericDisplay({required Color color}) => GoogleFonts.orbitron(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
        color: color,
      );

  static TextStyle displayHeader({required Color color}) => GoogleFonts.orbitron(
        fontSize: 30,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle titleLarge({required Color color}) => GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
        color: color,
      );

  static TextStyle titleMedium({required Color color}) => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle bodyLarge({required Color color}) => GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle bodyMedium({required Color color}) => GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle caption({required Color color}) => GoogleFonts.outfit(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: color,
      );

  static TextStyle button({required Color color}) => GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: color,
      );
}

class LuxSpacing {
  static const double p4 = 4.0;
  static const double p8 = 8.0;
  static const double p12 = 12.0;
  static const double p16 = 16.0;
  static const double p20 = 20.0;
  static const double p24 = 24.0;
  static const double p32 = 32.0;
  static const double p40 = 40.0;
  static const double p48 = 48.0;
  static const double p64 = 64.0;
  static const double p80 = 80.0;
  static const double p96 = 96.0;

  // Legacy aliases
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class LuxRadius {
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  static const double extraLarge = 32.0;

  // Legacy aliases
  static const double sm = 12.0;
  static const double md = 18.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double circular = 999.0;
}

class LuxShadows {
  static List<BoxShadow> glassGlow(Color glowColor) => [
        BoxShadow(
          color: glowColor.withValues(alpha: 0.35),
          blurRadius: 28,
          spreadRadius: -2,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.55),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> neonAura(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.5),
          blurRadius: 22,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.7),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> neumorphicDark = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.6),
      offset: const Offset(4, 4),
      blurRadius: 12,
    ),
    BoxShadow(
      color: const Color(0xFF222C3D).withValues(alpha: 0.35),
      offset: const Offset(-3, -3),
      blurRadius: 10,
    ),
  ];

  static List<Shadow> textGlow(Color glowColor) => [
        Shadow(
          color: glowColor.withValues(alpha: 0.8),
          blurRadius: 16,
        ),
      ];
}

/// RESPONSIVE BREAKPOINT UTILITY FOR DESKTOP, TABLET & MOBILE VIEWPORTS
class LuxResponsive {
  static const double mobileMax = 600.0;
  static const double tabletMax = 1024.0;
  static const double contentMaxWidth = 920.0;

  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width > tabletMax;
  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w > mobileMax && w <= tabletMax;
  }
  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width <= mobileMax;

  static double contentWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w > contentMaxWidth ? contentMaxWidth : w;
  }
}

