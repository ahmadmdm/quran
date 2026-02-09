package com.luxury.prayer.prayer_app.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.luxury.prayer.prayer_app.MainActivity
import com.luxury.prayer.prayer_app.R
import android.graphics.Color
import es.antonborri.home_widget.HomeWidgetPlugin
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.TimeUnit

class CreativeWidgetProvider : AppWidgetProvider() {

    companion object {
        private val PRAYER_NAMES = arrayOf("الفجر", "الشروق", "الظهر", "العصر", "المغرب", "العشاء")
        
        private val HIJRI_MONTHS = arrayOf(
            "محرم", "صفر", "ربيع الأول", "ربيع الثاني",
            "جمادى الأولى", "جمادى الآخرة", "رجب", "شعبان",
            "رمضان", "شوال", "ذو القعدة", "ذو الحجة"
        )
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
        
        // Schedule updates
        WidgetUpdateReceiver.scheduleUpdates(context)
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        WidgetUpdateReceiver.scheduleUpdates(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        WidgetUpdateReceiver.checkAndCancelUpdates(context)
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_creative)
        val widgetData = HomeWidgetPlugin.getData(context)

        // Customization
        val bgHex = widgetData.getString("creative_background_color", "#FF0F1629")
        val textHex = widgetData.getString("creative_text_color", "#FFFFFFFF")
        val accentHex = widgetData.getString("creative_accent_color", "#FFC9A24D")

        val bgColor = try { Color.parseColor(bgHex) } catch (e: Exception) { Color.parseColor("#FF0F1629") }
        val textColor = try { Color.parseColor(textHex) } catch (e: Exception) { Color.WHITE }
        val accentColor = try { Color.parseColor(accentHex) } catch (e: Exception) { Color.parseColor("#FFC9A24D") }

        // Apply Background
        views.setInt(R.id.iv_background, "setColorFilter", bgColor)

        // Apply Text Colors
        views.setTextColor(R.id.next_prayer_name, accentColor)
        views.setTextColor(R.id.time_remaining, textColor)
        views.setTextColor(R.id.current_time, textColor)
        views.setTextColor(R.id.current_date, Color.argb(200, Color.red(textColor), Color.green(textColor), Color.blue(textColor)))
        views.setTextColor(R.id.location, Color.argb(150, Color.red(textColor), Color.green(textColor), Color.blue(textColor)))
        
        // Get prayer times
        val prayerTimes = arrayOf(
            widgetData.getString("fajr_time", "04:30") ?: "04:30",
            widgetData.getString("sunrise_time", "06:00") ?: "06:00",
            widgetData.getString("dhuhr_time", "12:15") ?: "12:15",
            widgetData.getString("asr_time", "03:30") ?: "03:30",
            widgetData.getString("maghrib_time", "06:00") ?: "06:00",
            widgetData.getString("isha_time", "07:30") ?: "07:30"
        )
        
        // Set prayer times
        views.setTextViewText(R.id.fajr_time, prayerTimes[0])
        views.setTextViewText(R.id.dhuhr_time, prayerTimes[2])
        views.setTextViewText(R.id.asr_time, prayerTimes[3])
        views.setTextViewText(R.id.maghrib_time, prayerTimes[4])
        views.setTextViewText(R.id.isha_time, prayerTimes[5])
        
        // Get next prayer info
        val nextPrayerName = widgetData.getString("next_prayer", "العصر") ?: "العصر"
        val timeRemaining = calculateTimeRemaining(widgetData)
        
        views.setTextViewText(R.id.next_prayer_name, nextPrayerName)
        views.setTextViewText(R.id.time_remaining, timeRemaining)
        
        // Current time
        val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
        views.setTextViewText(R.id.current_time, timeFormat.format(Date()))
        
        // Hijri date
        val now = Calendar.getInstance()
        val hijriDate = gregorianToHijri(
            now.get(Calendar.YEAR),
            now.get(Calendar.MONTH) + 1,
            now.get(Calendar.DAY_OF_MONTH)
        )
        // Ensure month index is within bounds
        val monthIndex = (hijriDate.month - 1).coerceIn(0, 11)
        views.setTextViewText(R.id.current_date, "${hijriDate.day} ${HIJRI_MONTHS[monthIndex]} ${hijriDate.year}")
        
        // Location
        val location = widgetData.getString("location", "الرياض") ?: "الرياض"
        views.setTextViewText(R.id.location, location)
        
        // Highlight next prayer in grid
        highlightNextPrayer(views, nextPrayerName, textColor, accentColor)
        
        // Set click intent - make entire widget clickable
        val intent = Intent(context, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            context,
            appWidgetId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_creative_root, pendingIntent)
        
        try {
            appWidgetManager.updateAppWidget(appWidgetId, views)
        } catch (e: Exception) {
            android.util.Log.e("CreativeWidget", "Error updating widget: ${e.message}")
        }
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
        
        if (nextPrayerTime == Long.MAX_VALUE || nextPrayerTime <= currentTime) {
            return "--:--"
        }
        
        val remainingMillis = nextPrayerTime - currentTime
        val hours = TimeUnit.MILLISECONDS.toHours(remainingMillis)
        val minutes = TimeUnit.MILLISECONDS.toMinutes(remainingMillis) % 60
        
        return if (hours > 0) {
            String.format("%d:%02d", hours, minutes)
        } else {
            String.format("%d د", minutes)
        }
    }
    
    private fun highlightNextPrayer(views: RemoteViews, nextPrayerName: String, textColor: Int, accentColor: Int) {
        // Reset all to default color
        val defaultColor = textColor
        val highlightColor = accentColor
        
        views.setTextColor(R.id.fajr_time, defaultColor)
        views.setTextColor(R.id.dhuhr_time, defaultColor)
        views.setTextColor(R.id.asr_time, defaultColor)
        views.setTextColor(R.id.maghrib_time, defaultColor)
        views.setTextColor(R.id.isha_time, defaultColor)
        
        // Highlight next prayer
        when (nextPrayerName) {
            "الفجر" -> views.setTextColor(R.id.fajr_time, highlightColor)
            "الظهر" -> views.setTextColor(R.id.dhuhr_time, highlightColor)
            "العصر" -> views.setTextColor(R.id.asr_time, highlightColor)
            "المغرب" -> views.setTextColor(R.id.maghrib_time, highlightColor)
            "العشاء" -> views.setTextColor(R.id.isha_time, highlightColor)
        }
    }
    
    // Hijri date calculation
    private data class HijriDate(val year: Int, val month: Int, val day: Int)
    
    private fun gregorianToHijri(year: Int, month: Int, day: Int): HijriDate {
        val jd = gregorianToJulian(year, month, day)
        return julianToHijri(jd)
    }
    
    private fun gregorianToJulian(year: Int, month: Int, day: Int): Double {
        var y = year
        var m = month
        
        if (m <= 2) {
            y -= 1
            m += 12
        }
        
        val a = y / 100
        val b = 2 - a + a / 4
        
        return Math.floor(365.25 * (y + 4716)) + 
               Math.floor(30.6001 * (m + 1)) + 
               day + b - 1524.5
    }
    
    private fun julianToHijri(jd: Double): HijriDate {
        val l = Math.floor(jd - 1948439.5 + 10632).toInt()
        val n = Math.floor((l - 1) / 10631.0).toInt()
        val l2 = l - 10631 * n + 354
        val j = (Math.floor((10985 - l2) / 5316.0) * Math.floor((50 * l2) / 17719.0) + 
                Math.floor(l2 / 5670.0) * Math.floor((43 * l2) / 15238.0)).toInt()
        val l3 = l2 - Math.floor((30 - j) / 15.0).toInt() * Math.floor((17719 * j) / 50.0).toInt() - 
                Math.floor(j / 16.0).toInt() * Math.floor((15238 * j) / 43.0).toInt() + 29
        val month = Math.floor((24 * l3) / 709.0).toInt()
        val day = l3 - Math.floor((709 * month) / 24.0).toInt()
        val year = 30 * n + j - 30
        
        return HijriDate(year, month, day)
    }
}
