import 'package:flutter/material.dart';

/// Modal dialog displaying full keyboard hotkeys for 3D Garage
class KeyboardShortcutsModal extends StatelessWidget {
  const KeyboardShortcutsModal({super.key});

  static const List<Map<String, String>> shortcuts = [
    {'key': 'R', 'action': 'Reset 3D Camera to Default Front 3/4'},
    {'key': 'F', 'action': 'Toggle Fullscreen Mode'},
    {'key': 'A', 'action': 'Toggle 360 deg Auto-Rotation'},
    {'key': 'E', 'action': 'Start / Stop Motorcycle Engine'},
    {'key': 'C', 'action': 'Open Vehicle Configurator & Paint Studio'},
    {'key': 'L', 'action': 'Open Lighting Studio Panel'},
    {'key': '1', 'action': 'Camera: Front 3/4 View'},
    {'key': '2', 'action': 'Camera: Rear 3/4 View'},
    {'key': '3', 'action': 'Camera: Side Profile View'},
    {'key': '4', 'action': 'Camera: Front Head-on View'},
    {'key': '5', 'action': 'Camera: Rear Tail View'},
    {'key': '6', 'action': 'Camera: Top-Down Aerial View'},
    {'key': '7', 'action': 'Camera: Cockpit TFT Detail View'},
    {'key': '8', 'action': 'Camera: Cinematic Orbit Sweep'},
    {'key': 'SPACE', 'action': 'Rev Engine (Hold to Redline)'},
    {'key': 'ESC', 'action': 'Close Open Panel or Exit Fullscreen'},
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: const Color(0xF00A0F1D),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3), width: 1.2),
          boxShadow: const [
            BoxShadow(color: Colors.black87, blurRadius: 40, spreadRadius: 10),
          ],
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.keyboard_rounded, color: Color(0xFF00E5FF), size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  'KEYBOARD SHORTCUTS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Shortcuts Grid
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: shortcuts.map((s) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Text(
                              s['key']!,
                              style: const TextStyle(
                                color: Color(0xFF00E5FF),
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              s['action']!,
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
