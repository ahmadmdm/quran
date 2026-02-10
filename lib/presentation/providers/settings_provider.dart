import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:adhan/adhan.dart';
import '../../core/utils/notification_sound_support.dart';

enum FoldPaneMode { auto, left, right, span }

class SettingsState {
  final CalculationMethod calculationMethod;
  final Madhab madhab;
  final ThemeMode themeMode;
  final bool areNotificationsEnabled;
  final int preAzanReminderOffset;
  final bool use24hFormat;
  final bool largeText;
  final bool alwaysShowHomeCards;
  final String notificationSound;
  final bool vibrationEnabled;
  final bool prayerTimeNotificationsEnabled;
  final bool prePrayerRemindersEnabled;
  final bool fajrNotificationsEnabled;
  final bool dhuhrNotificationsEnabled;
  final bool asrNotificationsEnabled;
  final bool maghribNotificationsEnabled;
  final bool ishaNotificationsEnabled;
  final bool useManualLocation;
  final double? manualLatitude;
  final double? manualLongitude;
  final String? manualLocationLabel;
  final FoldPaneMode foldPaneMode;

  SettingsState({
    required this.calculationMethod,
    required this.madhab,
    required this.themeMode,
    required this.areNotificationsEnabled,
    required this.preAzanReminderOffset,
    required this.use24hFormat,
    required this.largeText,
    required this.alwaysShowHomeCards,
    required this.notificationSound,
    required this.vibrationEnabled,
    required this.prayerTimeNotificationsEnabled,
    required this.prePrayerRemindersEnabled,
    required this.fajrNotificationsEnabled,
    required this.dhuhrNotificationsEnabled,
    required this.asrNotificationsEnabled,
    required this.maghribNotificationsEnabled,
    required this.ishaNotificationsEnabled,
    required this.useManualLocation,
    required this.manualLatitude,
    required this.manualLongitude,
    required this.manualLocationLabel,
    required this.foldPaneMode,
  });

  SettingsState copyWith({
    CalculationMethod? calculationMethod,
    Madhab? madhab,
    ThemeMode? themeMode,
    bool? areNotificationsEnabled,
    int? preAzanReminderOffset,
    bool? use24hFormat,
    bool? largeText,
    bool? alwaysShowHomeCards,
    String? notificationSound,
    bool? vibrationEnabled,
    bool? prayerTimeNotificationsEnabled,
    bool? prePrayerRemindersEnabled,
    bool? fajrNotificationsEnabled,
    bool? dhuhrNotificationsEnabled,
    bool? asrNotificationsEnabled,
    bool? maghribNotificationsEnabled,
    bool? ishaNotificationsEnabled,
    bool? useManualLocation,
    double? manualLatitude,
    double? manualLongitude,
    String? manualLocationLabel,
    FoldPaneMode? foldPaneMode,
    bool clearManualLocationLabel = false,
  }) {
    return SettingsState(
      calculationMethod: calculationMethod ?? this.calculationMethod,
      madhab: madhab ?? this.madhab,
      themeMode: themeMode ?? this.themeMode,
      areNotificationsEnabled:
          areNotificationsEnabled ?? this.areNotificationsEnabled,
      preAzanReminderOffset:
          preAzanReminderOffset ?? this.preAzanReminderOffset,
      use24hFormat: use24hFormat ?? this.use24hFormat,
      largeText: largeText ?? this.largeText,
      alwaysShowHomeCards: alwaysShowHomeCards ?? this.alwaysShowHomeCards,
      notificationSound: notificationSound ?? this.notificationSound,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      prayerTimeNotificationsEnabled:
          prayerTimeNotificationsEnabled ?? this.prayerTimeNotificationsEnabled,
      prePrayerRemindersEnabled:
          prePrayerRemindersEnabled ?? this.prePrayerRemindersEnabled,
      fajrNotificationsEnabled:
          fajrNotificationsEnabled ?? this.fajrNotificationsEnabled,
      dhuhrNotificationsEnabled:
          dhuhrNotificationsEnabled ?? this.dhuhrNotificationsEnabled,
      asrNotificationsEnabled:
          asrNotificationsEnabled ?? this.asrNotificationsEnabled,
      maghribNotificationsEnabled:
          maghribNotificationsEnabled ?? this.maghribNotificationsEnabled,
      ishaNotificationsEnabled:
          ishaNotificationsEnabled ?? this.ishaNotificationsEnabled,
      useManualLocation: useManualLocation ?? this.useManualLocation,
      manualLatitude: manualLatitude ?? this.manualLatitude,
      manualLongitude: manualLongitude ?? this.manualLongitude,
      manualLocationLabel: clearManualLocationLabel
          ? null
          : (manualLocationLabel ?? this.manualLocationLabel),
      foldPaneMode: foldPaneMode ?? this.foldPaneMode,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier()
    : super(
        SettingsState(
          calculationMethod: CalculationMethod.muslim_world_league,
          madhab: Madhab.shafi,
          themeMode: ThemeMode.light,
          areNotificationsEnabled: true,
          preAzanReminderOffset: 15,
          use24hFormat: false,
          largeText: false,
          alwaysShowHomeCards: false,
          notificationSound: normalizeNotificationSound('azan'),
          vibrationEnabled: true,
          prayerTimeNotificationsEnabled: true,
          prePrayerRemindersEnabled: true,
          fajrNotificationsEnabled: true,
          dhuhrNotificationsEnabled: true,
          asrNotificationsEnabled: true,
          maghribNotificationsEnabled: true,
          ishaNotificationsEnabled: true,
          useManualLocation: false,
          manualLatitude: null,
          manualLongitude: null,
          manualLocationLabel: null,
          foldPaneMode: FoldPaneMode.auto,
        ),
      ) {
    _loadSettings();
  }

  static const _boxName = 'settings';

  Future<void> _loadSettings() async {
    final box = Hive.box(_boxName);

    final calcMethodName = box.get(
      'calculationMethod',
      defaultValue: CalculationMethod.muslim_world_league.name,
    );
    final madhabName = box.get('madhab', defaultValue: Madhab.shafi.name);
    final themeModeIndex = box.get(
      'themeMode',
      defaultValue: ThemeMode.light.index,
    );
    final notificationsEnabled = box.get(
      'areNotificationsEnabled',
      defaultValue: true,
    );
    final offset = box.get('preAzanReminderOffset', defaultValue: 15);
    final use24h =
        (box.get('use24hFormat', defaultValue: false) as bool?) ?? false;
    final largeTextEnabled =
        (box.get('largeText', defaultValue: false) as bool?) ?? false;
    final alwaysShowHomeCards =
        (box.get('alwaysShowHomeCards', defaultValue: false) as bool?) ?? false;
    final storedSound = box.get('notificationSound', defaultValue: 'azan');
    final sound = normalizeNotificationSound(
      storedSound is String ? storedSound : null,
    );
    final vib =
        (box.get('vibrationEnabled', defaultValue: true) as bool?) ?? true;
    final prayerTimeNotificationsEnabled =
        (box.get('prayerTimeNotificationsEnabled', defaultValue: true)
            as bool?) ??
        true;
    final prePrayerRemindersEnabled =
        (box.get('prePrayerRemindersEnabled', defaultValue: true) as bool?) ??
        true;
    final fajrNotificationsEnabled =
        (box.get('fajrNotificationsEnabled', defaultValue: true) as bool?) ??
        true;
    final dhuhrNotificationsEnabled =
        (box.get('dhuhrNotificationsEnabled', defaultValue: true) as bool?) ??
        true;
    final asrNotificationsEnabled =
        (box.get('asrNotificationsEnabled', defaultValue: true) as bool?) ??
        true;
    final maghribNotificationsEnabled =
        (box.get('maghribNotificationsEnabled', defaultValue: true) as bool?) ??
        true;
    final ishaNotificationsEnabled =
        (box.get('ishaNotificationsEnabled', defaultValue: true) as bool?) ??
        true;
    final useManualLocation =
        (box.get('useManualLocation', defaultValue: false) as bool?) ?? false;
    final manualLatitude = (box.get('manualLatitude') as num?)?.toDouble();
    final manualLongitude = (box.get('manualLongitude') as num?)?.toDouble();
    final manualLocationLabel = box.get('manualLocationLabel') as String?;
    final foldPaneModeName = box.get(
      'foldPaneMode',
      defaultValue: FoldPaneMode.auto.name,
    );

    CalculationMethod calcMethod = CalculationMethod.values.firstWhere(
      (e) => e.name == calcMethodName,
      orElse: () => CalculationMethod.muslim_world_league,
    );

    Madhab madhab = Madhab.values.firstWhere(
      (e) => e.name == madhabName,
      orElse: () => Madhab.shafi,
    );

    final themeMode = SettingsNotifier.themeModeFromStorageIndex(
      themeModeIndex,
    );
    final foldPaneMode = FoldPaneMode.values.firstWhere(
      (e) => e.name == foldPaneModeName,
      orElse: () => FoldPaneMode.auto,
    );

    state = SettingsState(
      calculationMethod: calcMethod,
      madhab: madhab,
      themeMode: themeMode,
      areNotificationsEnabled: notificationsEnabled,
      preAzanReminderOffset: offset,
      use24hFormat: use24h,
      largeText: largeTextEnabled,
      alwaysShowHomeCards: alwaysShowHomeCards,
      notificationSound: sound,
      vibrationEnabled: vib,
      prayerTimeNotificationsEnabled: prayerTimeNotificationsEnabled,
      prePrayerRemindersEnabled: prePrayerRemindersEnabled,
      fajrNotificationsEnabled: fajrNotificationsEnabled,
      dhuhrNotificationsEnabled: dhuhrNotificationsEnabled,
      asrNotificationsEnabled: asrNotificationsEnabled,
      maghribNotificationsEnabled: maghribNotificationsEnabled,
      ishaNotificationsEnabled: ishaNotificationsEnabled,
      useManualLocation: useManualLocation,
      manualLatitude: manualLatitude,
      manualLongitude: manualLongitude,
      manualLocationLabel: manualLocationLabel,
      foldPaneMode: foldPaneMode,
    );
  }

  Future<void> setCalculationMethod(CalculationMethod method) async {
    state = state.copyWith(calculationMethod: method);
    final box = Hive.box(_boxName);
    await box.put('calculationMethod', method.name);
  }

  Future<void> setMadhab(Madhab madhab) async {
    state = state.copyWith(madhab: madhab);
    final box = Hive.box(_boxName);
    await box.put('madhab', madhab.name);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final box = Hive.box(_boxName);
    await box.put('themeMode', mode.index);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(areNotificationsEnabled: enabled);
    final box = Hive.box(_boxName);
    await box.put('areNotificationsEnabled', enabled);
  }

  Future<void> setPreAzanReminderOffset(int offset) async {
    state = state.copyWith(preAzanReminderOffset: offset);
    final box = Hive.box(_boxName);
    await box.put('preAzanReminderOffset', offset);
  }

  Future<void> setUse24hFormat(bool use24h) async {
    state = state.copyWith(use24hFormat: use24h);
    final box = Hive.box(_boxName);
    await box.put('use24hFormat', use24h);
  }

  Future<void> setLargeText(bool enabled) async {
    state = state.copyWith(largeText: enabled);
    final box = Hive.box(_boxName);
    await box.put('largeText', enabled);
  }

  Future<void> setAlwaysShowHomeCards(bool enabled) async {
    state = state.copyWith(alwaysShowHomeCards: enabled);
    final box = Hive.box(_boxName);
    await box.put('alwaysShowHomeCards', enabled);
  }

  Future<void> setNotificationSound(String sound) async {
    final normalized = normalizeNotificationSound(sound);
    state = state.copyWith(notificationSound: normalized);
    final box = Hive.box(_boxName);
    await box.put('notificationSound', normalized);
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    state = state.copyWith(vibrationEnabled: enabled);
    final box = Hive.box(_boxName);
    await box.put('vibrationEnabled', enabled);
  }

  Future<void> setPrayerTimeNotificationsEnabled(bool enabled) async {
    state = state.copyWith(prayerTimeNotificationsEnabled: enabled);
    final box = Hive.box(_boxName);
    await box.put('prayerTimeNotificationsEnabled', enabled);
  }

  Future<void> setPrePrayerRemindersEnabled(bool enabled) async {
    state = state.copyWith(prePrayerRemindersEnabled: enabled);
    final box = Hive.box(_boxName);
    await box.put('prePrayerRemindersEnabled', enabled);
  }

  Future<void> setPrayerNotificationEnabled(Prayer prayer, bool enabled) async {
    final box = Hive.box(_boxName);
    switch (prayer) {
      case Prayer.fajr:
        state = state.copyWith(fajrNotificationsEnabled: enabled);
        await box.put('fajrNotificationsEnabled', enabled);
        break;
      case Prayer.dhuhr:
        state = state.copyWith(dhuhrNotificationsEnabled: enabled);
        await box.put('dhuhrNotificationsEnabled', enabled);
        break;
      case Prayer.asr:
        state = state.copyWith(asrNotificationsEnabled: enabled);
        await box.put('asrNotificationsEnabled', enabled);
        break;
      case Prayer.maghrib:
        state = state.copyWith(maghribNotificationsEnabled: enabled);
        await box.put('maghribNotificationsEnabled', enabled);
        break;
      case Prayer.isha:
        state = state.copyWith(ishaNotificationsEnabled: enabled);
        await box.put('ishaNotificationsEnabled', enabled);
        break;
      case Prayer.none:
      case Prayer.sunrise:
        break;
    }
  }

  Future<void> setManualLocation({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    state = state.copyWith(
      useManualLocation: true,
      manualLatitude: latitude,
      manualLongitude: longitude,
      manualLocationLabel: label,
    );
    final box = Hive.box(_boxName);
    await box.put('useManualLocation', true);
    await box.put('manualLatitude', latitude);
    await box.put('manualLongitude', longitude);
    if (label == null || label.trim().isEmpty) {
      await box.delete('manualLocationLabel');
    } else {
      await box.put('manualLocationLabel', label.trim());
    }
  }

  Future<void> setUseAutoLocation() async {
    state = state.copyWith(useManualLocation: false);
    final box = Hive.box(_boxName);
    await box.put('useManualLocation', false);
  }

  Future<void> setFoldPaneMode(FoldPaneMode mode) async {
    state = state.copyWith(foldPaneMode: mode);
    final box = Hive.box(_boxName);
    await box.put('foldPaneMode', mode.name);
  }

  static ThemeMode themeModeFromStorageIndex(Object? index) {
    final value = index is int ? index : ThemeMode.light.index;
    if (value < 0 || value >= ThemeMode.values.length) {
      return ThemeMode.light;
    }
    return ThemeMode.values[value];
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    return SettingsNotifier();
  },
);
