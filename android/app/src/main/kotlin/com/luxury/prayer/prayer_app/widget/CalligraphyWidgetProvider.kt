package com.luxury.prayer.prayer_app.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.luxury.prayer.prayer_app.MainActivity
import com.luxury.prayer.prayer_app.R
import java.util.*
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Typeface
import android.graphics.Color
import es.antonborri.home_widget.HomeWidgetPlugin

class CalligraphyWidgetProvider : AppWidgetProvider() {

    companion object {
        private val ARABIC_DAYS = arrayOf(
            "الأحد", "الإثنين", "الثلاثاء", "الأربعاء",
            "الخميس", "الجمعة", "السبت"
        )
        
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
        val widgetData = HomeWidgetPlugin.getData(context)
        val views = RemoteViews(context.packageName, R.layout.widget_calligraphy)

        // Customization - Load specific keys first, fall back to global if not found
        // Note: Flutter saves as "calligraphy_..." now.
        // We check "calligraphy_..." keys.
        val bgHex = widgetData.getString("calligraphy_background_color", 
            widgetData.getString("widget_background_color", "#FF0F1629"))
        val textHex = widgetData.getString("calligraphy_text_color", 
            widgetData.getString("widget_text_color", "#FFFFFFFF"))
        val fontStyle = widgetData.getString("calligraphy_font_style", "default") ?: "default"
        
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

        // Apply Customization
        views.setInt(R.id.iv_background, "setColorFilter", bgColor)
        
        // Secondary text slightly transparent or same color
        val secondaryColor = Color.argb(200, Color.red(textColor), Color.green(textColor), Color.blue(textColor))
        views.setTextColor(R.id.tv_full_date, secondaryColor)
        
        val now = Calendar.getInstance()
        
        // Day Name
        val dayOfWeek = now.get(Calendar.DAY_OF_WEEK) - 1
        val dayName = ARABIC_DAYS[dayOfWeek]
        
        // Render Day Name to Bitmap with Custom Font
        val bitmap = createBitmapFromText(context, dayName, fontStyle, textColor)
        views.setImageViewBitmap(R.id.iv_day_name, bitmap)
        // Hide TextView if we are using ImageView (we need to update layout to have both or switch visibility)
        // For now, assuming we will replace TextView with ImageView in XML or use existing one.
        // Let's check layout first. We have tv_day_name. We need iv_day_name.
        views.setViewVisibility(R.id.tv_day_name, android.view.View.GONE)
        views.setViewVisibility(R.id.iv_day_name, android.view.View.VISIBLE)
        
        // Hijri Date Calculation
        val adjustment = widgetData.getInt("hijri_adjustment", 0)
        now.add(Calendar.DAY_OF_MONTH, adjustment)
        val hijriDate = gregorianToHijri(
            now.get(Calendar.YEAR),
            now.get(Calendar.MONTH) + 1,
            now.get(Calendar.DAY_OF_MONTH)
        )
        
        // Format: 20 Sha'ban, 1447
        val formattedDate = "${toArabicDigits(hijriDate.day)} ${HIJRI_MONTHS[hijriDate.month - 1]}، ${toArabicDigits(hijriDate.year)}"
        views.setTextViewText(R.id.tv_full_date, formattedDate)

        // Click Intent
        val intent = Intent(context, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            context,
            appWidgetId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_calligraphy_root, pendingIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
    
    private fun toArabicDigits(number: Int): String {
        return number.toString()
            .replace('0', '٠')
            .replace('1', '١')
            .replace('2', '٢')
            .replace('3', '٣')
            .replace('4', '٤')
            .replace('5', '٥')
            .replace('6', '٦')
            .replace('7', '٧')
            .replace('8', '٨')
            .replace('9', '٩')
    }

    // Hijri Calculation Logic (Duplicated from HijriDateWidgetProvider for independence)
    private data class HijriDate(val year: Int, val month: Int, val day: Int)
    
    // Note: RemoteViews doesn't support setTypeface directly for custom fonts without file access.
    // However, we can create a bitmap for complex rendering if needed, but for now we rely on system fonts.
    // The user requested "creative fonts", so we map to available system styles.
    // Ideally, we would render text to Bitmap if we had the font files.
    
    private fun createBitmapFromText(context: Context, text: String, fontStyle: String, color: Int): Bitmap {
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        paint.textSize = 200f // Large size for high quality
        paint.color = color
        paint.textAlign = Paint.Align.CENTER

        // Select Typeface
        val typeface = when (fontStyle) {
            "serif" -> Typeface.create(Typeface.SERIF, Typeface.BOLD)
            "monospace" -> Typeface.create(Typeface.MONOSPACE, Typeface.BOLD)
            "cursive" -> Typeface.create(Typeface.SANS_SERIF, Typeface.ITALIC) // Fallback as standard cursive not reliable
            else -> Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        }
        paint.typeface = typeface

        val baseline = -paint.ascent() // ascent() is negative
        val width = (paint.measureText(text) + 50).toInt() // Add padding
        val height = (baseline + paint.descent() + 50).toInt()
        
        val bitmap = Bitmap.createBitmap(Math.max(width, 1), Math.max(height, 1), Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        
        // Draw centered
        canvas.drawText(text, width / 2f, baseline + 25, paint)
        
        return bitmap
    }

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
