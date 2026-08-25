import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings_model.dart';

final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettingsModel>((ref) {
  return AppSettingsNotifier();
});

class AppSettingsNotifier extends StateNotifier<AppSettingsModel> {
  AppSettingsNotifier() : super(const AppSettingsModel()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('app_user_settings');
      if (raw != null) {
        state = AppSettingsModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[AppSettings] Load error: $e');
    }
  }

  Future<void> updateSettings(AppSettingsModel newSettings) async {
    state = newSettings;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_user_settings', jsonEncode(newSettings.toJson()));
    } catch (e) {
      debugPrint('[AppSettings] Save error: $e');
    }
  }

  Future<void> setSpeedUnit(SpeedUnit unit) async {
    await updateSettings(state.copyWith(speedUnit: unit));
  }

  Future<void> setDistanceUnit(DistanceUnit unit) async {
    await updateSettings(state.copyWith(distanceUnit: unit));
  }

  Future<void> setTemperatureUnit(TemperatureUnit unit) async {
    await updateSettings(state.copyWith(temperatureUnit: unit));
  }

  Future<void> setGraphicsQuality(GraphicsQuality quality) async {
    await updateSettings(state.copyWith(graphicsQuality: quality));
  }

  Future<void> setReducedMotion(bool enabled) async {
    await updateSettings(state.copyWith(reducedMotion: enabled));
  }

  Future<void> setAvoidTolls(bool avoid) async {
    await updateSettings(state.copyWith(avoidTolls: avoid));
  }

  Future<void> setAvoidHighways(bool avoid) async {
    await updateSettings(state.copyWith(avoidHighways: avoid));
  }

  Future<void> setVoiceGuidance(bool enabled) async {
    await updateSettings(state.copyWith(voiceGuidanceEnabled: enabled));
  }

  Future<void> setSatelliteMap(bool enabled) async {
    await updateSettings(state.copyWith(satelliteMapEnabled: enabled));
  }
}
