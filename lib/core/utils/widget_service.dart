import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

class WidgetService {
  // All widget provider names
  static const List<String> _allWidgets = [
    'MinimalWidgetProvider',
    'SmartCardWidgetProvider',
    'PremiumClockWidgetProvider',
    'GlassCardWidgetProvider',
    'QuranVerseWidgetProvider',
    'HijriDateWidgetProvider',
    'CalligraphyWidgetProvider',
    'CreativeWidgetProvider',
  ];

  static const Map<String, String> _widgetTypeToSlug = {
    'Minimal': 'minimal',
    'Smart Card': 'smart_card',
    'Premium Clock': 'premium_clock',
    'Glass Card': 'glass_card',
    'Quran Verse': 'quran_verse',
    'Hijri Date': 'hijri_date',
    'Calligraphy': 'calligraphy',
    'Creative': 'creative',
  };

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
    String? fontStyle,
    double? fontSize,
    String? widgetType, // Add widgetType parameter
  }) async {
    // Convert colors to Hex Strings (#AARRGGBB) for Android compatibility
    String toHex(int colorValue) =>
        '#${(colorValue & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0').toUpperCase()}';

    final prefix = _prefixForType(widgetType);

    await HomeWidget.saveWidgetData<String>(
      '${prefix}background_color',
      toHex(backgroundColor),
    );
    await HomeWidget.saveWidgetData<String>(
      '${prefix}text_color',
      toHex(textColor),
    );
    await HomeWidget.saveWidgetData<String>(
      '${prefix}accent_color',
      toHex(accentColor),
    );
    await HomeWidget.saveWidgetData<double>('${prefix}opacity', opacity);

    if (fontStyle != null) {
      await HomeWidget.saveWidgetData<String>('${prefix}font_style', fontStyle);
    }
    if (fontSize != null) {
      await HomeWidget.saveWidgetData<String>(
        '${prefix}font_size',
        fontSize.toStringAsFixed(1),
      );
    }

    // Update all widgets
    await _updateAllWidgets();
  }

  /// Get settings for a specific widget type
  static Future<Map<String, dynamic>> getWidgetSettings(
    String widgetType,
  ) async {
    final prefix = _prefixForType(widgetType);

    final bgColorHex = await HomeWidget.getWidgetData<String>(
      '${prefix}background_color',
      defaultValue: '#FF0F1629',
    );
    final textColorHex = await HomeWidget.getWidgetData<String>(
      '${prefix}text_color',
      defaultValue: '#FFFFFFFF',
    );
    final accentColorHex = await HomeWidget.getWidgetData<String>(
      '${prefix}accent_color',
      defaultValue: '#FFC9A24D',
    );
    final opacity = await HomeWidget.getWidgetData<double>(
      '${prefix}opacity',
      defaultValue: 1.0,
    );
    final fontStyle = await HomeWidget.getWidgetData<String>(
      '${prefix}font_style',
      defaultValue: 'default',
    );
    final fontSizeString = await HomeWidget.getWidgetData<String>(
      '${prefix}font_size',
      defaultValue: '56.0',
    );
    final fontSize = double.tryParse(fontSizeString ?? '56.0') ?? 56.0;

    return {
      'backgroundColor': parseWidgetColorHex(bgColorHex, 0xFF0F1629),
      'textColor': parseWidgetColorHex(textColorHex, 0xFFFFFFFF),
      'accentColor': parseWidgetColorHex(accentColorHex, 0xFFC9A24D),
      'opacity': opacity,
      'fontStyle': fontStyle,
      'fontSize': fontSize,
    };
  }

  /// Update widget colors from Color objects
  static Future<void> updateWidgetColors({
    required Color backgroundColor,
    required Color textColor,
    required Color accentColor,
    required double opacity,
    String? fontStyle,
    double? fontSize,
    String? widgetType, // Add widgetType parameter
  }) async {
    await saveWidgetSettings(
      backgroundColor: backgroundColor.toARGB32(),
      textColor: textColor.toARGB32(),
      accentColor: accentColor.toARGB32(),
      opacity: opacity,
      fontStyle: fontStyle,
      fontSize: fontSize,
      widgetType: widgetType,
    );
  }

  static Future<void> _updateAllWidgets() async {
    for (final widgetName in _allWidgets) {
      try {
        await HomeWidget.updateWidget(androidName: widgetName);
      } catch (e) {
        // Widget might not exist, ignore error
        debugPrint('Failed to update widget $widgetName: $e');
      }
    }
  }

  static Future<void> initializeDefaultSettings() async {
    for (final widgetType in _widgetTypeToSlug.keys) {
      final prefix = _prefixForType(widgetType);
      final existingBackground = await HomeWidget.getWidgetData<String>(
        '${prefix}background_color',
      );
      if (existingBackground != null) continue;

      await saveWidgetSettings(
        backgroundColor: 0xFF0F1629,
        textColor: 0xFFFFFFFF,
        accentColor: 0xFFC9A24D,
        opacity: 1.0,
        widgetType: widgetType,
      );
    }
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
      debugPrint('Failed to update Quran widget: $e');
    }
  }

  static String _prefixForType(String? widgetType) {
    if (widgetType == null) return 'widget_';
    final slug =
        _widgetTypeToSlug[widgetType] ??
        widgetType.toLowerCase().replaceAll(' ', '_');
    return '${slug}_';
  }

  static int parseWidgetColorHex(String? colorHex, int fallback) {
    if (colorHex == null || colorHex.isEmpty) return fallback;
    final normalized = colorHex.trim().replaceFirst('#', '');
    if (normalized.length != 8) return fallback;
    final parsed = int.tryParse('0x$normalized');
    return parsed ?? fallback;
  }
}
