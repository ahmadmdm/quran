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

class GlassCardWidgetProvider : AppWidgetProvider() {
    
    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        WidgetUpdateReceiver.scheduleUpdates(context)
    }
    
    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        WidgetUpdateReceiver.checkAndCancelUpdates(context)
    }
    
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.widget_glass_card)
            
            val prayerName = widgetData.getString("next_prayer_name", "الفجر")
            val prayerTime = widgetData.getString("next_prayer_time", "--:--")
            val timeRemaining = calculateTimeRemaining(widgetData)
            
            // Customization
            val bgHex = getSetting(widgetData, "glass_card_background_color", "glass card_background_color", "#FF0F1629")
            val textHex = getSetting(widgetData, "glass_card_text_color", "glass card_text_color", "#FFFFFFFF")
            val accentHex = getSetting(widgetData, "glass_card_accent_color", "glass card_accent_color", "#FFC9A24D")

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
            
            // Set text values
            views.setTextViewText(R.id.tv_prayer_name, prayerName)
            views.setTextViewText(R.id.tv_time_remaining, timeRemaining)
            views.setTextViewText(R.id.tv_prayer_time, prayerTime)

            // Apply background and text customization
            views.setInt(R.id.iv_glass_bg, "setColorFilter", bgColor)
            views.setTextColor(R.id.tv_label, Color.argb(160, Color.red(textColor), Color.green(textColor), Color.blue(textColor)))
            views.setTextColor(R.id.tv_prayer_name, textColor)
            views.setTextColor(R.id.tv_time_remaining, textColor)
            views.setTextColor(R.id.tv_prayer_time, Color.argb(190, Color.red(textColor), Color.green(textColor), Color.blue(textColor)))
            
            // Apply accent color
            views.setTextColor(R.id.tv_islamic_icon, accentColor)
            views.setTextColor(R.id.tv_time_icon, accentColor)
            
            // Add click intent to open app
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_glass_root, pendingIntent)
            
            try {
                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                android.util.Log.e("GlassCardWidget", "Error updating widget: ${e.message}")
            }
        }
        
        WidgetUpdateReceiver.scheduleUpdates(context)
    }
    
    private fun calculateTimeRemaining(widgetData: android.content.SharedPreferences): String {
        val currentTime = System.currentTimeMillis()
        var nextPrayerTime = widgetData.getLong("next_prayer_millis", 0L)
        
        if (nextPrayerTime <= currentTime) {
            nextPrayerTime = Long.MAX_VALUE
            for (i in 0..5) {
                val prayerTimeMillis = widgetData.getLong("prayer_time_millis_$i", 0L)
                if (prayerTimeMillis > currentTime && prayerTimeMillis < nextPrayerTime) {
                    nextPrayerTime = prayerTimeMillis
                }
            }
        }
        
        return if (nextPrayerTime != Long.MAX_VALUE && nextPrayerTime > currentTime) {
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

    private fun getSetting(
        prefs: android.content.SharedPreferences,
        key: String,
        legacyKey: String,
        defaultValue: String
    ): String {
        return prefs.getString(key, null)
            ?: prefs.getString(legacyKey, null)
            ?: defaultValue
    }
}
