import 'package:flutter/material.dart';

enum AppLanguage {
  english('en', 'English', TextDirection.ltr),
  hindi('hi', 'हिंदी', TextDirection.ltr),
  odia('or', 'ଓଡ଼ିଆ', TextDirection.ltr),
  spanish('es', 'Español', TextDirection.ltr),
  french('fr', 'Français', TextDirection.ltr),
  german('de', 'Deutsch', TextDirection.ltr),
  japanese('ja', '日本語', TextDirection.ltr),
  arabic('ar', 'العربية', TextDirection.rtl);

  final String code;
  final String displayName;
  final TextDirection direction;

  const AppLanguage(this.code, this.displayName, this.direction);
}

class AppLocalizations {
  static AppLanguage currentLanguage = AppLanguage.english;

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'Rideo Pro',
      'welcome_rider': 'Welcome Rider',
      'dashboard': 'Dashboard',
      'navigation': '3D Navigation',
      'voice_ai': 'Voice AI',
      'garage': '3D Garage',
      'radar_squad': 'Radar & Squad',
      'dashcam': 'Dashcam',
      'trips_analytics': 'Trips & Analytics',
      'obd_diagnostics': 'OBD-II CAN-BUS',
      'settings': 'Settings',
      'profile_vault': 'Profile Vault',
      'emergency_sos': 'Emergency SOS',
      'system_nominal': 'System Nominal',
    },
    'hi': {
      'app_title': 'राइडियो प्रो',
      'welcome_rider': 'स्वागत है राइडर',
      'dashboard': 'डैशबोर्ड',
      'navigation': '3डी नेविगेशन',
      'voice_ai': 'वॉयस एआई',
      'garage': '3डी गैरेज',
      'radar_squad': 'रडार और स्क्वाड',
      'dashcam': 'डैशकैम',
      'trips_analytics': 'ट्रिप्स और एनालिटिक्स',
      'obd_diagnostics': 'ओबीडी-II डायग्नोस्टिक्स',
      'settings': 'सेटिंग्स',
      'profile_vault': 'प्रोफाइल वॉल्ट',
      'emergency_sos': 'आपत्कालीन एसओएस',
      'system_nominal': 'प्रणाली सामान्य',
    },
    'or': {
      'app_title': 'ରାଇଡିଓ ପ୍ରୋ',
      'welcome_rider': 'ସ୍ୱାଗତ ରାଇଡର୍',
      'dashboard': 'ଡ୍ୟାସବୋର୍ଡ',
      'navigation': '୩ଡ଼ି ନେଭିଗେସନ୍',
      'voice_ai': 'ଭଏସ୍ ଏଆଇ',
      'garage': '୩ଡ଼ି ଗ୍ୟାରେଜ୍',
      'radar_squad': 'ରାଡାର୍ ଓ ସ୍କ୍ୱାଡ୍',
      'dashcam': 'ଡ୍ୟାସକ୍ୟାମ୍',
      'trips_analytics': 'ଟ୍ରିପ୍ସ ଓ ଆନାଲିଟିକ୍ସ',
      'obd_diagnostics': 'ଓବିଡି-୨ ଡାଇଗ୍ନୋଷ୍ଟିକ୍ସ',
      'settings': 'ସେଟିଂସ୍',
      'profile_vault': 'ପ୍ରୋଫାଇଲ୍ ଭଲ୍ଟ',
      'emergency_sos': 'ଜରୁରୀକାଳୀନ ଏସଓଏସ',
      'system_nominal': 'ସିଷ୍ଟମ୍ ସାଧାରଣ',
    },
    'es': {
      'app_title': 'Rideo Pro',
      'welcome_rider': 'Bienvenido Piloto',
      'dashboard': 'Panel de Control',
      'navigation': 'Navegación 3D',
      'voice_ai': 'IA de Voz',
      'garage': 'Garaje 3D',
      'radar_squad': 'Radar y Escuadrón',
      'dashcam': 'Cámara de Tablero',
      'trips_analytics': 'Viajes y Analítica',
      'obd_diagnostics': 'OBD-II CAN-BUS',
      'settings': 'Configuración',
      'profile_vault': 'Bóveda de Perfil',
      'emergency_sos': 'SOS de Emergencia',
      'system_nominal': 'Sistema Nominal',
    },
    'fr': {
      'app_title': 'Rideo Pro',
      'welcome_rider': 'Bienvenue Pilote',
      'dashboard': 'Tableau de Bord',
      'navigation': 'Navigation 3D',
      'voice_ai': 'IA Vocale',
      'garage': 'Garage 3D',
      'radar_squad': 'Radar & Escouade',
      'dashcam': 'Caméra Embarquée',
      'trips_analytics': 'Trajets & Données',
      'obd_diagnostics': 'OBD-II CAN-BUS',
      'settings': 'Paramètres',
      'profile_vault': 'Coffre de Profil',
      'emergency_sos': 'SOS Urgence',
      'system_nominal': 'Système Nominal',
    },
    'de': {
      'app_title': 'Rideo Pro',
      'welcome_rider': 'Willkommen Fahrer',
      'dashboard': 'Armaturenbrett',
      'navigation': '3D Navigation',
      'voice_ai': 'Sprach-KI',
      'garage': '3D Garage',
      'radar_squad': 'Radar & Gruppe',
      'dashcam': 'Dashcam',
      'trips_analytics': 'Fahrten & Analytik',
      'obd_diagnostics': 'OBD-II CAN-BUS',
      'settings': 'Einstellungen',
      'profile_vault': 'Profil-Tresor',
      'emergency_sos': 'Notfall-SOS',
      'system_nominal': 'System Nominal',
    },
    'ja': {
      'app_title': 'Rideo Pro',
      'welcome_rider': 'ようこそ ライダー',
      'dashboard': 'ダッシュボード',
      'navigation': '3Dナビゲーション',
      'voice_ai': '音声AI',
      'garage': '3Dガレージ',
      'radar_squad': 'レーダー＆分隊',
      'dashcam': 'ドライブレコーダー',
      'trips_analytics': '走行履歴・分析',
      'obd_diagnostics': 'OBD-II診断',
      'settings': '設定',
      'profile_vault': 'プロファイル保管庫',
      'emergency_sos': '緊急SOS',
      'system_nominal': 'システム正常',
    },
    'ar': {
      'app_title': 'ريديو برو',
      'welcome_rider': 'أهلاً بك أيها الراكب',
      'dashboard': 'لوحة القيادة',
      'navigation': 'ملاحة ثلاثية الأبعاد',
      'voice_ai': 'الذكاء الاصطناعي الصوتی',
      'garage': 'المرآب ثلاثي الأبعاد',
      'radar_squad': 'الرادار والفريق',
      'dashcam': 'كاميرا القيادة',
      'trips_analytics': 'الرحلات والتحليلات',
      'obd_diagnostics': 'تشخيص OBD-II',
      'settings': 'الإعدادات',
      'profile_vault': 'خزنة الملف الشخصي',
      'emergency_sos': 'طوارئ SOS',
      'system_nominal': 'النظام يعمل بشكل مثالي',
    },
  };

  static String tr(String key) {
    final langCode = currentLanguage.code;
    return _localizedValues[langCode]?[key] ?? _localizedValues['en']?[key] ?? key;
  }

  static void setLanguage(AppLanguage language) {
    currentLanguage = language;
  }
}
