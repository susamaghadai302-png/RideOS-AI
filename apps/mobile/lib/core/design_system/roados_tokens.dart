import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// RideOS Pro Ultra-Futuristic Automotive Design Tokens (Reference Theme)
class RoadOSColors {
  // Brand Primary & Futuristic Accents
  static const Color neonViolet = Color(0xFF8B5CF6);
  static const Color electricIndigo = Color(0xFF6366F1);
  static const Color electricBlue = Color(0xFF3B82F6);
  static const Color cyberCyan = Color(0xFF06B6D4);
  static const Color neonMagenta = Color(0xFFD946EF);
  static const Color roadCyan = Color(0xFF00F2FE);
  static const Color hyperOrange = Color(0xFFF97316);
  static const Color apexEmerald = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color errorCrimson = Color(0xFFEF4444);
  static const Color goldAccent = Color(0xFFFBBF24);

  // Dark Cinematic Futuristic Palette
  static const Color deepSpaceBlack = Color(0xFF040714); // Primary dark background
  static const Color midnightNavy = Color(0xFF080D22); // Structural dark surface
  static const Color obsidianSurface = Color(0xFF0C132C); // Mid layer surface
  static const Color cardSurface = Color(0xFF101733); // Card container
  static const Color elevatedSurface = Color(0xFF172146); // Elevated capsule / hover
  static const Color glassSurface = Color(0x2B101A38); // Ultra-translucent liquid glass surface
  static const Color liquidGlassHighlight = Color(0x66FFFFFF); // Glass top-edge specular highlight
  static const Color liquidGlassSheen = Color(0x14FFFFFF); // Subsurface water reflection sheen
  static const Color borderTranslucent = Color(0x386366F1); // Glowing indigo border
  static const Color borderCyan = Color(0x4006B6D4); // Subtle cyan border
  static const Color borderSubtle = Color(0x2FFFFFFF); // 18% white glass rim outline
  static const Color borderGlassSpecular = Color(0x55FFFFFF); // Specular glass bevel border

  // Light Theme Palette (Fallback)
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCardSurface = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Typography & Neutrals
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textCyan = Color(0xFF00F2FE);
  static const Color textViolet = Color(0xFFA78BFA);
  static const Color platinumWhite = Color(0xFFF8FAFC);

  // Extended Accent Colors (referenced across the codebase)
  static const Color solarGold = Color(0xFFFFD700); // Solar gold accent
  static const Color obsidianCard = Color(0xFF101733); // Card alias (same as cardSurface)
  static const Color crimsonRed = Color(0xFFEF4444); // Alias of errorCrimson
  static const Color titaniumSlate = Color(0xFF334155); // Dark slate/titanium
  static const Color starlightSilver = Color(0xFFCBD5E1); // Light silver accent

  // Gradient tokens (LinearGradient — static final, not const)
  static final LinearGradient hyperOrangeGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B35), Color(0xFFF97316)],
  );
  static final LinearGradient cyberCyanGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00BFFF), Color(0xFF06B6D4)],
  );
  static final LinearGradient violetGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
  );
  static final LinearGradient emeraldGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  // Convenience decoration helpers
  static BoxDecoration glassCardDecoration({
    Color? glowColor,
    double radius = 18,
    double borderWidth = 1.0,
  }) {
    return BoxDecoration(
      color: const Color(0xFF101733).withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: (glowColor ?? const Color(0xFF6366F1)).withValues(alpha: 0.25),
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: (glowColor ?? const Color(0xFF6366F1)).withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        const BoxShadow(
          color: Color(0x44000000),
          blurRadius: 6,
          offset: Offset(0, 3),
        ),
      ],
    );
  }
}

/// Standardized Motion System for Consistent, Jitter-Free Animations
class RoadOSMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration smooth = Duration(milliseconds: 450);
  static const Duration cinematic = Duration(milliseconds: 700);
  static const Duration masterChoreography = Duration(milliseconds: 3800);

  static const Curve standardEase = Curves.easeOutCubic;
  static const Curve smoothOut = Curves.easeOutQuart;
  static const Curve springy = Curves.easeOutBack;
  static const Curve entrance = Curves.easeInOutCubic;
}

class RoadOSGradients {
  static const LinearGradient anodizedCyan = LinearGradient(
    colors: [Color(0xFF80F3FF), Color(0xFF00E5FF), Color(0xFF0052CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryViolet = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brandCyan = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient electricPill = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient hyperOrange = LinearGradient(
    colors: [Color(0xFFFF5500), Color(0xFFFF8C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldSpeed = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient crimsonAlert = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    begin: Alignment(-0.9, -1.0),
    end: Alignment(0.9, 1.0),
    colors: [
      Color(0x35FFFFFF), // Specular light hit
      Color(0x18121B38), // Translucent liquid body
      Color(0x22080E24), // Ambient refracted base
      Color(0x2806B6D4), // Subtle water-cyan caustic glow
    ],
    stops: [0.0, 0.4, 0.8, 1.0],
  );

  static const LinearGradient liquidWaterGlass = LinearGradient(
    begin: Alignment(-0.85, -1.0),
    end: Alignment(0.85, 1.0),
    colors: [
      Color(0x35FFFFFF), // Intense specular top light
      Color(0x28162244), // Highly translucent fluid body
      Color(0x2A090F26), // Depth absorption
      Color(0x1800F2FE), // Liquid cyan refraction
    ],
    stops: [0.0, 0.35, 0.75, 1.0],
  );

  static const LinearGradient glassSpecularBorder = LinearGradient(
    begin: Alignment(-0.8, -1.0),
    end: Alignment(0.8, 1.0),
    colors: [
      Color(0x88FFFFFF), // Crisp top-left specular bevel
      Color(0x28FFFFFF), // Soft glass side rim
      Color(0x1500F2FE), // Very subtle water refraction edge
      Color(0x446366F1), // Indigo bottom-right rim glow
    ],
    stops: [0.0, 0.35, 0.7, 1.0],
  );

  static const LinearGradient waterSheenOverlay = LinearGradient(
    begin: Alignment(-1.0, -0.6),
    end: Alignment(1.0, 0.6),
    colors: [
      Color(0x00FFFFFF),
      Color(0x1AFFFFFF),
      Color(0x00FFFFFF),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient capsuleGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x401E2B58), Color(0x250D142E)],
  );

  static const LinearGradient roadHorizon = LinearGradient(
    colors: [Color(0xFF040714), Color(0xFF0A1028), Color(0xFF10193E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class RoadOSShadows {
  static List<BoxShadow> neonGlow({Color color = const Color(0xFF6366F1), double opacity = 0.35, double blur = 18}) => [
        BoxShadow(
          color: color.withValues(alpha: opacity),
          blurRadius: blur,
          spreadRadius: 1,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> cyanGlow({double opacity = 0.25, double blur = 14}) => [
        BoxShadow(
          color: const Color(0xFF06B6D4).withValues(alpha: opacity),
          blurRadius: blur,
          spreadRadius: 1,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> luxuryCard = [
    // Deep ambient occlusion
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.75),
      blurRadius: 36,
      spreadRadius: -4,
      offset: const Offset(0, 16),
    ),
    // Core structural shadow
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.45),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    // Subtle ambient color reflection
    BoxShadow(
      color: const Color(0xFF06B6D4).withValues(alpha: 0.05),
      blurRadius: 24,
      spreadRadius: -2,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
      blurRadius: 30,
      spreadRadius: -1,
      offset: const Offset(0, -2),
    ),
  ];

  static List<BoxShadow> liquidGlassElevation = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.8),
      blurRadius: 40,
      spreadRadius: -5,
      offset: const Offset(0, 20),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.5),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: const Color(0xFF00F2FE).withValues(alpha: 0.15),
      blurRadius: 24,
      spreadRadius: -4,
      offset: const Offset(0, 10),
    ),
  ];
}

class RoadOSTypography {
  static const List<Shadow> _subtleDepth = [
    Shadow(color: Color(0x66000000), offset: Offset(0, 1.5), blurRadius: 2.0),
  ];

  static TextStyle get heroDisplay => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: RoadOSColors.textPrimary,
        letterSpacing: 1.2,
        shadows: _subtleDepth,
      );

  static TextStyle get screenTitle => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: RoadOSColors.textPrimary,
        letterSpacing: 2.0,
        shadows: _subtleDepth,
      );

  static TextStyle get sectionHeader => GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: RoadOSColors.textSecondary,
        letterSpacing: 1.8,
      );

  static TextStyle get cardTitle => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: RoadOSColors.textPrimary,
        shadows: _subtleDepth,
      );

  static TextStyle get metricValue => GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: RoadOSColors.textPrimary,
        shadows: _subtleDepth,
      );

  static TextStyle get metricLabel => GoogleFonts.outfit(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: RoadOSColors.textMuted,
        letterSpacing: 1.4,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: RoadOSColors.textSecondary,
      );

  static TextStyle bodyMedium({Color? color}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color ?? RoadOSColors.textPrimary,
      );

  static TextStyle bodyLarge({Color? color}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: color ?? RoadOSColors.textPrimary,
      );

  static TextStyle caption({Color? color}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color ?? RoadOSColors.textMuted,
      );

  static TextStyle titleLarge({Color? color}) => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: color ?? RoadOSColors.textPrimary,
      );

  static TextStyle titleMedium({Color? color}) => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color ?? RoadOSColors.textPrimary,
      );

  static TextStyle get badge => GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      );
}

