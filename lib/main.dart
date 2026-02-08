import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:geolocator/geolocator.dart';
import 'core/theme/app_theme.dart';
import 'presentation/pages/home_page.dart';
import 'core/localization/app_localizations.dart';
import 'presentation/providers/locale_provider.dart';
import 'presentation/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('settings');

  // Start the app immediately without waiting for location
  runApp(const ProviderScope(child: PrayerApp()));

  // Request location permission in background (non-blocking)
  _requestLocationPermissionInBackground();
}

/// Request location permission in background without blocking app startup
Future<void> _requestLocationPermissionInBackground() async {
  try {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return; // Location services disabled, will handle in UI
    }

    // Check current permission status
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Request permission in background
      await Geolocator.requestPermission();
    }
  } catch (e) {
    // Silently handle errors - location will be requested again when needed
    debugPrint('Background location permission request failed: $e');
  }
}

class PrayerApp extends ConsumerWidget {
  const PrayerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeNotifierProvider);
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    final largeText = ref.watch(settingsProvider.select((s) => s.largeText));

    return MaterialApp(
      title: 'Luxury Prayer App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(largeText ? 1.15 : 1.0),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const HomePage(),
    );
  }
}
