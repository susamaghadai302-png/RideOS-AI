import 'dart:ui';
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard, RoadOSThemeEngine;

import 'package:flutter/material.dart';
import '../../../../core/design_system/premium_navigation.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../core/map_abstraction/map_engine_interface.dart';
import '../../core/services/offline_map_manager.dart';

class OfflineMapDialog extends StatefulWidget {
  const OfflineMapDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const OfflineMapDialog(),
    );
  }

  @override
  State<OfflineMapDialog> createState() => _OfflineMapDialogState();
}

class _OfflineMapDialogState extends State<OfflineMapDialog> {
  final OfflineMapManager _manager = OfflineMapManager();
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  void _startDownload() async {
    LuxAudioHapticsService.mediumImpact();
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    await _manager.downloadRegion(
      'Northern Coast Motorcycle Loop',
      const MapCoordinates(latitude: 37.0, longitude: -122.5),
      const MapCoordinates(latitude: 38.5, longitude: -121.0),
      (progress) {
        if (mounted) {
          setState(() => _downloadProgress = progress);
        }
      },
    );

    if (mounted) {
      setState(() => _isDownloading = false);
      showLuxSnack(context, 'Offline map region downloaded successfully!', variant: LuxSnackVariant.info);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: RoadOSCard(
          blurSigma: 24,
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.download_for_offline_rounded, color: RoadOSColors.cyberCyan, size: 24),
                        SizedBox(width: 10),
                        Text('OFFLINE MAPS MANAGER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: RoadOSColors.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Download regions for full vector turn-by-turn navigation without cellular connectivity.',
                  style: TextStyle(fontSize: 11, color: RoadOSColors.textMuted),
                ),
                const SizedBox(height: 16),
                if (_isDownloading) ...[
                  LinearProgressIndicator(
                    value: _downloadProgress / 100.0,
                    backgroundColor: Colors.black38,
                    valueColor: const AlwaysStoppedAnimation<Color>(RoadOSColors.cyberCyan),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Downloading Region Tiles... ${_downloadProgress.round()}%',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RoadOSColors.cyberCyan),
                  ),
                  const SizedBox(height: 16),
                ],
                ElevatedButton.icon(
                  onPressed: _isDownloading ? null : _startDownload,
                  icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                  label: const Text('DOWNLOAD CURRENT REGION (95 MB)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RoadOSColors.cyberCyan.withValues(alpha: 0.2),
                    foregroundColor: RoadOSColors.cyberCyan,
                    minimumSize: const Size(double.infinity, 44),
                    side: const BorderSide(color: RoadOSColors.cyberCyan),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('DOWNLOADED REGIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: RoadOSColors.textMuted)),
                const SizedBox(height: 8),
                ..._manager.downloadedRegions.map((region) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(region.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                              Text('${region.sizeMb} MB | Auto-Updated Daily', style: const TextStyle(fontSize: 9, color: RoadOSColors.textMuted)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: RoadOSColors.errorCrimson, size: 20),
                          onPressed: () {
                            LuxAudioHapticsService.heavyImpact();
                            setState(() {
                              _manager.deleteRegion(region.id);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
