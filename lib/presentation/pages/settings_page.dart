import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:adhan/adhan.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/location_service.dart';
import '../providers/locale_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/prayer_provider.dart';
import '../providers/notification_provider.dart';

import 'widget_customization_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeNotifierProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(localizations.translate('settings')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, localizations.translate('general')),
          _buildSettingsTile(
            context,
            icon: Icons.language,
            title: localizations.translate('language'),
            subtitle: currentLocale.languageCode == 'ar'
                ? localizations.translate('arabic')
                : localizations.translate('english'),
            onTap: () {
              ref.read(localeNotifierProvider.notifier).toggleLocale();
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.widgets,
            title:
                localizations.translate('widget_customization') ??
                'Widget Customization',
            subtitle: 'Customize home screen widgets',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WidgetCustomizationPage(),
                ),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.location_on,
            title: localizations.translate('location'),
            subtitle: localizations.translate('auto_detect'),
            onTap: () => _handleLocationTap(context, ref, localizations),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.gps_fixed,
            title: 'دقة GPS',
            subtitle: LocationService.getAccuracyDescription(
              LocationService.accuracyLevel,
            ),
            onTap: () => _handleGpsAccuracyTap(context, ref, localizations),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.notifications,
            title: localizations.translate('notifications'),
            subtitle: settings.areNotificationsEnabled
                ? localizations.translate('enabled')
                : localizations.translate('disabled'),
            onTap: () =>
                _handleNotificationsTap(context, ref, settings, localizations),
          ),
          if (settings.areNotificationsEnabled) ...[
            _buildSettingsTile(
              context,
              icon: Icons.timer,
              title: localizations.translate('pre_azan_duration'),
              subtitle:
                  '${settings.preAzanReminderOffset} ${localizations.translate('minutes_short')}',
              onTap: () => _handlePreAzanDurationTap(
                context,
                ref,
                settings,
                localizations,
              ),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.music_note,
              title:
                  localizations.translate('notification_sound') ??
                  'Notification Sound',
              subtitle: _getSoundName(settings.notificationSound),
              onTap: () =>
                  _handleSoundTap(context, ref, settings, localizations),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.vibration,
              title: localizations.translate('vibration') ?? 'Vibration',
              subtitle: settings.vibrationEnabled
                  ? localizations.translate('enabled')
                  : localizations.translate('disabled'),
              onTap: () => ref
                  .read(settingsProvider.notifier)
                  .setVibrationEnabled(!settings.vibrationEnabled),
            ),
          ],

          _buildSectionHeader(context, localizations.translate('calculation')),
          _buildSettingsTile(
            context,
            icon: Icons.calculate,
            title: localizations.translate('method'),
            subtitle: _formatCalculationMethod(settings.calculationMethod),
            onTap: () => _handleCalculationMethodTap(
              context,
              ref,
              settings,
              localizations,
            ),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.mosque,
            title: localizations.translate('asr_juristic'),
            subtitle: settings.madhab == Madhab.shafi
                ? localizations.translate('shafi')
                : localizations.translate('hanafi'),
            onTap: () =>
                _handleMadhabTap(context, ref, settings, localizations),
          ),

          _buildSectionHeader(context, localizations.translate('appearance')),
          _buildSettingsTile(
            context,
            icon: Icons.dark_mode,
            title: localizations.translate('theme'),
            subtitle: _getThemeName(settings.themeMode, localizations),
            onTap: () => _handleThemeTap(context, ref, settings, localizations),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.access_time,
            title: localizations.translate('time_format'),
            subtitle: settings.use24hFormat
                ? localizations.translate('twenty_four_hour')
                : localizations.translate('twelve_hour'),
            onTap: () =>
                _handleTimeFormatTap(context, ref, settings, localizations),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.format_size,
            title: localizations.translate('large_text'),
            subtitle: settings.largeText
                ? localizations.translate('enabled')
                : localizations.translate('disabled'),
            onTap: () =>
                _handleLargeTextTap(context, ref, settings, localizations),
          ),
        ],
      ),
    );
  }

  String _formatCalculationMethod(CalculationMethod method) {
    // Basic formatting, can be improved with localization
    return method.name.replaceAll('_', ' ').toUpperCase();
  }

  void _handleTimeFormatTap(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
    AppLocalizations localizations,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.translate('time_format')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<bool>(
              title: Text(localizations.translate('twelve_hour')),
              value: false,
              groupValue: settings.use24hFormat,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setUse24hFormat(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<bool>(
              title: Text(localizations.translate('twenty_four_hour')),
              value: true,
              groupValue: settings.use24hFormat,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setUse24hFormat(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleLargeTextTap(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
    AppLocalizations localizations,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.translate('large_text')),
        content: SwitchListTile(
          title: Text(localizations.translate('large_text')),
          value: settings.largeText,
          onChanged: (value) {
            ref.read(settingsProvider.notifier).setLargeText(value);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  String _getThemeName(ThemeMode mode, AppLocalizations localizations) {
    switch (mode) {
      case ThemeMode.dark:
        return localizations.translate('dark_mode');
      case ThemeMode.light:
        return localizations.translate('light_mode');
      case ThemeMode.system:
        return localizations.translate('system_default');
    }
  }

  void _handleLocationTap(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations localizations,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${localizations.translate('auto_detect')}...')),
    );
    try {
      ref.invalidate(userLocationProvider);
      final position = await ref.read(userLocationProvider.future);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location updated: ${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _handleGpsAccuracyTap(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations localizations,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('دقة GPS'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: GpsAccuracyLevel.values.map((level) {
            return RadioListTile<GpsAccuracyLevel>(
              title: Text(LocationService.getAccuracyDescription(level)),
              subtitle: Text(
                LocationService.getAccuracyRange(level),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              value: level,
              groupValue: LocationService.accuracyLevel,
              onChanged: (value) {
                if (value != null) {
                  LocationService.setAccuracyLevel(value);
                  Navigator.pop(context);

                  // Refresh location with new accuracy
                  ref.invalidate(userLocationProvider);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'تم تغيير دقة GPS إلى: ${LocationService.getAccuracyDescription(value)}',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _handleNotificationsTap(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
    AppLocalizations localizations,
  ) {
    // Immediate toggle logic
    final newValue = !settings.areNotificationsEnabled;
    ref.read(settingsProvider.notifier).setNotificationsEnabled(newValue);

    // Re-schedule notifications immediately
    final prayerTimes = ref.read(prayerTimesProvider).value;
    if (prayerTimes != null) {
      ref
          .read(notificationServiceProvider)
          .schedulePrayers(
            prayerTimes,
            notificationsEnabled: newValue,
            preAzanReminderOffset: settings.preAzanReminderOffset,
          );
    }
  }

  void _handlePreAzanDurationTap(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
    AppLocalizations localizations,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.translate('pre_azan_duration')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [5, 10, 15, 20, 30, 45, 60].map((duration) {
              return RadioListTile<int>(
                title: Text(
                  '$duration ${localizations.translate('minutes_short')}',
                ),
                value: duration,
                groupValue: settings.preAzanReminderOffset,
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(settingsProvider.notifier)
                        .setPreAzanReminderOffset(value);
                    Navigator.pop(context);

                    // Re-schedule with new offset
                    final prayerTimes = ref.read(prayerTimesProvider).value;
                    if (prayerTimes != null) {
                      ref
                          .read(notificationServiceProvider)
                          .schedulePrayers(
                            prayerTimes,
                            notificationsEnabled: true,
                            preAzanReminderOffset: value,
                          );
                    }
                  }
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _handleCalculationMethodTap(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
    AppLocalizations localizations,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.translate('method')),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: CalculationMethod.values.length,
            itemBuilder: (context, index) {
              final method = CalculationMethod.values[index];
              return RadioListTile<CalculationMethod>(
                title: Text(
                  _formatCalculationMethod(method),
                  style: const TextStyle(fontSize: 14),
                ),
                value: method,
                groupValue: settings.calculationMethod,
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(settingsProvider.notifier)
                        .setCalculationMethod(value);
                    Navigator.pop(context);
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleMadhabTap(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
    AppLocalizations localizations,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.translate('asr_juristic')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: Madhab.values.map((madhab) {
            return RadioListTile<Madhab>(
              title: Text(
                madhab == Madhab.shafi
                    ? localizations.translate('shafi')
                    : localizations.translate('hanafi'),
              ),
              value: madhab,
              groupValue: settings.madhab,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setMadhab(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _handleThemeTap(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
    AppLocalizations localizations,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.translate('theme')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: Text(localizations.translate('dark_mode')),
              value: ThemeMode.dark,
              groupValue: settings.themeMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text(localizations.translate('light_mode')),
              value: ThemeMode.light,
              groupValue: settings.themeMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text(localizations.translate('system_default')),
              value: ThemeMode.system,
              groupValue: settings.themeMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.secondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      title: Text(
        title,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
      ),
      onTap: onTap,
    );
  }

  String _getSoundName(String sound) {
    switch (sound) {
      case 'azan':
        return 'Azan (Custom)';
      case 'system':
        return 'System Sound';
      case 'silent':
        return 'Silent';
      default:
        return 'Azan (Custom)';
    }
  }

  void _handleSoundTap(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
    AppLocalizations localizations,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          localizations.translate('notification_sound') ?? 'Notification Sound',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(localizations.translate('azan') ?? 'Azan (Custom)'),
              value: 'azan',
              groupValue: settings.notificationSound,
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(settingsProvider.notifier)
                      .setNotificationSound(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: Text(
                localizations.translate('system_sound') ?? 'System Sound',
              ),
              value: 'system',
              groupValue: settings.notificationSound,
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(settingsProvider.notifier)
                      .setNotificationSound(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: Text(localizations.translate('silent') ?? 'Silent'),
              value: 'silent',
              groupValue: settings.notificationSound,
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(settingsProvider.notifier)
                      .setNotificationSound(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
