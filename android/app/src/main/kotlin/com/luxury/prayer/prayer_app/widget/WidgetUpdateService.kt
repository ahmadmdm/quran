package com.luxury.prayer.prayer_app.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.util.Log
import es.antonborri.home_widget.HomeWidgetPlugin
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.TimeUnit

class WidgetUpdateReceiver : BroadcastReceiver() {
    companion object {
        const val ACTION_UPDATE_WIDGETS = "com.luxury.prayer.prayer_app.UPDATE_WIDGETS"
        private const val TAG = "WidgetUpdateReceiver"
        
        // Update every 30 seconds for faster updates
        private const val UPDATE_INTERVAL_MS = 30000L
        
        fun scheduleUpdates(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, WidgetUpdateReceiver::class.java).apply {
                action = ACTION_UPDATE_WIDGETS
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            // Cancel any existing alarms
            alarmManager.cancel(pendingIntent)
            
            // For Android 12+ (API 31+), check if we can schedule exact alarms
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    // Use exact alarm for precise updates
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.ELAPSED_REALTIME_WAKEUP,
                        SystemClock.elapsedRealtime() + UPDATE_INTERVAL_MS,
                        pendingIntent
                    )
                } else {
                    // Fall back to inexact repeating alarm
                    alarmManager.setRepeating(
                        AlarmManager.ELAPSED_REALTIME,
                        SystemClock.elapsedRealtime() + UPDATE_INTERVAL_MS,
                        UPDATE_INTERVAL_MS,
                        pendingIntent
                    )
                }
            } else {
                // For older Android versions, use setExactAndAllowWhileIdle
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.ELAPSED_REALTIME_WAKEUP,
                    SystemClock.elapsedRealtime() + UPDATE_INTERVAL_MS,
                    pendingIntent
                )
            }
            
            Log.d(TAG, "Widget updates scheduled every ${UPDATE_INTERVAL_MS}ms")
        }
        
        fun cancelUpdates(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, WidgetUpdateReceiver::class.java).apply {
                action = ACTION_UPDATE_WIDGETS
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(pendingIntent)
            Log.d(TAG, "Widget updates cancelled")
        }

        fun checkAndCancelUpdates(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val providers = arrayOf(
                MinimalWidgetProvider::class.java,
                SmartCardWidgetProvider::class.java,
                PremiumClockWidgetProvider::class.java,
                GlassCardWidgetProvider::class.java,
                QuranVerseWidgetProvider::class.java,
                CreativeWidgetProvider::class.java,
                HijriDateWidgetProvider::class.java,
                CalligraphyWidgetProvider::class.java
            )
            
            var hasActiveWidgets = false
            for (provider in providers) {
                if (appWidgetManager.getAppWidgetIds(ComponentName(context, provider)).isNotEmpty()) {
                    hasActiveWidgets = true
                    break
                }
            }
            
            if (!hasActiveWidgets) {
                cancelUpdates(context)
            } else {
                Log.d(TAG, "Widgets still active, not cancelling updates")
            }
        }
        
        // Force immediate update
        fun forceUpdate(context: Context) {
            val intent = Intent(context, WidgetUpdateReceiver::class.java).apply {
                action = ACTION_UPDATE_WIDGETS
            }
            context.sendBroadcast(intent)
            Log.d(TAG, "Force update triggered")
        }
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Received action: ${intent.action}")
        
        when (intent.action) {
            ACTION_UPDATE_WIDGETS -> {
                updateAllWidgets(context)
                // Reschedule for next update (for exact alarms)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    scheduleUpdates(context)
                }
            }
            Intent.ACTION_BOOT_COMPLETED, 
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                updateAllWidgets(context)
                scheduleUpdates(context)
            }
            Intent.ACTION_TIME_CHANGED, 
            Intent.ACTION_TIMEZONE_CHANGED -> {
                updateAllWidgets(context)
            }
        }
    }
    
    private fun updateAllWidgets(context: Context) {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        
        // Update time remaining based on stored prayer times
        updateTimeRemaining(context)
        
        // Update Minimal Widget
        updateWidgetProvider(context, appWidgetManager, MinimalWidgetProvider::class.java)
        
        // Update Smart Card Widget
        updateWidgetProvider(context, appWidgetManager, SmartCardWidgetProvider::class.java)
        
        // Update Premium Clock Widget
        updateWidgetProvider(context, appWidgetManager, PremiumClockWidgetProvider::class.java)
        
        // Update Glass Card Widget
        updateWidgetProvider(context, appWidgetManager, GlassCardWidgetProvider::class.java)
        
        // Update Quran Verse Widget
        updateWidgetProvider(context, appWidgetManager, QuranVerseWidgetProvider::class.java)

        // Update Creative Widget
        updateWidgetProvider(context, appWidgetManager, CreativeWidgetProvider::class.java)
        
        // Update Hijri Date Widget
        updateWidgetProvider(context, appWidgetManager, HijriDateWidgetProvider::class.java)
        
        Log.d(TAG, "All widgets updated at ${SimpleDateFormat("HH:mm:ss", Locale.getDefault()).format(Date())}")
    }
    
    private fun <T : BroadcastReceiver> updateWidgetProvider(
        context: Context, 
        appWidgetManager: AppWidgetManager, 
        providerClass: Class<T>
    ) {
        val ids = appWidgetManager.getAppWidgetIds(ComponentName(context, providerClass))
        if (ids.isNotEmpty()) {
            val intent = Intent(context, providerClass).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            }
            context.sendBroadcast(intent)
        }
    }
    
    private fun updateTimeRemaining(context: Context) {
        val widgetData = HomeWidgetPlugin.getData(context)
        val currentTime = System.currentTimeMillis()
        
        // Get stored prayer times in milliseconds
        var nextPrayerIndex = -1
        var nextPrayerTime = widgetData.getLong("next_prayer_millis", 0L)
        
        val prayerNames = arrayOf("الفجر", "الشروق", "الظهر", "العصر", "المغرب", "العشاء")
        
        // If next_prayer_millis is valid and in the future, use it
        if (nextPrayerTime > currentTime) {
            // Find which prayer index this corresponds to
            // This is a best-effort matching
            val nextPrayerName = widgetData.getString("next_prayer_name", "")
            nextPrayerIndex = prayerNames.indexOf(nextPrayerName)
            
            // If we couldn't match by name, try to match by time (handling next day Fajr case)
            if (nextPrayerIndex == -1) {
                 // Check if it matches any of today's prayer times
                 for (i in 0..5) {
                    val prayerTimeMillis = widgetData.getLong("prayer_time_millis_$i", 0L)
                    if (Math.abs(prayerTimeMillis - nextPrayerTime) < 10000) { // 10 seconds tolerance
                        nextPrayerIndex = i
                        break
                    }
                }
                
                // If still -1, it might be tomorrow's Fajr
                if (nextPrayerIndex == -1) {
                    // Assuming if it's not today's prayers, and we have a valid future time, it's likely Fajr
                    // We can also check the stored next_prayer_index from Flutter
                    nextPrayerIndex = widgetData.getInt("next_prayer_index", -1)
                }
            }
        } else {
            // Fallback to finding the next prayer from today's list (only works for same-day prayers)
            nextPrayerTime = Long.MAX_VALUE
            for (i in 0..5) {
                val prayerTimeMillis = widgetData.getLong("prayer_time_millis_$i", 0L)
                if (prayerTimeMillis > currentTime && prayerTimeMillis < nextPrayerTime) {
                    nextPrayerTime = prayerTimeMillis
                    nextPrayerIndex = i
                }
            }
        }
        
        if (nextPrayerTime != Long.MAX_VALUE && nextPrayerTime > currentTime) {
            val remainingMillis = nextPrayerTime - currentTime
            val hours = TimeUnit.MILLISECONDS.toHours(remainingMillis)
            val minutes = TimeUnit.MILLISECONDS.toMinutes(remainingMillis) % 60
            val seconds = TimeUnit.MILLISECONDS.toSeconds(remainingMillis) % 60
            
            // Format time remaining with seconds for more precision
            val timeRemaining = when {
                hours > 0 -> String.format("%d:%02d:%02d", hours, minutes, seconds)
                minutes > 0 -> String.format("%d:%02d", minutes, seconds)
                else -> String.format("%d ث", seconds)
            }
            
            // Also format without seconds for widgets that don't need it
            val timeRemainingShort = when {
                hours > 0 -> String.format("%d:%02d", hours, minutes)
                else -> String.format("%d د", minutes)
            }
            
            // Update the time remaining in shared preferences
            val editor = widgetData.edit()
            editor.putString("time_remaining", timeRemaining)
            editor.putString("time_remaining_short", timeRemainingShort)
            editor.putInt("next_prayer_index", nextPrayerIndex)
            editor.putString("next_prayer_name", prayerNames.getOrElse(nextPrayerIndex) { "" })
            editor.putLong("last_update_time", currentTime)
            editor.apply()
            
            Log.d(TAG, "Time remaining: $timeRemaining for ${prayerNames.getOrElse(nextPrayerIndex) { "Unknown" }}")
        }
    }
}
