import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:permission_handler/permission_handler.dart';
import 'package:adhan/adhan.dart';
import 'package:device_info_plus/device_info_plus.dart';

class NotificationService {
  static const platform = MethodChannel('com.luxury.prayer/countdown');

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  int _androidSdkVersion = 0;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));
    } catch (e) {
      print('Timezone initialization error: $e');
    }

    // Get Android SDK version for compatibility
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      _androidSdkVersion = androidInfo.version.sdkInt;
      print('Android SDK Version: $_androidSdkVersion');
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationTapped,
    );

    await _createNotificationChannels();
    await _requestPermissions();

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - can navigate to specific screen
    print('Notification tapped: ${response.payload}');
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    // Handle background notification tap
    print('Background notification tapped: ${response.payload}');
  }

  Future<void> _createNotificationChannels() async {
    final platform = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (platform == null) return;

    // Main Azan Channel with custom sound - High importance for Android 13+
    await platform.createNotificationChannel(
      AndroidNotificationChannel(
        'azan_channel',
        'إشعارات الأذان',
        description: 'إشعارات وقت الصلاة مع صوت الأذان',
        importance: Importance.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('azan'),
        enableVibration: true,
        enableLights: true,
        ledColor: const Color.fromARGB(255, 201, 162, 77),
        showBadge: true,
        // Android 14+ specific settings
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );

    // Reminder Channel - For pre-prayer reminders
    await platform.createNotificationChannel(
      const AndroidNotificationChannel(
        'reminder_channel',
        'تذكيرات الصلاة',
        description: 'تذكيرات قبل وقت الصلاة',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );

    // Silent Channel for countdown - Low importance
    await platform.createNotificationChannel(
      const AndroidNotificationChannel(
        'silent_channel',
        'إشعارات صامتة',
        description: 'تحديثات العد التنازلي',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        showBadge: false,
      ),
    );

    // Instant notifications channel
    await platform.createNotificationChannel(
      const AndroidNotificationChannel(
        'instant_channel',
        'إشعارات فورية',
        description: 'إشعارات فورية',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );

    // Dynamic channels for customization
    final channels = [
      ('azan_sound_vibrate', 'أذان مع اهتزاز', true, true, 'azan'),
      ('azan_sound_no_vibrate', 'أذان بدون اهتزاز', true, false, 'azan'),
      ('system_sound_vibrate', 'صوت النظام مع اهتزاز', true, true, null),
      ('system_sound_no_vibrate', 'صوت النظام بدون اهتزاز', true, false, null),
      ('silent_vibrate', 'صامت مع اهتزاز', false, true, null),
      ('silent_no_vibrate', 'صامت بدون اهتزاز', false, false, null),
    ];

    for (final channel in channels) {
      await platform.createNotificationChannel(
        AndroidNotificationChannel(
          channel.$1,
          channel.$2,
          description: channel.$2,
          importance: Importance.max,
          playSound: channel.$3,
          sound: channel.$5 != null
              ? RawResourceAndroidNotificationSound(channel.$5!)
              : null,
          enableVibration: channel.$4,
          showBadge: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final platform = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      // Request notification permission (Android 13+)
      final notificationStatus = await Permission.notification.request();
      print('Notification permission: $notificationStatus');

      // Request exact alarm permission for Android 12+
      await platform?.requestNotificationsPermission();

      // For Android 12+ (API 31+), request exact alarms permission
      if (_androidSdkVersion >= 31) {
        await platform?.requestExactAlarmsPermission();

        // Check if exact alarms are allowed
        final exactAlarmsAllowed =
            await Permission.scheduleExactAlarm.isGranted;
        if (!exactAlarmsAllowed) {
          await Permission.scheduleExactAlarm.request();
        }
      }

      // For Android 14+ (API 34+), request full screen intent permission
      if (_androidSdkVersion >= 34) {
        // Full screen intent permission is automatically granted for alarm apps
        // but we should check and handle it
        print('Android 14+ detected, full screen intent handling enabled');
      }

      // Request ignore battery optimizations for reliable notifications
      if (await Permission.ignoreBatteryOptimizations.isDenied) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } else if (Platform.isIOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final platform = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await platform?.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  Future<bool> canScheduleExactAlarms() async {
    if (Platform.isAndroid && _androidSdkVersion >= 31) {
      final platform = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await platform?.canScheduleExactNotifications() ?? false;
    }
    return true;
  }

  Future<void> schedulePrayers(
    PrayerTimes prayerTimes, {
    bool notificationsEnabled = true,
    int preAzanReminderOffset = 15,
    String notificationSound = 'azan',
    bool vibrationEnabled = true,
  }) async {
    // Cancel all existing notifications first
    await cancelAll();

    if (!notificationsEnabled) {
      print('Notifications disabled, skipping scheduling');
      return;
    }

    // Check if notifications are actually enabled at system level
    final enabled = await areNotificationsEnabled();
    if (!enabled) {
      print('System notifications disabled');
      return;
    }

    // Check if we can schedule exact alarms (Android 12+)
    final canScheduleExact = await canScheduleExactAlarms();
    if (!canScheduleExact) {
      print('Cannot schedule exact alarms, requesting permission');
      await _requestPermissions();
    }

    final prayers = [
      (Prayer.fajr, prayerTimes.fajr, 'الفجر', 'Fajr'),
      (Prayer.dhuhr, prayerTimes.dhuhr, 'الظهر', 'Dhuhr'),
      (Prayer.asr, prayerTimes.asr, 'العصر', 'Asr'),
      (Prayer.maghrib, prayerTimes.maghrib, 'المغرب', 'Maghrib'),
      (Prayer.isha, prayerTimes.isha, 'العشاء', 'Isha'),
    ];

    int id = 0;
    final now = DateTime.now();

    for (final prayer in prayers) {
      final prayerNameAr = prayer.$3;
      final prayerNameEn = prayer.$4;
      final prayerTime = prayer.$2;

      // Schedule main Azan notification
      if (prayerTime.isAfter(now)) {
        await _scheduleNotification(
          id: id++,
          title: 'حان وقت صلاة $prayerNameAr',
          body: 'حان الآن موعد صلاة $prayerNameAr - $prayerNameEn',
          scheduledTime: prayerTime,
          isAzan: true,
          soundType: notificationSound,
          vibrate: vibrationEnabled,
          payload: 'prayer_$prayerNameEn',
        );

        // Schedule pre-Azan reminder
        if (preAzanReminderOffset > 0) {
          final reminderTime = prayerTime.subtract(
            Duration(minutes: preAzanReminderOffset),
          );
          if (reminderTime.isAfter(now)) {
            await _scheduleNotification(
              id: id++,
              title: 'تذكير: صلاة $prayerNameAr',
              body: 'باقي $preAzanReminderOffset دقيقة على صلاة $prayerNameAr',
              scheduledTime: reminderTime,
              isAzan: false,
              soundType: 'system',
              vibrate: vibrationEnabled,
              payload: 'reminder_$prayerNameEn',
            );
          }
        }
      }
    }

    // Start native countdown service
    await _startCountdownService(prayerTimes);

    print('Scheduled $id notifications');
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required bool isAzan,
    required String soundType,
    required bool vibrate,
    String? payload,
  }) async {
    String channelId;
    String channelName;
    String channelDesc;
    Importance importance = Importance.max;
    Priority priority = Priority.high;
    AndroidNotificationSound? sound;
    bool playSound = true;
    bool enableVibration = vibrate;

    if (isAzan) {
      if (soundType == 'azan') {
        channelId = vibrate ? 'azan_sound_vibrate' : 'azan_sound_no_vibrate';
        channelName = 'إشعارات الأذان';
        channelDesc = 'إشعارات وقت الصلاة مع صوت الأذان';
        sound = const RawResourceAndroidNotificationSound('azan');
      } else if (soundType == 'silent') {
        channelId = vibrate ? 'silent_vibrate' : 'silent_no_vibrate';
        channelName = 'إشعارات صامتة';
        channelDesc = 'إشعارات صامتة';
        playSound = false;
      } else {
        channelId = vibrate
            ? 'system_sound_vibrate'
            : 'system_sound_no_vibrate';
        channelName = 'إشعارات الصلاة';
        channelDesc = 'إشعارات وقت الصلاة';
        sound = null;
      }
    } else {
      if (soundType == 'silent') {
        channelId = vibrate ? 'silent_vibrate' : 'silent_no_vibrate';
        channelName = 'تذكيرات صامتة';
        channelDesc = 'تذكيرات صامتة';
        playSound = false;
      } else {
        channelId = vibrate
            ? 'system_sound_vibrate'
            : 'system_sound_no_vibrate';
        channelName = 'تذكيرات الصلاة';
        channelDesc = 'تذكيرات قبل وقت الصلاة';
        sound = null;
      }
      importance = Importance.high;
      priority = Priority.defaultPriority;
    }

    try {
      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      // Determine schedule mode based on Android version
      AndroidScheduleMode scheduleMode;
      if (_androidSdkVersion >= 31) {
        // Android 12+ - Use exact alarm if allowed, otherwise inexact
        final canScheduleExact = await canScheduleExactAlarms();
        scheduleMode = canScheduleExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle;
      } else {
        scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
      }

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDesc,
            importance: importance,
            priority: priority,
            fullScreenIntent:
                isAzan && _androidSdkVersion < 34, // Disable for Android 14+
            sound: sound,
            playSound: playSound,
            enableVibration: enableVibration,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            icon: '@mipmap/ic_launcher',
            largeIcon: const DrawableResourceAndroidBitmap(
              '@mipmap/ic_launcher',
            ),
            styleInformation: BigTextStyleInformation(
              body,
              contentTitle: title,
              summaryText: isAzan ? 'وقت الصلاة' : 'تذكير',
            ),
            // Android 13+ specific
            actions: isAzan
                ? [
                    const AndroidNotificationAction(
                      'dismiss',
                      'إغلاق',
                      showsUserInterface: false,
                      cancelNotification: true,
                    ),
                    const AndroidNotificationAction(
                      'open_app',
                      'فتح التطبيق',
                      showsUserInterface: true,
                    ),
                  ]
                : null,
            // Android 14+ - Use foreground service for time-sensitive notifications
            usesChronometer: false,
            chronometerCountDown: false,
            ongoing: false,
            autoCancel: true,
            // Color for notification
            color: const Color.fromARGB(255, 201, 162, 77),
            colorized: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: playSound,
            sound: isAzan && soundType == 'azan' ? 'azan.caf' : null,
            interruptionLevel: isAzan
                ? InterruptionLevel.timeSensitive
                : InterruptionLevel.active,
          ),
        ),
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      print(
        'Scheduled notification $id for $scheduledTime (mode: $scheduleMode)',
      );
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  Future<void> _startCountdownService(PrayerTimes prayerTimes) async {
    final next = prayerTimes.nextPrayer();
    if (next == Prayer.none) return;

    final nextTime = prayerTimes.timeForPrayer(next);
    if (nextTime == null) return;

    final prayerNames = {
      Prayer.fajr: 'الفجر',
      Prayer.dhuhr: 'الظهر',
      Prayer.asr: 'العصر',
      Prayer.maghrib: 'المغرب',
      Prayer.isha: 'العشاء',
    };

    try {
      await platform.invokeMethod('startCountdown', {
        'prayer_name': prayerNames[next] ?? next.name.toUpperCase(),
        'target_time': nextTime.millisecondsSinceEpoch,
      });
    } on PlatformException catch (e) {
      print("Failed to start countdown service: '${e.message}'.");
    }
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'instant_channel',
          'إشعارات فورية',
          channelDescription: 'إشعارات فورية',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color.fromARGB(255, 201, 162, 77),
          colorized: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  Future<void> showPersistentNotification(
    int id,
    String title,
    String body,
  ) async {
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'silent_channel',
          'إشعارات صامتة',
          channelDescription: 'تحديثات العد التنازلي',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          showWhen: false,
        ),
      ),
    );
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  // Get notification permission status
  Future<Map<String, bool>> getPermissionStatus() async {
    final status = <String, bool>{};

    if (Platform.isAndroid) {
      status['notifications'] = await areNotificationsEnabled();
      status['exactAlarms'] = await canScheduleExactAlarms();
      status['batteryOptimization'] =
          await Permission.ignoreBatteryOptimizations.isGranted;
    } else {
      status['notifications'] = true;
      status['exactAlarms'] = true;
      status['batteryOptimization'] = true;
    }

    return status;
  }
}
