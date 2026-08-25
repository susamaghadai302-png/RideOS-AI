import 'package:equatable/equatable.dart';
import '../../domain/entities/offline_region_entity.dart';

class OfflineEngineState extends Equatable {
  final List<OfflineRegionEntity> regions;
  final bool isDownloading;

  const OfflineEngineState({
    this.regions = const [],
    this.isDownloading = false,
  });

  OfflineEngineState copyWith({
    List<OfflineRegionEntity>? regions,
    bool? isDownloading,
  }) {
    return OfflineEngineState(
      regions: regions ?? this.regions,
      isDownloading: isDownloading ?? this.isDownloading,
    );
  }

  @override
  List<Object?> get props => [regions, isDownloading];
}
