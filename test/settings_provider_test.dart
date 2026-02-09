import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayer_app/presentation/providers/settings_provider.dart';

void main() {
  group('SettingsNotifier.themeModeFromStorageIndex', () {
    test('returns expected values for valid indexes', () {
      expect(
        SettingsNotifier.themeModeFromStorageIndex(ThemeMode.light.index),
        ThemeMode.light,
      );
      expect(
        SettingsNotifier.themeModeFromStorageIndex(ThemeMode.dark.index),
        ThemeMode.dark,
      );
      expect(
        SettingsNotifier.themeModeFromStorageIndex(ThemeMode.system.index),
        ThemeMode.system,
      );
    });

    test('falls back to light mode for invalid input', () {
      expect(SettingsNotifier.themeModeFromStorageIndex(-1), ThemeMode.light);
      expect(SettingsNotifier.themeModeFromStorageIndex(999), ThemeMode.light);
      expect(SettingsNotifier.themeModeFromStorageIndex('1'), ThemeMode.light);
      expect(SettingsNotifier.themeModeFromStorageIndex(null), ThemeMode.light);
    });
  });
}
