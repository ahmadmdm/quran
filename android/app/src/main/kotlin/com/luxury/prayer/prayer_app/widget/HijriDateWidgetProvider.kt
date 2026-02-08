package com.luxury.prayer.prayer_app.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.luxury.prayer.prayer_app.MainActivity
import com.luxury.prayer.prayer_app.R
import java.text.SimpleDateFormat
import java.util.*

class HijriDateWidgetProvider : AppWidgetProvider() {

    companion object {
        private val HIJRI_MONTHS = arrayOf(
            "محرم", "صفر", "ربيع الأول", "ربيع الثاني",
            "جمادى الأولى", "جمادى الآخرة", "رجب", "شعبان",
            "رمضان", "شوال", "ذو القعدة", "ذو الحجة"
        )
        
        private val ARABIC_DAYS = arrayOf(
            "الأحد", "الإثنين", "الثلاثاء", "الأربعاء",
            "الخميس", "الجمعة", "السبت"
        )
        
        private val ARABIC_MONTHS = arrayOf(
            "يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو",
            "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"
        )
        
        // Hijri calendar calculation constants
        private const val HIJRI_EPOCH = 1948439.5 // Julian day of Hijri epoch
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
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_hijri_date)
        
        val now = Calendar.getInstance()
        
        // Get day name in Arabic
        val dayOfWeek = now.get(Calendar.DAY_OF_WEEK) - 1
        views.setTextViewText(R.id.day_name_ar, ARABIC_DAYS[dayOfWeek])
        
        // Calculate Hijri date
        val hijriDate = gregorianToHijri(
            now.get(Calendar.YEAR),
            now.get(Calendar.MONTH) + 1,
            now.get(Calendar.DAY_OF_MONTH)
        )
        
        views.setTextViewText(R.id.hijri_day, hijriDate.day.toString())
        // Ensure month index is within bounds
        val monthIndex = (hijriDate.month - 1).coerceIn(0, 11)
        views.setTextViewText(R.id.hijri_month, HIJRI_MONTHS[monthIndex])
        views.setTextViewText(R.id.hijri_year, "${hijriDate.year} هـ")
        
        // Gregorian date in Arabic
        val gregorianMonth = ARABIC_MONTHS[now.get(Calendar.MONTH)]
        val gregorianDay = now.get(Calendar.DAY_OF_MONTH)
        val gregorianYear = now.get(Calendar.YEAR)
        views.setTextViewText(R.id.gregorian_date, "$gregorianDay $gregorianMonth $gregorianYear")
        
        // Current time
        val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
        views.setTextViewText(R.id.current_time, timeFormat.format(now.time))
        
        // Set click intent to open app - make entire widget clickable
        val intent = Intent(context, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            context,
            appWidgetId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_hijri_root, pendingIntent)
        
        try {
            appWidgetManager.updateAppWidget(appWidgetId, views)
        } catch (e: Exception) {
            android.util.Log.e("HijriDateWidget", "Error updating widget: ${e.message}")
        }
    }
    
    // Hijri date calculation
    private data class HijriDate(val year: Int, val month: Int, val day: Int)
    
    private fun gregorianToHijri(year: Int, month: Int, day: Int): HijriDate {
        // Calculate Julian Day Number
        val jd = gregorianToJulian(year, month, day)
        
        // Calculate Hijri date from Julian Day
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
