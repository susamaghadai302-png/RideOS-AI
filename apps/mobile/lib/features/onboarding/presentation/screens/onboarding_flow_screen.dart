import 'package:flutter/material.dart';
import '../../../../core/widgets/cinematic_background.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/design_system/premium_navigation.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../auth/presentation/screens/welcome_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  PREMIUM 3-PAGE ONBOARDING FLOW
//  Only shown on first launch. Persisted via SharedPreferences key
//  'onboarding_completed'. Uses RoadOSCard, 3D press button, and
//  custom animated dot indicator.
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingFlowScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  const OnboardingFlowScreen({super.key, this.onComplete});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen>
    with TickerProviderStateMixin {

  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Per-page entry animation
  late AnimationController _pageAnim;
  late Animation<double> _pageFade;
  late Animation<Offset> _pageSlide;

  // Button press effect
  double _btnScale = 1.0;

  // ── 3 focused luxury pages ─────────────────────────────────────────────────
  static const List<_OnboardingPage> _pages = [
    _OnboardingPage(
      tag:         'AI INTELLIGENCE',
      accentColor: Color(0xFF00F2FE),    // quantum cyan
      icon:        Icons.psychology_rounded,
      gradientColors: [Color(0xFF0066FF), Color(0xFF00F2FE)],
      title:       'Neural AI Copilot',
      subtitle:    'Real-time motorcycle intelligence',
      description: 'Jarvis AI listens to your engine, monitors lean angles, and predicts component failures before they happen — all on-device.',
    ),
    _OnboardingPage(
      tag:         'CONNECTIVITY',
      accentColor: Color(0xFF8A2BE2),    // neon violet
      icon:        Icons.bluetooth_connected_rounded,
      gradientColors: [Color(0xFF8A2BE2), Color(0xFFFF007A)],
      title:       'Direct BLE Link',
      subtitle:    'Zero simulation. Raw telemetry.',
      description: 'Connect to any ECU, OBD-II dongle, or CCU. Stream RPM, speed, temperature & lean angle with sub-20ms latency over encrypted BLE.',
    ),
    _OnboardingPage(
      tag:         '3D EXPERIENCE',
      accentColor: Color(0xFF00E676),    // apex emerald
      icon:        Icons.view_in_ar_rounded,
      gradientColors: [Color(0xFF00E676), Color(0xFF00F2FE)],
      title:       'Digital Twin Garage',
      subtitle:    'Your bike. Photorealistic 3D.',
      description: 'Inspect your exact motorcycle with physically based 3D models, interactive component diagnostics, and live health overlays.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    _pageFade = CurvedAnimation(parent: _pageAnim, curve: Curves.easeOut);
    _pageSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _pageAnim, curve: Curves.easeOutCubic));
    _pageAnim.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pageAnim.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    LuxAudioHapticsService.successPattern();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
    } catch (_) {}
    if (!mounted) return;
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.pushReplacement(context, premiumRoute(const WelcomeScreen()));
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      LuxAudioHapticsService.lightImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _onPageChanged(int idx) {
    _pageAnim.reset();
    setState(() => _currentPage = idx);
    _pageAnim.forward();
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: CinematicBackground(child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background: animated accent glow for current page ─────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF000000),
                  page.accentColor.withValues(alpha: 0.07),
                  const Color(0xFF000000),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ── Main content ─────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Top bar: page tag + skip
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _LuxTagBadge(
                          key: ValueKey(_currentPage),
                          label: page.tag,
                          accentColor: page.accentColor,
                        ),
                      ),
                      if (!isLast)
                        TextButton(
                          onPressed: () {
                            LuxAudioHapticsService.lightImpact();
                            _finishOnboarding();
                          },
                          child: Text(
                            'SKIP',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 56),
                    ],
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _OnboardingPageView(
                        page: _pages[index],
                        pageFade: index == _currentPage ? _pageFade : const AlwaysStoppedAnimation(1.0),
                        pageSlide: index == _currentPage ? _pageSlide : const AlwaysStoppedAnimation(Offset.zero),
                      );
                    },
                  ),
                ),

                // ── Custom dot indicator ────────────────────────────────────
                _LuxDotIndicator(
                  count: _pages.length,
                  current: _currentPage,
                  pages: _pages,
                ),
                const SizedBox(height: 28),

                // ── 3D press CTA button ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  child: GestureDetector(
                    onTapDown: (_) {
                      LuxAudioHapticsService.lightImpact();
                      setState(() => _btnScale = 0.95);
                    },
                    onTapUp: (_) {
                      setState(() => _btnScale = 1.0);
                      _nextPage();
                    },
                    onTapCancel: () => setState(() => _btnScale = 1.0),
                    child: AnimatedScale(
                      scale: _btnScale,
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOutBack,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        height: 56,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: page.gradientColors),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: page.accentColor.withValues(alpha: 0.45),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Text(
                              isLast ? '  GET STARTED  ' : '  CONTINUE  ',
                              key: ValueKey(isLast),
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      )),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PAGE CONTENT — RoadOSCard hero
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingPageView extends StatelessWidget {
  final _OnboardingPage page;
  final Animation<double> pageFade;
  final Animation<Offset> pageSlide;

  const _OnboardingPageView({
    required this.page,
    required this.pageFade,
    required this.pageSlide,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: pageFade,
      child: SlideTransition(
        position: pageSlide,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: RoadOSCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon orb
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        page.accentColor.withValues(alpha: 0.20),
                        page.accentColor.withValues(alpha: 0.06),
                      ],
                    ),
                    border: Border.all(color: page.accentColor.withValues(alpha: 0.50), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: page.accentColor.withValues(alpha: 0.25), blurRadius: 24),
                    ],
                  ),
                  child: ShaderMask(
                    shaderCallback: (bounds) =>
                        LinearGradient(colors: page.gradientColors).createShader(bounds),
                    child: Icon(page.icon, size: 52, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                ShaderMask(
                  shaderCallback: (bounds) =>
                      LinearGradient(colors: page.gradientColors).createShader(bounds),
                  child: Text(
                    page.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  page.subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: page.accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 18),

                // Description
                Text(
                  page.description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 13.5,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CUSTOM ANIMATED DOT INDICATOR
// ─────────────────────────────────────────────────────────────────────────────

class _LuxDotIndicator extends StatelessWidget {
  final int count;
  final int current;
  final List<_OnboardingPage> pages;

  const _LuxDotIndicator({required this.count, required this.current, required this.pages});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        final color = pages[i].accentColor;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive ? color : color.withValues(alpha: 0.25),
            boxShadow: isActive
                ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: -1)]
                : null,
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TAG BADGE
// ─────────────────────────────────────────────────────────────────────────────

class _LuxTagBadge extends StatelessWidget {
  final String label;
  final Color accentColor;
  const _LuxTagBadge({super.key, required this.label, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withValues(alpha: 0.40), width: 1),
        boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.15), blurRadius: 10)],
      ),
      child: Text(
        label,
        style: GoogleFonts.robotoMono(
          color: accentColor,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.6,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingPage {
  final String tag;
  final Color accentColor;
  final IconData icon;
  final List<Color> gradientColors;
  final String title;
  final String subtitle;
  final String description;

  const _OnboardingPage({
    required this.tag,
    required this.accentColor,
    required this.icon,
    required this.gradientColors,
    required this.title,
    required this.subtitle,
    required this.description,
  });
}
