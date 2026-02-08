import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:adhan/adhan.dart';

class SettingsState {
  final CalculationMethod calculationMethod;
  final Madhab madhab;
  final ThemeMode themeMode;
  final bool areNotificationsEnabled;
  final int preAzanReminderOffset;
  final bool use24hFormat;
  final bool largeText;
  final String notificationSound;
  final bool vibrationEnabled;

  SettingsState({
    required this.calculationMethod,
    required this.madhab,
    required this.themeMode,
    required this.areNotificationsEnabled,
    required this.preAzanReminderOffset,
    required this.use24hFormat,
    required this.largeText,
    required this.notificationSound,
    required this.vibrationEnabled,
  });

  SettingsState copyWith({
    CalculationMethod? calculationMethod,
    Madhab? madhab,
    ThemeMode? themeMode,
    bool? areNotificationsEnabled,
    int? preAzanReminderOffset,
    bool? use24hFormat,
    bool? largeText,
    String? notificationSound,
    bool? vibrationEnabled,
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
      notificationSound: notificationSound ?? this.notificationSound,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
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
          notificationSound: 'azan',
          vibrationEnabled: true,
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
    final sound = box.get('notificationSound', defaultValue: 'azan');
    final vib =
        (box.get('vibrationEnabled', defaultValue: true) as bool?) ?? true;

    CalculationMethod calcMethod = CalculationMethod.values.firstWhere(
      (e) => e.name == calcMethodName,
      orElse: () => CalculationMethod.muslim_world_league,
    );

    Madhab madhab = Madhab.values.firstWhere(
      (e) => e.name == madhabName,
      orElse: () => Madhab.shafi,
    );

    ThemeMode themeMode = ThemeMode.values[themeModeIndex];

    state = SettingsState(
      calculationMethod: calcMethod,
      madhab: madhab,
      themeMode: themeMode,
      areNotificationsEnabled: notificationsEnabled,
      preAzanReminderOffset: offset,
      use24hFormat: use24h,
      largeText: largeTextEnabled,
      notificationSound: sound,
      vibrationEnabled: vib,
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

  Future<void> setNotificationSound(String sound) async {
    state = state.copyWith(notificationSound: sound);
    final box = Hive.box(_boxName);
    await box.put('notificationSound', sound);
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    state = state.copyWith(vibrationEnabled: enabled);
    final box = Hive.box(_boxName);
    await box.put('vibrationEnabled', enabled);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    return SettingsNotifier();
  },
);
