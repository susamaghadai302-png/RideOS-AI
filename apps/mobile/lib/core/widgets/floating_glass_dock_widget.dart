import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/lux_haptics_audio_service.dart';

class FloatingGlassDockWidget extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTabSelected;

  const FloatingGlassDockWidget({
    super.key,
    required this.activeIndex,
    required this.onTabSelected,
  });

  static const List<Map<String, dynamic>> _tabs = [
    {'icon': Icons.home_rounded, 'label': 'Home'},
    {'icon': Icons.navigation_rounded, 'label': 'Nav'},
    {'icon': Icons.two_wheeler_rounded, 'label': 'Garage'},
    {'icon': Icons.psychology_rounded, 'label': 'AI'},
    {'icon': Icons.speed_rounded, 'label': 'Ride'},
    {'icon': Icons.library_music_rounded, 'label': 'Music'},
    {'icon': Icons.person_rounded, 'label': 'Profile'},
    {'icon': Icons.settings_rounded, 'label': 'Settings'},
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF040816).withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xFF00FFE5).withValues(alpha: 0.50),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7B2DFF).withValues(alpha: 0.45),
                blurRadius: 28,
                spreadRadius: 3,
              ),
              BoxShadow(
                color: const Color(0xFF00FFE5).withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_tabs.length, (index) {
              final tab = _tabs[index];
              final isSelected = activeIndex == index;

              return Flexible(
                child: GestureDetector(
                  onTap: () {
                    LuxAudioHapticsService.selectionClick();
                    onTabSelected(index);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [Color(0xFF00FFE5), Color(0xFF7B2DFF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF00FFE5).withValues(alpha: 0.55),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          tab['icon'] as IconData,
                          size: 20,
                          color: isSelected ? Colors.white : const Color(0xFF4B5A6E),
                        ),
                      ),
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 200),
                        firstChild: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            tab['label'] as String,
                            style: const TextStyle(
                              color: Color(0xFF00FFE5),
                              fontSize: 7.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        secondChild: const SizedBox(height: 0),
                        crossFadeState: isSelected
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
