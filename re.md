MASTER PROMPT
Flutter Widgets \& Notifications System – Android 14/15/16 Ready
ROLE

Act as a Senior Android System Engineer + Flutter Platform Specialist with deep experience in Android widgets, background services, and system notifications.

OBJECTIVE

Design and implement a professional-grade widgets and notifications system for a premium Islamic Prayer Times Flutter app, fully compliant with the latest Android versions (Android 13 → 16), using best practices for battery, permissions, and user experience.

PART 1 – WIDGET SYSTEM
Widgets to Generate
Widget 1 – Minimal Widget (1x1 / 2x1)

Shows:

Next prayer name

Time remaining

Transparent background

Updates every minute

Widget 2 – Smart Card (4x2)

Shows:

All 5 prayers

Highlight next prayer

Circular progress bar

Dark \& Light themes

Widget 3 – Premium Clock Widget (4x4)

Huge analog/digital clock

Prayer countdown ring

Qibla mini icon

Gold glow accent

Widget 4 – Lock Screen Widget (Android 14+)

Minimal text

Always-on display style

AMOLED friendly

Widget Requirements

Native Android AppWidget (not Flutter-only fake)

Auto refresh using:

AlarmManager

WorkManager fallback

Ultra low battery usage

Dynamic theming

RTL support

Adaptive sizes

Material You (Dynamic Color)

PART 2 – NOTIFICATION SYSTEM
Notification Types

1. Pre-Azan Reminder

10 / 15 / 30 minutes before

Silent or vibration

2. Full Azan

Custom audio

Full screen intent

Lockscreen priority

3. Next Prayer Countdown

Persistent notification

Updates every minute

4. Smart Daily Summary

Morning summary

All prayer times

Android 13+ Compliance
Must Implement:

POST\_NOTIFICATIONS permission

Exact alarm permission handling

Notification channels:

Azan

Reminders

Silent

Widgets

Power Optimizations:

Respect Doze mode

Use foreground service only if needed

Battery optimization bypass dialog

TECH IMPLEMENTATION
Flutter Side

flutter\_local\_notifications

android\_alarm\_manager\_plus

WorkManager

Native Android

Kotlin platform channel

AppWidgetProvider

AlarmReceiver

NotificationReceiver

ForegroundService

UX STANDARDS

No spam notifications

Clear onboarding screen:

Permissions

Battery optimization

Exact alarm explanation

User controls:

Per-prayer notification toggle

Custom sound per prayer

Snooze

PREMIUM TOUCHES

Haptic feedback on widget tap

Smooth fade animation on update

Material You colors on Android 12+

Lock screen blur

AMOLED true black mode

AI KEYWORDS
Android professional widgets
Material You
Lock screen widgets
Persistent countdown notification
Exact alarms
Low battery usage
Foreground service minimal
Samsung OneUI style
Google Pixel UX

OUTPUT REQUIREMENTS

Generate:

Native Android widget XML layouts.

Kotlin AppWidgetProvider code.

Platform channel to Flutter.

Notification channel setup.

Exact alarm scheduler.

Battery optimization dialog.

Permissions handling flow.

WorkManager background refresh.

SUCCESS CRITERIA

The system must feel like:

Google Clock Widgets
Samsung Calendar Notifications
Apple Watch Complications

But for Islamic prayer times.

