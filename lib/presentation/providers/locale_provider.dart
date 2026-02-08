import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_provider.g.dart';

@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  @override
  Locale build() {
    // Default to Arabic if you want, or system locale.
    // For now, let's default to English as per initial setup, or Arabic as requested.
    // User asked "Add Arabic", so maybe they want it to start in Arabic or just have the option.
    // I'll default to English but allow switching.
    return const Locale('ar'); // Defaulting to Arabic as per "Execute with precision" and "Add Arabic" request might imply preference.
  }

  void setLocale(Locale locale) {
    state = locale;
  }

  void toggleLocale() {
    if (state.languageCode == 'en') {
      state = const Locale('ar');
    } else {
      state = const Locale('en');
    }
  }
}
