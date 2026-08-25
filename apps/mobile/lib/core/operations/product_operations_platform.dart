import 'dart:developer' as developer;

enum ReleaseChannel { stable, beta, alpha, internal }

class RemoteConfigOverrides {
  final bool emergencyKillswitchActive;
  final bool arNavigationEnabled;
  final bool cloudSyncEnabled;
  final String maxBleSamplingHz;

  const RemoteConfigOverrides({
    required this.emergencyKillswitchActive,
    required this.arNavigationEnabled,
    required this.cloudSyncEnabled,
    required this.maxBleSamplingHz,
  });
}

class OperationalHealthStatus {
  final String apiGatewayStatus; // 'HEALTHY', 'DEGRADED', 'OUTAGE'
  final String telemetrySyncStatus;
  final double activeCrashRatePercentage;
  final int activeConnectedBikes;

  const OperationalHealthStatus({
    required this.apiGatewayStatus,
    required this.telemetrySyncStatus,
    required this.activeCrashRatePercentage,
    required this.activeConnectedBikes,
  });
}

class ProductOperationsPlatform {
  static final ProductOperationsPlatform instance = ProductOperationsPlatform._internal();
  ProductOperationsPlatform._internal();

  ReleaseChannel getActiveReleaseChannel() => ReleaseChannel.stable;

  RemoteConfigOverrides fetchRemoteConfig() {
    developer.log('Fetching latest Remote Config overrides...', name: 'RideOS.ProductOperations');
    return const RemoteConfigOverrides(
      emergencyKillswitchActive: false,
      arNavigationEnabled: true,
      cloudSyncEnabled: true,
      maxBleSamplingHz: '50Hz',
    );
  }

  OperationalHealthStatus auditOperationalHealth() {
    return const OperationalHealthStatus(
      apiGatewayStatus: 'HEALTHY',
      telemetrySyncStatus: 'HEALTHY',
      activeCrashRatePercentage: 0.01,
      activeConnectedBikes: 12450,
    );
  }
}
