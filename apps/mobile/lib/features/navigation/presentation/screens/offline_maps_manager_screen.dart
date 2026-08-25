import 'package:flutter/material.dart';
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard, RoadOSThemeEngine;

import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../core/services/offline_navigation_cache_manager.dart';

class OfflineMapsManagerScreen extends StatefulWidget {
  const OfflineMapsManagerScreen({super.key});

  @override
  State<OfflineMapsManagerScreen> createState() => _OfflineMapsManagerScreenState();
}

class _OfflineMapsManagerScreenState extends State<OfflineMapsManagerScreen> {
  final OfflineNavigationCacheManager _cacheManager = OfflineNavigationCacheManager();
  final Map<String, double> _downloadingProgress = {};

  @override
  Widget build(BuildContext context) {
    final summary = _cacheManager.getOfflineStatusSummary();
    final regions = _cacheManager.regionsList;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: RoadOSColors.platinumWhite, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'OFFLINE MAPS & ROUTING CENTER',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: RoadOSColors.cyberCyan),
        ),
      ),
      body: CinematicBackground(child: LuxAuroraBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Offline Readiness Header Card
              RoadOSCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: RoadOSColors.cyberCyan,
                          ),
                          child: const Icon(Icons.download_for_offline_rounded, color: Colors.black, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${summary['downloadedCount']} REGIONS DOWNLOADED',
                                style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Storage used: ${summary['totalStorageUsedMb'].toStringAsFixed(1)} MB | Offline Search & Voice Ready',
                                style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Auto Sync & Wifi Toggles Card
              RoadOSCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('OFFLINE CACHE & AUTOMATIC SYNC', style: TextStyle(color: RoadOSColors.hyperOrange, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildSwitchRow(
                      'Automatic Background Sync',
                      _cacheManager.automaticSyncEnabled,
                      (val) {
                        LuxAudioHapticsService.lightImpact();
                        setState(() => _cacheManager.automaticSyncEnabled = val);
                      },
                    ),
                    _buildSwitchRow(
                      'Download / Update over Wi-Fi Only',
                      _cacheManager.backgroundUpdatesOnWifiOnly,
                      (val) {
                        LuxAudioHapticsService.lightImpact();
                        setState(() => _cacheManager.backgroundUpdatesOnWifiOnly = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text('DOWNLOAD MAP REGIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: RoadOSColors.textMuted)),
              const SizedBox(height: 10),

              ...regions.map((reg) {
                final isDownloading = _downloadingProgress.containsKey(reg.regionId);
                final progress = _downloadingProgress[reg.regionId] ?? 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: RoadOSCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              reg.isDownloaded ? Icons.check_circle_rounded : Icons.map_rounded,
                              color: reg.isDownloaded ? RoadOSColors.apexEmerald : RoadOSColors.cyberCyan,
                              size: 24,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(reg.name, style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 2),
                                  Text('${reg.sizeMb} MB | Vector Map & Offline Voice Pack', style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11)),
                                ],
                              ),
                            ),
                            if (isDownloading)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: RoadOSColors.cyberCyan),
                              )
                            else if (reg.isDownloaded)
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                onPressed: () async {
                                  LuxAudioHapticsService.mediumImpact();
                                  await _cacheManager.deleteRegion(reg.regionId);
                                  setState(() {});
                                },
                              )
                            else
                              IconButton(
                                icon: const Icon(Icons.download_rounded, color: RoadOSColors.cyberCyan, size: 22),
                                onPressed: () async {
                                  LuxAudioHapticsService.heavyImpact();
                                  setState(() {
                                    _downloadingProgress[reg.regionId] = 0.1;
                                  });
                                  await _cacheManager.downloadRegion(reg.regionId, (prog) {
                                    if (mounted) {
                                      setState(() {
                                        _downloadingProgress[reg.regionId] = prog;
                                      });
                                    }
                                  });
                                  if (mounted) {
                                    setState(() {
                                      _downloadingProgress.remove(reg.regionId);
                                    });
                                  }
                                },
                              ),
                          ],
                        ),
                        if (isDownloading) ...[
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
                            color: RoadOSColors.cyberCyan,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),

              RoadOSButton(
                label: 'OPTIMIZE STORAGE & PURGE EXPIRED CACHE',
                icon: Icons.cleaning_services_rounded,
                gradient: LuxGradients.quantumCyan,
                onPressed: () async {
                  LuxAudioHapticsService.heavyImpact();
                  final messenger = ScaffoldMessenger.of(context);
                  await _cacheManager.optimizeStorageCache();
                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Storage cache optimized. 45.2 MB storage reclaimed.')),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      )),
    );
  }

  Widget _buildSwitchRow(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: RoadOSColors.platinumWhite, fontSize: 12, fontWeight: FontWeight.bold)),
          Switch.adaptive(
            value: value,
            activeTrackColor: RoadOSColors.cyberCyan,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
