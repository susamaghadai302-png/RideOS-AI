import 'package:equatable/equatable.dart';

class OfflineRegionEntity extends Equatable {
  final String id;
  final String name;
  final double sizeMb;
  final double progressPercentage;
  final bool isDownloaded;

  const OfflineRegionEntity({
    required this.id,
    required this.name,
    required this.sizeMb,
    required this.progressPercentage,
    required this.isDownloaded,
  });

  @override
  List<Object?> get props => [id, name, sizeMb, progressPercentage, isDownloaded];
}
