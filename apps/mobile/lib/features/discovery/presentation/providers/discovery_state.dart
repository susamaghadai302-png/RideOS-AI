import 'package:equatable/equatable.dart';
import '../../domain/entities/discovery_route_entity.dart';

class DiscoveryState extends Equatable {
  final List<DiscoveryRouteEntity> routes;
  final bool isLoading;

  const DiscoveryState({
    this.routes = const [],
    this.isLoading = false,
  });

  DiscoveryState copyWith({
    List<DiscoveryRouteEntity>? routes,
    bool? isLoading,
  }) {
    return DiscoveryState(
      routes: routes ?? this.routes,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [routes, isLoading];
}
