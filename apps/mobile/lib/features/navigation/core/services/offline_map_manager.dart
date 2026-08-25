import 'dart:async';
import 'package:flutter/foundation.dart';
import '../map_abstraction/map_engine_interface.dart';

class OfflineRegionInfo {
  final String id;
  final String name;
  final double sizeMb;
  final DateTime downloadedAt;
  final bool isAutoUpdateEnabled;

  const OfflineRegionInfo({
    required this.id,
    required this.name,
    required this.sizeMb,
    required this.downloadedAt,
    this.isAutoUpdateEnabled = true,
  });
}

class OfflineMapManager {
  final List<OfflineRegionInfo> _downloadedRegions = [
    OfflineRegionInfo(
      id: 'region-odisha-metro',
      name: 'Odisha Metro (Bhubaneswar, Cuttack, Puri & Khordha)',
      sizeMb: 148.5,
      downloadedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    OfflineRegionInfo(
      id: 'region-odisha-coastal',
      name: 'Golden Triangle & Coastal Highway (Puri to Konark)',
      sizeMb: 92.0,
      downloadedAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    OfflineRegionInfo(
      id: 'region-odisha-western',
      name: 'Western Odisha Belt (Sambalpur, Rourkela, Jharsuguda)',
      sizeMb: 215.0,
      downloadedAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    OfflineRegionInfo(
      id: 'region-nh16-corridor',
      name: 'National Highway Corridor (NH-16 Kolkata-Chennai stretch)',
      sizeMb: 310.4,
      downloadedAt: DateTime.now().subtract(const Duration(days: 14)),
    ),
  ];

  List<OfflineRegionInfo> get downloadedRegions => List.unmodifiable(_downloadedRegions);

  Future<void> downloadRegion(String name, MapCoordinates min, MapCoordinates max, Function(double) onProgress) async {
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 120));
      onProgress(i * 10.0);
    }

    final newRegion = OfflineRegionInfo(
      id: 'region-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      sizeMb: 110.5,
      downloadedAt: DateTime.now(),
    );

    _downloadedRegions.add(newRegion);
    debugPrint('[OfflineMapManager] Region "$name" downloaded successfully.');
  }

  Future<void> deleteRegion(String id) async {
    _downloadedRegions.removeWhere((r) => r.id == id);
  }

  Future<void> autoUpdateMaps() async {
    debugPrint('[OfflineMapManager] Checking and auto-updating downloaded Indian map packs...');
  }
}

