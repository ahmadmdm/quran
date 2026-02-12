package com.luxury.prayer.prayer_app.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.app.PendingIntent
import android.media.AudioManager
import android.media.MediaPlayer
import android.net.Uri
import android.widget.RemoteViews
import com.luxury.prayer.prayer_app.R
import com.luxury.prayer.prayer_app.MainActivity
import es.antonborri.home_widget.HomeWidgetPlugin
import android.graphics.Color
import kotlin.random.Random

class QuranVerseWidgetProvider : AppWidgetProvider() {
    
    companion object {
        const val ACTION_REFRESH = "com.luxury.prayer.prayer_app.REFRESH_VERSE"
        const val ACTION_TOGGLE_AUDIO = "com.luxury.prayer.prayer_app.TOGGLE_QURAN_AUDIO"
        private var mediaPlayer: MediaPlayer? = null
        private var currentlyPlayingWidgetId: Int = AppWidgetManager.INVALID_APPWIDGET_ID
        private var currentlyPlayingVerseKey: String? = null
        
        // Sample verses for the widget
        private val verses = listOf(
            VerseEntry("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ", "الفاتحة", 1, 1),
            VerseEntry("الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ", "الفاتحة", 1, 2),
            VerseEntry("الرَّحْمَٰنِ الرَّحِيمِ", "الفاتحة", 1, 3),
            VerseEntry("إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ", "الفاتحة", 1, 5),
            VerseEntry("قُلْ هُوَ اللَّهُ أَحَدٌ", "الإخلاص", 112, 1),
            VerseEntry("اللَّهُ الصَّمَدُ", "الإخلاص", 112, 2),
            VerseEntry("وَمَا تَوْفِيقِي إِلَّا بِاللَّهِ", "هود", 11, 88),
            VerseEntry("إِنَّ مَعَ الْعُسْرِ يُسْرًا", "الشرح", 94, 6),
            VerseEntry("فَإِنَّ مَعَ الْعُسْرِ يُسْرًا", "الشرح", 94, 5),
            VerseEntry("وَاصْبِرْ وَمَا صَبْرُكَ إِلَّا بِاللَّهِ", "النحل", 16, 127),
            VerseEntry("رَبِّ اشْرَحْ لِي صَدْرِي", "طه", 20, 25),
            VerseEntry("وَيَسِّرْ لِي أَمْرِي", "طه", 20, 26),
            VerseEntry("رَبِّ زِدْنِي عِلْمًا", "طه", 20, 114),
            VerseEntry("حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ", "آل عمران", 3, 173),
            VerseEntry("لَا إِلَٰهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ", "الأنبياء", 21, 87),
        )

        private fun buildAudioUrl(surah: Int, verse: Int): String {
            val surahPart = surah.toString().padStart(3, '0')
            val versePart = verse.toString().padStart(3, '0')
            return "https://everyayah.com/data/Alafasy_128kbps/$surahPart$versePart.mp3"
        }
    }

    data class VerseEntry(
        val text: String,
        val surahName: String,
        val surahNumber: Int,
        val verseNumber: Int,
    )

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        stopAudio()
        currentlyPlayingWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
        currentlyPlayingVerseKey = null
    }

    private fun stopAudio() {
        try {
            mediaPlayer?.stop()
            mediaPlayer?.reset()
            mediaPlayer?.release()
        } catch (_: Exception) {
        } finally {
            mediaPlayer = null
        }
    }

    private fun toggleVerseAudio(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        verse: VerseEntry
    ) {
        val verseKey = "${verse.surahNumber}:${verse.verseNumber}"
        val isSameVerse =
            currentlyPlayingWidgetId == appWidgetId && currentlyPlayingVerseKey == verseKey && mediaPlayer?.isPlaying == true

        if (isSameVerse) {
            stopAudio()
            currentlyPlayingWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
            currentlyPlayingVerseKey = null
            updateWidget(context, appWidgetManager, appWidgetId, forceNewVerse = false)
            return
        }

        stopAudio()
        try {
            val player = MediaPlayer().apply {
                setAudioStreamType(AudioManager.STREAM_MUSIC)
                setDataSource(context, Uri.parse(buildAudioUrl(verse.surahNumber, verse.verseNumber)))
                setOnPreparedListener { it.start() }
                setOnCompletionListener {
                    currentlyPlayingWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
                    currentlyPlayingVerseKey = null
                    val manager = AppWidgetManager.getInstance(context)
                    updateWidget(context, manager, appWidgetId, forceNewVerse = false)
                }
                setOnErrorListener { _, _, _ ->
                    currentlyPlayingWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
                    currentlyPlayingVerseKey = null
                    true
                }
                prepareAsync()
            }
            mediaPlayer = player
            currentlyPlayingWidgetId = appWidgetId
            currentlyPlayingVerseKey = verseKey
        } catch (_: Exception) {
            stopAudio()
            currentlyPlayingWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
            currentlyPlayingVerseKey = null
        }

        updateWidget(context, appWidgetManager, appWidgetId, forceNewVerse = false)
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
            return
        }

        if (intent.action == ACTION_TOGGLE_AUDIO) {
            val appWidgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
            if (appWidgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val prefs = context.getSharedPreferences("quran_widget_$appWidgetId", Context.MODE_PRIVATE)
                val verseIndex = prefs.getInt("verse_index", 0).coerceIn(0, verses.lastIndex)
                toggleVerseAudio(context, appWidgetManager, appWidgetId, verses[verseIndex])
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
        val bgHex = getSetting(widgetData, "quran_verse_background_color", "quran verse_background_color", "#FF0F1629")
        val textHex = getSetting(widgetData, "quran_verse_text_color", "quran verse_text_color", "#FFFFFFFF")
        val accentHex = getSetting(widgetData, "quran_verse_accent_color", "quran verse_accent_color", "#FFC9A24D")

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
        
        // Apply background and text customization
        views.setInt(R.id.iv_quran_bg, "setColorFilter", bgColor)

        // Set text values
        views.setTextViewText(R.id.tv_verse, verse.text)
        views.setTextViewText(R.id.tv_surah_name, "سورة ${verse.surahName}")
        views.setTextViewText(R.id.tv_verse_number, "الآية ${verse.verseNumber}")
        val isPlayingThisWidget = currentlyPlayingWidgetId == appWidgetId && mediaPlayer?.isPlaying == true
        views.setTextViewText(R.id.tv_quran_icon, if (isPlayingThisWidget) "⏸" else "▶")
        views.setTextColor(R.id.tv_quran_icon, accentColor)
        views.setTextColor(R.id.tv_header, accentColor)
        views.setTextColor(R.id.tv_verse, textColor)
        views.setTextColor(R.id.tv_surah_name, Color.argb(190, Color.red(textColor), Color.green(textColor), Color.blue(textColor)))
        views.setTextColor(R.id.tv_verse_number, Color.argb(190, Color.red(textColor), Color.green(textColor), Color.blue(textColor)))
        views.setTextColor(R.id.tv_refresh, Color.argb(170, Color.red(textColor), Color.green(textColor), Color.blue(textColor)))
        views.setTextViewText(R.id.tv_refresh, "↻")
        
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

        val audioIntent = Intent(context, QuranVerseWidgetProvider::class.java).apply {
            action = ACTION_TOGGLE_AUDIO
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        val audioPendingIntent = PendingIntent.getBroadcast(
            context,
            appWidgetId + 5000,
            audioIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.tv_quran_icon, audioPendingIntent)
        
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
