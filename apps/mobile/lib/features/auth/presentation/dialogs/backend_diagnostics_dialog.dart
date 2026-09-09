import 'package:flutter/material.dart';
import '../../../../core/design_system/premium_navigation.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard;
import '../../../../core/network/api_config.dart';

class BackendDiagnosticsDialog extends StatefulWidget {
  const BackendDiagnosticsDialog({super.key});

  @override
  State<BackendDiagnosticsDialog> createState() => _BackendDiagnosticsDialogState();
}

class _BackendDiagnosticsDialogState extends State<BackendDiagnosticsDialog> {
  late BackendConnectionMode _selectedMode;
  late TextEditingController _urlController;
  HealthCheckResult? _lastResult;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _selectedMode = ApiConfig.currentMode;
    _urlController = TextEditingController(text: ApiConfig.activeBaseUrl);
    _testCurrentEndpoint();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testCurrentEndpoint() async {
    setState(() => _isTesting = true);
    final result = await ApiConfig.testHealth(_urlController.text.trim());
    if (mounted) {
      setState(() {
        _lastResult = result;
        _isTesting = false;
      });
    }
  }

  Future<void> _runAutoDetect() async {
    setState(() => _isTesting = true);
    final result = await ApiConfig.autoDetectWorkingEndpoint();
    if (mounted) {
      setState(() {
        _selectedMode = ApiConfig.currentMode;
        _urlController.text = ApiConfig.activeBaseUrl;
        _lastResult = result;
        _isTesting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.isReachable
              ? '✅ Auto-detected live backend: ${result.url} (${result.latencyMs}ms)'
              : '❌ Auto-detect failed: ${result.errorMessage}'),
          backgroundColor: result.isReachable ? RoadOSColors.apexEmerald : RoadOSColors.errorCrimson,
        ),
      );
    }
  }

  void _onModeChanged(BackendConnectionMode mode) {
    setState(() {
      _selectedMode = mode;
      switch (mode) {
        case BackendConnectionMode.usb:
          _urlController.text = ApiConfig.kDefaultUsbBaseUrl;
          break;
        case BackendConnectionMode.lan:
          _urlController.text = ApiConfig.kDefaultLanBaseUrl;
          break;
        case BackendConnectionMode.custom:
          break;
        case BackendConnectionMode.auto:
          _urlController.text = ApiConfig.kDefaultUsbBaseUrl;
          break;
      }
    });
    _testCurrentEndpoint();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = _lastResult?.isReachable ?? false;

    return Dialog(
      backgroundColor: const Color(0xFF060912),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: RoadOSColors.cyberCyan, width: 1.5),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.router_rounded, color: RoadOSColors.cyberCyan, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Backend Diagnostics',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: RoadOSColors.textMuted, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: RoadOSColors.borderTranslucent, height: 20),

              // Status Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isOnline
                      ? RoadOSColors.apexEmerald.withValues(alpha: 0.15)
                      : RoadOSColors.errorCrimson.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isOnline ? RoadOSColors.apexEmerald : RoadOSColors.errorCrimson,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOnline ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: isOnline ? RoadOSColors.apexEmerald : RoadOSColors.errorCrimson,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isOnline ? 'BACKEND ONLINE & REACHABLE' : 'BACKEND UNREACHABLE',
                            style: TextStyle(
                              color: isOnline ? RoadOSColors.apexEmerald : RoadOSColors.errorCrimson,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isOnline
                                ? 'HTTP 200 OK | ${_lastResult?.latencyMs ?? 0} ms round-trip latency'
                                : (_lastResult?.errorMessage ?? 'Connection refused / timed out'),
                            style: TextStyle(
                              color: isOnline ? Colors.white70 : RoadOSColors.warningAmber,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isTesting)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: RoadOSColors.cyberCyan),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Mode Selection
              const Text(
                'CONNECTION MODE:',
                style: TextStyle(color: RoadOSColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const SizedBox(height: 8),

              // Mode Selector Tabs
              Row(
                children: [
                  Expanded(
                    child: _buildModeTab(
                      label: '🔌 USB Tunnel',
                      mode: BackendConnectionMode.usb,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildModeTab(
                      label: '📶 Wi-Fi LAN',
                      mode: BackendConnectionMode.lan,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildModeTab(
                      label: '⚙️ Custom',
                      mode: BackendConnectionMode.custom,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Instructions based on mode
              if (_selectedMode == BackendConnectionMode.usb)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF080C1A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1A2035)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('USB Development Mode (Recommended for 5G / cellular data):',
                          style: TextStyle(color: RoadOSColors.cyberCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('1. Enable USB Debugging on your phone.\n2. Run on your Mac terminal:\n   adb reverse tcp:3000 tcp:3000\n3. Phone can now talk to Mac backend via 127.0.0.1:3000.',
                          style: TextStyle(color: Colors.white70, fontSize: 10.5, height: 1.3)),
                    ],
                  ),
                )
              else if (_selectedMode == BackendConnectionMode.lan)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF080C1A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1A2035)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Wi-Fi / LAN Mode:',
                          style: TextStyle(color: RoadOSColors.cyberCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('1. Connect both phone and Mac to the SAME Wi-Fi network.\n2. Backend listens on 0.0.0.0:3000.\n3. Enter your Mac\'s current Wi-Fi IP below.',
                          style: TextStyle(color: Colors.white70, fontSize: 10.5, height: 1.3)),
                    ],
                  ),
                ),

              const SizedBox(height: 14),

              // URL Input
              const Text(
                'TARGET BACKEND URL:',
                style: TextStyle(color: RoadOSColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _urlController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF080C1A),
                  hintText: 'http://127.0.0.1:3000/api/v1',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                  prefixIcon: const Icon(Icons.link_rounded, color: RoadOSColors.cyberCyan, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: RoadOSColors.cyberCyan),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Action Buttons
              Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: RoadOSColors.cyberCyan,
                      side: const BorderSide(color: RoadOSColors.cyberCyan),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Test Ping', style: TextStyle(fontSize: 12)),
                    onPressed: _isTesting ? null : _testCurrentEndpoint,
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: RoadOSColors.apexEmerald,
                      side: const BorderSide(color: RoadOSColors.apexEmerald),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                    label: const Text('Auto-Detect', style: TextStyle(fontSize: 12)),
                    onPressed: _isTesting ? null : _runAutoDetect,
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RoadOSColors.cyberCyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      final url = _urlController.text.trim();
                      if (url.isNotEmpty) {
                        if (_selectedMode == BackendConnectionMode.custom) {
                          await ApiConfig.setBaseUrl(url);
                        } else {
                          await ApiConfig.setMode(_selectedMode, customUrl: url);
                        }
                        if (context.mounted) {
                          Navigator.pop(context);
                          showLuxSnack(context, '✅ Backend endpoint saved: $url', variant: LuxSnackVariant.info);
                        }
                      }
                    },
                    child: const Text('Save & Apply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeTab({required String label, required BackendConnectionMode mode}) {
    final isSelected = _selectedMode == mode;
    return GestureDetector(
      onTap: () => _onModeChanged(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? RoadOSColors.cyberCyan.withValues(alpha: 0.2) : RoadOSColors.cardSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? RoadOSColors.cyberCyan : RoadOSColors.borderSubtle,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? RoadOSColors.cyberCyan : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
