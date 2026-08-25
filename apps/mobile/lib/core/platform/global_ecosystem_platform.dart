import 'dart:developer' as developer;

class PluginManifest {
  final String pluginId;
  final String name;
  final String version;
  final String category; // 'Navigation', 'Telemetry', 'AI', 'Theme'
  final List<String> requiredPermissions;

  const PluginManifest({
    required this.pluginId,
    required this.name,
    required this.version,
    required this.category,
    required this.requiredPermissions,
  });
}

class OtaUpdateMetadata {
  final String targetComponent; // 'CONFIG', 'AI_MODEL', 'MAP_TILES', 'BIKE_FIRMWARE'
  final String availableVersion;
  final int downloadSizeBytes;
  final bool isMandatory;

  const OtaUpdateMetadata({
    required this.targetComponent,
    required this.availableVersion,
    required this.downloadSizeBytes,
    required this.isMandatory,
  });
}

class WhiteLabelThemeConfig {
  final String brandName;
  final String primaryHexColor;
  final String secondaryHexColor;
  final String logoAssetPath;

  const WhiteLabelThemeConfig({
    required this.brandName,
    required this.primaryHexColor,
    required this.secondaryHexColor,
    required this.logoAssetPath,
  });
}

class GlobalEcosystemPlatform {
  static final GlobalEcosystemPlatform instance = GlobalEcosystemPlatform._internal();
  GlobalEcosystemPlatform._internal();

  List<PluginManifest> getInstalledPlugins() {
    return const [
      PluginManifest(
        pluginId: 'plugin_mapbox_v3',
        name: 'Mapbox Vector Tile Renderer Plugin',
        version: '3.1.0',
        category: 'Navigation',
        requiredPermissions: ['LOCATION', 'INTERNET'],
      ),
      PluginManifest(
        pluginId: 'plugin_ducati_canbus',
        name: 'Ducati DES EVO Telemetry Adapter',
        version: '1.4.2',
        category: 'Telemetry',
        requiredPermissions: ['BLUETOOTH'],
      ),
    ];
  }

  OtaUpdateMetadata checkForOtaUpdates() {
    developer.log('Scanning OTA update servers...', name: 'RideOS.GlobalEcosystemPlatform');
    return const OtaUpdateMetadata(
      targetComponent: 'AI_MODEL',
      availableVersion: 'v2.4.0',
      downloadSizeBytes: 14500000,
      isMandatory: false,
    );
  }

  WhiteLabelThemeConfig getActiveBrandConfig() {
    return const WhiteLabelThemeConfig(
      brandName: 'RideOS AI Global Edition',
      primaryHexColor: '#FF6B00',
      secondaryHexColor: '#00F0FF',
      logoAssetPath: 'assets/branding/rideos_logo.png',
    );
  }
}
