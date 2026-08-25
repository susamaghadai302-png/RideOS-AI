import 'package:flutter/material.dart';

abstract class IRideOSPlugin {
  String get pluginId;
  String get pluginName;
  String get version;

  Future<void> initializePlugin();
  Future<void> shutdownPlugin();

  Widget? buildPluginWidget(BuildContext context);
}

class RideOSPluginManager {
  static final RideOSPluginManager _instance = RideOSPluginManager._internal();
  factory RideOSPluginManager() => _instance;
  RideOSPluginManager._internal();

  final Map<String, IRideOSPlugin> _registeredPlugins = {};

  List<IRideOSPlugin> get registeredPlugins => _registeredPlugins.values.toList();

  Future<void> registerPlugin(IRideOSPlugin plugin) async {
    _registeredPlugins[plugin.pluginId] = plugin;
    await plugin.initializePlugin();
  }

  IRideOSPlugin? getPlugin(String pluginId) {
    return _registeredPlugins[pluginId];
  }
}
