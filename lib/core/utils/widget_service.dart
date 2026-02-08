import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

class WidgetService {
  static const String _groupId = 'group.com.luxury.prayer';
  static const String _androidWidgetName = 'MinimalWidgetProvider';

  // All widget provider names
  static const List<String> _allWidgets = [
    'MinimalWidgetProvider',
    'SmartCardWidgetProvider',
    'PremiumClockWidgetProvider',
    'GlassCardWidgetProvider',
    'QuranVerseWidgetProvider',
    'HijriDateWidgetProvider',
    'CreativeWidgetProvider',
  ];

  static Future<void> updateWidgetData({
    required String nextPrayerName,
    required String nextPrayerTime,
    required String timeRemaining,
    required int nextPrayerTimeMillis,
    int? nextPrayerIndex,
    List<String>? prayerNames,
    List<String>? prayerTimes,
    List<int>? prayerTimeMillis,
    String? location,
    String? sunriseTime, // Added sunrise time
    bool isSunrise = false, // Flag to indicate if next prayer is Sunrise
  }) async {
    await HomeWidget.saveWidgetData<String>('next_prayer_name', nextPrayerName);
    await HomeWidget.saveWidgetData<String>('next_prayer_time', nextPrayerTime);
    await HomeWidget.saveWidgetData<String>('time_remaining', timeRemaining);
    await HomeWidget.saveWidgetData<String>('next_prayer', nextPrayerName);
    await HomeWidget.saveWidgetData<bool>('is_sunrise', isSunrise);
    
    if (sunriseTime != null) {
      await HomeWidget.saveWidgetData<String>('sunrise_time', sunriseTime);
    }
    
    await HomeWidget.saveWidgetData<int>(
      'next_prayer_millis',
      nextPrayerTimeMillis,
    );

    if (nextPrayerIndex != null) {
      await HomeWidget.saveWidgetData<int>(
        'next_prayer_index',
        nextPrayerIndex,
      );
    }

    if (location != null) {
      await HomeWidget.saveWidgetData<String>('location', location);
    }

    if (prayerNames != null && prayerTimes != null) {
      // Save individual prayer times (excluding sunrise for main prayers)
      // Index 0-4 for main prayers: Fajr, Dhuhr, Asr, Maghrib, Isha
      final prayerKeys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
      for (int i = 0; i < prayerNames.length && i < prayerKeys.length; i++) {
        await HomeWidget.saveWidgetData<String>(
          'prayer_name_$i',
          prayerNames[i],
        );
        await HomeWidget.saveWidgetData<String>(
          'prayer_time_$i',
          prayerTimes[i],
        );
        await HomeWidget.saveWidgetData<String>(
          '${prayerKeys[i]}_time',
          prayerTimes[i],
        );
      }
    }

    if (prayerTimeMillis != null) {
      for (int i = 0; i < prayerTimeMillis.length; i++) {
        await HomeWidget.saveWidgetData<int>(
          'prayer_time_millis_$i',
          prayerTimeMillis[i],
        );
      }
    }

    // Update all widgets
    await _updateAllWidgets();
  }

  static Future<void> saveWidgetSettings({
    required int backgroundColor,
    required int textColor,
    required int accentColor,
    required double opacity,
  }) async {
    // Convert colors to Hex Strings (#AARRGGBB) for Android compatibility
    String toHex(int colorValue) =>
        '#${(colorValue & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0').toUpperCase()}';

    await HomeWidget.saveWidgetData<String>(
      'widget_background_color',
      toHex(backgroundColor),
    );
    await HomeWidget.saveWidgetData<String>(
      'widget_text_color',
      toHex(textColor),
    );
    await HomeWidget.saveWidgetData<String>(
      'widget_accent_color',
      toHex(accentColor),
    );
    await HomeWidget.saveWidgetData<double>('widget_opacity', opacity);

    // Update all widgets
    await _updateAllWidgets();
  }

  /// Update widget colors from Color objects
  static Future<void> updateWidgetColors({
    required Color backgroundColor,
    required Color textColor,
    required Color accentColor,
    required double opacity,
  }) async {
    await saveWidgetSettings(
      backgroundColor: backgroundColor.value,
      textColor: textColor.value,
      accentColor: accentColor.value,
      opacity: opacity,
    );
  }

  static Future<void> _updateAllWidgets() async {
    for (final widgetName in _allWidgets) {
      try {
        await HomeWidget.updateWidget(androidName: widgetName);
      } catch (e) {
        // Widget might not exist, ignore error
        print('Failed to update widget $widgetName: $e');
      }
    }
  }

  static Future<void> initializeDefaultSettings() async {
    // Set default widget colors
    await saveWidgetSettings(
      backgroundColor: 0xFF0F1629,
      textColor: 0xFFFFFFFF,
      accentColor: 0xFFC9A24D,
      opacity: 1.0,
    );
  }

  /// Force refresh all widgets - useful when prayer times change
  static Future<void> forceRefreshAllWidgets() async {
    await _updateAllWidgets();
  }

  /// Save Quran verse for widget
  static Future<void> saveQuranVerse({
    required String verse,
    required String surahName,
    required int verseNumber,
  }) async {
    await HomeWidget.saveWidgetData<String>('quran_verse', verse);
    await HomeWidget.saveWidgetData<String>('quran_surah', surahName);
    await HomeWidget.saveWidgetData<int>('quran_verse_number', verseNumber);

    // Update Quran widget specifically
    try {
      await HomeWidget.updateWidget(androidName: 'QuranVerseWidgetProvider');
    } catch (e) {
      print('Failed to update Quran widget: $e');
    }
  }
}
