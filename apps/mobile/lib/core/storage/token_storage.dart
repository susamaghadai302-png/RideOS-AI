import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class TokenStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageKeys.accessToken, accessToken);
      await prefs.setString(StorageKeys.refreshToken, refreshToken);
      return;
    }
    try {
      await _storage.write(key: StorageKeys.accessToken, value: accessToken);
      await _storage.write(key: StorageKeys.refreshToken, value: refreshToken);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageKeys.accessToken, accessToken);
      await prefs.setString(StorageKeys.refreshToken, refreshToken);
    }
  }

  Future<String?> getAccessToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(StorageKeys.accessToken);
    }
    try {
      return await _storage.read(key: StorageKeys.accessToken);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(StorageKeys.accessToken);
    }
  }

  Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(StorageKeys.refreshToken);
    }
    try {
      return await _storage.read(key: StorageKeys.refreshToken);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(StorageKeys.refreshToken);
    }
  }

  Future<void> clearTokens() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(StorageKeys.accessToken);
      await prefs.remove(StorageKeys.refreshToken);
      return;
    }
    try {
      await _storage.delete(key: StorageKeys.accessToken);
      await _storage.delete(key: StorageKeys.refreshToken);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(StorageKeys.accessToken);
      await prefs.remove(StorageKeys.refreshToken);
    }
  }
}
