import 'dart:async';

class OfflineRegionPackage {
  final String regionId;
  final String name;
  final double sizeMb;
  final bool isDownloaded;
  final double downloadProgress; // 0.0 to 1.0
  final DateTime lastUpdated;

  const OfflineRegionPackage({
    required this.regionId,
    required this.name,
    required this.sizeMb,
    required this.isDownloaded,
    required this.downloadProgress,
    required this.lastUpdated,
  });

  OfflineRegionPackage copyWith({
    bool? isDownloaded,
    double? downloadProgress,
    DateTime? lastUpdated,
  }) {
    return OfflineRegionPackage(
      regionId: regionId,
      name: name,
      sizeMb: sizeMb,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class OfflineNavigationCacheManager {
  static final OfflineNavigationCacheManager _instance = OfflineNavigationCacheManager._internal();
  factory OfflineNavigationCacheManager() => _instance;
  OfflineNavigationCacheManager._internal();

  bool automaticSyncEnabled = true;
  bool backgroundUpdatesOnWifiOnly = true;

  final Map<String, OfflineRegionPackage> _regions = {
    'reg_1': OfflineRegionPackage(
      regionId: 'reg_1',
      name: 'California Coast & Mountain Passes',
      sizeMb: 142.5,
      isDownloaded: true,
      downloadProgress: 1.0,
      lastUpdated: DateTime.now().subtract(const Duration(days: 2)),
    ),
    'reg_2': OfflineRegionPackage(
      regionId: 'reg_2',
      name: 'Pacific Northwest Rider Trail',
      sizeMb: 198.0,
      isDownloaded: false,
      downloadProgress: 0.0,
      lastUpdated: DateTime.now().subtract(const Duration(days: 14)),
    ),
    'reg_3': OfflineRegionPackage(
      regionId: 'reg_3',
      name: 'Alpine & Canyon Expressway',
      sizeMb: 85.2,
      isDownloaded: false,
      downloadProgress: 0.0,
      lastUpdated: DateTime.now().subtract(const Duration(days: 30)),
    ),
  };

  List<OfflineRegionPackage> get regionsList => _regions.values.toList();

  Future<void> downloadRegion(String regionId, Function(double) onProgress) async {
    // Native map SDK download process here
    onProgress(1.0);
    final existing = _regions[regionId];
    if (existing != null) {
      _regions[regionId] = existing.copyWith(
        isDownloaded: true,
        downloadProgress: 1.0,
        lastUpdated: DateTime.now(),
      );
    }
  }

  Future<void> deleteRegion(String regionId) async {
    final existing = _regions[regionId];
    if (existing != null) {
      _regions[regionId] = existing.copyWith(
        isDownloaded: false,
        downloadProgress: 0.0,
      );
    }
  }

  Future<void> optimizeStorageCache() async {
    // Native cache optimization
  }

  Map<String, dynamic> getOfflineStatusSummary() {
    final totalSize = _regions.values.where((r) => r.isDownloaded).fold(0.0, (acc, r) => acc + r.sizeMb);
    return {
      'downloadedCount': _regions.values.where((r) => r.isDownloaded).length,
      'totalStorageUsedMb': totalSize,
      'offlineRoutingReady': true,
      'offlineVoiceReady': true,
      'offlineSearchReady': true,
    };
  }
}
