import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'offline_engine_state.dart';
import '../../domain/entities/offline_region_entity.dart';

class OfflineEngineNotifier extends StateNotifier<OfflineEngineState> {
  OfflineEngineNotifier() : super(const OfflineEngineState());

  void loadDownloadedRegions() {
    state = state.copyWith(
      regions: const [
        OfflineRegionEntity(
          id: 'region-sf',
          name: 'San Francisco Bay & Coast Highway',
          sizeMb: 145.0,
          progressPercentage: 100.0,
          isDownloaded: true,
        ),
        OfflineRegionEntity(
          id: 'region-tahoe',
          name: 'Lake Tahoe Alpine Pass',
          sizeMb: 210.0,
          progressPercentage: 0.0,
          isDownloaded: false,
        ),
      ],
    );
  }

  Future<void> downloadRegion(String regionId) async {
    state = state.copyWith(isDownloading: true);
    await Future.delayed(const Duration(seconds: 1));

    final updated = state.regions.map((r) {
      if (r.id == regionId) {
        return OfflineRegionEntity(
          id: r.id,
          name: r.name,
          sizeMb: r.sizeMb,
          progressPercentage: 100.0,
          isDownloaded: true,
        );
      }
      return r;
    }).toList();

    state = state.copyWith(regions: updated, isDownloading: false);
  }
}

final offlineEngineNotifierProvider =
    StateNotifierProvider<OfflineEngineNotifier, OfflineEngineState>((ref) {
  return OfflineEngineNotifier();
});
