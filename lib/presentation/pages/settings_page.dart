import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:adhan/adhan.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/location_service.dart';
import '../../core/utils/notification_sound_support.dart';
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
            title: localizations.translate('widget_customization'),
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
            subtitle: settings.useManualLocation
                ? 'يدوي: ${settings.manualLocationLabel ?? '${settings.manualLatitude?.toStringAsFixed(4)}, ${settings.manualLongitude?.toStringAsFixed(4)}'}'
                : localizations.translate('auto_detect'),
            onTap: () => _handleLocationTap(context, ref, localizations),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.gps_fixed,
            title: 'دقة GPS',
            subtitle: LocationService.getAccuracyDescription(
              LocationService.accuracyLevel,
            ),
            onTap: () => _handleGpsAccuracyTap(context, ref),
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
              title: localizations.translate('notification_sound'),
              subtitle: _getSoundName(settings.notificationSound),
              onTap: () =>
                  _handleSoundTap(context, ref, settings, localizations),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.vibration,
              title: localizations.translate('vibration'),
              subtitle: settings.vibrationEnabled
                  ? localizations.translate('enabled')
                  : localizations.translate('disabled'),
              onTap: () => _handleVibrationToggle(context, ref, settings),
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
          _buildSettingsTile(
            context,
            icon: Icons.dashboard_customize,
            title: localizations.translate('always_show_home_cards'),
            subtitle: settings.alwaysShowHomeCards
                ? localizations.translate('enabled')
                : localizations.translate('disabled'),
            onTap: () => ref
                .read(settingsProvider.notifier)
                .setAlwaysShowHomeCards(!settings.alwaysShowHomeCards),
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
            _buildChoiceTile(
              context,
              title: Text(localizations.translate('twelve_hour')),
              selected: settings.use24hFormat == false,
              onTap: () {
                ref.read(settingsProvider.notifier).setUse24hFormat(false);
                Navigator.pop(context);
              },
            ),
            _buildChoiceTile(
              context,
              title: Text(localizations.translate('twenty_four_hour')),
              selected: settings.use24hFormat == true,
              onTap: () {
                ref.read(settingsProvider.notifier).setUse24hFormat(true);
                Navigator.pop(context);
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
    final settings = ref.read(settingsProvider);
    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.gps_fixed),
              title: Text(localizations.translate('auto_detect')),
              subtitle: const Text('استخدام GPS تلقائيًا'),
              onTap: () async {
                Navigator.pop(bottomSheetContext);
                await ref.read(settingsProvider.notifier).setUseAutoLocation();
                ref.invalidate(userLocationProvider);
                ref.invalidate(cityNameProvider);
                ref.invalidate(prayerTimesProvider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_location_alt),
              title: const Text('اختيار يدوي'),
              subtitle: Text(
                settings.useManualLocation
                    ? (settings.manualLocationLabel ?? 'مفعل حاليًا')
                    : 'أدخل خط العرض والطول يدويًا',
              ),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _showManualLocationDialog(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleGpsAccuracyTap(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('دقة GPS'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: GpsAccuracyLevel.values.map((level) {
            return _buildChoiceTile(
              context,
              title: Text(LocationService.getAccuracyDescription(level)),
              subtitle: Text(
                LocationService.getAccuracyRange(level),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              selected: LocationService.accuracyLevel == level,
              onTap: () {
                LocationService.setAccuracyLevel(level);
                Navigator.pop(context);

                // Refresh location with new accuracy
                ref.invalidate(userLocationProvider);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'تم تغيير دقة GPS إلى: ${LocationService.getAccuracyDescription(level)}',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        final currentSettings = ref.watch(settingsProvider);
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text(localizations.translate('notifications')),
                value: currentSettings.areNotificationsEnabled,
                onChanged: (_) async {
                  await _handleNotificationToggle(context, ref);
                },
              ),
              SwitchListTile(
                title: Text(
                  localizations.translate('notification_prayer_time'),
                ),
                subtitle: const Text('تنبيه عند دخول وقت الصلاة'),
                value: currentSettings.prayerTimeNotificationsEnabled,
                onChanged: (value) async {
                  await ref
                      .read(settingsProvider.notifier)
                      .setPrayerTimeNotificationsEnabled(value);
                  await _applyNotificationSettings(ref);
                },
              ),
              SwitchListTile(
                title: Text(localizations.translate('notification_pre_prayer')),
                subtitle: const Text('تنبيه قبل الأذان حسب المدة المحددة'),
                value: currentSettings.prePrayerRemindersEnabled,
                onChanged: (value) async {
                  await ref
                      .read(settingsProvider.notifier)
                      .setPrePrayerRemindersEnabled(value);
                  await _applyNotificationSettings(ref);
                },
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: SizedBox.shrink(),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    localizations.translate('notification_per_prayer'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SwitchListTile(
                dense: true,
                title: const Text('الفجر'),
                value: currentSettings.fajrNotificationsEnabled,
                onChanged: (value) =>
                    _togglePrayerNotification(ref, Prayer.fajr, value),
              ),
              SwitchListTile(
                dense: true,
                title: const Text('الظهر'),
                value: currentSettings.dhuhrNotificationsEnabled,
                onChanged: (value) =>
                    _togglePrayerNotification(ref, Prayer.dhuhr, value),
              ),
              SwitchListTile(
                dense: true,
                title: const Text('العصر'),
                value: currentSettings.asrNotificationsEnabled,
                onChanged: (value) =>
                    _togglePrayerNotification(ref, Prayer.asr, value),
              ),
              SwitchListTile(
                dense: true,
                title: const Text('المغرب'),
                value: currentSettings.maghribNotificationsEnabled,
                onChanged: (value) =>
                    _togglePrayerNotification(ref, Prayer.maghrib, value),
              ),
              SwitchListTile(
                dense: true,
                title: const Text('العشاء'),
                value: currentSettings.ishaNotificationsEnabled,
                onChanged: (value) =>
                    _togglePrayerNotification(ref, Prayer.isha, value),
              ),
              ListTile(
                leading: const Icon(Icons.tune),
                title: const Text('إعدادات النظام للإشعارات'),
                subtitle: const Text(
                  'فتح إعدادات التطبيق للتحقق من السماح بالإشعارات',
                ),
                onTap: () async {
                  await ref
                      .read(notificationServiceProvider)
                      .openAppNotificationSettings();
                },
              ),
              ListTile(
                leading: const Icon(Icons.alarm_on),
                title: const Text('تفعيل جدولة دقيقة'),
                subtitle: const Text('طلب أذونات التنبيه والبطارية'),
                onTap: () async {
                  await ref
                      .read(notificationServiceProvider)
                      .requestCriticalAlarmPermissions();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم إرسال طلب الأذونات المطلوبة'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
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
              return _buildChoiceTile(
                context,
                title: Text(
                  '$duration ${localizations.translate('minutes_short')}',
                ),
                selected: settings.preAzanReminderOffset == duration,
                onTap: () {
                  ref
                      .read(settingsProvider.notifier)
                      .setPreAzanReminderOffset(duration);
                  Navigator.pop(context);
                  _applyNotificationSettings(ref);
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
              return _buildChoiceTile(
                context,
                title: Text(
                  _formatCalculationMethod(method),
                  style: const TextStyle(fontSize: 14),
                ),
                selected: settings.calculationMethod == method,
                onTap: () {
                  ref
                      .read(settingsProvider.notifier)
                      .setCalculationMethod(method);
                  Navigator.pop(context);
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
            return _buildChoiceTile(
              context,
              title: Text(
                madhab == Madhab.shafi
                    ? localizations.translate('shafi')
                    : localizations.translate('hanafi'),
              ),
              selected: settings.madhab == madhab,
              onTap: () {
                ref.read(settingsProvider.notifier).setMadhab(madhab);
                Navigator.pop(context);
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
            _buildChoiceTile(
              context,
              title: Text(localizations.translate('dark_mode')),
              selected: settings.themeMode == ThemeMode.dark,
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .setThemeMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            _buildChoiceTile(
              context,
              title: Text(localizations.translate('light_mode')),
              selected: settings.themeMode == ThemeMode.light,
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            _buildChoiceTile(
              context,
              title: Text(localizations.translate('system_default')),
              selected: settings.themeMode == ThemeMode.system,
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .setThemeMode(ThemeMode.system);
                Navigator.pop(context);
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
    switch (normalizeNotificationSound(sound)) {
      case 'azan':
        return 'Azan (Custom)';
      case 'system':
        return 'System Sound';
      case 'silent':
        return 'Silent';
      default:
        return 'System Sound';
    }
  }

  Future<void> _applyNotificationSettings(WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    final prayerTimes = ref.read(prayerTimesProvider).value;
    if (prayerTimes == null) return;

    final enabledPrayers = _enabledPrayersFromSettings(settings);

    await ref
        .read(notificationServiceProvider)
        .schedulePrayers(
          prayerTimes,
          notificationsEnabled: settings.areNotificationsEnabled,
          prayerTimeNotificationsEnabled:
              settings.prayerTimeNotificationsEnabled,
          prePrayerRemindersEnabled: settings.prePrayerRemindersEnabled,
          preAzanReminderOffset: settings.preAzanReminderOffset,
          notificationSound: settings.notificationSound,
          vibrationEnabled: settings.vibrationEnabled,
          enabledPrayers: enabledPrayers,
        );
  }

  Future<void> _handleNotificationToggle(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final settings = ref.read(settingsProvider);
    await ref
        .read(settingsProvider.notifier)
        .setNotificationsEnabled(!settings.areNotificationsEnabled);
    await _applyNotificationSettings(ref);
  }

  Future<void> _togglePrayerNotification(
    WidgetRef ref,
    Prayer prayer,
    bool enabled,
  ) async {
    await ref
        .read(settingsProvider.notifier)
        .setPrayerNotificationEnabled(prayer, enabled);
    await _applyNotificationSettings(ref);
  }

  Set<Prayer> _enabledPrayersFromSettings(SettingsState settings) {
    final enabled = <Prayer>{};
    if (settings.fajrNotificationsEnabled) enabled.add(Prayer.fajr);
    if (settings.dhuhrNotificationsEnabled) enabled.add(Prayer.dhuhr);
    if (settings.asrNotificationsEnabled) enabled.add(Prayer.asr);
    if (settings.maghribNotificationsEnabled) enabled.add(Prayer.maghrib);
    if (settings.ishaNotificationsEnabled) enabled.add(Prayer.isha);
    return enabled;
  }

  Future<void> _handleVibrationToggle(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) async {
    await ref
        .read(settingsProvider.notifier)
        .setVibrationEnabled(!settings.vibrationEnabled);
    await _applyNotificationSettings(ref);
  }

  void _showManualLocationDialog(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsProvider);
    final latController = TextEditingController(
      text: settings.manualLatitude?.toString() ?? '',
    );
    final lngController = TextEditingController(
      text: settings.manualLongitude?.toString() ?? '',
    );
    final labelController = TextEditingController(
      text: settings.manualLocationLabel ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('اختيار موقع يدوي'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latController,
              keyboardType: const TextInputType.numberWithOptions(
                signed: true,
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'خط العرض'),
            ),
            TextField(
              controller: lngController,
              keyboardType: const TextInputType.numberWithOptions(
                signed: true,
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'خط الطول'),
            ),
            TextField(
              controller: labelController,
              decoration: const InputDecoration(
                labelText: 'اسم المكان (اختياري)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              final lat = double.tryParse(latController.text.trim());
              final lng = double.tryParse(lngController.text.trim());
              if (lat == null ||
                  lng == null ||
                  lat.abs() > 90 ||
                  lng.abs() > 180) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('إحداثيات غير صالحة')),
                );
                return;
              }

              await ref
                  .read(settingsProvider.notifier)
                  .setManualLocation(
                    latitude: lat,
                    longitude: lng,
                    label: labelController.text.trim(),
                  );
              ref.invalidate(userLocationProvider);
              ref.invalidate(cityNameProvider);
              ref.invalidate(prayerTimesProvider);
              if (context.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _handleSoundTap(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
    AppLocalizations localizations,
  ) {
    final availableSounds = availableNotificationSounds();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.translate('notification_sound')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (availableSounds.contains('azan'))
              _buildChoiceTile(
                context,
                title: Text(localizations.translate('azan')),
                selected: settings.notificationSound == 'azan',
                onTap: () {
                  ref
                      .read(settingsProvider.notifier)
                      .setNotificationSound('azan');
                  _applyNotificationSettings(ref);
                  Navigator.pop(context);
                },
              ),
            _buildChoiceTile(
              context,
              title: Text(localizations.translate('system_sound')),
              selected: settings.notificationSound == 'system',
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .setNotificationSound('system');
                _applyNotificationSettings(ref);
                Navigator.pop(context);
              },
            ),
            _buildChoiceTile(
              context,
              title: Text(localizations.translate('silent')),
              selected: settings.notificationSound == 'silent',
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .setNotificationSound('silent');
                _applyNotificationSettings(ref);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceTile(
    BuildContext context, {
    required Widget title,
    Widget? subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: title,
      subtitle: subtitle,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected
            ? Theme.of(context).colorScheme.secondary
            : Theme.of(context).disabledColor,
      ),
      onTap: onTap,
    );
  }
}
