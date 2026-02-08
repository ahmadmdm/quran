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

class SmartCardWidgetProvider : AppWidgetProvider() {

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
            val views = RemoteViews(context.packageName, R.layout.widget_smart_card)
            
            // Customization
            val bgHex = widgetData.getString("widget_background_color", "#FF0F1629")
            val textHex = widgetData.getString("widget_text_color", "#FFFFFFFF")
            val accentHex = widgetData.getString("widget_accent_color", "#FFC9A24D")
            
            val bgColor = try { Color.parseColor(bgHex) } catch (e: Exception) { Color.parseColor("#FF0F1629") }
            val textColor = try { Color.parseColor(textHex) } catch (e: Exception) { Color.WHITE }
            val accentColor = try { Color.parseColor(accentHex) } catch (e: Exception) { Color.parseColor("#FFC9A24D") }
            
            views.setInt(R.id.iv_background, "setColorFilter", bgColor)
            
            // Get next prayer info
            val nextPrayerName = widgetData.getString("next_prayer_name", "--")
            val timeRemaining = calculateTimeRemaining(widgetData)
            
            views.setTextViewText(R.id.tv_next_prayer, nextPrayerName)
            views.setTextViewText(R.id.tv_countdown, timeRemaining)
            views.setTextColor(R.id.tv_next_prayer, accentColor)
            views.setTextColor(R.id.tv_countdown, textColor)
            views.setTextColor(R.id.tv_header_label, Color.argb(136, Color.red(textColor), Color.green(textColor), Color.blue(textColor)))

            // Find which prayer is next (0-4)
            var nextPrayerIndex = -1
            val now = System.currentTimeMillis()
            for (i in 0..4) {
                val millis = widgetData.getLong("prayer_time_millis_$i", 0)
                if (millis > now && nextPrayerIndex == -1) {
                    nextPrayerIndex = i
                }
            }

            // Loop for 5 prayers (0 to 4)
            for (i in 0..4) {
                val nameKey = "prayer_name_$i"
                val timeKey = "prayer_time_$i"
                
                val name = widgetData.getString(nameKey, "--")
                val time = widgetData.getString(timeKey, "--:--")
                
                val nameId = getResId(i, "name")
                val timeId = getResId(i, "time")
                val itemId = getResId(i, "item")
                
                views.setTextViewText(nameId, name)
                views.setTextViewText(timeId, time)
                
                // Highlight next prayer
                if (i == nextPrayerIndex) {
                    views.setTextColor(nameId, accentColor)
                    views.setTextColor(timeId, textColor)
                } else {
                    views.setTextColor(nameId, Color.argb(136, Color.red(textColor), Color.green(textColor), Color.blue(textColor)))
                    views.setTextColor(timeId, Color.argb(204, Color.red(textColor), Color.green(textColor), Color.blue(textColor)))
                }

                // Add Click Listener to show remaining time
                val intent = Intent(context, SmartCardWidgetProvider::class.java).apply {
                    action = "SHOW_REMAINING"
                    putExtra("index", i)
                    putExtra("appWidgetId", appWidgetId)
                }
                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    i + (appWidgetId * 10), // Unique request code per item per widget
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(itemId, pendingIntent)
            }
            
            // Add click intent to open app on header
            val appIntent = Intent(context, MainActivity::class.java)
            val appPendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId,
                appIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_smart_card_root, appPendingIntent)
            
            try {
                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                android.util.Log.e("SmartCardWidget", "Error updating widget: ${e.message}")
            }
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == "SHOW_REMAINING") {
            val index = intent.getIntExtra("index", -1)
            val appWidgetId = intent.getIntExtra("appWidgetId", -1)
            
            if (index != -1 && appWidgetId != -1) {
                val widgetData = HomeWidgetPlugin.getData(context)
                val millis = widgetData.getLong("prayer_time_millis_$index", 0)
                
                if (millis > 0) {
                    val now = System.currentTimeMillis()
                    val diff = millis - now
                    
                    val text = if (diff > 0) {
                        val hours = TimeUnit.MILLISECONDS.toHours(diff)
                        val minutes = TimeUnit.MILLISECONDS.toMinutes(diff) % 60
                        String.format("-%02d:%02d", hours, minutes)
                    } else {
                        val absDiff = Math.abs(diff)
                        val hours = TimeUnit.MILLISECONDS.toHours(absDiff)
                        val minutes = TimeUnit.MILLISECONDS.toMinutes(absDiff) % 60
                        String.format("+%02d:%02d", hours, minutes)
                    }
                    
                    val views = RemoteViews(context.packageName, R.layout.widget_smart_card)
                    val timeId = getResId(index, "time")
                    
                    views.setTextViewText(timeId, text)
                    
                    // Re-apply customization
                    val bgHex = widgetData.getString("widget_background_color", "#FF0F1629")
                    val textHex = widgetData.getString("widget_text_color", "#FFFFFFFF")
                    val accentHex = widgetData.getString("widget_accent_color", "#FFC9A24D")
                    
                    val bgColor = try { Color.parseColor(bgHex) } catch (e: Exception) { Color.parseColor("#FF0F1629") }
                    val textColor = try { Color.parseColor(textHex) } catch (e: Exception) { Color.WHITE }
                    val accentColor = try { Color.parseColor(accentHex) } catch (e: Exception) { Color.parseColor("#FFC9A24D") }
                    
                    views.setInt(R.id.iv_background, "setColorFilter", bgColor)
                    
                    // Check if this is the next prayer
                    var nextPrayerIndex = widgetData.getInt("next_prayer_index", -1)
                    
                    // Fallback to time-based calculation if next_prayer_index is not set or invalid
                    if (nextPrayerIndex == -1) {
                        for (i in 0..4) {
                            val pMillis = widgetData.getLong("prayer_time_millis_$i", 0)
                            if (pMillis > now && nextPrayerIndex == -1) {
                                nextPrayerIndex = i
                            }
                        }
                    }
                    
                    if (index == nextPrayerIndex) {
                        views.setTextColor(timeId, textColor)
                    } else {
                        views.setTextColor(timeId, Color.argb(204, Color.red(textColor), Color.green(textColor), Color.blue(textColor)))
                    }
                    
                    val appWidgetManager = AppWidgetManager.getInstance(context)
                    appWidgetManager.partiallyUpdateAppWidget(appWidgetId, views)
                }
            }
        }
    }

    private fun getResId(index: Int, type: String): Int {
        return when(index) {
            0 -> when(type) { "name" -> R.id.tv_name_0; "time" -> R.id.tv_time_0; else -> R.id.item_0 }
            1 -> when(type) { "name" -> R.id.tv_name_1; "time" -> R.id.tv_time_1; else -> R.id.item_1 }
            2 -> when(type) { "name" -> R.id.tv_name_2; "time" -> R.id.tv_time_2; else -> R.id.item_2 }
            3 -> when(type) { "name" -> R.id.tv_name_3; "time" -> R.id.tv_time_3; else -> R.id.item_3 }
            4 -> when(type) { "name" -> R.id.tv_name_4; "time" -> R.id.tv_time_4; else -> R.id.item_4 }
            else -> R.id.tv_name_0
        }
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
