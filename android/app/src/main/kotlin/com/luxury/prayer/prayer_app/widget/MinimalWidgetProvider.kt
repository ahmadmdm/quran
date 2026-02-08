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

class MinimalWidgetProvider : AppWidgetProvider() {
    
    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        // Start periodic updates when first widget is added
        WidgetUpdateReceiver.scheduleUpdates(context)
    }
    
    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        // Stop updates only if no other widgets are active
        WidgetUpdateReceiver.checkAndCancelUpdates(context)
    }
    
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.widget_minimal).apply {
                val prayerName = widgetData.getString("next_prayer_name", "--")
                val prayerTime = widgetData.getString("next_prayer_time", "--:--")
                
                // Calculate time remaining dynamically
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

                // Apply Background tint
                setInt(R.id.iv_background, "setColorFilter", bgColor)

                // Set text values
                setTextViewText(R.id.tv_prayer_name, prayerName)
                setTextViewText(R.id.tv_next_time, prayerTime)
                setTextViewText(R.id.tv_time_remaining, timeRemaining)
                
                // Apply Text Colors
                setTextColor(R.id.tv_prayer_name, accentColor)
                setTextColor(R.id.tv_time_remaining, textColor)
                setTextColor(R.id.tv_next_time, Color.argb(153, Color.red(textColor), Color.green(textColor), Color.blue(textColor)))
                setTextColor(R.id.tv_label_next, Color.argb(136, Color.red(textColor), Color.green(textColor), Color.blue(textColor)))
            }
            
            // Add click intent to open app
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            
            try {
                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                android.util.Log.e("MinimalWidget", "Error updating widget: ${e.message}")
            }
        }
        
        // Ensure updates are scheduled
        WidgetUpdateReceiver.scheduleUpdates(context)
    }
    
    private fun calculateTimeRemaining(widgetData: android.content.SharedPreferences): String {
        val currentTime = System.currentTimeMillis()
        var nextPrayerTime = widgetData.getLong("next_prayer_millis", 0L)
        
        // Fallback to finding from list if next_prayer_millis is invalid or past (shouldn't happen if Flutter logic is correct)
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
}
