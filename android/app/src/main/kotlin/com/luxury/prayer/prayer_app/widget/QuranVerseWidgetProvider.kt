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
import kotlin.random.Random

class QuranVerseWidgetProvider : AppWidgetProvider() {
    
    companion object {
        const val ACTION_REFRESH = "com.luxury.prayer.prayer_app.REFRESH_VERSE"
        
        // Sample verses for the widget
        private val verses = listOf(
            Triple("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ", "الفاتحة", "1"),
            Triple("الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ", "الفاتحة", "2"),
            Triple("الرَّحْمَٰنِ الرَّحِيمِ", "الفاتحة", "3"),
            Triple("إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ", "الفاتحة", "5"),
            Triple("قُلْ هُوَ اللَّهُ أَحَدٌ", "الإخلاص", "1"),
            Triple("اللَّهُ الصَّمَدُ", "الإخلاص", "2"),
            Triple("وَمَا تَوْفِيقِي إِلَّا بِاللَّهِ", "هود", "88"),
            Triple("إِنَّ مَعَ الْعُسْرِ يُسْرًا", "الشرح", "6"),
            Triple("فَإِنَّ مَعَ الْعُسْرِ يُسْرًا", "الشرح", "5"),
            Triple("وَاصْبِرْ وَمَا صَبْرُكَ إِلَّا بِاللَّهِ", "النحل", "127"),
            Triple("رَبِّ اشْرَحْ لِي صَدْرِي", "طه", "25"),
            Triple("وَيَسِّرْ لِي أَمْرِي", "طه", "26"),
            Triple("رَبِّ زِدْنِي عِلْمًا", "طه", "114"),
            Triple("حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ", "آل عمران", "173"),
            Triple("لَا إِلَٰهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ", "الأنبياء", "87"),
        )
    }
    
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        if (intent.action == ACTION_REFRESH) {
            val appWidgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
            if (appWidgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                updateWidget(context, appWidgetManager, appWidgetId, forceNewVerse = true)
            }
        }
    }
    
    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        forceNewVerse: Boolean = false
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)
        val views = RemoteViews(context.packageName, R.layout.widget_quran_verse)
        
        // Get or generate verse index
        val prefs = context.getSharedPreferences("quran_widget_$appWidgetId", Context.MODE_PRIVATE)
        val lastUpdate = prefs.getLong("last_update", 0)
        val currentTime = System.currentTimeMillis()
        val dayInMillis = 24 * 60 * 60 * 1000L
        
        val verseIndex = if (forceNewVerse || (currentTime - lastUpdate) > dayInMillis) {
            val newIndex = Random.nextInt(verses.size)
            prefs.edit()
                .putInt("verse_index", newIndex)
                .putLong("last_update", currentTime)
                .apply()
            newIndex
        } else {
            prefs.getInt("verse_index", 0)
        }
        
        val verse = verses[verseIndex]
        
        // Customization
        val accentHex = getSetting(widgetData, "quran_verse_accent_color", "quran verse_accent_color", "#FFC9A24D")
        val accentColor = try {
            Color.parseColor(accentHex)
        } catch (e: Exception) {
            Color.parseColor("#FFC9A24D")
        }
        
        // Set text values
        views.setTextViewText(R.id.tv_verse, verse.first)
        views.setTextViewText(R.id.tv_surah_name, "سورة ${verse.second}")
        views.setTextViewText(R.id.tv_verse_number, "الآية ${verse.third}")
        views.setTextColor(R.id.tv_header, accentColor)
        
        // Refresh button click
        val refreshIntent = Intent(context, QuranVerseWidgetProvider::class.java).apply {
            action = ACTION_REFRESH
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        val refreshPendingIntent = PendingIntent.getBroadcast(
            context,
            appWidgetId,
            refreshIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.tv_refresh, refreshPendingIntent)
        
        // Open app on click
        val appIntent = Intent(context, MainActivity::class.java)
        val appPendingIntent = PendingIntent.getActivity(
            context,
            appWidgetId + 1000,
            appIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_quran_root, appPendingIntent)
        
        try {
            appWidgetManager.updateAppWidget(appWidgetId, views)
        } catch (e: Exception) {
            android.util.Log.e("QuranVerseWidget", "Error updating widget: ${e.message}")
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
