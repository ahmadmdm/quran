import 'package:hive_flutter/hive_flutter.dart';

enum AppFeature {
  smartQuranSearch,
  tadabburRecommendations,
  adaptiveKhatmaPlan,
  advancedBookmarks,
  focusModePlus,
  interactiveMemorization,
  dynamicWidgets,
  multiProfile,
  encryptedBackup,
  privacyFirstAnalytics,
  advancedNotificationRules,
  developerLab,
}

class FeatureFlagsService {
  static const String _prefix = 'feature_flag_';

  Box get _box => Hive.box('settings');

  String _key(AppFeature feature) => '$_prefix${feature.name}';

  bool isEnabled(AppFeature feature) {
    return (_box.get(_key(feature), defaultValue: _defaultValue(feature)) as bool?) ??
        _defaultValue(feature);
  }

  Future<void> setEnabled(AppFeature feature, bool enabled) async {
    await _box.put(_key(feature), enabled);
  }

  Map<AppFeature, bool> getAll() {
    return {
      for (final feature in AppFeature.values) feature: isEnabled(feature),
    };
  }

  Future<void> resetToDefaults() async {
    for (final feature in AppFeature.values) {
      await _box.put(_key(feature), _defaultValue(feature));
    }
  }

  bool _defaultValue(AppFeature feature) {
    switch (feature) {
      case AppFeature.developerLab:
      case AppFeature.privacyFirstAnalytics:
      case AppFeature.advancedBookmarks:
      case AppFeature.focusModePlus:
        return true;
      default:
        return false;
    }
  }
}

const Map<AppFeature, String> appFeatureLabels = {
  AppFeature.smartQuranSearch: 'بحث قرآني ذكي',
  AppFeature.tadabburRecommendations: 'توصيات تدبر',
  AppFeature.adaptiveKhatmaPlan: 'خطة ختمة تكيفية',
  AppFeature.advancedBookmarks: 'فواصل متقدمة',
  AppFeature.focusModePlus: 'وضع تركيز متقدم',
  AppFeature.interactiveMemorization: 'حفظ تفاعلي',
  AppFeature.dynamicWidgets: 'ودجت ديناميكي',
  AppFeature.multiProfile: 'ملفات شخصية متعددة',
  AppFeature.encryptedBackup: 'نسخ احتياطي مشفر',
  AppFeature.privacyFirstAnalytics: 'تحليلات محلية',
  AppFeature.advancedNotificationRules: 'قواعد إشعارات متقدمة',
  AppFeature.developerLab: 'أدوات المطور',
};
