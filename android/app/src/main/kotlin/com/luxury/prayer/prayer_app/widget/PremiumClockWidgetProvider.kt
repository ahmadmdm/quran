package com.luxury.prayer.prayer_app.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.app.PendingIntent
import android.widget.RemoteViews
import com.luxury.prayer.prayer_app.R
import com.luxury.prayer.prayer_app.MainActivity
import es.antonborri.home_widget.HomeWidgetPlugin
import android.graphics.Color
import java.util.concurrent.TimeUnit

class PremiumClockWidgetProvider : AppWidgetProvider() {
    
    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        WidgetUpdateReceiver.scheduleUpdates(context)
    }
    
    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        WidgetUpdateReceiver.cancelUpdates(context)
    }
    
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.widget_premium_clock)
            
            val prayerName = widgetData.getString("next_prayer_name", "--")
            val prayerTime = widgetData.getString("next_prayer_time", "--:--")
            val timeRemaining = calculateTimeRemaining(widgetData)
            
            // Customization
            val bgHex = widgetData.getString("widget_background_color", "#FF0F1629")
            val textHex = widgetData.getString("widget_text_color", "#FFFFFFFF")
            val accentHex = widgetData.getString("widget_accent_color", "#FFC9A24D")

            val bgColor = try {
                Color.parseColor(bgHex)
            } catch (e: Exception) {
                Color.parseColor("#FF0F1629")
            }

            val textColor = try {
                Color.parseColor(textHex)
            } catch (e: Exception) {
                Color.WHITE
            }
            
            val accentColor = try {
                Color.parseColor(accentHex)
            } catch (e: Exception) {
                Color.parseColor("#FFC9A24D")
            }

            // Apply Background
            views.setInt(R.id.iv_background, "setColorFilter", bgColor)
            
            // Apply Text Colors
            views.setTextColor(R.id.tv_clock_time, accentColor)
            views.setTextColor(R.id.tv_clock_seconds, Color.argb(136, Color.red(accentColor), Color.green(accentColor), Color.blue(accentColor)))
            views.setTextColor(R.id.tv_next_prayer_name, textColor)
            views.setTextColor(R.id.tv_time_remaining, Color.argb(153, Color.red(textColor), Color.green(textColor), Color.blue(textColor)))
            views.setTextColor(R.id.tv_prayer_time, Color.argb(102, Color.red(textColor), Color.green(textColor), Color.blue(textColor)))
            
            // Set text values
            views.setTextViewText(R.id.tv_next_prayer_name, prayerName)
            views.setTextViewText(R.id.tv_time_remaining, timeRemaining)
            views.setTextViewText(R.id.tv_prayer_time, prayerTime)
            
            // Calculate progress for the ring (time until next prayer)
            // For now, we'll use a static progress. In a real implementation,
            // you'd calculate based on time between prayers
            val now = System.currentTimeMillis()
            var nextPrayerMillis = 0L
            var prevPrayerMillis = 0L
            
            for (i in 0..4) {
                val millis = widgetData.getLong("prayer_time_millis_$i", 0)
                if (millis > now && nextPrayerMillis == 0L) {
                    nextPrayerMillis = millis
                    if (i > 0) {
                        prevPrayerMillis = widgetData.getLong("prayer_time_millis_${i-1}", 0)
                    }
                }
            }
            
            if (nextPrayerMillis > 0 && prevPrayerMillis > 0) {
                val totalDuration = nextPrayerMillis - prevPrayerMillis
                val elapsed = now - prevPrayerMillis
                val progress = ((elapsed.toFloat() / totalDuration.toFloat()) * 100).toInt().coerceIn(0, 100)
                views.setProgressBar(R.id.progress_ring, 100, progress, false)
            } else {
                views.setProgressBar(R.id.progress_ring, 100, 50, false)
            }
            
            // Interaction: Open App on Click
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_clock_root, pendingIntent)

            try {
                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                android.util.Log.e("PremiumClockWidget", "Error updating widget: ${e.message}")
            }
        }
        
        // Ensure updates are scheduled
        WidgetUpdateReceiver.scheduleUpdates(context)
    }
    
    private fun calculateTimeRemaining(widgetData: android.content.SharedPreferences): String {
        val currentTime = System.currentTimeMillis()
        var nextPrayerTime = Long.MAX_VALUE
        
        for (i in 0..5) {
            val prayerTimeMillis = widgetData.getLong("prayer_time_millis_$i", 0L)
            if (prayerTimeMillis > currentTime && prayerTimeMillis < nextPrayerTime) {
                nextPrayerTime = prayerTimeMillis
            }
        }
        
        return if (nextPrayerTime != Long.MAX_VALUE) {
            val remainingMillis = nextPrayerTime - currentTime
            val hours = TimeUnit.MILLISECONDS.toHours(remainingMillis)
            val minutes = TimeUnit.MILLISECONDS.toMinutes(remainingMillis) % 60
            
            if (hours > 0) {
                String.format("%d:%02d", hours, minutes)
            } else {
                String.format("%d دقيقة", minutes)
            }
        } else {
            widgetData.getString("time_remaining", "--:--") ?: "--:--"
        }
    }
}
