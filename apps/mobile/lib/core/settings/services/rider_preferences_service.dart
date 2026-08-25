import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RiderPreferences {
  final bool useMetric;
  final bool crashDetectionEnabled;
  final bool voiceAlertsEnabled;
  final bool autoPauseEnabled;
  final String preferredVoice;
  final String preferredLanguage;
  final double sensorSensitivity;
  final bool anonymousTelemetrySharing;
  final bool isDarkMode;

  const RiderPreferences({
    this.useMetric = true,
    this.crashDetectionEnabled = true,
    this.voiceAlertsEnabled = true,
    this.autoPauseEnabled = true,
    this.preferredVoice = 'Jarvis AI (Neural English)',
    this.preferredLanguage = 'English (US)',
    this.sensorSensitivity = 0.85,
    this.anonymousTelemetrySharing = true,
    this.isDarkMode = true,
  });

  RiderPreferences copyWith({
    bool? useMetric,
    bool? crashDetectionEnabled,
    bool? voiceAlertsEnabled,
    bool? autoPauseEnabled,
    String? preferredVoice,
    String? preferredLanguage,
    double? sensorSensitivity,
    bool? anonymousTelemetrySharing,
    bool? isDarkMode,
  }) {
    return RiderPreferences(
      useMetric: useMetric ?? this.useMetric,
      crashDetectionEnabled: crashDetectionEnabled ?? this.crashDetectionEnabled,
      voiceAlertsEnabled: voiceAlertsEnabled ?? this.voiceAlertsEnabled,
      autoPauseEnabled: autoPauseEnabled ?? this.autoPauseEnabled,
      preferredVoice: preferredVoice ?? this.preferredVoice,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      sensorSensitivity: sensorSensitivity ?? this.sensorSensitivity,
      anonymousTelemetrySharing: anonymousTelemetrySharing ?? this.anonymousTelemetrySharing,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'useMetric': useMetric,
        'crashDetectionEnabled': crashDetectionEnabled,
        'voiceAlertsEnabled': voiceAlertsEnabled,
        'autoPauseEnabled': autoPauseEnabled,
        'preferredVoice': preferredVoice,
        'preferredLanguage': preferredLanguage,
        'sensorSensitivity': sensorSensitivity,
        'anonymousTelemetrySharing': anonymousTelemetrySharing,
        'isDarkMode': isDarkMode,
      };

  factory RiderPreferences.fromJson(Map<String, dynamic> json) => RiderPreferences(
        useMetric: json['useMetric'] as bool? ?? true,
        crashDetectionEnabled: json['crashDetectionEnabled'] as bool? ?? true,
        voiceAlertsEnabled: json['voiceAlertsEnabled'] as bool? ?? true,
        autoPauseEnabled: json['autoPauseEnabled'] as bool? ?? true,
        preferredVoice: json['preferredVoice'] as String? ?? 'Jarvis AI (Neural English)',
        preferredLanguage: json['preferredLanguage'] as String? ?? 'English (US)',
        sensorSensitivity: (json['sensorSensitivity'] as num?)?.toDouble() ?? 0.85,
        anonymousTelemetrySharing: json['anonymousTelemetrySharing'] as bool? ?? true,
        isDarkMode: json['isDarkMode'] as bool? ?? true,
      );
}

class RiderPreferencesService extends StateNotifier<RiderPreferences> {
  static const String _prefsKey = 'rider_preferences_v1';
  SharedPreferences? _prefs;

  RiderPreferencesService() : super(const RiderPreferences()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final savedStr = _prefs?.getString(_prefsKey);
      if (savedStr != null) {
        final Map<String, dynamic> decoded = jsonDecode(savedStr) as Map<String, dynamic>;
        state = RiderPreferences.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('[RiderPreferencesService] Error loading preferences: $e');
    }
  }

  Future<void> updatePreferences(RiderPreferences newPreferences) async {
    state = newPreferences;
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.setString(_prefsKey, jsonEncode(newPreferences.toJson()));
    } catch (e) {
      debugPrint('[RiderPreferencesService] Error saving preferences: $e');
    }
  }

  Future<void> toggleMetric(bool useMetric) async {
    await updatePreferences(state.copyWith(useMetric: useMetric));
  }

  Future<void> toggleCrashDetection(bool enabled) async {
    await updatePreferences(state.copyWith(crashDetectionEnabled: enabled));
  }

  Future<void> toggleVoiceAlerts(bool enabled) async {
    await updatePreferences(state.copyWith(voiceAlertsEnabled: enabled));
  }

  Future<void> setSensitivity(double sensitivity) async {
    await updatePreferences(state.copyWith(sensorSensitivity: sensitivity));
  }
}

final riderPreferencesProvider =
    StateNotifierProvider<RiderPreferencesService, RiderPreferences>((ref) {
  return RiderPreferencesService();
});
